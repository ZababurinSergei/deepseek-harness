---
name: asuse-databases
description: PostgreSQL migrations, SQL functions and views for ASUSE schemas (address, payer, meta, admin)
---

# SKILL · asuse-databases (universal)

<!-- created: 20261027-114149 -->
<!-- foreign-context sources: asuse-ai-databases pg_get_functiondef address.kf_get_cities payer.hf_org_navigator_get -->
<!-- lead-sync 2026-11-11: ПУТИ РЕЗОЛВИМЫ В ЭТОМ ROOT (снимается foreign-context-пометка doc-sync 2026-11-07):
     databases\ASUSE\sqlobj\address_test\address_test.kf_get_cities.sql, databases\ASUSE\2026\11\{ddl,dml\meta}\*,
     databases\README.md (таблица применений + дефект args 12-vs-10).
     Битые от sed токены ниже: `ddress` = address, `ame_s` = name_s, `i-tree-node-load` = ai-tree-node-load.
     ТРЕБОВАНИЯ к функции-датасету (path integer[], ветки kod_m IS NULL / k_npw=N, вызов по ключу для has_items) — trees-workflow §8. -->

## 0. Назначение
Репозиторий миграций и SQL-кода (функции, вьюхи, таблицы) для PostgreSQL.






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

## 1. Структура
- databases/ASUSE/YYYY/MM/ddl/ — создание таблиц, функций, вьюх.
- databases/ASUSE/sqlobj/ — исходный код функций (например, ddress.kf_get_cities.sql).
- databases/ASUSE/2025/11/dml/meta/ — миграции для meta.api_meta_url.

## 2. Дерево адресов (ddress)
- ddress.adr_m — таблица с иерархией (kod_m, k_npw,
  ame_s).
- ddress.kf_get_cities(json_param) — функция, возвращающая узлы.
    - sel_all = true -> рекурсивный CTE (всё дерево).
    - kod_m = null -> корни (k_npw is null).
    - kod_m = N -> дети (k_npw = N).
- **Поиск** в функции НЕ реализован. Его добавляет i-tree-node-load через LIKE.

## 3. Дерево контрагентов (payer)
- Таблицы: kr_org, kr_payer, kr_dogovor, kr_numobj.
- payer.hf_org_navigator_get(json_param) — функция, возвращающая плоский список с parent_id.
    - Принимает фильтры (pr_active, show_all_tu) внутри json_param->select_args->filters.
    - Иерархия собирается внутри функции, фронт (AiDataTable) только отрисовывает.

## 4. Подходы к анализу
- Посмотреть код функции: SELECT pg_get_functiondef(oid) FROM pg_proc WHERE proname = '...'.
- Посмотреть структуру таблицы: SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '...'.
- Проверить права: dmin.mk_right (object), dmin.mk_area_right (area_id).


<!-- sources: .dsh/skills/asuse-databases/SKILL.md -->
