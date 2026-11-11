# Demo — Chrome on-device AI APIs

Три демо-страницы + объединённая. Открывать локально (file://) в Chrome с нужными флагами.

## Файлы

| Файл | API | Chrome | Флаг |
|---|---|---|---|
| webmcp-demo.html | WebMCP | 146+ | chrome://flags/#enable-webmcp-testing |
| prompt-api-demo.html | Prompt API | 148+ | — (включён по умолчанию) |
| summarizer-demo.html | Summarizer API | 138+ | — (включён по умолчанию) |
| all-in-one.html | все три | 148+ | #enable-webmcp-testing |

## Требования (Prompt API / Summarizer)

- Windows 10/11, macOS 13+, Linux
- ≥22 ГБ свободного места
- GPU ≥4 ГБ VRAM или CPU ≥16 ГБ RAM + 4 ядра

## Что проверять

### webmcp-demo.html
1. Открыть → статус «Инструмент зарегистрирован».
2. DevTools Console: `await document.modelContext.getTools()` → `summarize_text`.
3. Model Context Tool Inspector (расширение Chrome) → вызвать инструмент.

### prompt-api-demo.html
1. Открыть → «Доступность: available».
2. Нажать «Выполнить» → `Rating: 5, positive: true`.

### summarizer-demo.html
1. Открыть → «Доступность: available».
2. Нажать «Суммаризировать» → 2–3 ключевых пункта.
3. chrome://on-device-internals — запрос виден как prompt к Gemini Nano.

### all-in-one.html
1. Открыть в Chrome 148+ с #enable-webmcp-testing.
2. Статус: `Prompt API availability: available`.
3. Нажать Ask → Prompt API вызывает `get_weather` (WebMCP-инструмент).
4. При переполнении контекста — Summarizer сжимает историю (`[summarizer] compressed: ...`).

## Источники

- developer.chrome.com/docs/ai/webmcp
- developer.chrome.com/docs/ai/prompt-api
- developer.chrome.com/docs/ai/summarizer-api

## KEEP

- demo/README.md
