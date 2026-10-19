import Foundation

/// Постоянные реквизиты шаблона. Новое показание сюда не сохраняется:
/// оно относится к конкретному месяцу и каждый раз запрашивается заново.
struct SavedUtilityDetails {
    let account: String
    let previousReading: Int

    func readingError(_ value: String) -> String? {
        guard !value.isEmpty else { return "Укажите текущие показания" }
        guard value.count <= 6, value.allSatisfy(\.isNumber), let reading = Int(value) else {
            return "Введите показания цифрами" }
        guard reading >= previousReading else { return "Не меньше предыдущих: \(previousReading)" }
        return nil
    }

    static func period(for date: Date = .now) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: date)
    }
}
