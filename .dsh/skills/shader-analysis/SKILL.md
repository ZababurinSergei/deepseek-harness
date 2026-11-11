---
name: shader-analysis
description: WGSL and GLSL shader, pipeline and uniform analysis for WebGPU and Orillusion
---

# SKILL · shader-analysis (universal)

<!-- sources: .dsh/skills/shader-analysis/SKILL.md -->
<!-- synced: 20261025-235509 -->

Не привязан к проекту. Описывает инструменты и порядок действий для анализа WGSL/GLSL-шейдеров, пайплайнов и юниформ-буферов в WebGPU/Orillusion.

## Когда использовать
- Invalid RenderPipeline, GPUValidationError, redeclaration, дубли @group/@binding.
- «0 ошибок, но ничего не видно», пустой draw call, вырожденная геометрия.
- Uniform'ы «не доезжают» до шейдера; struct не совпадает с тем, что шлёт setUniform.

## Инструменты (по слоям)
1) naga-cli — валидация WGSL без браузера.
   Установка: `cargo install naga-cli`. Запуск: `naga shader.wgsl`.
   Ловит синтаксис/семантику до браузера: дубли binding, redeclaration, несовпадение типов.
2) wgsl_reflect — рефлексия WGSL (JS/TS).
   Установка: `npm i -D wgsl_reflect`.
   Даёт реальные @group/@binding, layout struct, смещения полей, entry points, resources.
   Сверять struct GlobalUniform с тем, что шлёт setUniform (порядок/набор полей).
3) WebGPU Inspector (Chrome extension) — RenderDoc-style.
   Инспекция GPU-объектов, live-edit шейдеров, просмотр uniform/storage буферов, захват кадров.
   Manual Injection: подключить `webgpu_inspector.js` в HTML до WebGPU-кода; выставляет `window.webgpuInspector`.
   Важно: инспектор рисует свои виджеты (например, «Recent frame times») — это не рендер игры.
4) WebGPU Dev Extension (greggman) — ошибки в месте генерации.
   Показывает WebGPU-ошибки там, где они произошли; дампит шейдеры, adapter info, pass state.
5) В коде: pushErrorScope + getCompilationInfo.
   Стандарт вокруг createShaderModule / createRenderPipeline:
   device.pushErrorScope('validation');
   const module = device.createShaderModule({ code: wgsl });
   const info = await module.getCompilationInfo();
   if (info.messages.length) console.error(info.messages);
   const err = await device.popErrorScope();
   if (err) console.error('shader module error:', err.message);
   Без этого Invalid RenderPipeline остаётся «is invalid due to a previous error» без текста.

## Порядок действий при ошибке шейдера
1) naga — синтаксис/семантика WGSL.
2) getCompilationInfo — ошибки компиляции в браузере.
3) pushErrorScope/popErrorScope — ошибки создания пайплайна.
4) wgsl_reflect — сверка layout struct vs setUniform.
5) WebGPU Dev Extension — место генерации ошибки.
6) WebGPU Inspector — live-просмотр буферов и значений.

## Диагностика «пустого экрана» без ошибок
- Проверить, что `createRenderPipeline` вернул валидный pipeline.
- Проверить, что `geometry.generate(shaderReflection)` выполнен (vertexBuffer.vertexCount > 0).
- Проверить, что `instanceCount`/`indexCount` > 0 и `subGeometries[0].lodLevels[0].indexCount` > 0.
- Проверить значения uniform (viewMat/projMat не нулевые).
- Проверить, что объект в visibleLayer камеры и в render-graph.

## Массовые объекты
- Один MeshRenderer + PlaneGeometry + StorageGPUBuffer + кастомный шейдер с `instance_index`.
- `InstanceDrawComponent` — группировка дочерних MeshRenderer в один инстансированный draw call.
- Не создавать MeshRenderer на каждый объект при тысячах объектов.

## Orillusion 0.9.2: кастомный шейдер с globalUniform/starBuffer

Симптом: `drawIndexed(6,20)` идёт в `_MainColorRT` с правильным pipeline,
`vertexCount=4`, `readyPipeline=true`, ошибок компиляции нет — но пикселей
нет, `diff(after, hidden)=0`, `center avg=0`.

Диагностика: `renderPass.shaderReflection.groups`:

[{ bindings: 0 }, { bindings: 0 }]   // <-- bind group не создаётся

`_bufferDic` при этом знает `global`, `materialUniform`, `starBuffer`
(`RenderShaderPass.ts:146-147`), но bind group из reflection не строится.

Факты (проверено 2026-10-25):
- `#include "GlobalUniform"` + `@group(0) @binding(0) var<uniform> globalUniform`
  в кастомном `Shader`/`RenderShaderPass` **не заполняет** reflection.
  Проверены 3 конфигурации: inline `global`, inline `globalUniform`, `#include`.
- Ручное заполнение `shaderReflection.groups` из `createStarMaterial`
  **затирается** `initPipeline` (`RenderShaderPass.ts:1324` очищает `groups`).
- `ShaderReflectionInfo.getShaderReflection2` делает `Preprocessor.parse` →
  `parser2` → `combineShaderReflectionVarInfo`; для встроенных шейдеров
  (через `ShaderLib.register`) reflection заполняется, для кастомных — нет.

