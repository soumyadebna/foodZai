#!/bin/bash

# Find the flutter_local_notifications plugin directory
PLUGIN_DIR=$(find ~/.pub-cache -path "*flutter_local_notifications-9.9.1*" -type d | grep -v "example" | head -n 1)
ANDROID_DIR="$PLUGIN_DIR/android"

if [ -z "$PLUGIN_DIR" ]; then
  echo "Could not find flutter_local_notifications plugin directory"
  exit 1
fi

echo "Found plugin at: $PLUGIN_DIR"
echo "Android directory: $ANDROID_DIR"

# Copy our custom build.gradle to the plugin's android directory
cp .gradle_fix/flutter_local_notifications/build.gradle "$ANDROID_DIR/build.gradle"

echo "Copied custom build.gradle to plugin directory"
