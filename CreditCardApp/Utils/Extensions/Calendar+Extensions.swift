import Foundation

extension Calendar {
    static var currentQuarter: Int {
        let month = Calendar.current.component(.month, from: Date())
        return Int((month - 1) / 3) + 1
    }
    
    static var currentYear: Int {
        return Calendar.current.component(.year, from: Date())
    }
    
    func quarterForDate(_ date: Date) -> Int {
        let month = component(.month, from: date)
        return Int((month - 1) / 3) + 1
    }
    
    func startOfQuarter(for date: Date) -> Date {
        let quarter = quarterForDate(date)
        let year = component(.year, from: date)
        let startMonth = (quarter - 1) * 3 + 1
        
        var components = DateComponents()
        components.year = year
        components.month = startMonth
        components.day = 1
        
        return Calendar.current.date(from: components) ?? date
    }
    
    func endOfQuarter(for date: Date) -> Date {
        let quarter = quarterForDate(date)
        let year = component(.year, from: date)
        let endMonth = quarter * 3
        
        var components = DateComponents()
        components.year = year
        components.month = endMonth + 1
        components.day = 0 // Last day of previous month
        
        return Calendar.current.date(from: components) ?? date
    }
}