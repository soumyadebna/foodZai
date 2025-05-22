#!/bin/bash

# This script fixes the namespace issue in flutter_local_notifications plugin
# for Android Gradle Plugin 8.0.0 and above

# Find the flutter_local_notifications plugin directory
PLUGIN_DIR=$(find ~/.pub-cache -path "*flutter_local_notifications-8.2.0*" -type d | grep -v "example" | head -n 1)
ANDROID_DIR="$PLUGIN_DIR/android"

if [ -z "$PLUGIN_DIR" ]; then
  echo "Could not find flutter_local_notifications plugin directory"
  exit 1
fi

echo "Found plugin at: $PLUGIN_DIR"
echo "Android directory: $ANDROID_DIR"

# Create a backup of the original build.gradle file
cp "$ANDROID_DIR/build.gradle" "$ANDROID_DIR/build.gradle.bak"

# Add namespace to the build.gradle file
sed -i '' 's/android {/android {\n    namespace "com.dexterous.flutterlocalnotifications"/g' "$ANDROID_DIR/build.gradle"

echo "Added namespace to build.gradle"

# Check if the change was successful
if grep -q "namespace" "$ANDROID_DIR/build.gradle"; then
  echo "Namespace added successfully"
else
  echo "Failed to add namespace"
  exit 1
fi

# Now fix any other plugins that might have the same issue
TIMEZONE_PLUGIN_DIR=$(find ~/.pub-cache -path "*flutter_native_timezone-2.0.0*" -type d | grep -v "example" | head -n 1)
if [ -n "$TIMEZONE_PLUGIN_DIR" ]; then
  TIMEZONE_ANDROID_DIR="$TIMEZONE_PLUGIN_DIR/android"
  echo "Found flutter_native_timezone plugin at: $TIMEZONE_PLUGIN_DIR"
  
  # Create a backup of the original build.gradle file
  cp "$TIMEZONE_ANDROID_DIR/build.gradle" "$TIMEZONE_ANDROID_DIR/build.gradle.bak"
  
  # Add namespace to the build.gradle file
  sed -i '' 's/android {/android {\n    namespace "com.whelksoft.flutter_native_timezone"/g' "$TIMEZONE_ANDROID_DIR/build.gradle"
  
  echo "Added namespace to flutter_native_timezone build.gradle"
fi

echo "Namespace fix completed"
