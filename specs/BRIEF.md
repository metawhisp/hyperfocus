# BRIEF — Hyperfocus (исходное задание, дословно)

> Этот файл — первоисточник продуктовых требований. Он не редактируется.
> Все остальные документы в `specs/` производны от него. При конфликте
> детализации побеждает `specs/00-canon.md` (там зафиксированы принятые
> решения), при конфликте продуктового смысла — этот файл.

---

Ты — senior macOS product engineer, Swift/SwiftUI/AppKit developer и UX designer. Твоя задача — спроектировать и реализовать рабочий MVP macOS-приложения под названием Hyperfocus.

Hyperfocus — это улучшенный Pomodoro/focus timer для людей с ADHD/СДВГ и для всех, кому тяжело начать задачу, удерживать внимание и не выпадать из работы. Приложение должно ощущаться не как обычный таймер, а как кинематографический режим входа в работу: пользователь нажимает маленькую точку на экране, выбирает одну задачу, задаёт время, видит обратный отсчёт, экран темнеет, появляется зелёная аура по краям экрана, включается таймер и камера-присутствие.

Главный продуктовый образ:
Hyperfocus turns your Mac into a focus mode.
One click. One task. Enter Hyperfocus.

Суть приложения:
На экране Mac всегда видна маленькая стеклянная floating-точка — Focus Orb. Пользователь нажимает её, вводит одну конкретную задачу, выбирает длительность сессии и запускает режим Hyperfocus. После запуска приложение показывает fullscreen countdown: "Enter Hyperfocus Mode. 3…2…1… Focus." Затем экран возвращается в рабочий режим, но по краям экрана остаётся зелёное свечение — Aura Frame. Запускается таймер. Камера MacBook включается и локально проверяет, находится ли пользователь перед экраном.

Если пользователь уходит из кадра или явно выпадает из режима, приложение ставит таймер на паузу, зелёная аура становится красной, включается мягкий продолжительный alarm/brown-noise звук, появляется карточка "Session paused. Return to Hyperfocus or exit." Когда пользователь возвращается в кадр и остаётся там 3 секунды, сессия продолжается: звук выключается, аура снова становится зелёной, таймер идёт дальше.

Это приложение не должно выглядеть как дешёвый gaming UI. Нужен дорогой macOS-стиль: Liquid Glass, glass cards, blur, dark translucent UI, мягкие тени, зелёное свечение, минимальный интерфейс, лёгкий sci-fi focus mode.

Платформа:
macOS.

Предпочтительный стек:
Swift.
SwiftUI.
AppKit там, где SwiftUI недостаточно.
AVFoundation для камеры.
Vision framework для face detection.
NSSpeechSynthesizer или AVSpeechSynthesizer для голосовых подсказок.
SwiftData, UserDefaults или SQLite для локального хранения сессий.
NSPanel, borderless windows или overlay windows для Focus Orb, fullscreen countdown и Aura Frame.

Главные функции MVP:
1. Floating Focus Orb.
2. Start Session Popover.
3. Mission input.
4. Time selector.
5. Cinematic countdown.
6. Edge Aura Frame.
7. Active timer.
8. Camera permission request.
9. Local face presence detection.
10. Away Mode.
11. Pause/resume timer based on presence.
12. Soft alarm/brown-noise sound.
13. Voice prompts.
14. Completion screen.
15. Local session history.
16. Basic settings.

Не нужно делать в первой версии:
Командные комнаты.
Социальные фокус-сессии.
Cloud sync.
Подписки.
Платежи.
AI coach.
Website blocking.
iPhone camera mode.
Advanced analytics.
App Store payment flow.

