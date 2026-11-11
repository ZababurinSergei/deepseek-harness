# MCP-сервер для PostgreSQL

STDIO MCP-сервер для безопасного чтения данных из PostgreSQL. Чистый Go (pgx),
работает на Windows/Linux/macOS без клиентских библиотек Postgres.

Отличие от mcp-oracle: тип запроса определяется **встроенным парсером Postgres**
(`libpg_query` — тот же парсер, что работает на сервере), а не текстовым
разбором SQL. Двойная защита: парсер отклоняет всё, что не SELECT, плюс запрос
выполняется в транзакции `SET TRANSACTION READ ONLY`.

## Сборка

```bash
go build -o mcp-postgres .
```

## Конфигурация

`db_profiles.json`:

```json
{
  "dev": {
    "host": "localhost",
    "port": 5432,
    "dbname": "mydb",
    "user": "reader",
    "password": "secret"
  },
  "prod": {
    "host": "pg.example.local",
    "port": 5432,
    "dbname": "main",
    "user": "reader",
    "password": "${PG_PROD_PASSWORD}"
  }
}
```

Поддерживается `${ENV_VAR}` в значениях. Переменные окружения:

| Переменная | Описание | По умолчанию |
|---|---|---|
| `DB_CONFIG_PATH` | Путь к файлу профилей | `./db_profiles.json` |
| `DB_PROFILE` | Стартовый профиль (опционально) | не задан |
| `DB_QUERY_TIMEOUT` | Таймаут запроса (`30s`, `1m`) | `30s` |
| `DB_CONNECT_TIMEOUT` | Таймаут подключения | `10s` |
| `DB_MAX_ROWS` | Максимум строк в ответе | `1000` |
| `DB_MAX_RESPONSE_SIZE` | Максимум размера ответа (`20M`) | `20M` |

На Linux/macOS файл конфига должен иметь права `0600`.

## Инструменты

Те же, что у mcp-oracle: `connection_info`, `list_profiles`, `set_profile`,
`unset_profile`, `execute_query`.

Формат ответов — MCP `CallToolResult` (protocol `2024-11-05`):
`content[0].text` всегда строка; для успеха — JSON-массив объектов-строк.
Ошибка инструмента → `isError: true` (не JSON-RPC error).

### `execute_query`

Только `SELECT` (включая `WITH ... SELECT`). Плейсхолдеры — именованные
`@param`:

```json
{
  "query": "SELECT * FROM t WHERE id = @id",
  "params": { "id": 42 }
}
```

Запрещено: INSERT, UPDATE, DELETE, MERGE, CREATE, ALTER, DROP, TRUNCATE,
DO, CALL, COMMIT/ROLLBACK/SET (TransactionStmt), COPY, VACUUM и т.д.,
несколько операторов через `;`.

Определение типа: `pg_query.Parse` → один оператор → `Node.GetSelectStmt()`
и пр. CTE-обёртки (`WITH x AS (...) DELETE ...`) классифицируются по корневому
оператору и отклоняются. Даже если бы парсер пропустил что-то,
`SET TRANSACTION READ ONLY` в транзакции отклонит запись на уровне сервера.

## MCP-методы

| Метод | Ответ |
|---|---|
| `initialize` | `protocolVersion`, `capabilities`, `serverInfo` |
| `tools/list` | список инструментов |
| `tools/call` | `CallToolResult` (`content` / `isError`) |
| `ping` | `{}` |
| `notifications/*` | без ответа |

## Подключение Hermes / Claude Desktop

```jsonc
{
  "mcpServers": {
    "postgres": {
      "command": "D:\\Projects\\AI\\mcp\\postgres\\mcp-postgres.exe",
      "env": {
        "DB_CONFIG_PATH": "D:\\Projects\\AI\\mcp\\postgres\\db_profiles.json",
        "DB_PROFILE": "dev"
      }
    }
  }
}
```

## Безопасность

- Только чтение: парсер Postgres (libpg_query) + `SET TRANSACTION READ ONLY`
- Пароли не логируются и не возвращаются в ответах
- На Linux/macOS: конфиг `0600`
- BYTEA > 1KB → `[binary:<sha256-8bytes-hex>]`, ≤ 1KB → Base64
- Завершение при закрытии STDIN
