# ============================================================================
# CONTENT: the degree (then and now), the thesis guide and the writing parts
# Everything the user reads is in Mexican Spanish (usted).
# ============================================================================

CARRERA <- "Ciencias Políticas y Administración Pública"
UNIVERSIDAD <- "Universidad Iberoamericana (IBERO), Ciudad de México"

# ---------------------------------------------------------------- Plan 1979-80
PLAN_1979 <- list(
  resumen = paste(
    "Los planes de estudio de la IBERO de finales de los años 70 no están digitalizados materia por materia.",
    "Según la Biblioteca Francisco Xavier Clavigero (Historia de las Carreras de la IBERO 1943–2021),",
    "el plan vigente en 1979–1980 tenía un enfoque centrado en la sociología política, el marxismo,",
    "el funcionalismo y el análisis de la administración del Estado."
  ),
  ejes = list(
    list(titulo = "Teoría del Estado y Filosofía Política",
         texto = "Pensadores clásicos (Maquiavelo, los contractualistas) con visiones estructural-funcionalistas y el auge del análisis marxista, muy común en las ciencias sociales latinoamericanas de la época."),
    list(titulo = "Historia Política de México",
         texto = "La consolidación del Estado posrevolucionario y el régimen de partido hegemónico."),
    list(titulo = "Administración del Estado",
         texto = "Organización gubernamental, derecho administrativo, finanzas públicas y burocracia."),
    list(titulo = "Métodos y Técnicas de Investigación",
         texto = "Metodología de la investigación social, técnicas estadísticas aplicadas y lectura crítica de textos sociopolíticos.")
  )
)

# ---------------------------------------------------------------- Plan actual
PLAN_ACTUAL <- list(
  "Semestre 1" = c("Teoría Política Clásica", "Taller de Escritura Académica",
                   "Introducción a las Ciencias Políticas y la Administración Pública", "Taller de Integración Universitaria",
                   "Estadística Aplicada a las Ciencias Sociales", "Teoría del Estado y Principios Constitucionales",
                   "Introducción a la Investigación de las Ciencias Sociales"),
  "Semestre 2" = c("Teoría Política Moderna", "Contexto Histórico Contemporáneo", "Derecho Administrativo I",
                   "Taller de Investigación Social", "Administración Pública", "Métodos Estadísticos",
                   "Perspectivas Contemporáneas de Economía Política"),
  "Semestre 3" = c("Teoría Política Contemporánea", "Administración y Gobierno Local",
                   "Pensamiento Político y Social Latinoamericano", "La Persona en su Entorno Socioambiental",
                   "Políticas Públicas y Derechos Humanos", "Métodos de Investigación", "Economía y Finanzas Públicas"),
  "Semestre 4" = c("Análisis de Políticas Públicas", "Sistema Político Mexicano", "Historia Política de México",
                   "Investigación Social Aplicada", "Interpersonalidad y Trascendencias", "Ciencias Políticas"),
  "Semestre 5" = c("Partidos y Sistemas Electorales", "Sociología Política", "Gerencia Pública",
                   "Sistemas Políticos y Gobiernos Contemporáneos", "Ciudadanía Mundial y Medio Ambiente",
                   "Evaluación de Políticas Públicas", "Género y Política"),
  "Semestre 6" = c("Optativa 1", "Optativa 2", "Comunicación Política", "Construcción de Democracia y Sostenibilidad",
                   "Análisis Político de Coyuntura", "Geopolítica y Negocios"),
  "Semestre 7" = c("Optativa 3", "Optativa 4", "Taller de Formación y Acción Social", "Seminario de Investigación Política I"),
  "Semestre 8" = c("Optativa 5", "Optativa 6", "Seminario de Investigación Política II")
)

# Áreas de formación del plan actual (folleto oficial de la licenciatura)
AREAS_ACTUALES <- c("Administración pública", "Teoría política", "Estrategias políticas y electorales",
                    "Democracia y actores políticos", "Investigación política y social", "Política global",
                    "Políticas públicas")

