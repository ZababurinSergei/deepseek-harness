---
name: postgres-readonly
description: Read-only PostgreSQL queries from PowerShell on Windows for schema audit and route checks
---

# SKILL · postgres-readonly (universal)

<!-- created: 20261026-193812 -->
<!-- foreign-context sources: psql asuse DB -->
<!-- foreign-context: файл описывает чужой проект, пути нерезолвимы в этом репозитории (doc-sync 2026-11-07) -->

## 0. Назначение
Read-only запросы к PostgreSQL из PowerShell на Windows без установки тяжелых ORM.
Используется для аудита схем, проверки прав, поиска контроллеров и таблиц.

## 1. Подключение
В Windows psql часто не в PATH. Используй полный путь:
C:\Program Files\PostgreSQL\15\bin\psql.exe (версия может отличаться).

Пароль передается через переменную окружения \$env:PGPASSWORD\, чтобы не светить его в истории команд.

## 2. Шаблон PowerShell для SELECT
\\\powershell
\kl0pik = "твой_пароль"
\C:\Program Files\PostgreSQL\15\bin\psql.exe = "C:\Program Files\PostgreSQL\15\bin\psql.exe"
\ = @("-h", "host", "-p", "5432", "-U", "user", "-d", "dbname")

# -c "SQL" — выполнить и выйти
# -t -A — только данные, без заголовков и выравнивания (удобно для парсинга)
\         url         |                url_meta                 |             args              |       name         ---------------------+-----------------------------------------+-------------------------------+-------------------  address./cities/get | meta./meta/ai-tree-node-load/select/get | {                            +| view-address-edit                      |                                         |   "schema": "address",       +|                       |                                         |   "dataset": "kf_get_cities",+|                       |                                         |   "fields": [                +|                       |                                         |     "kod_m",                 +|                       |                                         |     "name_s",                +|                       |                                         |     "k_npw",                 +|                       |                                         |     "guid",                  +|                       |                                         |     "path",                  +|                       |                                         |     "asset_svg",             +|                       |                                         |     "okato",                 +|                       |                                         |     "oktmo",                 +|                       |                                         |     "ur",                    +|                       |                                         |     "path_names"             +|                       |                                         |   ]                          +|                       |                                         | }                             |  (1 ������)  = & \C:\Program Files\PostgreSQL\15\bin\psql.exe @args -c "SELECT 1;" -t -A
\         url         |                url_meta                 |             args              |       name         ---------------------+-----------------------------------------+-------------------------------+-------------------  address./cities/get | meta./meta/ai-tree-node-load/select/get | {                            +| view-address-edit                      |                                         |   "schema": "address",       +|                       |                                         |   "dataset": "kf_get_cities",+|                       |                                         |   "fields": [                +|                       |                                         |     "kod_m",                 +|                       |                                         |     "name_s",                +|                       |                                         |     "k_npw",                 +|                       |                                         |     "guid",                  +|                       |                                         |     "path",                  +|                       |                                         |     "asset_svg",             +|                       |                                         |     "okato",                 +|                       |                                         |     "oktmo",                 +|                       |                                         |     "ur",                    +|                       |                                         |     "path_names"             +|                       |                                         |   ]                          +|                       |                                         | }                             |  (1 ������)  | ForEach-Object { Write-Host \ }
\\\

## 3. Безопасность (КРИТИЧНО)
- **Только SELECT**. Запрещено: INSERT, UPDATE, DELETE, DROP, TRUNCATE, ALTER, CREATE.
- Если нужно посмотреть структуру — используй information_schema или pg_catalog.
- Для проверки прав и маршрутов используй таблицы dmin.mk_right, dmin.mk_area_right, meta.api_meta_url.
- Не сохраняй пароли в скриптах (только \kl0pik в рамках сессии).

## 4. Частые запросы (шпаргалка)

**Список таблиц в схеме:**
\\\sql
SELECT table_name FROM information_schema.tables WHERE table_schema = 'meta';
\\\

**Список колонок в таблице:**
\\\sql
SELECT column_name, data_type FROM information_schema.columns
WHERE table_schema = 'meta' AND table_name = 'api_meta_url';
\\\

**Поиск API-маршрута:**
\\\sql
SELECT url, url_meta, args FROM meta.api_meta_url WHERE url = 'address./cities/get';
\\\

**Права на API:**
\\\sql
SELECT id, name, object, object_type FROM admin.mk_right WHERE object_type = 'api_route';
\\\

**Проверка соединения:**
\\\sql
SELECT 1 AS ok;
\\\

## 5. Ограничения
- Если таблица возвращает 0 строк — это тоже evidence (not_found).
- Для сложных JSON-полей (например, rgs в pi_meta_url) используй jsonb_pretty(args::jsonb).<!-- windows-ps51: re-audited 20261030-175400 (marker appended, sources сохранены) -->
<!-- sources: .dsh/skills/postgres-readonly/SKILL.md -->
