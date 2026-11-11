---
name: postmessage
description: Inter-session messaging protocol via append-only POSTMESSAGE file with claim/ask/answer/done
---

# SKILL · postmessage (universal)

Протокол обмена сообщениями между двумя и более сессиями, работающими над одним проектом.
Обе сессии **читают** и **пишут** в один общий файл `POSTMESSAGE` в корне проекта.

## 0. Идентификатор сессии
Каждая сессия должна знать свой `SESSION_ID`. Правила:
- Если `SESSION_ID` уже задан в окружении — использовать.
- Иначе при первом запуске: `export SESSION_ID="S$(date +%s)-$$"` и сохранить в `POSTMESSAGE.seen.$SESSION_ID`.
- Явная нумерация (`S1`, `S2`) — только если её задаёт человек.

## 1. Файлы
- `POSTMESSAGE` — общий файл в корне проекта (append-only).
- `POSTMESSAGE.seen.<id>` — маркер «дочитал до строки N» для сессии `<id>` (не коммитится).
- `scripts/postmessage.sh` — helper (write/read/last).

## 2. Формат сообщения
В `POSTMESSAGE` пишем в конец (append). Формат:
```
## session=<ID> @ <ISO8601>
<текст сообщения, может быть многострочным>
---
```
Правила:
- Заголовок `## session=<ID> @ <TS>` — обязателен.
- Разделитель `---` — обязателен.
- Многострочный текст — как есть, без экранирования.
- Не редактировать чужие сообщения, не удалять их, только append.

## 3. Конкурентная запись (flock)
Две сессии могут писать одновременно → одна затрёт другую.
Использовать `flock` на файле-локе:
```bash
exec 9>"$ROOT/POSTMESSAGE.lock"
flock 9
printf "## session=%s @ %s\\n%s\\n---\\n" "$SESSION_ID" "$(date -Iseconds)" "$MSG" >> "$ROOT/POSTMESSAGE"
exec 9>&-
```
Helper `scripts/postmessage.sh write "$MSG"` делает это сам.

## 4. Чтение: только новые сообщения
Не перечитывать весь файл. Хранить маркер:
- `POSTMESSAGE.seen.<id>` содержит номер строки, до которого сессия уже видела.
- Читаем `tail -n +$((last+1)) "$ROOT/POSTMESSAGE"`.
- После обработки: `wc -l < "$ROOT/POSTMESSAGE" > "$ROOT/POSTMESSAGE.seen.<id>"`.

Helper:
```bash
scripts/postmessage.sh read "$SESSION_ID"     # вывести новые сообщения
scripts/postmessage.sh last                    # последние 50 строк
```

## 5. Что писать
- `claim <path>` — «я взял файл X в работу, не редактируй».
- `release <path>` — «файл X свободен».
- `ask <text>` — вопрос другой сессии.
- `answer <text>` — ответ.
- `blocked <path>: <reason>` — блокер.
- `done <path>` — закончил правку.
- `handoff <summary>` — передача контекста.

## 6. Что НЕ делать
- Не `rm`, не `>` (перезапись) — только append через helper.
- Не редактировать чужие блоки, не «схлопывать» историю.
- Не писать вне `## session=...` блока.
- Не полагаться на то, что «сессия сейчас прочитает» — писать всегда, читать при каждом шаге.

## 7. Ротация (P11, 2026-11-08; критерий P17-3) — append-only-совместимая
Порог (любой из): канал >150 KB (153600 b), ИЛИ блоков `## session=` ≥20, ИЛИ указание человека/лида.
**P17-3 (2026-11-08):** пороги считают **ДЕЛЬТУ после последнего `## ROTATION`-анкера**: байты =
сумма append'ов после ROTATION, блоки = новые `^## session` после него. Канал append-only и не
усекается — абсолютный размер порога срабатывал бы каждый такт; дельта = рабочий критерий.
**P14-guard (PS 5.1):** у `Copy-Item` **нет** `-NoClobber` (параметр 7.x) — после снимка обязателен
`Test-Path` архива + сверка sha1; инцидент 2026-11-08 03:33: архив создался пустым (прошлый sha1 потерян),
починен ROTATION-CORRECTION-блоком.
Исполнитель — **только лид** (он писатель/читатель канала, §20.5). Процедура (канал НЕ усекается, §3):
1. Лид фиксирует sha1 канала и создаёт снимок-копию: `POSTMESSAGE.archive-<YYYYMMDD>` (тот же каталог, что канал).
2. В канал append-ится блок (с `\n\n`-префиксом, .NET `AppendAllText` UTF8NoBOM):
   ```
   ## ROTATION <YYYYMMDD> @<commit>
   ROTATION: archived to POSTMESSAGE.archive-<YYYYMMDD> sha1-8=<снимок8> @<commit>, канал продолжает append
   ---
   ```
