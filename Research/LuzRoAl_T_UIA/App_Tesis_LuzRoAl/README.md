# 📘 Mi Tesis — Ciencias Políticas y Administración Pública (IBERO) · R Shiny, modular

An app that guides an elderly graduate of the IBERO's **Ciencias Políticas y Administración Pública** degree
(1979–80 study plan) step by step to write the thesis that completes the degree, with feedback from **Claude**.
The whole interface is in **Mexican Spanish** (usted form). This README stays in English for whoever maintains it.

Same modular architecture and purple look as the *Travel Photo Selector* (module registry + `ModuleLoader`,
one shared R6 manager, `www/css/global.css`, bundled easy-to-read fonts). The Claude connection follows the
`APIManager` of *Modular_db_books_llm* (httr POST to the Messages API, configurable model / max tokens / timeout,
friendly error messages), extended with a system prompt, multi-turn follow-ups and usage counters.

## Quick start
```r
setwd("path/to/App_Tesis_LuzRoAl")
source("install_packages.R", encoding = "UTF-8")   # once
shiny::runApp(launch.browser = TRUE)
```
1. **Conexión con Claude**: paste the API key (console.anthropic.com), press **Probar conexión**. Tick “Recordar la clave” to keep it on this computer (`data/.claude_key`), or set the environment variable `ANTHROPIC_API_KEY`.
2. **Administrador** (code **718**): choose the **work folder** (e.g. *Documentos/Mi tesis*), the author's name and generation.
3. The user follows the sidebar from top to bottom.

## Tabs (sidebar order = `modules/_module_registry.yml`)
| Tab | What it does |
|---|---|
| **Conexión con Claude** | API key, model (Sonnet 5.5 default, Opus 5.5, Haiku 5.5, Sonnet 4.6 or any typed model id), max tokens, timeout, test, remember key, usage counters (calls / tokens), a box to try a question. The header shows “Claude conectado / sin conectar”. |
| **Cómo escribir una buena tesis** | 5 sub-tabs: **Mi avance** (overall %, step-by-step route with “Ir” buttons, “Ya leí la guía”), **La carrera: ayer y hoy** (1979–80 plan axes vs. the 2026 plan by semester, IBERO features, graduate profile, “bridge” ideas that can be added to *Mis ideas*), **Una buena tesis** (criteria, thesis types, common mistakes, the family example), **Estructura, método y fuentes** (parts, length targets, APA examples, method, Mexican sources), **Pregúntele a Claude** (honest AI use + free/quick questions). |
| **Mis ideas y temas** | Idea cards (title, description, personal experience, related subjects from both plans, status). Per idea: Claude's opinion, follow-up conversation, edit, delete, **Elegir como mi tema**. “Que Claude me sugiera temas” returns 5 topics (JSON) that can be added as ideas. |
| **Bosquejo de la tesis** | Title, question, hypothesis, general/specific objectives, justification, theoretical framework, method, scope, plus a chapter list (add / reorder / remove; chapter ids keep their texts). Claude can **propose a full outline from the chosen topic** (JSON → “Usar esta propuesta”) or **review** it. Autosaves. |
| **Introducción** | 8 parts (context, question, objectives, hypothesis, justification, framework, method, structure), each with guidance and an orientative word target. |
| **Capítulos** | One editor per chapter of the outline (target words per chapter set by the admin). Extra button: **Sugerir fuentes**. |
| **Conclusiones** | 6 parts + bibliography. Extra button: **¿Responden a mi introducción?** (compares intro vs. conclusions). |
| **Administrador** (code 718) | Work folder (browse or type; copy current work there or open a thesis already there; open in Explorer/Finder), thesis data, Claude feedback style (brief / detailed / strict examiner), send topic+outline as context, extra instructions for Claude, chapter word target, autosave delay, **screen size 80–150 %**, **build the full thesis** (.docx with `officer`, printable .html, .md), backups (now / restore), change admin code, project summary, **Bloquear Administrador**. |

Writing tabs share `R/writing_module.R`: big part “pills” (✎ started, ✔ target reached), autosave ~2 s after typing stops,
“Guardar ahora”, **versions** (save / restore; a snapshot is always taken before a correction or restore),
Claude buttons (**Revisar mi texto**, **Ayúdeme a empezar o a seguir**, **Corregir ortografía y estilo** → “Usar esta versión corregida”),
free question box and the list of Claude's comments with **Seguir conversando** (Claude remembers that thread).

Every Claude request carries a shared system prompt (`R/prompts.R`): tutor (not author) role, Mexican Spanish with *usted*,
the user's background (1979–80 plan) vs. today's plan, citation style, feedback style, admin's extra instructions and — if enabled — the chosen topic and outline.

## Where things are saved
App folder `data/`: `config.json` (admin settings), `.claude_key` (only if remembered), `usage.json`, `app.log`.

Work folder (default `data/mi_tesis/`, chosen in Administrador):
```
proyecto.json        everything (ideas, outline, texts, Claude conversations)
textos/              readable .md copy of each part (rewritten on every save)
retroalimentacion/   every Claude answer as .md
versiones/           saved versions of each part
respaldos/           automatic daily copy + "Hacer respaldo ahora"
exportar/            the full thesis (.docx / .html / .md)
```

## Structure
```
App_Tesis_LuzRoAl/
├── app.R  global.R  install_packages.R  README.md
├── R/ module_loader.R  utils_common.R  content_ibero.R  utils_claude.R (ClaudeClient R6)
│      prompts.R  utils_thesis.R (ThesisManager R6)  ui_helpers.R  writing_module.R
├── modules/_module_registry.yml
│   ├── claude_api/ guia_tesis/ ideas/ bosquejo/ introduccion/ capitulos/ conclusion/ admin_settings/   (ui.R + server.R)
└── www/css/global.css  www/js/app.js  www/fonts/ (Atkinson Hyperlegible, Andika, Lexend + OFL licences)
```

## Testing without a key
`Sys.setenv(TESIS_MOCK_CLAUDE = "1")` before `runApp()` makes Claude return canned answers (for trying the flow offline). Remove it for real use.

## Notes
* Study-plan content: IBERO degree page/brochure (2026 plan) and Biblioteca Francisco Xavier Clavigero, *Historia de las Carreras de la IBERO (1943–2021)* (1979–80 focus). Graduation options and AI-use rules must be confirmed with the IBERO coordination; the app says so.
* Model ids can be changed without code: choose “Otro modelo” in Conexión con Claude.