RASGOS_IBERO <- c(
  "Primera universidad privada del país en ofrecer la carrera (desde 1964).",
  "Equilibrio entre ciencias políticas y administración pública a lo largo de la carrera.",
  "Enfoque aplicado, con estudio de casos para el análisis político.",
  "Enfoque plural, con tradición más europea y bases sociológicas cualitativas.",
  "Pedagogía ignaciana y perspectiva humanista: justicia, igualdad y solidaridad.",
  "Las personas como agentes de cambio en realidades locales y globales."
)

PERFIL_EGRESO <- c(
  "Participar en el diseño de políticas públicas federales, estatales y locales.",
  "Diseñar procesos organizacionales para la administración pública.",
  "Generar estrategias políticas y electorales.",
  "Crear campañas de comunicación política y social.",
  "Orientar la toma de decisiones en asuntos públicos, políticos y sociales."
)

# Subjects offered as tags for ideas (old axes + current plan, without the electives placeholders)
MATERIAS_CHOICES <- function() {
  actuales <- unique(unlist(PLAN_ACTUAL))
  actuales <- actuales[!grepl("^Optativa", actuales)]
  list(
    "Plan 1979–1980 (lo que usted estudió)" = vapply(PLAN_1979$ejes, function(e) e$titulo, character(1)),
    "Plan actual (2026)" = sort(actuales)
  )
}

# ------------------------------------------------------------- Ruta de trabajo
RUTA <- list(
  list(key = "claude",   tab = "claude_api",   titulo = "Conectar a Claude",          texto = "Para recibir comentarios y sugerencias."),
  list(key = "guia",     tab = "guia_tesis",   titulo = "Leer la guía",               texto = "Saber qué se espera de una buena tesis."),
  list(key = "ideas",    tab = "ideas",        titulo = "Anotar al menos 3 ideas",    texto = "Temas que le interesen o que haya vivido."),
  list(key = "tema",     tab = "ideas",        titulo = "Elegir el tema",             texto = "Marcar una idea como “Mi tema”."),
  list(key = "bosquejo", tab = "bosquejo",     titulo = "Armar el bosquejo",          texto = "Título, pregunta, objetivos y capítulos."),
  list(key = "intro",    tab = "introduccion", titulo = "Escribir la introducción",   texto = "Presentar el problema y el camino."),
  list(key = "caps",     tab = "capitulos",    titulo = "Escribir los capítulos",     texto = "El cuerpo de la investigación."),
  list(key = "concl",    tab = "conclusion",   titulo = "Escribir las conclusiones",  texto = "Responder la pregunta y cerrar.")
)

# ------------------------------------------------------- Parts of each writing tab
INTRO_PARTS <- list(
  list(key = "intro_contexto", titulo = "1. Contexto y planteamiento del problema",
       guia = "Describa la situación que le preocupa: ¿qué pasa, dónde, desde cuándo y a quién afecta? Termine diciendo qué es lo que todavía no se entiende o no se ha resuelto.",
       meta = 450),
  list(key = "intro_pregunta", titulo = "2. Pregunta de investigación",
       guia = "Escriba en una o dos frases la pregunta central que su tesis va a responder, y si quiere, 2 a 4 preguntas más específicas.",
       meta = 150),
  list(key = "intro_objetivos", titulo = "3. Objetivos",
       guia = "Un objetivo general (empieza con un verbo: analizar, explicar, comparar, evaluar…) y de 3 a 5 objetivos específicos.",
       meta = 200),
  list(key = "intro_hipotesis", titulo = "4. Hipótesis o tesis central",
       guia = "La respuesta tentativa a su pregunta: lo que usted sostiene y que los capítulos van a demostrar.",
       meta = 150),
  list(key = "intro_justificacion", titulo = "5. Justificación y relevancia",
       guia = "¿Por qué vale la pena este estudio? Su aporte para la ciencia política, para la administración pública y para la sociedad. Aquí también cabe su experiencia personal.",
       meta = 350),
  list(key = "intro_marco", titulo = "6. Marco teórico (en breve)",
       guia = "Los autores y conceptos que usará para mirar el problema (por ejemplo: Estado, poder, instituciones, políticas públicas, gobernanza).",
       meta = 350),
  list(key = "intro_metodo", titulo = "7. Metodología y fuentes",
       guia = "Cómo va a investigar: tipo de estudio (caso, comparación, histórico…), periodo, fuentes (documentos, estadísticas, entrevistas, su propia experiencia) y límites.",
       meta = 300),
  list(key = "intro_estructura", titulo = "8. Estructura del trabajo",
       guia = "Un párrafo corto por capítulo: qué trata cada uno y cómo se conecta con la pregunta.",
       meta = 250)
)

