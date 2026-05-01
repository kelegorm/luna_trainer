---
title: "feat: Full-game difficulty variation & post-session controls"
type: feat
date: 2026-05-01
origin: docs/brainstorms/2026-05-01-tango-trainer-requirements.md
parent_plan: docs/plans/2026-05-01-001-feat-tango-trainer-mvp-plan.md
status: ready
---

# Full-game difficulty variation & post-session controls

## Overview

Расширение требований к full-game режиму. Добавляются: (1) автоматическая вариация сложности партий (silent diagnostic-driven), (2) пост-сессионные кнопки для лёгкой относительной подстройки игроком, (3) variety-гарантия со стороны генератора («не под копирку»). Все события партии помечаются band-ом сложности и флагом подстройки — данные собираются в v1 для будущего factorial-анализа, но в FSRS/mastery в v1 не используются.

Это **расширение** существующего брейншторма, не замена. R1–R33 из origin остаются в силе. Добавляются R34–R39.

---

## Problem Frame

Игрок хочет:
- **разнообразия партий** — конкурентные приложения (Binary Twist) дают «под копирку» пазлы, плюс добавляют рекламу; здесь должно быть органично иначе;
- **варьирующиеся условия для замера mastery** — играть только в одном режиме сложности → mastery замерена в узком срезе условий;
- **возможность мягко настроить градус** — без кликов в меню, без выбора пресетов; «иногда хочется проще, иногда сложнее»;
- **режим «просто поиграть»** — без давления тренинга, но всё же со статистикой в фоне.

Главное продуктовое требование — **диагностика остаётся чистой**. Пользователь не выбирает «сложно» 80% времени, чтобы потом посмотреть на mastery в этой узкой полосе и принять решения. Поэтому управление условиями оставлено системе по умолчанию.

---

## Key Product Decisions

| Решение | Выбор |
|---|---|
| Кто выбирает условия | **Система авто** по умолчанию. Пользователь не видит параметров во время игры. |
| Granularity условий | **Один difficulty_band** ∈ {1=easy, 2=medium, 3=hard}. Внутри band инкапсулированы плотность стартовых меток, доля знаков `=`/`×`, набор требуемых техник дедукции. |
| Distraction отдельным фактором? | **Нет**. Distraction эмерджентно появляется в высоких band и измеряется через них. Можно вынести в v2, если данные покажут отдельный сигнал. |
| Mastery factorial (техника × band)? | **Нет в v1**. `difficulty_band` логируется на MoveEvent, но mastery остаётся per-heuristic. Через ~2 недели данных пересмотрим. |
| Спец-режим с явным выбором band? | **Не в v1**. Только авто + post-session relative nudge. |
| Manual technique selection в drill? | **Нет** (вне scope). FSRS-планировщик остаётся единственным источником решений о drill. |
| Изменение правил Tango (без `=`/`×` и т.д.) | **Нет** (вне scope). Tango = Tango с фиксированными правилами. |

---

## Requirements

### R34 — Difficulty band на партию
Каждая full-game партия начинается с присвоенным `difficulty_band ∈ {1, 2, 3}`. Параметр **невидим** в UI во время игры (R16-консистентность: «не давать пользователю оптимизироваться против шкалы»). Band варьируется между партиями: алгоритм rotation — Deferred to Implementation (стартово round-robin или weighted random; уточняется после первых 2 недель).

### R35 — Маппинг band → параметры генератора
`difficulty_band` транслируется генератором в конкретные параметры пазла:
- **density** — доля предзаполненных стартовых меток (низкая band → высокая плотность; высокая band → низкая);
- **sign_density** — доля заполненных рёбер знаками `=`/`×`;
- **required_techniques** — набор техник, которые solver должен задействовать для уникального решения (band 1 → только базовые `PairCompletion` + `TrioAvoidance`; band 3 → может потребовать `AdvancedMidLineInference` + `ChainExtension`).
Точные численные пороги — Deferred to Implementation. Калибровка по реальной игре (~2 недели).

### R36 — Логирование band на MoveEvent
Каждое событие хода несёт `difficulty_band` партии. В v1 это поле **не используется** в mastery-агрегации и FSRS-маппинге — оно собирается «впрок» для будущего фактор-анализа. Mastery остаётся per-heuristic, FSRS-карточка остаётся per-heuristic. Через ≥2 недели данных решение о factorial-расширении пересматривается.

### R37 — Post-session controls (4 кнопки)
Экран end-of-session full-game партии содержит ровно 4 кнопки продолжения:
- **«Следующая»** — новая партия с авто-выбранным band (стандартный rotation).
- **«Ещё такую же»** — новая партия с тем же band, что у только что завершённой.
- **«Сложнее ▲»** — band = текущий + 1, clamped to 3.
- **«Легче ▼»** — band = текущий − 1, clamped to 1.

Кнопки **«Сложнее»/«Легче»** не показывают цифру band пользователю, только направление. На band=3 кнопка «Сложнее» disabled (или скрыта); на band=1 «Легче» disabled.

### R38 — User-adjusted флаг
Когда пользователь нажимает любую из {«Ещё такую же», «Сложнее», «Легче»}, **следующая** партия помечается `user_adjusted=true`. Все её MoveEvent-ы наследуют этот флаг. Кнопка «Следующая» (авто) → `user_adjusted=false`.

В v1 этот флаг **логируется, но не используется** в mastery / FSRS — он будет нужен в v2 для контроля selection bias при agg-анализе. Default для всех drill-сессионных событий — `user_adjusted=false` (drill всегда auto).

