import Foundation

/// Only isolated examples opt in. Complete scenarios keep their ordinary UI.
enum FavouritesTransitionDemo {
    case pull, headerFromStart, headerFromEnd

    var startsAtEnd: Bool { self != .headerFromStart }
    var title: String {
        switch self {
        case .pull: "Раскрытие колоды"
        case .headerFromStart: "Переход из начала"
        case .headerFromEnd: "Переход от карточек"
        }
    }
    var instruction: String {
        switch self {
        case .pull:
            "Протяните ленту влево за её конец и отпустите. Карточки разойдутся и перелетят в избранное. Чтобы повторить, вернитесь назад."
        case .headerFromStart:
            "Нажмите заголовок «Избранное». Сохранённые карточки сейчас за краем ленты, поэтому раздел открывается через Move In. Назад — повторить."
        case .headerFromEnd:
            "Нажмите заголовок «Избранное». Видимые карточки перелетят из ленты в сетку. Назад — повторить."
        }
    }
}
