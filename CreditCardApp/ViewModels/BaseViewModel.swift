import Foundation
import Combine

// MARK: - Base ViewModel Protocol
protocol BaseViewModel: ObservableObject {
    var isLoading: Bool { get set }
    var errorMessage: String? { get set }
    var hasError: Bool { get }
    func handleError(_ error: Error)
    func clearError()
}

// MARK: - Base ViewModel Implementation
class BaseViewModelImpl: BaseViewModel {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    var hasError: Bool {
        return errorMessage != nil
    }
    
    let analyticsService: AnalyticsService?
    private var cancellables = Set<AnyCancellable>()
    
    init(analyticsService: AnalyticsService? = nil) {
        self.analyticsService = analyticsService
        setupErrorHandling()
    }
    
    func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }
    
    func clearError() {
        DispatchQueue.main.async {
            self.errorMessage = nil
        }
    }
    
    // MARK: - Loading State Management
    
    func setLoading(_ loading: Bool) {
        DispatchQueue.main.async {
            self.isLoading = loading
        }
    }
    
    func performAsyncTask<T>(_ task: @escaping () async throws -> T) async -> T? {
        setLoading(true)
        clearError()
        
        do {
            let result = try await task()
            setLoading(false)
            return result
        } catch {
            handleError(error)
            return nil
        }
    }
    
    // MARK: - Error Handling
    
    private func setupErrorHandling() {
        $errorMessage
            .sink { [weak self] message in
                if message != nil {
                    // Auto-clear error after 5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self?.clearError()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation
    
    func validateRequired(_ value: String?, fieldName: String) -> Bool {
        guard let value = value, value.isNotEmpty else {
            handleError(ValidationError.required(fieldName))
            return false
        }
        return true
    }
    
    func validateAmount(_ value: String?, fieldName: String) -> Bool {
        guard let value = value, value.isNotEmpty else {
            handleError(ValidationError.required(fieldName))
            return false
        }
        
        guard value.isValidAmount else {
            handleError(ValidationError.invalidAmount(fieldName))
            return false
        }
        
        return true
    }
    
    func validateEmail(_ value: String?, fieldName: String) -> Bool {
        guard let value = value, value.isNotEmpty else {
            handleError(ValidationError.required(fieldName))
            return false
        }
        
        guard value.isValidEmail else {
            handleError(ValidationError.invalidEmail(fieldName))
            return false
        }
        
        return true
    }
    
    // MARK: - Analytics
    
    func trackEvent(_ eventName: String, properties: [String: Any] = [:]) {
        let event = AnalyticsEvent(name: eventName, properties: properties)
        analyticsService?.trackEvent(event)
    }
    
    func trackScreenView(_ screenName: String) {
        analyticsService?.trackScreenView(screenName)
    }
    
    // MARK: - Memory Management
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Validation Errors

enum ValidationError: LocalizedError {
    case required(String)
    case invalidAmount(String)
    case invalidEmail(String)
    case invalidFormat(String)
    case tooShort(String, Int)
    case tooLong(String, Int)
    case custom(String)
    
    var errorDescription: String? {
        switch self {
        case .required(let fieldName):
            return "\(fieldName) is required"
        case .invalidAmount(let fieldName):
            return "\(fieldName) must be a valid amount"
        case .invalidEmail(let fieldName):
            return "\(fieldName) must be a valid email address"
        case .invalidFormat(let fieldName):
            return "\(fieldName) has an invalid format"
        case .tooShort(let fieldName, let minLength):
            return "\(fieldName) must be at least \(minLength) characters"
        case .tooLong(let fieldName, let maxLength):
            return "\(fieldName) must be no more than \(maxLength) characters"
        case .custom(let message):
            return message
        }
    }
}

// MARK: - Network Error

enum NetworkError: LocalizedError {
    case noConnection
    case timeout
    case serverError(Int)
    case invalidResponse
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "No internet connection available"
        case .timeout:
            return "Request timed out"
        case .serverError(let code):
            return "Server error (\(code))"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to process response"
        }
    }
}

// MARK: - Data Error

enum DataError: LocalizedError {
    case saveFailed
    case loadFailed
    case deleteFailed
    case notFound
    case duplicateEntry
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return "Failed to save data"
        case .loadFailed:
            return "Failed to load data"
        case .deleteFailed:
            return "Failed to delete data"
        case .notFound:
            return "Data not found"
        case .duplicateEntry:
            return "Entry already exists"
        }
    }
}


// MARK: - ViewModel Extensions

extension BaseViewModelImpl {
    func showLoading() {
        setLoading(true)
    }
    
    func hideLoading() {
        setLoading(false)
    }
    
    func showError(_ message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
        }
    }
    
    func showSuccess(_ message: String) {
        // For now, just log success messages
        // In a real app, you might want to show a success toast or notification
        print("Success: \(message)")
    }
} 
