# Источники и выбор формата

[← Обзор](README.md) · [Шаблон](../templates/motion-spec.md)

Изучены первичные публикации команд и авторов. Структура адаптирована под наш прототип; чужие параметры движения не выдаются за наши.

| Источник | Что использовано в документации |
|---|---|
| [Wise Design — Translating Motion into Code](https://medium.com/transferwise-design/translating-motion-into-code-182da0220e0d), Stephanie Martin, 24.04.2025 | Разделение по взаимодействиям, короткое описание запуска, движущиеся элементы, таймлайн и раскадровка. Координаты начала и конца задаются раскладкой |
| [Atlassian — Motion](https://atlassian.design/foundations/motion) и [Applying motion](https://atlassian.design/foundations/motion/applying-motion) | Назначение, длительность, характер ускорения и изменяемое свойство; отдельно уменьшение движения |
| [Carbon — Choreography](https://www.carbondesignsystem.com/building-blocks/foundations/motion/choreography) | Совместное описание нескольких объектов, последовательность и задержка соседей |
| [Adobe Spectrum — Motion](https://spectrum.adobe.com/page/motion/) | Разделение времени и кривой; связь движения с задачей пользователя |

В доступных первичных источниках Revolut не найден сопоставимый открытый шаблон motion-спеки. Сторонние наборы, стилизованные под Revolut, не используются как официальная документация Revolut. У Wise найден именно рассказ о передаче motion разработчикам, а не только брендовый сайт.

У Carbon собственные правила могут отличаться от нашего прототипа: например, их ограничения на диагональные пути и отскок сюда не переносились. Мы берём способы объяснения, а не меняем согласованное движение под чужой бренд.

## Авторство используемых эффектов и ресурсов

- **Сердце:** адаптация `Pop` из [Emerge Tools / Pow](https://github.com/EmergeTools/Pow), зафиксированная исходная версия `1b4b1dda28c50b95f0872927ee2226fe8b58950e`. Изменение оформления — один цвет text/icon Primary. [MIT-лицензия](../../WBSandbox/Resources/ThirdParty/Pow-LICENSE.txt) включена в проект.
- **Покачивание:** локальная реализация с размерозависимой амплитудой; подход сопоставлялся с [JiggleKit](https://github.com/visfitness/JiggleKit). Пакет не подключён, его готовый бесконечный модификатор не используется.
- **Google Sans:** встроенные файлы версии 13.002 с метаданными Google Sans Project Authors. [OFL-лицензия](../../WBSandbox/Resources/ThirdParty/GoogleSans-OFL.txt), [первичный репозиторий](https://github.com/googlefonts/googlesans).
- Остальная хореография — текущая реализация WBSandbox по описанным в задаче взаимодействиям. Макеты задают конечный вид, движение зафиксировано кодом и записями этого PR.

## Макеты для сверки конечных состояний

Все узлы относятся к [файлу ПиП](https://www.figma.com/design/PEi0USoqsPEnuuURAIMveL/?node-id=60919-530144).

| Что сверять | Узел |
|---|---|
| Разводящая ПиП | [60919:530144](https://www.figma.com/design/PEi0USoqsPEnuuURAIMveL/?node-id=60919-530144) |
| Полный раздел | [60982:634117](https://www.figma.com/design/PEi0USoqsPEnuuURAIMveL/?node-id=60982-634117) |
| Стопка | [60982:633273](https://www.figma.com/design/PEi0USoqsPEnuuURAIMveL/?node-id=60982-633273) |
| Редактирование / тост | [59127:602401](https://www.figma.com/design/PEi0USoqsPEnuuURAIMveL/?node-id=59127-602401), [59127:602391](https://www.figma.com/design/PEi0USoqsPEnuuURAIMveL/?node-id=59127-602391) |
| Форма / действия изменения | [60820:462281](https://www.figma.com/design/PEi0USoqsPEnuuURAIMveL/?node-id=60820-462281), [60571:215378](https://www.figma.com/design/PEi0USoqsPEnuuURAIMveL/?node-id=60571-215378) |
| Пустой раздел | [60530:420059](https://www.figma.com/design/PEi0USoqsPEnuuURAIMveL/?node-id=60530-420059) |
| Напоминание | [58033:851870](https://www.figma.com/design/PEi0USoqsPEnuuURAIMveL/?node-id=58033-851870) |
| Детали операции | [60571:136539](https://www.figma.com/design/PEi0USoqsPEnuuURAIMveL/?node-id=60571-136539) |
| Папка | [61122:47466](https://www.figma.com/design/PEi0USoqsPEnuuURAIMveL/?node-id=61122-47466) |

Узлы перечислены как ссылки из исходного задания; заново их содержимое в этом PR не выгружалось. При расхождении приоритет для текущей анимации — проверенная запись и актуальный код PR; изменение конечного дизайна согласуется отдельно.
