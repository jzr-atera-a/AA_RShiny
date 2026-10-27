# ============================================================================
# CLAUDE CLIENT - R6 CLASS
# Same approach as APIManager in Modular_db_books_llm (httr POST to the
# Messages API, configurable model / max tokens / timeout, friendly errors),
# extended with: system prompt, multi-turn messages, usage counters and
# messages in Spanish.
# ============================================================================

CLAUDE_URL <- "https://api.anthropic.com/v1/messages"

CLAUDE_MODELS <- c(
  "Claude Sonnet 5.5 (recomendado: rápido y muy bueno)" = "claude-sonnet-5-5",
  "Claude Opus 5.5 (el más capaz, más lento)" = "claude-opus-5-5",
  "Claude Haiku 5.5 (el más rápido y económico)" = "claude-haiku-5-5",
  "Claude Sonnet 4.6 (versión anterior)" = "claude-sonnet-4-6",
  "Otro modelo (escribirlo abajo)" = "__other__"
)

ClaudeClient <- R6::R6Class(
  "ClaudeClient",
  public = list(
    api_key = NULL,
    model = "claude-sonnet-5-5",
    max_tokens = 4000,
    timeout = 300,
    connected = FALSE,
    last_error = NULL,
    last_test = NULL,
    calls = 0L,
    tokens_in = 0,
    tokens_out = 0,
    mock = FALSE,          # TRUE only for offline testing (env var TESIS_MOCK_CLAUDE=1)

    initialize = function() {
      self$mock <- identical(Sys.getenv("TESIS_MOCK_CLAUDE"), "1")
    },

    set_credentials = function(api_key = NULL, model = NULL, max_tokens = NULL, timeout = NULL) {
      if (!is.null(api_key)) {
        key <- trimws(api_key)
        if (!identical(key, self$api_key)) self$connected <- FALSE
        self$api_key <- key
      }
      if (!is.null(model) && nzchar(model)) self$model <- model
      if (!is.null(max_tokens) && !is.na(max_tokens)) self$max_tokens <- as.integer(max_tokens)
      if (!is.null(timeout) && !is.na(timeout)) self$timeout <- as.integer(timeout)
      invisible(self)
    },

    has_key = function() !is.null(self$api_key) && nzchar(self$api_key),

    masked_key = function() {
      if (!self$has_key()) return("(sin clave)")
      k <- self$api_key
      paste0(substr(k, 1, 10), "…", substr(k, max(1, nchar(k) - 3), nchar(k)))
    },

    # Short call to check key + model
    test = function() {
      res <- self$chat(system = "Responde solo con la palabra: listo",
                       messages = list(list(role = "user", content = "Prueba de conexión.")),
                       max_tokens = 20, require_connected = FALSE)
      self$connected <- TRUE
      self$last_test <- Sys.time()
      res
    },

    # messages: list(list(role = "user"/"assistant", content = "..."))
    # Returns list(text, usage = list(input_tokens, output_tokens), model)
    chat = function(system = NULL, messages, max_tokens = NULL, require_connected = TRUE) {
      if (!self$has_key()) stop("Todavía no hay una clave de Claude. Escríbala en la pestaña “Conexión con Claude”.")
      if (require_connected && !self$connected)
        stop("Claude todavía no está conectado. Presione “Probar conexión” en la pestaña “Conexión con Claude”.")

      tokens <- as.integer(max_tokens %||% self$max_tokens)

      if (isTRUE(self$mock)) return(self$mock_reply(system, messages))

      body <- list(model = self$model, max_tokens = tokens, messages = messages)
      if (!is.null(system) && nzchar(system)) body$system <- system

      response <- tryCatch(
        httr::POST(
          url = CLAUDE_URL,
          httr::add_headers(
            "x-api-key" = self$api_key,
            "anthropic-version" = "2023-06-01",
            "content-type" = "application/json"
          ),
          body = jsonlite::toJSON(body, auto_unbox = TRUE),
          encode = "raw",
          httr::timeout(self$timeout)
        ),
        error = function(e) {
          msg <- conditionMessage(e)
          self$last_error <- msg
          if (grepl("timeout|timed out", msg, ignore.case = TRUE)) {
            stop(sprintf("Claude tardó más de %s segundos en responder. Intente de nuevo, o aumente el tiempo de espera en “Conexión con Claude”.", self$timeout))
          }
          stop(paste0("No se pudo conectar con Claude. Revise que la computadora tenga internet. (Detalle: ", msg, ")"))
        }
      )

      status <- httr::status_code(response)
      parsed <- tryCatch(httr::content(response, "parsed", encoding = "UTF-8"), error = function(e) NULL)

      if (status != 200) {
        detail <- if (is.list(parsed) && !is.null(parsed$error$message)) parsed$error$message else paste("HTTP", status)
        self$last_error <- detail
        if (status %in% c(401, 403)) self$connected <- FALSE
        msg <- switch(as.character(status),
          "400" = paste0("Claude no pudo procesar la solicitud. (Detalle: ", detail, ")"),
          "401" = "La clave de Claude no es válida. Revísela en la pestaña “Conexión con Claude”.",
          "403" = "Esta clave no tiene permiso para usar ese modelo. Pruebe con otro modelo.",
          "404" = paste0("No se encontró el modelo “", self$model, "”. Elija otro modelo en “Conexión con Claude”."),
          "429" = "Se hicieron demasiadas solicitudes seguidas. Espere un minuto e intente de nuevo.",
          "500" = "Claude tuvo un problema de su lado. Intente de nuevo en unos minutos.",
          "529" = "Claude está muy ocupado en este momento. Intente de nuevo en unos minutos.",
          paste0("Claude respondió con un error. (Detalle: ", detail, ")")
        )
        stop(msg)
      }

      if (is.null(parsed$content) || length(parsed$content) == 0) {
        stop("Claude respondió vacío. Intente de nuevo.")
      }
      texts <- vapply(parsed$content, function(b) if (identical(b$type, "text")) b$text %||% "" else "", character(1))
      text <- paste(texts[nzchar(texts)], collapse = "\n\n")

      usage <- list(input_tokens = parsed$usage$input_tokens %||% 0,
                    output_tokens = parsed$usage$output_tokens %||% 0)
      self$calls <- self$calls + 1L
      self$tokens_in <- self$tokens_in + usage$input_tokens
      self$tokens_out <- self$tokens_out + usage$output_tokens
      self$last_error <- NULL
      if (identical(parsed$stop_reason, "max_tokens")) {
        text <- paste0(text, "\n\n*(La respuesta se cortó porque llegó al máximo de extensión. Puede aumentar “Extensión máxima de respuesta” en Conexión con Claude.)*")
      }
      list(text = text, usage = usage, model = parsed$model %||% self$model)
    },

    # Offline stand-in used only for automated testing
    mock_reply = function(system, messages) {
      last <- messages[[length(messages)]]$content
      Sys.sleep(0.3)
      self$calls <- self$calls + 1L
      txt <- if (grepl("FORMATO_JSON_BOSQUEJO", last)) {
        '{"titulo":"Del Estado administrador a la gerencia pública en México (1980–2026)","pregunta":"¿Cómo cambió la administración pública federal mexicana entre 1980 y 2026?","hipotesis":"La administración pública pasó de un modelo centralizado a uno gerencial, sin perder rasgos del Estado posrevolucionario.","objetivo_general":"Analizar la transformación de la administración pública federal entre 1980 y 2026.","objetivos_especificos":["Describir el modelo de 1980","Identificar las reformas clave","Evaluar sus resultados"],"justificacion":"Testimonio de una generación formada en el plan 1979–80.","marco_teorico":"Teoría del Estado, nueva gerencia pública, institucionalismo.","metodologia":"Análisis histórico-documental con entrevistas.","alcances":"Administración pública federal; 1980–2026.","capitulos":[{"titulo":"Marco teórico: del Estado a la gerencia","descripcion":"Conceptos y autores."},{"titulo":"El Estado administrador (1970–1982)","descripcion":"Contexto y estructura."},{"titulo":"Las reformas (1982–2000)","descripcion":"Ajuste y modernización."},{"titulo":"Gerencia pública y alternancia (2000–2026)","descripcion":"Nuevos modelos."}]}'
      } else if (grepl("FORMATO_JSON_TEMAS", last)) {
        '[{"titulo":"El municipio mexicano de 1983 a hoy","descripcion":"La reforma al artículo 115 y sus efectos.","por_que":"Une gobierno local y su experiencia."},{"titulo":"Paridad de género en la administración pública","descripcion":"De 1980 a la paridad en todo.","por_que":"Tema actual con raíz histórica."}]'
      } else if (grepl("<texto_corregido>", last, fixed = TRUE)) {
        paste0("<texto_corregido>", sub("(?s).*<texto>\\s*(.*?)\\s*</texto>.*", "\\1", last, perl = TRUE), " (corregido)</texto_corregido>\n\n**Cambios:** se corrigieron acentos.")
      } else {
        "## Comentarios\n\n**Lo que funciona bien:** el tema es claro y tiene relevancia.\n\n**Lo que conviene mejorar:**\n\n1. Delimitar el periodo.\n2. Precisar la pregunta.\n\n**Siguiente paso:** escriba la pregunta en una sola frase."
      }
      list(text = txt, usage = list(input_tokens = 100, output_tokens = 80), model = "mock")
    }
  )
)
