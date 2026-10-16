# tools/ — вспомогательные скрипты проекта

Краткий справочник. Все скрипты идемпотентны, не удаляют данные и не закрывают терминал.

## Что здесь лежит

| Файл | Назначение | Запуск |
|---|---|---|
| `gen-rules.sh` | Генератор `tmp/gen-rules-<TS>/RULES-expanded.md` (§1–§15) + снимок дерева проекта | `bash tools/gen-rules.sh` |
| `create-restore-point.sh` | Точка восстановления: tarball + manifest.sha256 + restore.sh + root-tree.filtered | `bash tools/create-restore-point.sh` |
| `vendor-diff.sh` | Диффы вендора `infoenergo-ui` по диапазонам из конфига | `bash tools/vendor-diff.sh [--list\|--stat\|--range NAME\|--working\|--save]` |
| `vendor-diff.config.json` | Конфиг диапазонов для `vendor-diff.sh` (`ranges[]`) | редактировать вручную |
| `run-e2e.sh` | Headless-прогон e2e (Playwright) + артефакты в `tmp/` | `bash tools/run-e2e.sh` |
| `install.sh` | Установка зависимостей проекта | `bash tools/install.sh` |

---

## gen-rules.sh

Создаёт `tmp/gen-rules-<TS>/`:
- `RULES-expanded.md` — правила чата §1–§15 с вшитым `ROOT_PATH`
- `root-tree.txt` — полный снимок корня (глубина ≤3)
- `root-tree.filtered` — только по `INCLUDE_DIRS`
- `root-tree.tsv` — path/type/size (TSV)
- `summary.txt`, `FULL-SUMMARY.txt`

Автодетект `INCLUDE_DIRS`: все подкаталоги корня, кроме `.git node_modules .cache dist build .next .nuxt .svelte-kit coverage .idea .vscode`.

Гарантии: `set +e`, `trap` только логирует; логи append; артефакты не удаляются; `ROOT_PATH` сверяется с `pwd`.

---

## create-restore-point.sh

Создаёт `tmp/restore-point-<TS>/`:
- `workdir.tar.gz` — снимок рабочей директории
- `manifest.sha256` — контрольные суммы
- `restore.sh` — скрипт восстановления (поддерживает `--dry-run`)
- `root-tree.filtered` — дерево для обзора

Печатает `verdict: CONFIRMED` при успехе. `restore.sh` — безопасный способ откатить состояние.

---

## vendor-diff.sh + vendor-diff.config.json

Печатает диффы вендора `vendor/infoenergo-ui` по диапазонам `from..to` из конфига.

Конфиг `vendor-diff.config.json`: `{ vendor_dir, tmp_dir, ranges: [{name, from, to, desc}] }`.

Режимы:
- `tools/vendor-diff.sh` — все диапазоны + рабочие правки
- `--list` — оглавление диапазонов
- `--stat` — сводка по каждому диапазону
- `--range NAME` — один диапазон по имени
- `--working` — только незакоммиченные правки
- `--save` — всё в `tmp/vendor-diff-<TS>.patch`

Требует `jq`. Использует тег `baseline-1m` (диапазон «оригинал → первый коммит с деревом»).
Рабочий цикл: закоммитить → добавить диапазон в `ranges[]` → `vendor-diff.sh --save`.

---

## run-e2e.sh

Запускает headless-прогон e2e (Playwright) и складывает артефакты (скриншоты, трассы, логи) в `tmp/`.

---

## install.sh

Устанавливает зависимости проекта (`npm ci` в корне и, при необходимости, в `vendor/infoenergo-ui`). Безопасен при повторном запуске.

---

## Примеры вызовов

### gen-rules.sh

```bash
# Базовый запуск: создать свежий снимок правил и дерева
bash tools/gen-rules.sh

# Запуск из корня проекта (ROOT_PATH сверяется с pwd — запускать только из корня)
cd /path/to/project && bash tools/gen-rules.sh

# Посмотреть, куда сложились артефакты последнего запуска
ls -1dt tmp/gen-rules-* | head -n1

# Прочитать summary последнего запуска
latest=$(ls -1dt tmp/gen-rules-* | head -n1)
cat "$latest/summary.txt"

# Найти только отфильтрованное дерево (по INCLUDE_DIRS)
cat "$latest/root-tree.filtered"

# Поиск по TSV-снимку (path/type/size)
column -t -s $'\t' "$latest/root-tree.tsv" | head
```

### create-restore-point.sh

```bash
# Создать точку восстановления
bash tools/create-restore-point.sh

# Найти последнюю точку и посмотреть манифест
rp=$(ls -1dt tmp/restore-point-* | head -n1)
cat "$rp/manifest.sha256"

# Проверить целостность точки восстановления
( cd "$rp" && sha256sum -c manifest.sha256 )

# Сухой прогон восстановления (ничего не меняет)
bash "$rp/restore.sh" --dry-run

# Реальное восстановление (осознанно!)
bash "$rp/restore.sh"
```

### vendor-diff.sh

```bash
# Оглавление диапазонов из конфига
bash tools/vendor-diff.sh --list

# Сводка (--stat) по всем диапазонам
bash tools/vendor-diff.sh --stat

# Один диапазон по имени (имя берётся из --list)
bash tools/vendor-diff.sh --range baseline-1m

# Только незакоммиченные правки в вендоре
bash tools/vendor-diff.sh --working

# Сохранить всё в tmp/vendor-diff-<TS>.patch
bash tools/vendor-diff.sh --save

# Посмотреть последний сохранённый патч
ls -1t tmp/vendor-diff-*.patch | head -n1
```

### run-e2e.sh

```bash
# Headless-прогон e2e (Playwright) с артефактами в tmp/
bash tools/run-e2e.sh

# Найти каталог артефактов последнего прогона
ls -1dt tmp/*e2e* 2>/dev/null | head -n1 || ls -1dt tmp/* | head -n1
```

### install.sh

```bash
# Установка зависимостей (безопасна при повторе)
bash tools/install.sh

# Повторный запуск (идемпотентно)
bash tools/install.sh
```

---

## Комбинированные сценарии

```bash
# Полный рабочий цикл вендора:
# 1) закоммитить правки в вендоре
# 2) добавить диапазон в tools/vendor-diff.config.json (ranges[])
# 3) собрать патч
bash tools/vendor-diff.sh --save

# Снимок перед рискованными изменениями:
bash tools/create-restore-point.sh && \
  bash tools/gen-rules.sh

# Проверить состояние и, при необходимости, откатиться:
rp=$(ls -1dt tmp/restore-point-* | head -n1)
bash "$rp/restore.sh" --dry-run
```

---

## Безопасные привычки (напоминание)

```bash
# Бэкап файла перед правкой — только так:
cp -n file file.bak-<task>-<TS>

# Логи — только append:
printf '%s\n' "msg" >> tmp/<task>-<TS>/log.txt

# Мягкий выход из скрипта:
return 0
```

---

## Правила поведения

- Логи только **append**.
- Артефакты в `tmp/<task>-<TS>/` **не удаляются**.
- Запрещено: `rm -rf`, `> file`, `git reset --hard`, `truncate -s 0`.
- Бэкапы: `cp -n file file.bak-<task>-<TS>`; правило `.bak-*` в `.gitignore` исключает их из коммитов.
- Терминал не закрывать; мягкий выход — `return 0`.
```
