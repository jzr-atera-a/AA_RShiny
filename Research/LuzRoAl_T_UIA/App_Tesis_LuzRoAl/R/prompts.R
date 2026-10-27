# ============================================================================
# PROMPTS FOR CLAUDE (all in Spanish)
# ============================================================================

FEEDBACK_STYLES <- c(
  "Amable y breve (lo esencial, con ánimo)" = "breve",
  "Amable y detallado (explica cada punto)" = "detallado",
  "Exigente, como un sinodal (señala todo lo que falta)" = "exigente"
)

style_instruction <- function(style) {
  switch(style %||% "detallado",
    breve = "Sé breve: máximo 5 puntos y unas 250 palabras. Empieza por lo que está bien.",
    exigente = "Actúa como un sinodal riguroso pero respetuoso: señala con precisión todo lo que falta o se debe corregir, ordenado por importancia.",
    "Explica cada punto con claridad y da ejemplos concretos. Empieza por lo que está bien."
  )
}

# System prompt shared by every call
build_system_prompt <- function(cfg, project_context = "") {
  autor <- cfg$author_name %||% ""
  gen <- cfg$generacion %||% ""
  paste0(
    "Eres un asesor de tesis de licenciatura en ", CARRERA, " de la ", UNIVERSIDAD, ". ",
    "Acompañas a una persona adulta mayor", if (nzchar(autor)) paste0(" (", autor, ")") else "",
    " que estudió la carrera", if (nzchar(gen)) paste0(" (generación ", gen, ")") else "",
    " con el plan de 1979–1980 (sociología política, marxismo, funcionalismo, administración del Estado, ",
    "historia política de México, métodos de investigación) y que ahora culmina su carrera con una tesis. ",
    "El plan actual de la carrera pone más peso en políticas públicas, gerencia pública, derechos humanos, ",
    "género, democracia y sostenibilidad, comunicación política y política global; puedes tender puentes entre ambos.\n\n",
    "Reglas:\n",
    "- Escribe siempre en español de México, tratando de usted, con calidez y respeto, frases claras y sin tecnicismos innecesarios.\n",
    "- Usa formato Markdown sencillo: títulos cortos (##), listas numeradas y negritas para lo importante. Nada de tablas muy anchas.\n",
    "- Eres tutor, no autor: guía, pregunta, sugiere y revisa; cuando des ejemplos de redacción, márcalos como ejemplo y anima a que la persona use sus propias palabras.\n",
    "- Valora la experiencia de vida de la persona como fuente (testimonio), siempre contrastada con otras fuentes.\n",
    "- Si mencionas autores, libros o datos, sé prudente: indica que deben verificarse y no inventes referencias exactas (páginas, DOI) si no estás seguro.\n",
    "- Termina con un “Siguiente paso” concreto y alcanzable.\n",
    "- Estilo de retroalimentación: ", style_instruction(cfg$feedback_style), "\n",
    "- Normas de citación de la tesis: ", cfg$citation_style %||% "APA 7.ª edición", ".\n",
    if (nzchar(cfg$extra_instructions %||% "")) paste0("\nIndicaciones adicionales del administrador:\n", cfg$extra_instructions, "\n") else "",
    if (nzchar(project_context)) paste0("\n=== CONTEXTO DEL PROYECTO DE TESIS (hasta ahora) ===\n", project_context, "\n") else ""
  )
}

prompt_free_question <- function(question, where = "") {
  paste0(if (nzchar(where)) paste0("(Estoy en la sección: ", where, ")\n\n") else "", question)
}

prompt_idea_feedback <- function(idea) {
  paste0(
    "Esta es una de mis ideas para la tesis. Dame tu opinión como asesor:\n\n",
    "**Título:** ", idea$titulo, "\n",
    "**Descripción:** ", idea$descripcion %||% "", "\n",
    "**Por qué me importa / mi experiencia:** ", idea$experiencia %||% "", "\n",
    "**Materias relacionadas:** ", paste(unlist(idea$materias), collapse = ", "), "\n\n",
    "Por favor incluye: 1) qué tiene de valioso; 2) qué tan viable es como tesis de licenciatura; ",
    "3) cómo delimitarla (lugar, periodo, actores); 4) dos o tres posibles preguntas de investigación; ",
    "5) qué fuentes podría usar; 6) siguiente paso."
  )
}

prompt_suggest_topics <- function(experiencia, intereses, materias) {
  paste0(
    "Ayúdame a encontrar temas de tesis. Sobre mí:\n\n",
    "**Mi experiencia de vida y de trabajo:** ", experiencia, "\n",
    "**Lo que me interesa hoy:** ", intereses, "\n",
    "**Materias o enfoques que me gustan:** ", paste(materias, collapse = ", "), "\n\n",
    "Propón 5 temas de tesis viables para una licenciatura en ", CARRERA, ", que aprovechen mi experiencia ",
    "y unan lo que estudié en el plan 1979–80 con los enfoques actuales.\n\n",
    "FORMATO_JSON_TEMAS: responde SOLO con un arreglo JSON (sin texto antes ni después) de 5 objetos con las claves ",
    "\"titulo\" (máx. 15 palabras), \"descripcion\" (2 frases) y \"por_que\" (1 frase: por qué me queda bien)."
  )
}

