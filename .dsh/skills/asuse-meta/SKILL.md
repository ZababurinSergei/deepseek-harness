---
name: asuse-meta
description: Data orchestrator resolving API requests via api_meta_url, calling DAL, returning JSON
---

# SKILL · asuse-meta (universal)

<!-- created: 20261027-114149 -->
<!-- foreign-context sources: asuse-ai-meta pg_proc pg_get_functiondef -->
<!-- lead-sync 2026-11-11: ПУТИ РЕЗОЛВИМЫ В ЭТОМ ROOT (снимается foreign-context-пометка doc-sync 2026-11-07).
     Локальные носители: asuse-ai-meta\routes\index.js, asuse-ai-meta\controllers\{controller.js,ai-tree-node-load-controller.js},
     asuse-ai-meta\dal\ai-tree-node-load-dal-new.js (321 стр.), asuse-ai-gateway-min\.configs-cache.json.
     Чинятся битые от sed токены ниже: pi_meta_url→api_meta_url, rgs→args, i-tree-node-load→ai-tree-node-load,
     i-grid-ro→ai-grid-ro, ddress→address, i-tree-grid-edit→ai-grid-edit. -->

## 0. Назначение
Оркестратор данных. Принимает запросы от Gateway, резолвит их через БД (pi_meta_url), вызывает нужный DAL и возвращает JSON.






## Абсолютные пути (Windows)

**Оригинальные проекты (production):**
- Frontend (основной):  C:\Users\szababurin\WebstormProjects\front-asuse-ai-infoenergo
- Gateway:              C:\Users\szababurin\WebstormProjects\infoenergo-core\asuse-ai-api-gateway
- Meta:                 C:\Users\szababurin\WebstormProjects\asuse-ai\asuse-ai-meta
- Databases:            C:\Users\szababurin\WebstormProjects\Chat-Stream-Monitor\packages\asuse-ai\asuse-ai-databases
- Auth:                 C:\Users\szababurin\WebstormProjects\infoenergo-core\asuse-ai-auth
- Config:               C:\Users\szababurin\WebstormProjects\infoenergo-core\asuse-ai-config
- Admin:                C:\Users\szababurin\WebstormProjects\asuse-ai\asuse-ai-admin
- UI-lib:               C:\Users\szababurin\WebstormProjects\Chat-Stream-Monitor\packages\infoenergo-ui

**Минимальные версии (для разработки):**
- Frontend (min):       C:\Users\szababurin\WebstormProjects\asuse-ai-front-min
- Gateway (min):        C:\Users\szababurin\WebstormProjects\infoenergo-core\asuse-ai-gateway-min
- Meta (min):           C:\Users\szababurin\WebstormProjects\asuse-ai\asuse-ai-meta-min

## 1. Стек
- Node.js (Express).
- БД: PostgreSQL (схемы meta, dmin, ddress, payer, dog).

## 2. Как работает запрос
1. Принимает { api, args } от Gateway.
2. Ищет в meta.api_meta_url запись по url = api.
3. Читает url_meta (например, i-tree-node-load или i-grid-ro).
4. Вызывает контроллер (controllers/ai-tree-node-load-controller.js).
5. DAL (dal/*.js) строит SQL и выполняет его в БД.

## 3. Типы DAL (важно)
- **i-tree-node-load**: динамический SQL. Строит SELECT из rgs.schema, rgs.dataset, rgs.fields (из БД) и keyExpr, keyParent (из запроса). Умеет фильтровать (likeText, columnsLikes).
- **i-grid-ro**: вызов хранимой функции. Просто выполняет SELECT * FROM args.select(...). Вся логика (фильтры, иерархия) внутри функции БД.
- **i-grid-edit**: для INSERT/UPDATE/DELETE (в наших деревьях не используется).

## 4. Схема meta.api_meta_url
- url — строка, которую шлёт фронт (например, ddress./cities/get).
- url_meta — целевой обработчик (например, meta./meta/ai-tree-node-load/select/get).
- rgs — JSON с базовыми параметрами (например, schema: address, dataset: kf_get_cities).

## 5. Подходы к отладке
- sql.ps1 "SELECT * FROM meta.api_meta_url WHERE url = '...'" — узнать, куда идёт запрос.
- Если success: false — проверить, что rgs.dataset существует в БД, и что функция (для i-grid-ro) не падает.



<!-- session-close-20261027-144435 -->
## meta-min (next session)
- Requirements same as gateway-min (prod-code, @infoenergo/*, dotenv, morgan, LOGS_ROOT, applyConfigs/loadCache/saveCache, /set-app-config/set-app-config alias, COMMON_MODE=local).
- Only two urls for front-min: address./cities/get + counteragent./org-context-navigator/get.
- P1: port 3107 busy → use 3108.
- See docs/HANDOFF-meta-min.md.
<!-- sources: .dsh/skills/asuse-meta/SKILL.md -->
