---
name: asuse-gateway
description: BFF gateway receiving POST /api, checking rights, resolving routes via meta-service and proxying
---

# SKILL · asuse-gateway (universal)

<!-- created: 20261027-114149 -->
<!-- foreign-context sources: asuse-ai-api-gateway RULES.md -->
<!-- foreign-context: файл описывает чужой проект, пути нерезолвимы в этом репозитории (doc-sync 2026-11-07) -->

## 0. Назначение
Единая точка входа (BFF) для фронтенда. Принимает POST /api, проверяет права, резолвит маршрут через мета-сервис и проксирует на целевой микросервис.






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
- Middleware: 	rebovatToken, alidateToken.
- Роутинг:
  routes/api-rights.js (для данных),
  routes/common.js (для авторизации).

## 2. Как работает запрос
1. Фронт шлёт { api, args }.
2. api-rights.js:67–70 → runApi('admin','/access/api/get',{appId,userId,route}) — gateway резолвит права ЧЕРЕЗ admin (SQL к dmin.mk_right — на стороне admin/meta DAL, не gateway). file: asuse-ai-gateway-min\routes\api-rights.js:68 (проверено 2026-11-09, HELP-asuse — самоссылка без sha: цикл SKILL↔HELP не замыкается, фикс.точка = путь).
3. Идёт в meta.api_meta_url (получает url_meta и базовые rgs).
4. Проксирует запрос на asuse-ai-meta (порт 3107) через
   runApi().
5. Если прав нет — возвращает { result: true, success: false }.

## 3. Ключевые файлы
- pp.js — точка входа, настройка CORS.
-
routes/api-rights.js — проверка прав и проксирование /api.
- controllers/apiController.js — функция
  runApi() (HTTP-клиент к мете).

## 4. Подходы к отладке
- В DevTools всегда смотреть POST /api и ответ success: false.
- Если success: false — проблема либо в правах (mk_right — через admin), либо в конфиге меты (api_meta_url), либо в БД (функция).
- Сам gateway SQL не пишет. Он только роутит.


<!-- sources: .dsh/skills/asuse-gateway/SKILL.md -->
