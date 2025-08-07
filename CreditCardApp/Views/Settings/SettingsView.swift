import SwiftUI
import Foundation

struct SettingsView: View {
    @StateObject private var viewModel = ViewModelFactory.makeSettingsViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                // Point System Preferences
                Section("Preferred Point System") {
                    ForEach(PointType.allCases, id: \.self) { pointSystem in
                        HStack {
                            Circle()
                                .fill(Color(pointSystem.color))
                                .frame(width: 12, height: 12)
                            
                            Text(pointSystem.displayName)
                                .font(.body)
                            
                            Spacer()
                            
                            if viewModel.userPreferences.preferredPointSystem == pointSystem {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.updatePreferredPointSystem(pointSystem)
                        }
                    }
                }
                
                // Quarterly Bonus Tracking
                Section("Quarterly Bonus Tracking") {
                    Toggle("Enable Quarterly Tracking", isOn: $viewModel.userPreferences.autoUpdateSpending)
                        .onChange(of: viewModel.userPreferences.autoUpdateSpending) { _ in
                            viewModel.toggleAutoUpdateSpending()
                        }
                }
                
                // Alert Settings
                Section("Alert Settings") {
                    Toggle("Enable Notifications", isOn: $viewModel.userPreferences.notificationsEnabled)
                        .onChange(of: viewModel.userPreferences.notificationsEnabled) { _ in
                            viewModel.toggleNotifications()
                        }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Alert Threshold: \(Int(viewModel.userPreferences.alertThreshold * 100))%")
                            .font(.body)
                        
                        Slider(value: $viewModel.userPreferences.alertThreshold, in: 0.5...1.0, step: 0.05)
                            .onChange(of: viewModel.userPreferences.alertThreshold) { newValue in
                                viewModel.updateAlertThreshold(newValue)
                            }
                    }
                }
                
                // Language Settings
                Section("Language") {
                    ForEach(Language.allCases, id: \.self) { language in
                        HStack {
                            Text(language.displayName)
                                .font(.body)
                            
                            Spacer()
                            
                            if viewModel.userPreferences.language == language {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.updateLanguage(language)
                        }
                    }
                }
                
                // Data Management
                Section("Data Management") {
                    NavigationLink("Export Data") {
                        EmptyView()
                    }
                    .onTapGesture {
                        viewModel.showingExportSheet = true
                    }
                    
                    Button("Reset All Data", role: .destructive) {
                        viewModel.showingResetAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                // App Information
                Section("App Information") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(viewModel.getAppVersion())
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .alert("Reset All Data", isPresented: $viewModel.showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                viewModel.resetAllData()
            }
        } message: {
            Text("This will delete all your cards, chat history, and preferences. This action cannot be undone.")
        }
        .sheet(isPresented: $viewModel.showingExportSheet) {
            ExportDataView(data: viewModel.exportData)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

struct ExportDataView: View {
    let data: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(data)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink("Share", item: data)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