3. Канал остаётся точкой входа: append продолжается, `tail -n 200`-читатели не затронуты.
4. Ретривал §20.5 (relay/session по sha1): `grep -n 'session=\|relay ' POSTMESSAGE.archive-*`; индекс архивов = ROTATION-строки канала.
5. Инварианты: усечение/перезапись/удаление строк канала ЗАПРЕЩЕНЫ (§3); архивы неизменяемы; правка чужих блоков запрещена.
   Старая формулировка «оставить последние 500 строк» = нарушение §3 — ОТМЕНЕНА этой политикой.
Гигиена append (анти-glue, P11-факт: `^relay`-якоря 0/16 из-за приклейки): append всегда с ведущими `\n\n`
и `[IO.File]::AppendAllText($pm, $text, UTF8NoBOM)`; PS 5.1 `Add-Content` при отсутствии завершающего
переноса приклеивает запись к последней строке — якорные regex (`^relay `, `^## session=`) перестают работать.
Dry-run процедуры: tmp/P11-rotation-*/rotation-dryrun.ps1 (проверено на копии: канал sha1 до=после).

## 8. Быстрый старт
```bash
export SESSION_ID="S1"
scripts/postmessage.sh write "claim src/foo.ts"
scripts/postmessage.sh read "$SESSION_ID"
```

## KEEP
- .dsh/skills/postmessage/SKILL.md
- scripts/postmessage.sh

## APPEND GUARD (added 20261026-122348)

Перед любым append в корневой POSTMESSAGE проверь:
- POSTMESSAGE не существует -> создать, первая строка: # DO NOT TRUNCATE
- (Get-Item POSTMESSAGE).Length -lt 256 байт, ИЛИ (Get-Content POSTMESSAGE).Count -lt 5 строк ->
  признак обнуления внешней сессией. Append НЕ выполнять, WARN в tmp/pm-guard-<TS>/warn.txt,
  затем append как новая секция ## session=<ID> @ <ISO> — старые строки не трогать.
- Никогда: Set-Content POSTMESSAGE, > POSTMESSAGE, Clear-Content POSTMESSAGE,
  truncate -s 0, : > POSTMESSAGE. Только Add-Content / >> / Out-File -Append.
- P11-уточнение: Add-Content/>> безопасны только когда файл заканчивается переводом строки; канонический
  писатель — [IO.File]::AppendAllText($pm, ("`n`n" + $блок), UTF8NoBOM) (анти-glue, см. §7).
- При append от себя всегда ставить разделитель --- строкой перед и после секции.
- Восстановление из tmp/postmessage-recovered-* — только в отдельный файл, не в POSTMESSAGE.
## 6. Windows / PowerShell 5.1 (замена flock)
`flock` на Windows нет. Append-only через `Add-Content` даёт тот же результат (атомарность на уровне ОС для одной строки).

```powershell
$msg  = "## session=$SESSION_ID @ $ISO`r`n"
$msg += "<текст>`r`n"
$msg += "---`r`n"
Add-Content -Path (Join-Path $ROOT "POSTMESSAGE") -Value $msg -Encoding UTF8
```

