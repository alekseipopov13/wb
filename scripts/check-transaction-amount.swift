import Foundation

@main
struct CheckTransactionAmount {
    static func main() {
        let samples: [(String, String, String?, Decimal)] = [
            ("", "0", nil, 0),
            (",", "0", "", 0),
            ("0,", "0", "", 0),
            ("0,5", "0", "5", Decimal(string: "0.5")!),
            ("1 234,", "1\u{00A0}234", "", 1234),
            ("1 234,50", "1\u{00A0}234", "50", Decimal(string: "1234.50")!),
            ("001.09", "1", "09", Decimal(string: "1.09")!),
            ("500,999", "500", "99", Decimal(string: "500.99")!),
            ("9999999999", "999\u{00A0}999\u{00A0}999", nil, 999999999),
        ]
        for (raw, whole, fraction, value) in samples {
            let input = AmountInput(raw: raw)
            precondition(input.displayInteger == whole, "Whole: \(raw)")
            precondition(input.fractionDigits == fraction, "Fraction: \(raw)")
            precondition(input.decimal == value, "Value: \(raw)")
            // Reformatting on every keystroke must keep incomplete input intact.
            let roundTrip = AmountInput(raw: input.displayInteger + (input.displayFraction ?? ""))
            precondition(input == roundTrip, "Typing round-trip: \(raw)")
        }
        var amount = AmountInput(raw: "1234,50")
        amount.backspace()
        precondition(amount.displayFraction == ",5" && amount.decimal == Decimal(string: "1234.5"))
        amount.backspace()
        precondition(amount.displayFraction == ",")
        amount.append(digit: "0")
        amount.append(digit: "7")
        precondition(amount.decimal == Decimal(string: "1234.07"))
        print("Transaction amount: decimal typing, trailing separator, formatting, limits and backspace passed")
    }
}
