---
name: trees-workflow
description: Two trees workflow - address/cities (lazy tree) and counteragent/org-context (grid)
---

# SKILL · trees-workflow (universal)

<!-- created: 20261027-114021 -->
<!-- foreign-context sources: RULES.md asuse-ai-front-min address./cities/get counteragent./org-context-navigator/get -->
<!-- lead-sync 2026-11-11: ПУТИ РЕЗОЛВИМЫ В ЭТОМ ROOT (снимается foreign-context-пометка doc-sync 2026-11-07):
     asuse-ai-meta\dal\ai-tree-node-load-dal-new.js (321 стр.), asuse-ai-meta\routes\index.js:36,
     asuse-ai-front-min\src\main.js + src\components\AddressTree.vue,
     databases\ASUSE\sqlobj\address_test\address_test.kf_get_cities.sql,
     databases\ASUSE\2026\11\dml\meta\20261111005500-712-meta.address-test-cities-read-schema.js,
     asuse-ai-front-min\node_modules\@infoenergo\infoenergo-ui\src\composables\AiDataTable\*.
     Добавлен §8 — бэкенд-контракт дерева (что делать практикующему бэкендеру), по такту 2026-11-11. -->

## 8. Бэкенд-контракт дерева (для бэкендера: «как сделать дерево») — lead-sync 2026-11-11
Формула: **таблица-узел + ОДНА функция-датасет + ОДНА строка `meta.api_meta_url`**. JS на бэке писать не нужно — DAL (`ai-tree-node-load-dal-new.js`) универсальный, генерирует SQL из `args`.
1. **Таблица-узел:** ключ (`kod_m`), родитель (`k_npw`, NULL у корня), **`path integer[]` — обязателен**: DAL безусловно пишет `icount(path)` / `subarray(path,0,icount(path)-1)` (`:127` roots, `:182` childes, `:244` find) → без `path` запрос падает во всех режимах.
2. **Функция-датасет — жёсткая сигнатура:** `schema.ds(json_param json) RETURNS TABLE(...)`, вызывается в `FROM`. Обязана иметь ветки: `(json_param->>'kod_m') IS NULL` → **корни**; `t.k_npw = (json_param->>'kod_m')::int` → **дети**. Причина двух веток: DAL вызывает датасет **дважды в одном SQL** — как источник (`:91-98`) и как предикат детей `(SELECT COUNT(*)>0 FROM schema.ds(json_build_object(keyExpr, t.keyExpr))) AS has_items` (`:127`, `:182`) → «голая таблица» вместо функции = стрелки раскрытия не работают; `GRANT EXECUTE` читателю обязателен.
3. **`meta.api_meta_url`:** `url_meta='meta./meta/ai-tree-node-load/select/get'`, `args` = `{schema, dataset, fields[], keyExpr, keyParent, hasItemsField, pathField, columnsLikes[], columns[]}`. Обязательные args без дефолта (`:5-32`): `schema`, `dataset`, `keyExpr`, `keyParent`, `hasItemsField` (+ `option` от фронта). Дефолты: `keyParentRootValue=null`, `columns=[]`, `columnsLikes=[]`, `sort={field:keyExpr,order:'asc'}`.
   - **`args.fields` обязан ровно совпадать с колонками `RETURNS TABLE`** — каждое поле кладётся в SELECT (`:141-155`); рассогласование = SQL-ошибка (задокументированный случай: `address.kf_get_cities` = 12 колонок с `checked/geopoint` против `address_test` = 10 → фикс миграцией `…712-meta.address-test-cities-read-schema.js:38-40`).
   - `columnsLikes` обязан быть подмножеством `columns` (регистронезависимо), иначе `field … not find in columns array` (`:42-55`).
4. **Режимы `option`** (`:14`): `roots` (`WHERE t.keyParent IS keyParentRootValue`, в SELECT `null as keyParent`), `childes` (требует `keyParentValue`, иначе `result:false`), `find` (требует `likeText` + непустой `columnsLikes`; `UPPER(col::TEXT) LIKE UPPER('%text%')` через OR, без рекурсии), `path` — **НЕ реализован**: `return {result:false}` (`:291-317`) → «показать путь к найденному» не работает.
5. **Ответ:** `{result:true, data:[…], totalCount}` через `json_agg` (`:73-84`). Успех фронта = `result===true`.
6. **Стык с фронтом 1:1:** `keyExpr→:key-expr`, `keyParent→tree.parentIdExpr`, `hasItemsField→tree.hasChildrenExpr` (дефолт пакета `has_item` ≠ `has_items` → задавать явно), аргумент докачки `keyParentValue`. Glue = только маппинг `mode/parentIdValue → option/keyParentValue` в `asuse-ai-front-min/src/main.js:96-101`.

## 1. Два типа деревьев (asuse)
- **address./cities/get** -> url_meta = ai-tree-node-load -> БД-функция address.kf_get_cities (RETURNS TABLE). Ленивая загрузка (option: roots/childes). Фильтрация (likeText/columnsLikes) на стороне DAL (ai-tree-node-load-dal-new.js).

## 2. AiDataTable (infoenergo-ui) - правила настройки
- **Ленивое дерево (ai-tree-node-load)**: \:is-tree="true"\, \:tree="{ remoteChildren: true, hasChildrenExpr: 'has_items', parentIdExpr: 'k_npw' }"\, \:key-expr="'kod_m'"\.
- **Грид (ai-grid-ro)**: `:is-tree="false"`, без `:tree`, `:key-expr="'id'"`. Иерархия на клиенте не строится.
- **Маппинг в main.js**: AiDataTable шлёт \mode/parentIdValue\, а ai-tree-node-load ждёт \option/keyParentValue\. В \	ableApi.data\ нужен перехват для \ddress./cities/get\.

## 3. Подходы к анализу (без правок в БД)
1. **Разведка HTTP**: Использовать \.http\ файлы (IntelliJ) для ручных запросов к \/api\. Логин через \/common\ с \developer\ / \123456\.
2. **Чтение конфигурации**: \SELECT url, url_meta, args FROM meta.api_meta_url WHERE url = '...'\.
3. **Проверка прав**: \dmin.mk_right\ -> \dmin.mk_area_right\ -> \dmin.ms_user_role\.
4. **Анализ кода БД**: \SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = '...'\.
5. **PSQL из PowerShell**: \psql.exe\ + \$env:PGPASSWORD\ (webuser / kl0pik). Вызов через обёртку \sql.ps1\.

## 4. Запреты
- Не менять БД (только SELECT).
- Не создавать новые API без согласования.
- Пароли хранить только в \.pg-env.ps1\ (в .gitignore).
<!-- session-close-20261027-144435 -->
## meta-min scope
- All other meta.api_meta_url rows -> NOT served.
- data.configs: full cache from gateway-min (5047 b, 19 services) — needed for global.META/ADMIN/AUTH.

## 7. min-ROOT: counteragent НЕ реализован
- В `asuse-ai-front-min` компонента для `counteragent./org-context-navigator/get` НЕТ.
- На prod-фронте (`front-asuse-ai-infoenergo`) это `DxTreeView` (`src/views/context-navigator/org-context-navigator.vue`).
- В min это должен быть ГРИД (`ai-grid-ro`, `is-tree="false"`, `:key-expr="'id'"`), без `:tree`.
- `CounteragentTree.vue` (дерево) — ошибочная реализация, в карантине `tmp/remove-counteragent-tree-*`.
<!-- sources: .dsh/skills/trees-workflow/SKILL.md -->
