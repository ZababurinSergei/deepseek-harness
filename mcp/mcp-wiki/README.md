# mcp-wiki (Go)

MCP-сервер BookStack (stdio, stdlib-only). Профили — как у mcp-oracle: файл `wiki_profiles.json`, переключение инструментом `set_profile`.

## Сборка

```
go build -o mcp-wiki.exe .
```

## Профили (`wiki_profiles.json`)

Токены формата `token_id:token_secret` из переменных окружения, `${NAME%:*}` — id, `${NAME#:*}` — secret. Два сервера: `ru` (https://wiki.infoenergo.ru) и `loc` (http://wiki.infoenergo.loc).

## Hermes config.yaml

```yaml
mcp-wiki-go:
  command: D:/Projects/AI/mcp/wiki/mcp-wiki.exe
  env:
    WIKI_CONFIG_PATH: D:/Projects/AI/mcp/wiki/wiki_profiles.json
```
Токены лежат literal в `wiki_profiles.json`; Node-серверы (`mcp-wiki`, `mcp-wiki-loc`) читают тот же файл через `WIKI_CONFIG_PATH`.

Опционально `WIKI_PROFILE=ru|loc` — стартовый профиль, `WIKI_TIMEOUT=30s` — таймаут HTTP.

## Инструменты

`list_profiles`, `set_profile` (проверяет доступ через `/api/system`), `unset_profile`, `connection_info`,
`bookstack_get_system`, `bookstack_search`, `bookstack_list_books`, `bookstack_get_book`, `bookstack_list_chapters`, `bookstack_list_shelves`, `bookstack_list_pages`, `bookstack_get_page`, `bookstack_create_page`, `bookstack_update_page`, `bookstack_delete_page`.

Отличие от Node-версии: только токен-авторизация (email/password-сессии не реализованы — не используются).
