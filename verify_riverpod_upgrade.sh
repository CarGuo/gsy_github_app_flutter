#!/bin/bash

# Riverpod 3.0 升级验证脚本 / Riverpod 3.0 Upgrade Verification Script

set -e

echo "🔍 Verifying Riverpod 3.0 upgrade..."

# Check if pubspec.yaml has the right versions
echo "📋 Checking pubspec.yaml versions..."
if grep -q "flutter_riverpod: \^3\." pubspec.yaml && \
   grep -q "riverpod_annotation: \^3\." pubspec.yaml && \
   grep -q "riverpod_generator: \^3\." pubspec.yaml; then
    echo "✅ pubspec.yaml has correct Riverpod 3.0 versions"
else
    echo "❌ pubspec.yaml doesn't have correct Riverpod 3.0 versions"
    exit 1
fi

# Check for deprecated patterns in generated files
echo "📋 Checking for deprecated patterns in .g.dart files..."
if find . -name "*.g.dart" -exec grep -l "Will be removed in 3.0" {} \; | head -1 > /dev/null; then
    echo "⚠️  Found deprecated patterns in .g.dart files"
    echo "   Run: dart run build_runner build --delete-conflicting-outputs"
    echo "   Then run this script again"
    exit 1
else
    echo "✅ No deprecated patterns found in .g.dart files"
fi

# Check for correct Ref usage in source files
echo "📋 Checking source code patterns..."
if grep -r "Ref ref" lib/ --include="*.dart" | grep -v ".g.dart" > /dev/null; then
    echo "✅ Source code uses correct Ref interface"
else
    echo "❌ No Ref interface usage found in source code"
fi

# Check for Consumer usage
if grep -r "Consumer\|ConsumerWidget\|ConsumerStatefulWidget" lib/ --include="*.dart" | grep -v ".g.dart" > /dev/null; then
    echo "✅ Consumer patterns found and compatible"
else
    echo "ℹ️  No Consumer patterns found (this is okay)"
fi

echo ""
echo "🎉 Riverpod 3.0 upgrade verification complete!"
echo ""
echo "Next steps:"
echo "1. flutter clean"
echo "2. flutter pub get"  
echo "3. dart run build_runner build --delete-conflicting-outputs"
echo "4. flutter run"
echo ""
echo "If everything works correctly, you can delete:"
echo "- RIVERPOD_3_UPGRADE_INSTRUCTIONS.md"
echo "- verify_riverpod_upgrade.sh"