Основной пользовательский сценарий:
1. Пользователь запускает приложение.
2. На экране появляется маленькая floating-точка Focus Orb.
3. Focus Orb всегда поверх обычных окон, но не мешает работе.
4. Пользователь может перетаскивать Focus Orb.
5. После отпускания рядом с краем экрана Focus Orb прилипает к краю.
6. Позиция Focus Orb сохраняется между запусками приложения.
7. Пользователь кликает по Focus Orb.
8. Открывается компактная стеклянная карточка Prepare Hyperfocus.
9. В карточке пользователь вводит Mission — одну конкретную задачу.
10. Пользователь может ввести Success condition, но это поле необязательное.
11. Пользователь выбирает длительность: 5, 15, 25, 45 минут или custom.
12. Пользователь выбирает Intensity: Calm, Strict или Cinematic.
13. Пользователь нажимает Enter Hyperfocus.
14. Открывается fullscreen countdown overlay.
15. Экран плавно темнеет.
16. В центре появляется текст "ENTER HYPERFOCUS MODE".
17. Затем показывается обратный отсчёт: 3, 2, 1, FOCUS.
18. Голос произносит: "Enter Hyperfocus Mode. Three. Two. One. Focus."
19. После countdown overlay исчезает.
20. По краям экрана появляется зелёная Aura Frame.
21. Запускается таймер.
22. Включается камера.
23. Face presence detection проверяет, есть ли лицо пользователя в кадре.
24. Если лицо видно, таймер идёт.
25. Если лицо пропало на 7 секунд, состояние меняется на warning, аура становится жёлтой или оранжевой.
26. Если лицо пропало на 15 секунд, состояние меняется на away.
27. В away state таймер останавливается.
28. Аура становится красной.
29. Включается мягкий продолжительный alarm/brown-noise звук.
30. Голос говорит: "Session paused. Return to Hyperfocus or exit."
31. На экране появляется стеклянная карточка с кнопками Return и Exit Session.
32. Если лицо снова видно 3 секунды, приложение переходит в recovering, затем возвращается в active.
33. Alarm выключается.
34. Аура снова становится зелёной.
35. Таймер продолжается.
36. Голос говорит: "Focus restored."
37. Когда таймер дошёл до нуля, сессия завершается.
38. Аура мягко исчезает.
39. Голос говорит: "Mission complete."
40. Показывается Completion screen со статистикой сессии.
41. Пользователь отмечает результат: Done, Partial или Not done.
42. Сессия сохраняется локально.
43. Камера выключается.
44. Focus Orb возвращается в idle state.

Focus Orb:
Сделай маленькую always-on-top floating-точку.
Размер по умолчанию: 18–24 px.
Форма: круг.
Стиль: glass, translucent, soft shadow.
Idle state: стеклянная полупрозрачная точка.
Ready state: мягкая зелёная пульсация.
Active state: зелёное ядро внутри.
Warning state: жёлтая/оранжевая пульсация.
Away state: красное ядро.
Completed state: мягкая зелёная вспышка.
Точка должна быть draggable.
Точка должна магнититься к краям экрана.
Точка должна сохранять позицию.
Клик открывает Start Session Popover.
Long press или secondary click открывает быстрые действия:
Pause.
Exit Session.
Hide for 10 minutes.
Settings.

Start Session Popover:
Карточка должна быть маленькой, стеклянной, полупрозрачной, с blur и мягкой тенью.
Это не полноэкранное окно.
Заголовок: "Prepare Hyperfocus".
Подзаголовок: "One task. One session."

Поля:
Mission:
Placeholder: "What are you doing in this session?"
Это обязательное поле.
Без Mission сессию нельзя запустить.

Success condition:
Placeholder: "This session is successful if…"
Поле необязательное.

Time:
Presets:
5 minutes.
15 minutes.
25 minutes.
45 minutes.
Custom.

Intensity:
Calm.
Strict.
Cinematic.

Primary CTA:
Enter Hyperfocus.

Secondary CTA:
Cancel.

Countdown Overlay:
После нажатия Enter Hyperfocus показывай fullscreen overlay.
Фон затемняется.
В центре:
ENTER HYPERFOCUS MODE.
Затем:
3.
2.
1.
FOCUS.