- **Правило PS 5.1:** строки с `$` и `"` — ЦЕЛИКОМ в ОДИНАРНЫХ кавычках. `\" внутри `"..."` НЕ работает (подтверждено инцидентом close-session).
- См. `.dsh/skills/powershell-first/SKILL.md` §1 и §3.

<!-- windows-ps51: updated by update-all-skills -->

<!-- sources: .dsh/skills/postmessage/SKILL.md, POSTMESSAGE, scripts/skills-audit.mjs, packages/nk-elite-orillusion-map/tmp/P16-stray-map-20261108-013412/strays.tsv -->
<!-- updated: 2026-11-08 P16 (раздел §9: канон-резолв с ABORT-проверкой + карта stray-ловушек) -->
<!-- updated: 2026-11-08 P11 (политика ротации append-only + анти-glue; старая «усечь до 500 строк» отменена) -->
<!-- updated: 20261030 (audit run S-20261030-175016-12764, RULES.md §12/§15) -->

## [TEAM-MODE] 2026-11-07 (§29 LISA-TEAM-V1)
- TEAM-MODE: [ЛИЗА] = тиммейт `liza` (Agent Team, общий ФС-доступ): обмен `send_message`, `ZADANIE -> ADDRESSEE: LEAD (FS)`; человек = цели/приёмка, не транспорт. CHAT-MODE: без изменений (человек-транспорт).
- Нумерация после перенумерации 23:10: STATE-BLOCK = §31, Роли/[STATE] = §32, ЗАДАЧА-КОНТЕКСТ = §36 (старые dev-ссылки §20.10/§20.11/§22 dev читаются по §37 МАППИНГ; релейные §20.9/§20.10/§20.11/§22 не менялись).
- npm-хуки генераторов: `agents:create` / `agents:create:win` (§21.1; бывшие core-pack/core-pack:win упразднены).

<!-- added: doc-sync 2026-11-07 (liza, ACCEPT all) -->

## 9. Резолв канала и stray-ловушки (P16, 2026-11-08)
Канал ОДИН: `POSTMESSAGE` в корне git-репозитория (= два уровня выше ROOT канона: `POSTMESSAGE`, §21.1).
Все остальные POSTMESSAGE* — ловушки дефолтов. Карта P16 (SRC: tmp/P16-stray-map-20261108-013412/strays.tsv, 30 записей):
`packages/POSTMESSAGE` 1548 b (в него упал дефолт ротации v1 в P15), `ROOT/POSTMESSAGE` (был tracked, 51520 b — архив tmp/P16-stray/), `packages/infoenergo-ui/POSTMESSAGE` (чужой проект), `.bak-*`-снимки.
**Канон-резолв (все писатели/читатели):**
1. Подъём от ROOT до каталога с `.git` (не останавливаться на POSTMESSAGE!): `while [ "$D" != "/" ] && [ ! -d "$D/.git" ]; do D="$(dirname "$D")"; done; PM="$D/POSTMESSAGE"`.
2. ABORT-проверка перед записью: резолв ДОЛЖЕН находиться на границе репозитория и НЕ содержать `/packages/`; файл должен существовать. Иначе — **ABORT** (не создавать, не писать; `touch $ROOT/POSTMESSAGE` = генератор строев, запрещён).
3. Примеры §3/§4 выше (`$ROOT/POSTMESSAGE`) действуют только для ROOT == корень репозитория; для packages-проектов канон — `POSTMESSAGE`.
4. Ротация/запись — только после подтверждения пути (паттерн P15: dry-run по умолчанию + `-Execute -ConfirmPath <тот же путь>`, §21.1).
Уязвимые резолвы, найденные P16 (патч-запросы лиду): `agents-create.sh:170` ($ROOT-приоритет), `agents-create.ps1:43` (fallback `../POSTMESSAGE` = packages-ловушка), `doc-sync.sh:13` (не сканирует ROOT-канал), `.dsh/skills/rules-first-task` (touch $ROOT/POSTMESSAGE), `scripts/postmessage.sh:6` (остановка на ROOT/POSTMESSAGE до .git).

**Gitfile-субмодуль (находка liza takt-3, 2026-11-09 14:15, ACCEPT лидом):** ROOT=`packages/infoenergo-ui` — сабмодуль с gitfile (`gitdir: ../../.git/modules/packages/infoenergo-ui`): у ROOT `.git` существует как **файл**, не каталог → walk метода 1 (`[ -d "$D/.git" ]` / PS `-PathType Container`) останавливается на ROOT, резолв содержит `\packages\` → **ABORT срабатывает штатно** (подтверждено прогоном tmp/liza-pm-hygiene-20261109-141455/). Рабочий резолв для этого репо = канон `../../POSTMESSAGE` (§9 «два уровня выше»). Правило: при gitfile-субмодуле резолв = **суперпроект** (родитель `packages/`), а не первая точка остановки; в ABORT-случае — не создавать/не писать, переключаться на канон-путь.

<!-- synced: 20261108-0345 (liza: §7 критерий P17-3 = дельта после ROTATION-анкера; P14-guard Copy-Item/Test-Path, инцидент 03:33) -->

<!-- SYNC-20261108-adresnaya-attributsiya -->
## [ADRESNAYA-ATTRIBUTSIYA-SCHYOTA 2026-11-08] schyot sobyti y v kanale = adresny y filter, a ne poisk shablona (@0bf2ef69; PM relay ozhidanie-v2-ADDENDUM; tsifry: 15 = 10+5+0)
- PASTUSHKA: schyot shablona (PRIYOMKA/PRINYATO/VIDZHU/M3/…) po vsemu kanaly, kotory y my sami zapolyaem shablony, = **samootchet nashikh zhe zaprosov**. Dokazatel stvo: 15 sovpadeniy = 10 v relayakh `from=lead` + 5 v `session:liza-*` + **0** `from=operator|chat|chelovek`; primer :2068 avtor=lead (moy zhe zapros).
- METOD (dva shaga, ne odin): (1) nayti avtora sovpadeniya — relay-`from=` / zagolovod `^## session <id>`; (2) filtrovat po avtoru, shablon — vtorym shagom. «Sobytiye vtoroy storony» = sovpadenie, gde avtor NE my (operator/chat/chelovek). Poisk shablona bez adresa = vsegda dayot >0 v kanale, gde my khozyaev.
- TRE sluchaya odnogo printsipa [MERA-OTVERGAET-METOD] (skilla powershell-first): (1) «odinochka protsessа» → 22 signatury ENOENT; (2) bayty-vs-simvoly clipboard → +4 066 lzha-obrezka; (3) schyot shablona po samonapisannomu kanaly → samootchet. Printsip: **metod izmireniya = tozhe proveryayemy y kritery**; pered vyvodom «sobytiya net/est» proveryay, kto avtor sovpadeniy.
- UZOL dlya relay-01 (kak vyglyadit NASTOYASHCHAYA bukva, kanon 844507B4): `relay priyomka-operatora-NN from=lead topics=priyomka sha1=<8hek>` (NN>00, bez probelov/kommov v topics, bez hvosta posle sha1) + **sleduyushchaya stroka = doslovny y tekst otveta operatora** (PRIYOMKA ZVYODZDY: PRINYATO ili PRIMECHANIYA — …). Otlichie ot nashikh zaprosovykh strok: nashi zaprosy soderzhat eti zhe slova v opisanii kriteriev (vyzyvayut lozhny e schyot); bukva = imenno relay s NN>00 + doslovny y otvet v sleduyushchey stroke, id i sha zafiksirovany; ego ozhidaet AKT 9A49BF4C (bez nego — nichego ne pishet, §20.9).