prompt_outline_propose <- function(tema) {
  paste0(
    "Con base en mi tema elegido, propón un bosquejo de tesis de licenciatura.\n\n",
    "**Tema:** ", tema$titulo, "\n**Descripción:** ", tema$descripcion %||% "", "\n",
    "**Mi experiencia relacionada:** ", tema$experiencia %||% "", "\n\n",
    "FORMATO_JSON_BOSQUEJO: responde SOLO con un objeto JSON (sin texto antes ni después) con estas claves: ",
    "\"titulo\", \"pregunta\", \"hipotesis\", \"objetivo_general\", \"objetivos_especificos\" (arreglo de 3 a 5 textos), ",
    "\"justificacion\", \"marco_teorico\", \"metodologia\", \"alcances\", ",
    "\"capitulos\" (arreglo de 3 a 5 objetos con \"titulo\" y \"descripcion\" de 1 o 2 frases). ",
    "No incluyas la introducción ni las conclusiones como capítulos."
  )
}

prompt_outline_review <- function(outline_text) {
  paste0(
    "Revisa mi bosquejo de tesis. Evalúa: claridad y delimitación de la pregunta, coherencia entre pregunta, ",
    "hipótesis, objetivos y capítulos, si el marco teórico y la metodología son adecuados, y si es viable. ",
    "Señala lo que falta y propón mejoras concretas.\n\n", outline_text
  )
}

prompt_section_review <- function(part_title, guide, text, extra = "") {
  paste0(
    "Revisa este texto de mi tesis. Sección: **", part_title, "**.\n",
    "Lo que esta sección debe lograr: ", guide, "\n\n",
    extra,
    "Evalúa contenido (¿cumple su función?), argumentación y evidencia, coherencia con mi bosquejo, ",
    "claridad de la redacción y uso de fuentes. Cita frases concretas de mi texto cuando sugieras cambios.\n\n",
    "=== MI TEXTO ===\n", clip_text(text)
  )
}

prompt_section_start <- function(part_title, guide, text, extra = "") {
  paste0(
    "Ayúdame a ", if (nzchar(trimws(text))) "continuar" else "empezar", " esta sección de mi tesis: **", part_title, "**.\n",
    "Lo que esta sección debe lograr: ", guide, "\n\n", extra,
    "Dame: 1) un orden sugerido de párrafos (qué va en cada uno); 2) preguntas que debo responderme para escribirla; ",
    "3) un párrafo de EJEMPLO corto, claramente marcado como ejemplo, para inspirarme (no para copiarlo).",
    if (nzchar(trimws(text))) paste0("\n\n=== LO QUE LLEVO ESCRITO ===\n", clip_text(text, 12000)) else ""
  )
}

prompt_section_correct <- function(text) {
  paste0(
    "Corrige la ortografía, la puntuación y la gramática de mi texto, y mejora un poco la claridad SIN cambiar ",
    "mis ideas, mi voz ni la estructura de párrafos. No agregues contenido nuevo.\n\n",
    "Responde exactamente así:\n<texto_corregido>\n(el texto completo corregido)\n</texto_corregido>\n",
    "Después, en una lista corta, los cambios más importantes que hiciste.\n\n",
    "<texto>\n", clip_text(text, 30000), "\n</texto>"
  )
}

prompt_sources <- function(part_title, text, extra = "") {
  paste0(
    "Para la sección **", part_title, "** de mi tesis, sugiere fuentes que me conviene consultar: ",
    "documentos oficiales y bases de datos mexicanas, autores y obras clásicas o recientes, archivos y personas a entrevistar. ",
    "Agrupa por tipo, explica en una línea para qué sirve cada una y marca con (verificar) lo que yo deba confirmar.\n\n",
    extra, "=== LO QUE LLEVO ESCRITO ===\n", clip_text(text, 10000)
  )
}

prompt_conclusion_coherence <- function(intro, concl) {
  paste0(
    "Compara mi introducción con mis conclusiones. ¿Las conclusiones responden la pregunta y los objetivos planteados? ",
    "¿Hay promesas de la introducción que no se cumplen o hallazgos que no se anunciaron? Sugiere ajustes concretos.\n\n",
    "=== INTRODUCCIÓN ===\n", clip_text(intro, 14000), "\n\n=== CONCLUSIONES ===\n", clip_text(concl, 14000)
  )
}