Анимации:
Плавный fade in.
Лёгкий scale.
Мягкое свечение текста.
После FOCUS overlay исчезает.
После исчезновения остаётся Aura Frame.

Голос:
"Enter Hyperfocus Mode. Three. Two. One. Focus."

Aura Frame:
Aura Frame — это свечение по краям экрана.
Сделай 4 overlay windows:
top.
bottom.
left.
right.

Каждое окно:
Transparent.
Borderless.
Always-on-top.
Не перехватывает клики.
Не мешает работе.
Рисует gradient glow.

Состояния:
Active: зелёная аура.
Warning: жёлтая/оранжевая аура.
Away: красная аура.
Completed: зелёная вспышка и fade out.
Idle: ауры нет.

Свечение должно быть тонким:
Заметно периферийным зрением.
Не перекрывает контент.
Не мешает читать текст.
Не выглядит как агрессивный neon.

Active Session HUD:
Во время сессии интерфейс должен быть минимальным.
HUD показывается рядом с Focus Orb или при hover.

HUD содержит:
Mission.
Remaining time.
Camera status.
Session status.
Exit button.

Пример:
Mission: Write landing page draft.
Time: 18:42.
Status: Present.

Camera status values:
Present.
Looking for you.
Away.
Camera off.
Permission needed.

Away Mode:
Away Mode запускается, если лицо не видно 15 секунд.
Поведение:
Таймер останавливается.
breakCount увеличивается.
currentStreak сбрасывается.
Аура становится красной.
Включается soft continuous alarm или brown-noise sound.
Голос говорит: "Session paused. Return to Hyperfocus or exit."
Появляется glass card:

Title:
Session paused

Text:
Return to Hyperfocus or exit the session.

Buttons:
Return.
Exit Session.

Return:
Кнопка активна, когда лицо снова видно.
После 3 секунд presence recovery сессия продолжается.

Exit Session:
Завершает сессию.
Сохраняет completionStatus = exited.
Закрывает камеру.
Выключает alarm.
Возвращает приложение в idle state.

Recovering State:
Когда лицо снова видно после Away Mode:
Показать короткий recovery countdown:
3.
2.
1.
Back to focus.

После этого:
alarm выключен.
aura green.
timer resumed.
voice: "Focus restored."

Completion Screen:
Когда remainingFocusTime == 0:
Остановить камеру.
Выключить alarm.
Скрыть Aura Frame через мягкий fade out.
Показать стеклянную карточку:

Title:
Mission complete

Fields:
Mission.
Focus time.
Paused time.
Breaks.
Longest streak.

Question:
Did you complete the mission?

Buttons:
Done.
Partial.
Not done.

Optional field:
Next action.

После сохранения результата:
Сохранить сессию локально.
Закрыть completion UI.
Вернуть Focus Orb в idle state.

Camera Presence Detection:
Используй AVFoundation для видеопотока с камеры.
Используй Vision framework для face detection.

Правила privacy:
Не записывать видео.
Не сохранять кадры.
Не отправлять кадры на сервер.
Не делать identity recognition.
Не делать emotion detection.
Не делать распознавание конкретного человека.
Обработка только локально на Mac.
Камера выключается после завершения сессии.
Пользователь может запустить сессию без камеры в fallback mode.

Camera states:
cameraNotAuthorized.
cameraUnavailable.
cameraDisabled.
facePresent.
faceMissing.
warning.
away.

Логика:
При старте сессии проверить camera permission.
Если доступа нет, запросить доступ.
Если доступ получен, начать capture session.
Каждые N кадров запускать Vision face detection.
Если face detected, state = facePresent.
Если face missing больше 7 секунд, state = warning.
Если face missing больше 15 секунд, state = away.
Если face detected again for 3 seconds, state = recovering, затем active.
Если камера недоступна, предложить no-camera session.

