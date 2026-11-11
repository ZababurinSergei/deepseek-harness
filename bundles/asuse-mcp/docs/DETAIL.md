# ASUSE MCP servers

Two local stdio MCP servers, launched from the prebuilt executables in this checkout:

- **mcp-postgres** (`mcp/mcp-postgres/mcp-postgres.exe`) — read-only PostgreSQL. The request type is classified by the built-in Postgres parser (libpg_query) and the query runs in a `SET TRANSACTION READ ONLY` transaction, so writes are rejected twice. Profiles come from `db_profiles.json` (`DB_CONFIG_PATH`): `asuse.dev`, `filestorage.dev`.
- **mcp-wiki** (`mcp/mcp-wiki/mcp-wiki.exe`) — BookStack over a token. Profiles come from `wiki_profiles.json` (`WIKI_CONFIG_PATH`): `ru` (https://wiki.infoenergo.ru), `loc` (http://wiki.infoenergo.loc).

## Tools

- `mcp__postgres__*`: `connection_info`, `list_profiles`, `set_profile`, `unset_profile`, `execute_query` (SELECT only, named placeholders `@param`).
- `mcp__wiki__*`: `list_profiles`, `set_profile`, `unset_profile`, `connection_info`, `bookstack_get_system`, `bookstack_search`, `bookstack_list_books`, `bookstack_get_book`, `bookstack_list_chapters`, `bookstack_list_shelves`, `bookstack_list_pages`, `bookstack_get_page`, `bookstack_create_page`, `bookstack_update_page`, `bookstack_delete_page`.

Start a session with `set_profile` (`asuse.dev`, `filestorage.dev`, `ru`, `loc`) before the first query.

## Limitations

- `mcp-wiki` writes (`bookstack_create_page`, `bookstack_update_page`, `bookstack_delete_page`) are enabled — the token decides what they can do.
- `mcp-postgres` rejects INSERT, UPDATE, DELETE, DDL, multi-statement and CTE-wrapped writes by design.
- The wiki token and database passwords live in the JSON profile files next to the executables; this bundle copies no secrets and stores none.
- `failOnStartupError: true`: a server that cannot start fails its plugin row and logs an error; the harness still boots.