CONCL_PARTS <- list(
  list(key = "concl_respuesta", titulo = "1. Respuesta a la pregunta",
       guia = "Responda con claridad su pregunta de investigación. ¿Se confirmó la hipótesis, en parte o no? ¿Por qué?",
       meta = 350),
  list(key = "concl_hallazgos", titulo = "2. Hallazgos principales",
       guia = "Lo más importante que encontró en cada capítulo, en pocas frases cada uno.",
       meta = 400),
  list(key = "concl_aportes", titulo = "3. Aportaciones",
       guia = "Qué aporta su tesis: a la ciencia política, a la administración pública, a la comprensión de México.",
       meta = 250),
  list(key = "concl_limites", titulo = "4. Alcances y limitaciones",
       guia = "Lo que su estudio no pudo cubrir y por qué. Reconocerlo da solidez.",
       meta = 200),
  list(key = "concl_recomendaciones", titulo = "5. Recomendaciones y agenda futura",
       guia = "Propuestas concretas (de política pública, de gestión) y preguntas que otros podrían investigar después.",
       meta = 300),
  list(key = "concl_reflexion", titulo = "6. Reflexión final",
       guia = "Unas palabras de cierre: lo que este recorrido significa para usted, de la carrera que empezó en la IBERO a esta tesis.",
       meta = 200),
  list(key = "concl_biblio", titulo = "7. Bibliografía y fuentes",
       guia = "La lista de todo lo que citó, en orden alfabético y con el mismo formato (normalmente APA 7.ª edición). Puede irla llenando desde el principio.",
       meta = 150)
)

CHAPTER_GUIDE <- paste(
  "Un buen capítulo tiene: (1) una entrada que diga qué va a tratar y cómo ayuda a responder la pregunta;",
  "(2) el desarrollo, con subtítulos, datos y citas de sus fuentes; (3) una síntesis al final:",
  "“lo que este capítulo aporta a la tesis”. Puede usar recuadros “Desde mi experiencia” para lo que usted vivió."
)

