import Foundation

public struct Formatters {
    public static let ton = Ton()
    public static let date = AppDateFormatter()

    public struct AppDateFormatter {

        public func full(from date: Date) -> String {
            self.dateFormatter.string(from: date)
        }

        private let dateFormatter: DateFormatter = {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .short
            dateFormatter.timeStyle = .medium
            return dateFormatter
        }()
    }

    public struct Ton {
        public func formatSignificant(_ value: Decimal) -> String {
            self.formatterSignificant.string(for: value) ?? "Unknown"
        }

        public func formatFull(_ value: Decimal) -> String {
            self.formatterFull.string(for: value) ?? "Unknown"
        }

        public func formatFull(_ value: String) -> String {
            guard let number = self.formatterReader.number(from: value) else { return "Unknown" }
            return (self.formatterFull.string(from: number) ?? "Unknown")
        }

        private let formatterReader: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.multiplier = NSNumber(value: 1_000_000_000)
            return formatter
        }()

        private let formatterSignificant: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.usesSignificantDigits = true
            formatter.usesGroupingSeparator = true
            formatter.maximumSignificantDigits = 12
            formatter.numberStyle = .currency
            formatter.locale = Locale.current
            formatter.currencyCode = "TON"
            return formatter
        }()

        private let formatterFull: NumberFormatter = {
            let formatter = NumberFormatter()
            formatter.usesGroupingSeparator = true
            formatter.maximumFractionDigits = 10
            formatter.numberStyle = .currency
            formatter.locale = Locale.current
            formatter.currencyCode = "TON"
            return formatter
        }()

    }
}
