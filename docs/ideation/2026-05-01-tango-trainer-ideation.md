---
date: 2026-05-01
topic: tango-trainer
focus: Flutter-мобильный тренажёр для LinkedIn Tango (sun/moon, 0-1) с per-move диагностикой слабых дедукций и генератором drill-ситуаций
mode: elsewhere-software
---

# Ideation: Tango Trainer (Flutter, mobile)

## Topic Context

**Что строим.** Личное Flutter-мобильное приложение для тренировки LinkedIn Tango (6×6 sun/moon: равные счётчики в строке/столбце, no-three-in-a-row, парные `=`/`×` constraints). Без рекламы, без сервера, без облака. Solo-проект для себя.

**Уникальный механизм.** Приложение наблюдает за игрой, замеряет per-move latency, классифицирует дедукции (named heuristics) и определяет, какие у игрока «медленные». Не решает за пользователя — только подсказывает по запросу. Drill-режим: «найди именно эту дедукцию здесь» → 1+ тап → следующая ситуация.

**Pluggable.** Архитектура такая, чтобы потом подключить Queens / Zip / Binairo поверх той же диагностической инфраструктуры.

## Grounding Highlights

- **Open-source Tango solver `brohitbrose/linkedin-games`** уже выделяет 5 named line-level heuristics: PairCompletion, TrioAvoidance, ParityFill, SignPropagation, AdvancedMidLineInference. Стартовый каркас бесплатно.
- **Канонической human-facing таксономии Tango нет** (в отличие от Sudoku). Open space для определения собственного словаря.
- **ChessTempo per-motif Glicko + Lichess Puzzle Themes** — прямой blueprint per-skill ratings; multi-theme attribution problem (Lichess) у Tango снимается, потому что каждый ход — атомарная дедукция.
- **Pitfall (Nature 2015, RT reverse-inference):** raw latency не диагностичен в одиночку. Нужны converging evidence: latency + (wrong move ИЛИ запрос подсказки ИЛИ повторение через несколько эпизодов).
- **FSRS / BKT** — open-source open-spaced-repetition/fsrs4anki, портируется на dart. Применяется на уровне *техники*, а не задачи.

## MVP — что строим в v1

### 1. Heuristic-Annotated Solver + канонический каталог дедукций

Один движок, который для любой позиции возвращает: список доступных дедукций (с тегом), какая «самая дешёвая», какие клетки она форсирует. Все остальные фичи — обёртки.

Стартовый каталог (~7 техник для MVP):
- `PairCompletion` — две одинаковые подряд → третья противоположна
- `TrioAvoidance` — `X _ X` → середина противоположна
- `ParityFill` — строка/столбец достиг 3 одного знака → остальные противоположны
- `SignPropagation` — известная клетка через `=`/`×` определяет соседа
- `AdvancedMidLineInference` — две середины через `=` + одна граничная → определяет другую границу
- `ChainExtension` — дедукция, ставшая доступной после предыдущего хода (тренируется отдельно как «басовая цепочка»)
- `Composite(unknown)` — позиция, требующая многоходовой/комбинированной дедукции вне MVP-словаря (логируется, но в drill не подаётся)

**Confidence:** 90% · **Complexity:** Medium · **Status:** Unexplored

---

### 2. Drill-режим: один экран, одна дедукция, цепочки

UX:
- Сгенерированный мини-фрагмент (2×4 / 3×3 / целая строка/столбец) показывает ровно одну форсированную дедукцию targeted-типа
- Юзер ставит **все** клетки, форсируемые этой дедукцией (может быть 1, может 3)
- Таймер скрыт; в конце сессии — средние показатели
- **ChainDrill:** если после ответа на доске появилась новая быстрая дедукция, не сбрасываем экран — продолжаем на той же позиции («давай ещё, она теперь видна»). Тренирует прокручивание domino-effect без пересканирования. Цепочка пишется в лог как chain-event.
- **Выход без штрафа всегда доступен.** Кнопка «выйти» не блокируется, прерванный сеанс не наказывает рейтинги.
- Кнопка «сдаюсь → объяснение» — по запросу. Объяснение показывается на отдельном «учебном поле» (не на основной доске), где видна только релевантная строка/столбец/фрагмент. Таймер паузится во время чтения.
- Сколько ситуаций в сессии — **открыто** (предложение: 5–10, или «пока хочу»).