<!-- SYNC-20261108-p11-merya -->
### P11 PORYADOK IZMIRENIYA DEL TY (dopolneniye k bloku rotatsii; @8eb5fcdf, merya lida: 17 strok · 1 session · 2 relay · 2 602 b)
- Nachnaya tochka = sleduyushchaya stroka posle zagolovka poslednego `^## ROTATION` (index+1). Izmeryat' OTDEL NO tri velichiny, ne svodya ih v odnu: (1) bloki = schyot strokek `^## session` v del te; (2) relay = schyot strokek `^relay ` v del te; (3) bayty = summa UTF8-baytov strokek del ty + 1 (EOL). Porogi: blokov >= 20 ИLI bayty > 153 600. Poisk postoronney strokeki v del te (napr. s chislom «10») = ne metod schyota.
- **CHETVYORTY Y SLUCHAY [MERA-OTVERGAET-METOD]** (2026-11-08 07:59): v PM-relaye zayavleno «10 session-blokov posle anker» (ochevibka — v del te po mere **1 session + 2 relay, 2 602 b**, 17 strok); itog po porogu ne izmenilsya (1 << 20 → rotatsiya ne trebuyetsya), no zayavlennoye chislo proveryaetsya Toy zhe mero y, chto i poryadok schyota: **lyuboye chislo v PM-relaye = proveryaemo y fakt, ego nado izmeryat' DO zapisi; esli uzh e zapisano (append-only §3) — chestny y ADDENDUM, kak s 15/12-0**. Sluchai: (1) 22 signatury · (2) +4 066 bayty-vs-simvoly · (3) samootchet 15 = 12/0 · (4) «10» vs merya «1+2».