No-camera fallback:
Если пользователь не дал доступ к камере или камеры нет:
Сессия всё равно может стартовать.
Вместо presence detection использовать manual mode:
Таймер идёт.
Пользователь может вручную pause/resume.
HUD показывает Camera off.
В settings должен быть toggle: Allow sessions without camera.

Timer Logic:
Таймер должен считать только active focus time.

Переменные:
plannedDurationSeconds.
remainingFocusTime.
activeFocusSeconds.
pausedSeconds.
breakCount.
longestStreakSeconds.
currentStreakSeconds.
sessionStartTime.
sessionEndTime.
mission.
successCondition.
completionStatus.
intensity.
cameraEnabled.

Правила:
Если state = active, remainingFocusTime уменьшается.
Если state = warning, таймер может продолжать идти до away threshold.
Если state = away, таймер не идёт.
Если state = manualPaused, таймер не идёт.
Если state = recovering, таймер ещё не идёт, затем продолжается.
Если user exits, сессия сохраняется как exited.
Если remainingFocusTime == 0, сессия завершается как completed.
activeFocusSeconds — это реально отработанное время.
pausedSeconds — время, когда сессия стояла на паузе.
longestStreakSeconds — самый длинный непрерывный active interval.
breakCount — количество переходов в away.

State Machine:
Используй такую модель состояний:

idle.
preparing.
countdown.
active.
warning.
away.
recovering.
manualPaused.
completed.
exited.

Переходы:
idle -> preparing.
preparing -> countdown.
countdown -> active.
active -> warning.
warning -> active.
warning -> away.
active -> away.
away -> recovering.
recovering -> active.
active -> manualPaused.
manualPaused -> active.
active -> completed.
active -> exited.
away -> exited.
completed -> idle.
exited -> idle.

State definitions:
idle:
Focus Orb visible.
No aura.
Camera off.
Timer stopped.

preparing:
Start popover visible.
User configures mission and time.

countdown:
Fullscreen countdown visible.
Screen darkened.
Voice countdown active.
Camera may start warming up.

active:
Green aura.
Timer running.
Face present or no-camera mode accepted.

warning:
Yellow/orange aura.
Face missing but below away threshold.
Timer may still run.

away:
Red aura.
Timer paused.
Alarm playing.
Prompt visible.

recovering:
Face visible again.
3-second recovery.
Timer resumes after recovery.

manualPaused:
User paused manually.
Timer stopped.
Aura subdued.

completed:
Timer ended.
Completion UI visible.
Camera off.

exited:
User ended session early.
Save incomplete session.
Camera off.

Audio and Voice:
Нужны 4 voice prompts:

Countdown:
"Enter Hyperfocus Mode. Three. Two. One. Focus."

Away:
"Session paused. Return to Hyperfocus or exit."

Return:
"Focus restored."

Complete:
"Mission complete."

Alarm:
Не резкий beep.
Не короткое пищание.
Нужен продолжительный low hum, brown noise или soft alarm.
Alarm должен играть в loop в away state.
Alarm должен сразу выключаться после return или exit.
Volume должен быть настраиваемым.

Settings for sound:
Voice prompts on/off.
Alarm on/off.
Volume slider.
Voice style: Calm, Strict, Cinematic.

Intensity modes:
Calm:
Мягкие prompts.
Низкая громкость.
Более спокойная аура.
Away prompt реже.

Strict:
Короткие prompts.
Выше контрастность.
Away prompt строже.
Alarm чуть заметнее.

Cinematic:
Более выразительный countdown.
Больше визуальной драматургии.
Более заметное свечение.
Sci-fi стиль голоса через системный speech, если возможно.

Settings Screen:
Создай Settings screen с разделами:

General:
Launch at login.
Show Focus Orb on launch.
Orb size.
Orb opacity.
Reset orb position.

