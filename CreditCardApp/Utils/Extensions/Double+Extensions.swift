import Foundation

extension Double {
    
    // MARK: - Currency Formatting
    
    var asCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: self)) ?? "$\(String(format: "%.2f", self))"
    }
    
    var asCurrencyWithoutSymbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? String(format: "%.2f", self)
    }
    
    var asCompactCurrency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        
        if self >= 1_000_000 {
            return formatter.string(from: NSNumber(value: self / 1_000_000))?.replacingOccurrences(of: formatter.currencySymbol, with: formatter.currencySymbol + "M") ?? "$\(String(format: "%.1fM", self / 1_000_000))"
        } else if self >= 1_000 {
            return formatter.string(from: NSNumber(value: self / 1_000))?.replacingOccurrences(of: formatter.currencySymbol, with: formatter.currencySymbol + "K") ?? "$\(String(format: "%.1fK", self / 1_000))"
        } else {
            return formatter.string(from: NSNumber(value: self)) ?? "$\(String(format: "%.2f", self))"
        }
    }
    
    // MARK: - Percentage Formatting
    
    var asPercentage: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: self)) ?? String(format: "%.1f%%", self * 100)
    }
    
    var asPercentageWithoutSymbol: String {
        return String(format: "%.1f", self * 100)
    }
    
    // MARK: - Number Formatting
    
    var asNumber: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? String(format: "%.2f", self)
    }
    
    var asInteger: String {
        return String(format: "%.0f", self)
    }
    
    var asCompactNumber: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        if self >= 1_000_000 {
            return formatter.string(from: NSNumber(value: self / 1_000_000))?.appending("M") ?? String(format: "%.1fM", self / 1_000_000)
        } else if self >= 1_000 {
            return formatter.string(from: NSNumber(value: self / 1_000))?.appending("K") ?? String(format: "%.1fK", self / 1_000)
        } else {
            return formatter.string(from: NSNumber(value: self)) ?? String(format: "%.0f", self)
        }
    }
    
    // MARK: - Rounding and Clamping
    
    func rounded(to places: Int) -> Double {
        let multiplier = pow(10.0, Double(places))
        return (self * multiplier).rounded() / multiplier
    }
    
    func clamped(to range: ClosedRange<Double>) -> Double {
        return min(max(self, range.lowerBound), range.upperBound)
    }
    
    func clamped(to range: Range<Double>) -> Double {
        return min(max(self, range.lowerBound), range.upperBound)
    }
    
    // MARK: - Comparison Helpers
    
    var isZero: Bool {
        return abs(self) < Double.ulpOfOne
    }
    
    var isPositive: Bool {
        return self > 0
    }
    
    var isNegative: Bool {
        return self < 0
    }
    
    var isInteger: Bool {
        return self.truncatingRemainder(dividingBy: 1) == 0
    }
    
    // MARK: - Mathematical Operations
    
    var absolute: Double {
        return abs(self)
    }
    
    var squared: Double {
        return self * self
    }
    
    var cubed: Double {
        return self * self * self
    }
    
    var squareRoot: Double {
        return sqrt(self)
    }
    
    // MARK: - Time Conversions
    
    var asMinutes: Double {
        return self * 60
    }
    
    var asHours: Double {
        return self / 60
    }
    
    var asDays: Double {
        return self / (24 * 60)
    }
    
    // MARK: - Distance Conversions
    
    var asKilometers: Double {
        return self / 1000
    }
    
    var asMiles: Double {
        return self * 0.621371
    }
    
    // MARK: - Weight Conversions
    
    var asKilograms: Double {
        return self / 1000
    }
    
    var asPounds: Double {
        return self * 2.20462
    }
    
    // MARK: - Temperature Conversions
    
    var asCelsius: Double {
        return (self - 32) * 5/9
    }
    
    var asFahrenheit: Double {
        return self * 9/5 + 32
    }
    
    // MARK: - Validation
    
    var isValidAmount: Bool {
        return self >= 0 && self.isFinite && !self.isNaN
    }
    
    var isValidPercentage: Bool {
        return self >= 0 && self <= 1 && self.isFinite && !self.isNaN
    }
    
    // MARK: - String Conversion
    
    var asString: String {
        return String(self)
    }
    
    var asStringWithDecimals: String {
        return String(format: "%.2f", self)
    }
    
    // MARK: - Array Operations
    
    func times<T>(_ block: () -> T) -> [T] {
        return (0..<Int(self)).map { _ in block() }
    }
    
    func times<T>(_ block: (Int) -> T) -> [T] {
        return (0..<Int(self)).map { block($0) }
    }
    
    // MARK: - Progress Calculations
    
    func progress(to target: Double) -> Double {
        guard target != 0 else { return 0 }
        return (self / target).clamped(to: 0...1)
    }
    
    func percentage(of total: Double) -> Double {
        guard total != 0 else { return 0 }
        return (self / total) * 100
    }
    
    // MARK: - Random Generation
    
    static func random(in range: ClosedRange<Double>) -> Double {
        return Double.random(in: range)
    }
    
    static func random(in range: Range<Double>) -> Double {
        return Double.random(in: range)
    }
    
    // MARK: - Statistical Operations
    
    var roundedToNearest: Double {
        return self.rounded()
    }
    
    var roundedUp: Double {
        return ceil(self)
    }
    
    var roundedDown: Double {
        return floor(self)
    }
    
    // MARK: - Formatting for Display
    
    var asDisplayString: String {
        if self.isInteger {
            return self.asInteger
        } else {
            return self.asStringWithDecimals
        }
    }
    
    var asDisplayCurrency: String {
        if self >= 1000 {
            return self.asCompactCurrency
        } else {
            return self.asCurrency
        }
    }
    
    // MARK: - Credit Card Specific
    
    var asCreditCardAmount: String {
        // Format for credit card amounts (no cents if whole number)
        if self.isInteger {
            return self.asCurrency.replacingOccurrences(of: ".00", with: "")
        } else {
            return self.asCurrency
        }
    }
    
    var asRewardPoints: String {
        // Format for reward points (no decimals)
        return self.asInteger
    }
    
    var asMultiplier: String {
        // Format for reward multipliers (e.g., "4x", "1.5x")
        if self.isInteger {
            return "\(self.asInteger)x"
        } else {
            return "\(self.asStringWithDecimals)x"
        }
    }
} 