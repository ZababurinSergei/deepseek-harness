---
name: asuse-frontend
description: Vue 3 + Vite frontend app rendering data trees via @infoenergo/infoenergo-ui AiDataTable
---

# SKILL · asuse-frontend (universal)

<!-- created: 20261027-114149 -->
<!-- foreign-context sources: asuse-ai-front-min infoenergo-ui AiDataTable -->
<!-- lead-sync 2026-11-11: ПУТИ РЕЗОЛВИМЫ В ЭТОМ ROOT (снимается foreign-context-пометка doc-sync 2026-11-07):
     asuse-ai-front-min\src\main.js (tableApi.data + маппинг :96-101), asuse-ai-front-min\src\components\AddressTree.vue,
     asuse-ai-front-min\node_modules\@infoenergo\infoenergo-ui\src\composables\AiDataTable\*.
     Битые от sed токены ниже: `	ableApi.data` = tableApi.data; `ddress./cities/get` = address./cities/get;
     `pi`/`rgs` = api/args. Бэкенд-контракт дерева — см. trees-workflow §8. -->

## 0. Назначение
Vue 3 + Vite приложение, которое рендерит данные (в нашем случае — два дерева) через библиотеку @infoenergo/infoenergo-ui.






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
- Vue 3, Naive UI (внутри библиотеки), Vite.
- @infoenergo/infoenergo-ui — локальный пакет с AiDataTable.

## 2. Как работает AiDataTable
- Принимает :columns, :api, :args, :key-expr, :is-tree.
- Для деревьев: :tree="{ remoteChildren: true, hasChildrenExpr: 'has_items', parentIdExpr: 'k_npw' }".
- Вызывает 	ableApi.data(api, args) при скролле и при раскрытии узла.

## 3. Роль main.js (обязательно)
- 	ableApi.data — это мост между AiDataTable и бэкендом.
- Для ddress./cities/get там написан **маппинг**: parentIdValue -> keyParentValue, mode -> option (
  oots/childes).
- **counteragent./org-context-navigator/get** — ГРИД (`ai-grid-ro`), `is-tree="false"`, без `:tree`, без `parentIdExpr`. Иерархия не строится. `main.js` fallback `mode:onExpand` для него не нужен.

## 4. Подходы к отладке
- Открыть DevTools -> Network -> POST /api. Проверить pi и rgs.
- Если success: false — смотреть rgs и сравнивать с тем, что ждёт бэкенд.
- Если success: true, но пусто — проверить parentIdExpr (должен совпадать с полем в ответе).


<!-- asuse-frontend: AiDataTable expand payload facts (session S-20261030-175016-12764) -->
- AiDataTable (e-grid) на expand шлёт родителя в args.keyParentValue (например keyParentValue:1), args.parentIdValue при этом null; начальный запрос mode:"onScroll" keyParentValue:null; mode:"onExpand" — только раскрытие.
- AddressTree (address./cities/get): option:"roots" (keyParentValue:null, level:0) -> option:"childes" c keyParentValue=kod_m родителя; поле наличия детей has_items (hasItemsField).
- Ответ бэкенда: {result:true, data:[...]}; успех фронта = result===true (ключа success в ответе нет).
- Playwright: на странице две таблицы (eobasket + AddressTree) -> локаторы скашивать к [data-testid="eobasket-table"] / [data-testid="address-tree"]; в JS-строках селектор c " внутри — только через одинарные кавычки.
<!-- sources: .dsh/skills/asuse-frontend/SKILL.md -->