Focus:
Default duration.
Default intensity.
Warning threshold seconds.
Away threshold seconds.
Return recovery seconds.
Allow sessions without camera.

Camera:
Camera permission status.
Use camera for presence check.
Privacy explanation.
Open system camera permissions, если возможно.

Sound:
Voice prompts on/off.
Alarm sound on/off.
Volume.
Voice style.

Visual:
Aura intensity.
Aura thickness.
Reduce motion.
Darken screen on start.
Cinematic countdown on/off.

Data:
Session history.
Clear local data.

Privacy copy:
Покажи этот текст в onboarding/settings:

"Hyperfocus uses your camera only to check whether you are present during a session. Video is processed locally on your Mac. Hyperfocus does not record, save, or upload camera footage."

Правила продукта:
No video recording.
No frame saving.
No upload.
No cloud by default.
No identity recognition.
No emotion detection.
Camera turns off when session ends.
No-camera mode is available.

Local Data Model:
Создай local Session model.

Fields:
id: UUID.
mission: String.
successCondition: String?.
plannedDurationSeconds: Int.
activeFocusSeconds: Int.
pausedSeconds: Int.
breakCount: Int.
longestStreakSeconds: Int.
completionStatus: enum done, partial, notDone, exited.
startedAt: Date.
endedAt: Date?.
intensity: enum calm, strict, cinematic.
cameraEnabled: Bool.

Session history:
Хранить локально.
Показать простой список последних сессий:
Date.
Mission.
Duration.
Status.
Breaks.
Можно сделать минимально в MVP.

Product tone:
Приложение должно быть строгим, но не стыдящим.

Хорошие фразы:
Session paused.
Return to Hyperfocus or exit.
Focus restored.
Mission complete.
Choose one task.
One task. One session.
Back to focus.

Плохие фразы:
You failed.
You got distracted again.
You lost control.
Try harder.
Focus better.

Onboarding:
Сделай короткий onboarding при первом запуске.

Screen 1:
Title: Hyperfocus for Mac.
Text: A cinematic focus mode for one task at a time.

Screen 2:
Title: Enter focus mode.
Text: Click the orb, choose a mission, start the countdown.

Screen 3:
Title: Presence check.
Text: Hyperfocus can use your camera to pause the timer when you leave.

Screen 4:
Title: Private by default.
Text: Camera frames are processed locally. No recording. No upload.

Screen 5:
CTA: Start using Hyperfocus.

Technical architecture:
Раздели код на модули. Не складывай всё в один giant View.

Suggested file structure:
Hyperfocus/
  App/
    HyperfocusApp.swift
    AppState.swift
    SessionState.swift

  Orb/
    FocusOrbWindowController.swift
    FocusOrbView.swift
    OrbPositionStore.swift

  Session/
    SessionModel.swift
    SessionTimer.swift
    SessionStore.swift
    SessionStateMachine.swift

  UI/
    StartSessionView.swift
    CountdownOverlayView.swift
    ActiveHUDView.swift
    AwayModeView.swift
    CompletionView.swift
    SettingsView.swift
    OnboardingView.swift

  Aura/
    AuraWindowController.swift
    AuraFrameView.swift
    AuraState.swift

  Camera/
    CameraPresenceService.swift
    FaceDetectionService.swift
    CameraPermissionService.swift

  Audio/
    VoicePromptService.swift
    AlarmService.swift

  Utilities/
    ScreenManager.swift
    Permissions.swift
    Constants.swift

Code quality:
Use clear module structure.
Keep UI, timer logic, camera logic, aura logic and audio logic separate.
Use ObservableObject or equivalent shared app state.
Keep state changes on the main thread where UI is affected.
Handle camera permission errors.
Handle no-camera devices.
Handle multiple displays.
Stop camera cleanly when session ends.
Stop audio cleanly when session ends.
Avoid memory leaks in capture session.
Add comments for complex AppKit overlay logic.
Make the app runnable locally from Xcode.