# ------------------------------------------------------------- Thesis guide text
GUIA_BUENA_TESIS <- list(
  criterios = c(
    "<b>Una pregunta clara y delimitada</b>: un problema concreto, un lugar y un periodo.",
    "<b>Una tesis o hipótesis</b> que se pueda sostener con evidencia.",
    "<b>Un marco teórico</b> que explique con qué conceptos y autores mira el problema.",
    "<b>Un método explícito</b>: qué fuentes usa y cómo las analiza.",
    "<b>Evidencia verificable</b>: documentos oficiales, datos, entrevistas, bibliografía citada.",
    "<b>Coherencia</b>: cada capítulo responde una parte de la pregunta y las conclusiones la contestan.",
    "<b>Aporte propio</b>: algo que no estaba dicho, o dicho desde una mirada nueva (¡su experiencia cuenta!).",
    "<b>Redacción clara</b> y citas correctas (normalmente APA 7.ª edición)."
  ),
  tipos = list(
    list("Análisis de una política pública", "Cómo nació, cómo se aplicó y qué resultados tuvo un programa o ley (p. ej. una reforma administrativa)."),
    list("Estudio de caso", "Un municipio, una institución, un movimiento o una elección, estudiado a fondo."),
    list("Análisis histórico-político", "Cómo cambió algo con el tiempo: el Estado, el sistema de partidos, la administración pública."),
    list("Estudio comparado", "Dos o más casos (países, estados, periodos) para ver qué los hace distintos."),
    list("Evaluación", "Si una política o institución logró sus objetivos, con datos e indicadores."),
    list("Ensayo teórico", "Discusión de conceptos y autores aplicada a un problema actual.")
  ),
  errores = c(
    "Un tema demasiado amplio (“la democracia en México”) en lugar de uno delimitado.",
    "Describir sin analizar: contar lo que pasó sin explicar por qué.",
    "Opinar sin evidencia, o con fuentes que no se pueden revisar.",
    "Capítulos sueltos que no se conectan con la pregunta.",
    "Conclusiones que no responden la pregunta del principio.",
    "Citar mal o no citar: todo lo que no es suyo debe llevar su fuente."
  ),
  estructura = c(
    "Portada (universidad, carrera, título, autor/a, lugar y año) y dedicatorias o agradecimientos",
    "Resumen (unas 250 palabras) y palabras clave",
    "Índice general (y de cuadros y figuras si los hay)",
    "Introducción",
    "Capítulos (normalmente de 3 a 5): marco teórico, contexto, análisis…",
    "Conclusiones",
    "Bibliografía y fuentes",
    "Anexos (entrevistas, cuadros, cronología, glosario)"
  ),
  fuentes = c(
    "<b>Documentos oficiales</b>: Diario Oficial de la Federación, Diario de los Debates, informes de gobierno.",
    "<b>Datos</b>: INEGI, INE, CONEVAL, Auditoría Superior de la Federación, Banco de México.",
    "<b>Archivos y hemerotecas</b>: Archivo General de la Nación, Hemeroteca Nacional, Biblioteca Francisco Xavier Clavigero (IBERO).",
    "<b>Bibliografía académica</b>: libros y revistas de ciencia política y administración pública.",
    "<b>Entrevistas e historia oral</b>: personas que vivieron o decidieron lo que usted estudia.",
    "<b>Su propia experiencia</b>: válida si la presenta como testimonio y la contrasta con otras fuentes."
  ),
  ia = c(
    "Claude es su <b>tutor</b>: pregunta, sugiere, revisa y explica. Las ideas y las palabras de la tesis son suyas.",
    "Verifique siempre las referencias que Claude sugiera: a veces puede equivocarse con autores, fechas o títulos.",
    "Consulte con su coordinación de la IBERO las reglas vigentes sobre el uso de inteligencia artificial y las opciones de titulación.",
    "Si su universidad lo pide, mencione en la tesis cómo usó la inteligencia artificial."
  ),
  ejemplo_casa = c(
    "Una <b>pregunta central y una tesis</b> escritas en un recuadro, al principio.",
    "Un <b>modelo visual</b> que acompaña todo el trabajo (en ese caso, un templo: cimiento, columnas y techo).",
    "Recuadros <b>“Desde mi práctica”</b> con experiencias personales, separados del análisis.",
    "Una <b>síntesis</b> al final de cada capítulo: “lo que este capítulo aporta a la tesis”.",
    "<b>Anexos</b> útiles: glosario, cronología, fichas de las fuentes y un plan práctico."
  )
)

# A few starting ideas that bridge the 1979–80 plan and today's plan
IDEAS_PUENTE <- c(
  "Del Estado administrador a la gerencia pública: cómo cambió la administración pública mexicana de 1980 a hoy.",
  "Del partido hegemónico a la alternancia: el sistema político mexicano visto por una generación.",
  "Marxismo, funcionalismo y políticas públicas: qué queda hoy de las teorías con que se estudiaba en los 70.",
  "La descentralización y el gobierno local: el municipio mexicano entre 1980 y 2026.",
  "Mujeres en la política y la administración pública mexicana: de 1980 a la paridad."
)
