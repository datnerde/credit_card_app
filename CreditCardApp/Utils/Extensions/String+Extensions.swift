import Foundation

extension String {
    
    // MARK: - Validation
    
    var isNotEmpty: Bool {
        return !trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    var isValidAmount: Bool {
        let amountRegex = "^\\$?\\d+(\\.\\d{2})?$"
        let amountPredicate = NSPredicate(format: "SELF MATCHES %@", amountRegex)
        return amountPredicate.evaluate(with: self)
    }
    
    // MARK: - Formatting
    
    var capitalizedWords: String {
        return self.components(separatedBy: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
    
    var titleCase: String {
        return self.components(separatedBy: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
    }
    
    func truncate(to length: Int, trailing: String = "...") -> String {
        if self.count <= length {
            return self
        }
        return String(self.prefix(length)) + trailing
    }
    
    // MARK: - Currency Formatting
    
    var asCurrency: String {
        guard let doubleValue = Double(self) else { return self }
        return doubleValue.asCurrency
    }
    
    var asNumber: Double? {
        return Double(self.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: ""))
    }
    
    // MARK: - Search and Matching
    
    func containsAny(of keywords: [String], caseSensitive: Bool = false) -> Bool {
        let searchString = caseSensitive ? self : self.lowercased()
        let searchKeywords = caseSensitive ? keywords : keywords.map { $0.lowercased() }
        
        return searchKeywords.contains { searchString.contains($0) }
    }
    
    func matches(pattern: String) -> Bool {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: self.utf16.count)
        return regex?.firstMatch(in: self, options: [], range: range) != nil
    }
    
    // MARK: - Cleaning
    
    var cleaned: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var removeSpecialCharacters: String {
        return self.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }
    
    var removeExtraWhitespace: String {
        return self.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
    
    // MARK: - Localization
    
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        return String(format: self.localized, arguments: arguments)
    }
    
    // MARK: - Encoding
    
    var urlEncoded: String {
        return self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
    
    var urlDecoded: String {
        return self.removingPercentEncoding ?? self
    }
    
    // MARK: - Case Conversion
    
    var camelCase: String {
        let words = self.components(separatedBy: CharacterSet.alphanumerics.inverted)
        guard let firstWord = words.first else { return self }
        
        let remainingWords = words.dropFirst().map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
        return firstWord.lowercased() + remainingWords.joined()
    }
    
    var snakeCase: String {
        return self.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "_")
            .lowercased()
    }
    
    var kebabCase: String {
        return self.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
            .lowercased()
    }
    
    // MARK: - Substring Operations
    
    func substring(from start: Int, to end: Int) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: start)
        let endIndex = self.index(self.startIndex, offsetBy: min(end, self.count))
        return String(self[startIndex..<endIndex])
    }
    
    func substring(from start: Int) -> String {
        let startIndex = self.index(self.startIndex, offsetBy: start)
        return String(self[startIndex...])
    }
    
    func substring(to end: Int) -> String {
        let endIndex = self.index(self.startIndex, offsetBy: min(end, self.count))
        return String(self[..<endIndex])
    }
    
    // MARK: - Character Count
    
    var wordCount: Int {
        return self.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .count
    }
    
    var characterCount: Int {
        return self.count
    }
    
    var characterCountWithoutSpaces: Int {
        return self.replacingOccurrences(of: " ", with: "").count
    }
    
    // MARK: - Validation Helpers
    
    var isNumeric: Bool {
        return Double(self) != nil
    }
    
    var isAlphabetic: Bool {
        return self.range(of: "^[a-zA-Z]+$", options: .regularExpression) != nil
    }
    
    var isAlphanumeric: Bool {
        return self.range(of: "^[a-zA-Z0-9]+$", options: .regularExpression) != nil
    }
    
    // MARK: - Phone Number Formatting
    
    var asPhoneNumber: String {
        let cleaned = self.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        switch cleaned.count {
        case 10:
            return "(\(cleaned.prefix(3))) \(cleaned.dropFirst(3).prefix(3))-\(cleaned.dropFirst(6))"
        case 11 where cleaned.hasPrefix("1"):
            let number = String(cleaned.dropFirst())
            return "(\(number.prefix(3))) \(number.dropFirst(3).prefix(3))-\(number.dropFirst(6))"
        default:
            return self
        }
    }
    
    // MARK: - Credit Card Formatting
    
    var asCreditCardNumber: String {
        let cleaned = self.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        var formatted = ""
        for (index, character) in cleaned.enumerated() {
            if index > 0 && index % 4 == 0 {
                formatted += " "
            }
            formatted += String(character)
        }
        
        return formatted
    }
    
    // MARK: - Date Parsing
    
    var asDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: self)
    }
    
    var asDateTime: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: self)
    }
} 