Multi-monitor behavior:
Aura Frame should appear on the active screen or all screens, depending on simpler implementation.
For MVP, prefer current main screen.
Focus Orb should stay on visible screen bounds.
If screen layout changes, reposition Focus Orb into visible bounds.

Prototype shortcut:
If real camera implementation slows down the first prototype, create debug controls:
Simulate Present.
Simulate Missing Face.
Simulate Away.
Simulate Return.

These debug controls should allow testing:
green aura.
yellow warning.
red away.
timer pause.
alarm.
return flow.
completion.

But architecture must still include CameraPresenceService prepared for real AVFoundation + Vision implementation.

Acceptance Criteria:
The MVP is successful when:
1. I can launch the app on macOS.
2. A small Focus Orb appears on the screen.
3. I can drag the orb.
4. The orb saves its position.
5. Clicking the orb opens the start popover.
6. I can enter a mission.
7. I can choose a duration.
8. I cannot start without mission.
9. Clicking Enter Hyperfocus starts countdown.
10. The screen darkens during countdown.
11. The app says or displays "Enter Hyperfocus Mode. 3…2…1… Focus."
12. After countdown, green edge glow appears.
13. Timer starts.
14. Camera permission is requested when needed.
15. If my face is visible, timer runs.
16. If my face is missing for 7 seconds, warning state starts.
17. If my face is missing for 15 seconds, away state starts.
18. In away state, timer pauses.
19. In away state, aura turns red.
20. In away state, alarm starts.
21. In away state, prompt says "Session paused. Return to Hyperfocus or exit."
22. When I return for 3 seconds, alarm stops.
23. Aura becomes green again.
24. Timer resumes.
25. When timer ends, completion screen appears.
26. I can mark the result as Done, Partial or Not done.
27. Session stats are saved locally.
28. Camera stops after session ends.
29. Focus Orb returns to idle state.
30. No video is recorded, saved or uploaded.

Implementation plan:
Build in phases.

Phase 1: App shell.
Create macOS SwiftUI app.
Create AppState.
Create SessionState enum.
Create basic settings storage.
Create basic menu bar item or app menu.

Phase 2: Focus Orb.
Create always-on-top transparent NSPanel or borderless window.
Draw glass orb.
Add dragging.
Add click handling.
Add magnetic edge snapping.
Save orb position.

Phase 3: Start Session Popover.
Build glass popover UI.
Add mission input.
Add success condition input.
Add time presets.
Add custom time.
Add intensity selector.
Add validation.
Add Enter Hyperfocus CTA.

Phase 4: Countdown.
Create fullscreen overlay.
Add dark background.
Add animated countdown.
Add voice prompt.
Dismiss overlay into active session.

Phase 5: Aura Frame.
Create 4 edge overlay windows.
Draw green/yellow/red gradient glow.
Add smooth state transitions.
Add fade out on completion.

Phase 6: Timer Engine.
Create session timer.
Create accurate active time counting.
Create pause/resume.
Track paused time.
Track break count.
Track longest streak.

Phase 7: Camera Presence.
Request camera permission.
Start AVFoundation capture.
Run Vision face detection.
Emit facePresent and faceMissing events.
Handle no-camera mode.

Phase 8: Away Mode.
Pause timer.
Switch aura to red.
Play alarm.
Show away card.
Handle return recovery.
Handle exit.

Phase 9: Completion.
Show completion screen.
Save session locally.
Reset app state.
Stop camera.
Stop audio.

Phase 10: Polish.
Add settings.
Add onboarding.
Add reduce motion.
Add multi-monitor handling.
Add debug simulation controls.
Clean code and explain how to run.

Final output expected:
1. Full macOS Swift/SwiftUI project.
2. Clear instructions to run in Xcode.
3. Explanation of implemented features.
4. Known limitations.
5. Next recommended improvements.
6. No external server dependency.
7. No camera recording.
8. Local-only session history.