### R39 — Variety guarantee
Генератор не выдаёт две последовательные full-game партии с структурно идентичной (или почти-идентичной) расстановкой стартовых меток. Существующий `diversity_filter.dart` (U6, Phase B) расширяется проверкой против предыдущей партии того же `difficulty_band`. На горизонте 10 последовательных партий должно быть видно ≥6 структурно различных «форм» пазла.

---

## Acceptance Examples

### AE11 — Авто-rotation и логирование band

Игрок открывает app, нажимает «Играть». Партия 1 → band=2, после финиша «Следующая» → партия 2 = band=1 или 3 (rotation), `user_adjusted=false` для всех MoveEvent обеих партий. В БД проверяемо: `difficulty_band` записан для всех 28 ходов первой партии и всех ходов второй.

### AE12 — Post-session «Сложнее»

Игрок завершает партию band=2 за 4:12. Нажимает «Сложнее ▲». Следующая партия имеет band=3 (видно по плотности меток — заметно меньше) и все её MoveEvent-ы помечены `user_adjusted=true`. На end-of-session этой следующей партии кнопка «Сложнее» disabled (band=3 = max).

### AE13 — Variety guarantee

Игрок играет 10 full-game партий подряд (любое сочетание авто/relative). На end-of-day Mastery-экране визуально или в логе видно: pattern signatures стартовых расстановок в этих 10 партиях имеют ≥6 различных значений. Не должно быть случая «5 подряд одинаковых форм пазла».

---

## Scope Boundaries

### Outside v1 (отвергнуто на этом брейншторме)

- **Ручной выбор band из главного меню** — нет «Спец-партии» / «Custom». Только авто + post-session relative nudge.
- **Настройки правил Tango** — без `=`/`×`, только-баланс, только-no-three — вне scope. Tango в v1 = классический Tango со всеми тремя правилами.
- **Ручной выбор техник для drill** («хочу прокачать только ParityFill») — вне scope. FSRS-планировщик единолично решает, что подавать в drill.
- **Factorial mastery (техника × band)** — отложено. Данные собираются, решение через ≥2 недели.
- **Distraction как отдельный фактор** — поглощён в difficulty_band. Если данные покажут отдельный сигнал — выносим в v2.
- **Видимый difficulty-индикатор во время игры** — пользователь не должен «оптимизироваться против шкалы» (R16-консистентность).

### Deferred to v2

- **Спец-режим с явным выбором band и параметров** — после первого месяца лайв-юза, если пользователь скажет «не хватает».
- **Factorial mastery model** — после анализа корреляции `band × heuristic latency` за 2 недели.
- **Sub-параметры band** (отдельные ползунки density / signs / techniques) — если факт-анализ покажет, что они независимо влияют на latency.
- **Per-game timer / speed-modes** — упомянуто в R16 как «потенциальные», не обязательны для v1.

---

## Impact on Phase C Plan

Этот брейншторм меняет **только U7 schema migration** в существующем плане Phase C. U8 (Mastery scorer) и U9 (FSRS scheduler) **не затрагиваются** — они игнорируют новые поля, mastery остаётся per-heuristic.

**U7 — добавления к schema v1 → v2 миграции:**
- `move_events.difficulty_band INTEGER NOT NULL DEFAULT 2` (R36)
- `move_events.user_adjusted BOOLEAN NOT NULL DEFAULT 0` (R38)
- (исходные из плана: `event_kind`, и поле для propagation/hunt — см. ниже про коллизию имени)

**Phase D — затронутые юниты:**
- **U6 (Phase B)** — генератор уже шипнут, но потребуется amendment: принимать `difficulty_band` параметр и применять маппинг R35. `diversity_filter` расширяется (R39).
- **U10/U11 (Phase D)** — full-game UI: end-of-session экран получает 4 кнопки (R37); главное меню без изменений (только «Играть» + «Тренировка»).
- **U13.1 / drill flow** — не затрагивается.

---

## Implementation-Time Open Questions

Эти вопросы планировщик/исполнитель решает на этапе плана/имплементации, не на брейншторме:

1. **Коллизия имени `mode`** в `move_events_table.dart` (существующий 'full_game'/'drill' vs новый 'propagation'/'hunt' из R31). Уже всплыла в Phase 0 ce-work и не зависит от этого брейншторма. Варианты обсуждены отдельно (drop existing redundant column / rename / use different name for new column).
2. **Rotation algorithm для R34** — round-robin {1,2,3,1,2,3...}, weighted random (50% medium / 25% easy / 25% hard), или mastery-aware (когда mastery выровнено — больше hard; иначе — больше easy). Стартово: round-robin с jitter. Калибруется.
3. **Численные пороги R35** — какая density / sign_density / technique-set даёт band=1 / 2 / 3. Стартовые значения подбираются эмпирически на 20–30 сгенерённых пазлах.
4. **Variety threshold для R39** — точное определение «структурно идентичная» расстановка (хеш позиций меток? косинус-сходство? ≥80% совпадение?). Стартово — exact-match по signature позиций; уточняется.

---

## Origin & Source

- Расширение [`docs/brainstorms/2026-05-01-tango-trainer-requirements.md`](2026-05-01-tango-trainer-requirements.md). R1–R33 остаются в силе.
- Концепт [`docs/tango_trainer_concept.md`](../tango_trainer_concept.md) и [`addendum`](../tango_trainer_concept_addendum.md) — раздел про three-layer drill (R30) формирует параллельную таксономию для **drill**, не для full-game. Этот брейншторм — full-game-specific.
- Затрагиваемый план — [`docs/plans/2026-05-01-001-feat-tango-trainer-mvp-plan.md`](../plans/2026-05-01-001-feat-tango-trainer-mvp-plan.md). Plan amendment требуется до старта Phase C (U7 schema).