<!-- SYNC-20261108-mera-snaruzh-pisatelya -->
## [MERA-SNARUZH-PISATELYA 2026-11-08] gde imenno izmeryat': mera = otdel ny y progon, ne vnutri pisatelya (@1d7d7ba0; dokazatel stvo: relay zhdu-v6 + ADDENDUM)
- PRAVILO 1: mera = **otdel ny y progon** (PS/node) so vvedom v relay: chisla peredavayutsya pisatelyu cherez **argv ili fayl arhefaktov** (napr. `node pm-append.mjs <sha1-8> <simv> <bayty>`); pisatel = tol ko formirovaniye i append, on ne izmeryayet.
- PRAVILO 2: vstroenny y shell v pisatelye = **zapreshchyon**. Dokazatel stvo taktiki (lid, chestnoye): node → `powershell -Command "... ?"` → ParserError na sinksise (ternarny y `?` = C#, ne PS) → mera ne vypolnilas → v relay popalo chestnoye «izmerenie nedostupno»; chisla polucheny otdel nym progonom → ADDENDUM `zhdu-v6-ADDENDUM` (append-only, bez otkata §3).
- PRAVILO 3: esli mera vse-taki vnutri i upala — v relay pishetsya «izmerenie nedostupno» + sleduyushchiy relay = ADDENDUM s izmeryonnymi chislami; nikakikh ocenok/otsenok vmesto chisel.
- SVYAZ: p. 2 poryadka P11 («chisla DO zapisi») zakryvaet vtoruyu polovinu: esli mera vnutri pisatelya, ona **ne proveryaetsya sovsem** (net razdeleniya «izmeril → zapisal»); printsip [MERA-OTVERGAET-METOD] (4 sluchaya: 22 signatury · +4 066 · 15=12/0 · «10» vs «1+2») — pyata y gran: otveryaetsya ne tol ko chislo i metod, no i MESTO izmireniya.

<!-- SYNC-20261108-snimok-mgnoveniya -->
## [SNIMOK-MGNOVENIYA 2026-11-08] mgnoveniya append-only kanala bez snimka ne povtoryaemy (@d8adfd2d; para primerov: FF40D01E → 33900147)
- PRAVILO: meru append-only kanala, kotora y mozhet ponadobitsya dlya razresheniya raskhоzhdene y, arhiviruyut **PERED izmireniyem**: `Copy-Item POSTMESSAGE tmp/<task>/kanal-<sha1-8>.txt` — eto i est snimok mgnoveniya (on zhe = tochnaya vkhodnaya tochka); schyot vedetsya **PO SNIMKU**, a ne po zhivomu kanaly.
- POCHEMU: mgnoveniya bez snimka **ne povtoryaemy** — eto svoystvo tipa dannyykh (append-only), a ne bytovoy sovet. Dva nablyudeniya odnogo takta dali raznyye chisla i ne mogut byt svedeny: lid `9/19/26 502 b` @ mgnovenie B084994E; liza `9/20/28 458 b` @ mgnovenie E9D3A8BE. Oba vyvereny v svoy moment, segodnya ne povtoryayutsya.
- Chto DELAT pri raskhоzhdanii: svyazyvat' kazhduyu meru s ee snimkom (sha1-8 kanala v moment mery); sravnivat' tol ko mery odnogo snimka; arifmetika «+1/+1/+1 mezhdu mgnoveniyami» = vyvoda, ne mera. Esli chislo uzh e zapisano v PM i ne povtoryaemo → chestny y ADDENDUM (pravilo 3 bloka [MERA-SNARUZH-PISATELYA]), bez otkata §3.
- PARA PRIMEROV («chislo uzh e zapisano → ADDENDUM»): B6A4E9C9 · DA966A1D → B084994E · FF40D01E → 33900147.
- SVYAZ: [MERA-SNARUZH-PISATELYA] (gde) · [EDINITSY-IZMIRENIYA-SIMVOLOV] (chem) · P11 «chisla DO zapisi» (kogda) · [ADRESNAYA-ATTRIBUTSIYA-SCHYOTA] (kto). Etot blok zavershaet kvartetu: **kakoy imenno mgnoveniye izmeryaetsya**.

<!-- SYNC-20261108-schyota-iz-vyvoda -->
## [SCHYOTA-IZ-VYVODA-GENERATORA 2026-11-08] istochnik chisla = ispolneniye, ne namerenie (@3924ab81; dokazatel stvo: tsepa ADCAAA77 → 05E7137F → 9228AC67)
- PRAVILO 1: schyota generiruyemykh arteфaktov (graf/zhurnaly/registry) dlya relay berutsya **iz vyvoda ispolnennogo generatora v tom zhe progone** (pechat `NODES/EDGES/FACTS`, exit code, sha faylov). Podschet elementov massiva «v golove» = **vyvoda, ne mera** (da zhe esli on veyno v golove avtora).
- PRAVILO 2 (pri padenii): esli generator upal — relay s chislami **ne pishetsya** (chisel net); pishetsya «izmerenie nedostupno», sleduyushchiy relay = ADDENDUM (pravilo 3 [MERA-SNARUZH-PISATELYA]). Pusty e/obrezannyye sha v relaye = eto zhe sluchay.
- PRAVILO 3 (svyaz s kvarteto y): chisla privyazyvayutsya k mgnoveniyu ispolneniya i peredavayutsya pisatelyu vne ego (argv = [MERA-SNARUZH-PISATELYA]); dlya append-only kanala predvaryaetsya snimkom ([SNIMOK-MGNOVENIYA]); KOGDA = DO zapisi (P11).
- DOKAZATEL STVO TAKTA (liza, chestno; 8-y/9-yy sluchay semiystva): generator upal (lishnyaya kotirovka stroke 100) → relay `handoff-v6` = **ADCAAA77** ugosha s pyaty pustymi sha → ADDENDUM **05E7137F** (pyat sha verny e, no schyota 55/23/34 «iz golovy») → ADDENDUM2 **9228AC67** (merenny y vyvod = **61/26/36**). Nezavisimaya proverka lida: pereschet po prefiksakh (`(F|S)-` / `E-` / `F`) = 61/26/36 + dva zapiska generatora dayut odinakovy ye pyat sha (A==B = True) → klass 1 (bajt-determinizm).
- SVYAZ: shestaya gran' printsipa [MERA-OTVERGAET-METOD] (pyat predyshchikh: chislo · metod · mesto · edinitsy · mgnoveniye · avtor adresa) = **istochnik chisla**: ispolnenny y vyvod, a ne namerenie/obsuzhdeniye.

<!-- SYNC-20261108-placeholder-vorota: liza takt14 (NAHODA FALSE-POSITIVE @22b8582a; ACCEPT takta-13) -->
## [PLACEHOLDER-VOROTA: LITERALY V SHA1=, NE LYUBYE OSTRYE SKOBK] 2026-11-08 @c67b629b
- UROK: vorota [<>] + $( v relay-stoke = found=4 FALSE POSITIVE (lovia -> v yaw=180->0 i $( v prose opisanija defekta).
- KANON detekta: (a) sha1=< + litera (napr. sha1=<HEAD>, sha1=<X>) = nezamenennaya podstanovka; (b) <[A-Z]{2,}> versholniy token = zamenennyy shablon; (c) -> v prose, strelki, masy s (v nakhode) = NE placeholder.
- MERA: etalon = predyushchiy relay-23 (chisty po suwestvi: sha1=c67b629b=HEAD). Pered appendom proveryat' regex sha1=<[A-Za-z0-9]*>; negodnyy = DEFECT-PLACEHOLDER (relay NET, peresobrat' s real'nymi chislyami; esli uze zapisano — supplementary-stroka, append-only ne terpit pravok §3).
## [RELAY-TEKST-IZ-FAILA 2026-11-08] relay s apostrofami/kirillicej = IZ FAJLA, ne PS-literal (@927597af, urok #18; prakika takt-18 relay30)
- FAKT: relay-tekst s apostrofami (kirillichnykh/translitnykh) peredajetsya kak PS-literal -RelayText '…' = PARSE-padenie v stroke parametra. Takt-18: relay-tekst s opisaniem uroka #17 (apostrof vnutri odinochnoy kakavki) SAM vyzval PARSE-padenie — ironiya kanona; pochin = FAIL-kanal (tekst v fail relay30.txt → Get-Content -Raw → -RelayText).
- KANON: relay-tekst = pishetsya v FAIL (relayN.txt, write/Redaktor), peredajetsya kak -RelayText (Get-Content -Raw relayN.txt -Encoding UTF8). PS-literal dopustim TOKO bez apostrofov/kavychk/spetsiomvolov. Vorota v2 (PLACEHOLDER-VOROTA) = proverka IZ FAILA posle chteniya (found=0 = prohod).
- MERA: takt-18 relay30.txt = pervaya boyovaya primeneniya (vorota found=0, PM-A ff54a0d7→646797b8, relay 30-y). Priyomka: v PM-A relay-stroka = odinochnaya, s real'nymi sha1=, bez vlozhennyh kavychok-lomov.