**Confidence:** 85% · **Complexity:** Medium · **Status:** Unexplored

---

### 3. Hint-as-diagnostic-signal

Когда пользователь просит подсказку в обычной игре:
- лесенка раскрытия: имя дедукции → подсветка клеток-преконда (на отдельном поле) → оптимальный ход → пояснение если незнакомо
- каждый шаг лесенки логируется как отдельный сигнал слабости («даже после имени дедукции не нашёл»)
- таймер паузится на время объяснения

**Это converging-evidence ход:** сочетание `latency + hint requested` имеет высочайший confidence «эту дедукцию не вижу».

**Confidence:** 90% · **Complexity:** Low–Medium · **Status:** Unexplored

---

### 4. Per-Heuristic Mastery Tracking + скользящее окно «последние 7 дней»

- На каждую дедукцию — отдельная статистика: latency-распределение (медиана + 25/75 перцентили + count), error rate, hint-rate
- **Гибрид:** FSRS-параметры на каждую технику для drill-планировщика (когда показать снова) + percentile-based mastery vs solver-baseline для прогресс-графика (насколько я хорош)
- Скользящее окно «последние 7 дней» — настраиваемое
- Cold-start: дедукция в drill активируется после ≥ ~10–15 событий калибровки. До того — играем обычные партии, статистика собирается, drill не предлагается по этой технике
- Радар-чарт по техникам; рост виден в динамике

**Confidence:** 80% · **Complexity:** Medium · **Status:** Unexplored

---

### 5. Параметрический генератор уровней с разнообразием

Генератор принимает target-heuristic mix histogram (например `{ParityFill: 2, SignPropagation: 3, TrioAvoidance: 1}`) и возвращает уникально-решаемый puzzle с заявленным составом.

Разнообразие через два механизма:
- **e1: target-mix histogram** — варьируется педагогическая нагрузка
- **e3: hash прошлых уровней + min-distance threshold** — структурная не-похожесть на ранее увиденное

Один генератор обслуживает: drill-фрагменты, full-game партии, калибровочные пазлы, прогрессию.

**Confidence:** 80% · **Complexity:** Medium-High · **Status:** Unexplored

---

### 6. Replay-as-Tutor + Stuck-Moment Scrubber

После full-game партии:
- diff между ходами игрока и solver-оптимальным путём
- автоматически генерируются drill-карточки для каждого медленного/неоптимального хода, помеченные нужной эвристикой, попадают в FSRS-очередь на завтра
- UX: скруббер только по 2–3 самым долгим паузам, не по всем 30 ходам

**Confidence:** 80% · **Complexity:** Medium · **Status:** Unexplored

---

### 7. Pluggable Puzzle-Type Architecture

Интерфейс `PuzzleKind`: правила-как-constraints, каталог эвристик, рендерер, input-handler. Tango — первая реализация. Двигатель тренажёра (telemetry, mastery, FSRS, drill-планировщик) — puzzle-agnostic.

**Confidence:** 75% · **Complexity:** Medium-High · **Status:** Unexplored

---

### 8. Distraction Guard + скрытый таймер

- `AppLifecycleState` + `sensors_plus`: ход помечается `contaminated`, если приложение в фоне / телефон неподвижен > N сек / простой > 8 сек
- Таймер юзеру не показывается; разные режимы (speed / untimed / drill) перемешиваются, чтобы нельзя было оптимизироваться против часов
- Без этого диагностический движок учится на мусоре

**Confidence:** 90% · **Complexity:** Low · **Status:** Unexplored

---

## Принципиальные правила (зафиксировано)

