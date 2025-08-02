import SwiftUI

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
                            
                            if viewModel.preferences.preferredPointSystem == pointSystem {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.updatePreferredPointSystem(pointSystem)
                        }
                    }
                }
                
                // Alert Settings
                Section("Alert Thresholds") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Limit Warning:")
                                .font(.body)
                            
                            Spacer()
                            
                            Text("\(Int(viewModel.preferences.alertThreshold * 100))%")
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        Slider(
                            value: Binding(
                                get: { viewModel.preferences.alertThreshold },
                                set: { viewModel.updateAlertThreshold($0) }
                            ),
                            in: 0.5...1.0,
                            step: 0.05
                        )
                        .accentColor(.blue)
                    }
                }
                
                // Language Settings
                Section("Language") {
                    ForEach(Language.allCases, id: \.self) { language in
                        HStack {
                            Text(language.displayName)
                                .font(.body)
                            
                            Spacer()
                            
                            if viewModel.preferences.language == language {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.updateLanguage(language)
                        }
                    }
                }
                
                // Notification Settings
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: Binding(
                        get: { viewModel.preferences.notificationsEnabled },
                        set: { _ in viewModel.toggleNotifications() }
                    ))
                    
                    Toggle("Auto Update Spending", isOn: Binding(
                        get: { viewModel.preferences.autoUpdateSpending },
                        set: { _ in viewModel.toggleAutoUpdateSpending() }
                    ))
                }
                
                // Data Management
                Section("Data Management") {
                    Button("Export Data") {
                        viewModel.showingExportSheet = true
                    }
                    .foregroundColor(.blue)
                    
                    Button("Reset All Data") {
                        viewModel.showingResetAlert = true
                    }
                    .foregroundColor(.red)
                }
                
                // App Information
                Section("App Information") {
                    HStack {
                        Text("Version")
                            .font(.body)
                        
                        Spacer()
                        
                        Text("1.0.0")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                            .font(.body)
                        
                        Spacer()
                        
                        Text("1")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
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
            ExportDataView(data: viewModel.exportData())
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
            }
            .navigationTitle("Exported Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    ShareLink(item: data) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
} 