Что проверять в рантайме:
- `groups[0].bindings > 0` и `groups[1].bindings > 0` — иначе bind group пуст.
- `_bufferDic.keys()` — знает ли пасс `global`/`starBuffer`.
- `instTotal` (перехват `drawIndexed` с `instanceCount>1`) — draw идёт или нет.

Куда смотреть в Orillusion:
- `RenderShaderPass.ts:146-147` — `_bufferDic.set('global'/'materialUniform', ...)`.
- `RenderShaderPass.ts:1324` — `initPipeline` очищает `shaderReflection.groups`.
- `ShaderReflectionInfo.getShaderReflection2` — `Preprocessor.parse` → `parser2`.
- `InstanceDrawComponent.renderPass2` — `firstInstance=0`, `@builtin(instance_index)` 0..N-1.

Следующий шаг (не сделано): явный
`pass.setUniformBuffer('globalUniform', ...uniformGPUBuffer)` +
`pass.setStorageBuffer('starBuffer', ...)` **после** `initPipeline`
(в `onUpdate` первого кадра), либо патч `ShaderReflectionInfo` для
кастомных шейдеров.

## Дополнение 0.9.2 (probe3-probe7, 2026-10-25)

Факты из orillusion/src/**:

- RenderShaderPass (0.9.2) не имеет публичных setUniformBuffer/setStorageBuffer. Это методы RenderNode/MeshRenderer. На пассе — setUniform(name, value) и setStorageBuffer(name, buf).
- _bufferDic для RenderShaderPass: ключи "global" → MaterialDataUniformGPUBuffer и "materialUniform" → тот же буфер. Ключа "globalUniform" нет.
- ShaderReflectionInfo.combineShaderReflectionVarInfo строит groups[group][binding] = varInfo; varName — имя переменной WGSL.
- RenderShaderPass.genGroups(groupIndex) читает _bufferDic.get(refs.varName) — refs.varName должен совпадать с ключом.
- RenderShaderPass.initGroups (около :1214): genGroups(0, ...) закомментирован; bindGroupLayouts[0] создаётся отдельно через GlobalBindGroupLayout.getGlobalDataBindGroupLayout(ctx); genGroups(1..3) вызываются.
- GlobalUniform (WGSL): @group(0) @binding(0) var<uniform> globalUniform: GlobalUniform;
- GlobalUniformGroup держит готовый globalBindGroup (camera bind) и uniformGPUBuffer.
- GlobalBindGroup.getCameraGroup(camera) -> GlobalUniformGroup.

Следствие для кастомного шейдера с #include "GlobalUniform":
- groups[0] остаётся пустым (bindings: 0): genGroups(0) не вызывается, а varName="globalUniform" != _bufferDic-ключ "global".
- groups[1] (например, starBuffer) собирается через setStorageBuffer → genGroups(1).
- Симптом: drawIndexed идёт, пикселей нет, diff=0. Это не баг InstanceDrawComponent и не баг starBuffer.

Вариант B (применён): убрать #include "GlobalUniform", объявить свой @group(0) @binding(0) var<uniform> starGlobal: StarGlobal (projMat/viewMat/time/delta), вызвать renderPass.setUniformBuffer("starGlobal", buf) в createStarMaterial, заполнять буфер в onUpdate из GlobalBindGroup.getCameraGroup(camera).uniformGPUBuffer.

Критерий успеха: groups[0].bindings > 0 AND groups[1].bindings > 0 AND diff > 0.


## Дополнение 20261025-230158: bind group и pipeline для кастомного шейдера (Orillusion 0.9.2)

Подтверждено рантаймом (Playwright + Vulkan, sky.html):

1. **`groups[i].bindings[*]`** должны иметь поле **`varName`** (не `name`).
   Иначе `genGroups` ищет `_bufferDic.get(refs.varName)` -> `null` -> `BindGroupLayout` пуст ->
   `GPUPipelineError: entry-point uses bindings in group 1 but PipelineLayout doesn't have a BindGroupLayout for this index`.
   Пример: `{ bindings: [{ binding: 0, visibility: 3, type: 'uniform', varName: 'starGlobal' }] }`.

2. **`@group(0)` конфликтует с Orillusion `GlobalUniform`** (camera bind auto).
   Переносить кастомные uniform'ы в **`@group(1)`**, storage в **`@group(2)`**:
   `@group(1) @binding(0) var<uniform> starGlobal: StarGlobal;`
   `@group(2) @binding(0) var<storage, read> starBuffer: array<StarInstance>;`

3. **`initPipeline` (`RenderShaderPass.genReflection`) обнуляет `groups`**.
   Guard: `if (this.shaderReflection && !(this.shaderReflection as any).__custom) { ... }`,
   и ставить `__custom = true` в `createStarMaterial` / `updateMaterial`.

4. **`FragmentOutput`** должен **точно** совпадать с `outBufferMask`:
   2 RT (color, normal) -> `@location(0) color`, `@location(1) normal`, `outBufferMask = [1,1,0,0]`.
   3 RT -> `@location(0..2)`, mask `[1,1,1,0]`.
   Лишний `@location` без target -> `Invalid RenderPipeline`.

5. **Порядок полей `struct StarGlobal`** должен **совпадать** с порядком
   `setFloat32Array('viewMat', ...)` / `setFloat32Array('projMat', ...)`.
   Проверено: viewMat **первым** (offset 0), projMat **вторым** (offset 64).
   Иначе `viewMat`/`projMat` **перепутаны** -> звёзды вне frustum.

6. **`setFloat32Array` для `UniformGPUBuffer`/`StorageGPUBuffer`**:
   `memoryNodes.get(name)` создаёт `MemoryInfo` с offset из `allocation_node`.
   Читать данные: `new Float32Array(buf.memory.shareDataBuffer, node.offset, n)`.
   В `console.log` значения `setFloat32Array` **не видны** (`viewMat` — не публичное поле) — читать из `shareDataBuffer`.

7. **`instanceCount = N`** -> `RenderNode.renderPass2` -> `drawIndexed(6, N)`.
   Без него `instanceCount=0` -> `drawIndexed(6, 1)`.

**Блокер, не решённый:** `MeshRenderer._inRenderer = false` для вложенных `star_N`
(`Object3D` в `Object3D` в `Scene3D`) — `EntityCollect`/Octree не собирает.
Рекомендация: **один** `MeshRenderer` на контейнере + `StorageGPUBuffer` + `instanceCount=N`,
без `Object3D`-на-звезду.

## Дополнение 20261026-001142 — сессия 20261026 (pipeline group 1 + single MR)

- **Точный pipeline error:** `The entry-point uses bindings in group 1 but [PipelineLayout] doesn't have a BindGroupLayout for this index`. Это **layout**-ошибка, не WGSL (`modules[].messages: []`).
- `__custom` < `setStorageBuffer` в `createStarMaterial` — **необходимо**, но **недостаточно**: `initPipeline` вызывается на cached shader из `sharedMaterialCache`, и cached path тоже должен выставлять `__custom`.
- `InstanceDrawComponent` — правильный путь для группировки дочерних MeshRenderer. Один `MeshRenderer` на container + `instanceCount=N` — альтернатива без InstanceDrawComponent.
- **Патч `loadStars` по regex — опасно:** `python3` regex на `for (...) { const starObj ... }` зацепил `createVertexBuffersForAllStars` (760..840), `build:sky` упал. Патчить **по номерам строк** (`sed -n '760,820p'` → новый блок → `python3` с диапазоном).

## Дополнение 20261026-031500: genGroups / _groupsShaderReflectionVarInfos (Orillusion 0.9.2)

**Ключевой факт (исходник `orillusion/src/gfx/graphics/webGpu/shader/RenderShaderPass.ts`):**
- `initGroups()` (`:1188-1198`) **перезаписывает** `this._groupsShaderReflectionVarInfos = []` и `this._groupsShaderReflectionVarInfos[i] = shaderRefs`, где `shaderRefs` приходят из `ShaderReflectionInfo` — для **кастомных** шейдеров они **пустые** (`null`).
- `genGroups(groupIndex)` (`:843`) читает `this._groupsShaderReflectionVarInfos`; `entries` собираются из `shaderRefs`. Если `shaderRefs=null` → `entries=[]` → `GPUBindGroupLayout` **без entries** → `CreateRenderPipeline` падает с `BindGroupLayout for group N missing` (or `entry-point uses bindings in group N`).
- `genGroups(0)` в `initGroups` (`:1214-1215`) **закомментирован** — group 0 (camera) подставляется через `GlobalUniformGroup` в bind-группы, но **layout** строится в `initPipeline` по `_bufferDic`.

**Антипаттерны (проверено fix13..fix18, CONFIRMED):**
- Заполнить `pass.shaderReflection.groups = [{},{starGlobal},{starBuffer}]` — **не помогает**: `genGroups` читает `_groupsShaderReflectionVarInfos`, не `reflection.groups`.
- Заполнить `pass._groupsShaderReflectionVarInfos = [[], [g], [b]]` — **не помогает**: `initGroups` перезаписывает массив при `reBuild`/`initPipeline`.
- Override `pass.reBuild` (fix17) с ручным `bindGroupLayouts[1]/[2] = device.createBindGroupLayout(...)` — **не работает**: `device` не доступен (`__engine.context3D.gpuContext.device=false`), а `bindGroupLayouts` (array) не принимает присваивание/splice.
- `pass.genGroups(1, pass.shaderReflection.groups, true)` (fix16) — **не работает**: `genGroups` ждёт `ShaderReflectionVarInfo[][]` (поля `varName`, `binding`, `buffer`), а `{bindings}` — другой формат, функция молча возвращает пустые `entries`.

**Единственный надёжный путь:** патч ядра Orillusion — в `RenderShaderPass.initGroups` заменить `this._groupsShaderReflectionVarInfos = ...` на **фолбэк на `this.shaderReflection.groups`** когда `shaderRefs` пустые. После патча — `cd orillusion && npm run build` (пересборка `orillusion.es.max.js`).
