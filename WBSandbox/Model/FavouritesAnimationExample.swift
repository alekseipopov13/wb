import Foundation

enum FavouritesAnimationExample: String, CaseIterable {
    case reminder
    case deckPull = "deck-pull"
    case headerMoveIn = "header-move-in"
    case headerFlight = "header-flight"
    case gridInsertion = "grid-insertion"
    case promotion
    case wiggle
    case removal
    case heart

    var title: String {
        switch self {
        case .reminder: "01 · Подсказка «Скоро оплата»"
        case .deckPull: "02 · Протяжка и раскрытие колоды"
        case .headerMoveIn: "03 · Заголовок: Move In"
        case .headerFlight: "04 · Заголовок: перелёт карточек"
        case .gridInsertion: "05 · Добавление в сетку"
        case .promotion: "06 · Сохранение рекомендации"
        case .wiggle: "07 · Покачивание при редактировании"
        case .removal: "08 · Удаление и отмена"
        case .heart: "09 · Сердце · Pow Pop"
        }
    }

    var subtitle: String {
        switch self {
        case .reminder: "Рост, деформация и поворот вокруг хвостика"
        case .deckPull: "Конец ленты · раздвигание · переход в сетку"
        case .headerMoveIn: "Тап из начала ленты, сохранённые карточки за краем"
        case .headerFlight: "Тап при видимых сохранённых карточках"
        case .gridInsertion: "Вставка в начало · каскад · перенос по дуге"
        case .promotion: "Пружинный отклик уже видимой карточки"
        case .wiggle: "Лёгкое несинхронное движение · полная остановка"
        case .removal: "Сдвиг сетки · тост с таймером · восстановление"
        case .heart: "Кольцо · частицы · заполнение сердца"
        }
    }
}