1. **Агент не решает за пользователя.** Только подсказывает (по запросу) и предлагает drill (можно отказаться).
2. **Выход из drill — всегда без штрафа.** Прерванный сеанс не понижает рейтинги.
3. **Локально, sqlite, без сервера, без облака.**
4. **Многоходовые/машинные дедукции — отложены.** Логируем как `Composite(unknown)`, в drill не подаём. Накопленные случаи — сигнал расширять таксономию.
5. **Cold-start = обычные партии.** Никакого специального «диагностического» онбординга.
6. **Distribution-aware скорость.** При оценке скорости эвристики смотрим на распределение, не только среднее.

## Открытые вопросы (для следующей итерации / brainstorm)

- Длина drill-сессии (фиксированная vs «пока хочу»)
- Где показывать прогресс — постоянно в углу / только по запросу / в конце сессии
- Авторитетный источник дедукций кроме `brohitbrose/linkedin-games` (искать после первого прототипа)
- Защита от выгорания — нужен ли soft-cap N drill/день
- Точные параметры FSRS (использовать дефолты open-spaced-repetition и калибровать на личных данных)
- Min-distance threshold для генератора разнообразия (определить эмпирически)

## Rejection Summary

| # | Идея | Причина отказа |
|---|------|-----------------|
| 1 | Hide the Diagnosis | Анти-паттерн для self-built: пользователь явно хочет видеть прогресс |
| 2 | Reverse Solver (build puzzle from solution) | Высокая стоимость, нишевый навык |
| 3 | Train the Adversary | Бутиковая механика, низкий ROI |
| 4 | Voice-Only Smartwatch | Огромный overhead Flutter+watch для v1 |
| 5 | Lose-Worst Mode | Тестирует другую ось skill-а, не core |
| 6 | Critic Mode (тренер играет, ты судишь) | Покрыто Hint-as-signal в духе |
| 7 | Slit Mode (одна строка) | Слишком сильно искажает игру, max боковой режим |
| 8 | Eye-tracking / dwell-time heatmap | Требует железо/ML, overlap со scrubber'ом |
| 9 | Ghost-pair / Ghost Heatmap past-self | Требует longitudinal data, отложить v2 |
| 10 | Crossword 'elegance budget' (detour ratio) | Продвинутый, не v1 |
| 11 | Multi-solution puzzles | Усложняет генерацию, нишевый сигнал |
| 12 | Variable grid size | Минор, отложить |
| 13 | Daily LinkedIn-Mirror Mode | Полезен для transfer'а, но v2 |
| 14 | Rule-less onboarding | Бутиковый, не v1 |
| 15 | Open-source the solver | Ортогонально, optional polish |
| 16 | Explain-Before-Place (тег при каждом ходе) | Пользователь явно предпочёл пассивное наблюдение + hint-as-signal |
| 17 | One-Second Reflex Drill | Поглощено в Drill-режим (B) — flash-вариант можно добавить как sub-mode |
| 18 | No-Undo Commit Mode | Поглощено: drill требует именно зафиксированных ходов |
| 19 | Auto-Fill the Trivial | Поглощено в Constraint-Isolation Drills (mid-puzzle starts) |
| 20 | Time the Puzzle, Not the Player | Поглощено: solver-baseline используется как нормализатор в percentile-mastery |
| 21 | Predict-the-Next-Move Roulette / DDx mode | Поглощено в Hint-as-signal лесенку |
| 22 | Heuristic Heatmap Over the Board | Поглощено в Replay-as-Tutor |
| 23 | The undo trace is the diagnosis | Поглощено в Move-Event Telemetry (стандартное логирование событий) |
| 24 | Generalize away from Tango | Поглощено в Pluggable Architecture (#7) |
| 25 | Keybr-style adaptive generator | Поглощено в #5 (target-mix histogram) |
| 26 | Speedcube algorithm cards | Поглощено в Drill-режим |
| 27 | Pre-mortem drills | Поглощено в Replay-as-Tutor cycle |
| 28 | Mistake-Rewind With Forced Re-derivation | Поглощено в Hint-as-signal лесенку |
| 29 | No-Solve Mode (Spot the Lie) | Полезен как сторонний sub-mode, не core MVP |
| 30 | Per-Heuristic Bayesian Skill Model (отдельной идеей) | Поглощено в Mastery Tracking (#4) — гибрид FSRS+percentile |
