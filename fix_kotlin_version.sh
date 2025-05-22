#!/bin/bash

# This script fixes the Kotlin version issue in flutter_native_timezone plugin

# Find the flutter_native_timezone plugin directory
TIMEZONE_PLUGIN_DIR=$(find ~/.pub-cache -path "*flutter_native_timezone-2.0.0*" -type d | grep -v "example" | head -n 1)
if [ -n "$TIMEZONE_PLUGIN_DIR" ]; then
  TIMEZONE_ANDROID_DIR="$TIMEZONE_PLUGIN_DIR/android"
  echo "Found flutter_native_timezone plugin at: $TIMEZONE_PLUGIN_DIR"
  
  # Create a backup of the original build.gradle file
  cp "$TIMEZONE_ANDROID_DIR/build.gradle" "$TIMEZONE_ANDROID_DIR/build.gradle.bak"
  
  # Update the Kotlin version in the build.gradle file
  sed -i '' 's/ext.kotlin_version = "1.3.50"/ext.kotlin_version = "1.5.20"/g' "$TIMEZONE_ANDROID_DIR/build.gradle"
  
  echo "Updated Kotlin version in flutter_native_timezone build.gradle"
  
  # Check if the change was successful
  if grep -q "1.5.20" "$TIMEZONE_ANDROID_DIR/build.gradle"; then
    echo "Kotlin version updated successfully"
  else
    echo "Failed to update Kotlin version"
    exit 1
  fi
fi

echo "Kotlin version fix completed"
