import UIKit
import SwiftUI

enum DeviceCapability {
    case fullAppleIntelligence  // iOS 18+ with Apple Silicon
    case fallbackMode          // iOS 16-17 or older devices
}

class DeviceCompatibilityManager: ObservableObject {
    @Published var deviceCapability: DeviceCapability = .fallbackMode
    @Published var isAppleIntelligenceAvailable: Bool = false
    
    static let shared = DeviceCompatibilityManager()
    
    private init() {
        checkDeviceCapabilities()
    }
    
    private func checkDeviceCapabilities() {
        let systemVersion = UIDevice.current.systemVersion
        let isIOS18OrLater = systemVersion.compare("18.0", options: .numeric) != .orderedAscending
        let hasAppleSilicon = hasAppleSiliconChip()
        
        if isIOS18OrLater && hasAppleSilicon {
            deviceCapability = .fullAppleIntelligence
            isAppleIntelligenceAvailable = true
        } else {
            deviceCapability = .fallbackMode
            isAppleIntelligenceAvailable = false
        }
    }
    
    private func hasAppleSiliconChip() -> Bool {
        // Check for Apple Silicon devices (M1 iPad, iPhone 15 Pro+)
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        // Apple Silicon devices
        let appleSiliconDevices = [
            "iPad13,1", "iPad13,2",    // iPad Pro 11" M1
            "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7",    // iPad Pro 12.9" M1
            "iPad14,1", "iPad14,2",    // iPad Pro 11" M2
            "iPad14,3", "iPad14,4",    // iPad Pro 12.9" M2
            "iPhone15,2", "iPhone15,3", "iPhone16,1", "iPhone16,2"  // iPhone 15 Pro/Pro Max, iPhone 16 Pro/Pro Max
        ]
        
        return appleSiliconDevices.contains(identifier) || identifier.hasPrefix("iPad") && identifier.contains("M")
    }
    
    var statusDescription: String {
        switch deviceCapability {
        case .fullAppleIntelligence:
            return "Apple Intelligence Active"
        case .fallbackMode:
            return "Standard Mode"
        }
    }
    
    var statusColor: Color {
        switch deviceCapability {
        case .fullAppleIntelligence:
            return .green
        case .fallbackMode:
            return .orange
        }
    }
}