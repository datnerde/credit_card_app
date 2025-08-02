#!/bin/bash

echo "🔍 Credit Card App Frontend Checker"
echo "=================================="
echo ""

# Check if Xcode is installed
if command -v xcodebuild &> /dev/null; then
    echo "✅ Xcode command line tools found"
else
    echo "❌ Xcode command line tools not found"
    echo "   Please install Xcode from the Mac App Store"
    exit 1
fi

# Check if project file exists
if [ -f "CreditCardApp.xcodeproj/project.pbxproj" ]; then
    echo "✅ Xcode project file found"
else
    echo "❌ Xcode project file not found"
    exit 1
fi

# Check if source files exist
echo ""
echo "📁 Checking source files..."
swift_files=$(find CreditCardApp -name "*.swift" -type f | wc -l)
echo "   Found $swift_files Swift files"

# List main components
echo ""
echo "🏗️  Project Structure:"
echo "   📱 Main App: CreditCardAppApp.swift"
echo "   🎨 Views: ContentView.swift, ChatView.swift, CardListView.swift, SettingsView.swift"
echo "   🧠 ViewModels: ChatViewModel.swift, CardListViewModel.swift, etc."
echo "   🔧 Services: DataManager.swift, RecommendationEngine.swift, etc."
echo "   📊 Models: CreditCard.swift, SpendingCategory.swift"

echo ""
echo "🚀 How to check your frontend:"
echo "   1. Open CreditCardApp.xcodeproj in Xcode"
echo "   2. Select a simulator (iPhone 15, etc.)"
echo "   3. Press ⌘+R to build and run"
echo ""
echo "📱 What you'll see:"
echo "   • Chat Tab: AI assistant for credit card recommendations"
echo "   • My Cards Tab: Manage your credit cards"
echo "   • Settings Tab: App preferences and data management"
echo ""
echo "✨ SwiftUI Previews:"
echo "   • Open any .swift file in Xcode"
echo "   • Look for the 'Canvas' button (right panel)"
echo "   • Click 'Resume' to see live previews"

echo ""
echo "🔧 Alternative: Command Line"
echo "   xcodebuild -scheme CreditCardApp -destination 'platform=iOS Simulator,name=iPhone 15' build" 