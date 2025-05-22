#!/bin/bash

# This script fixes the bigLargeIcon ambiguity issue in the flutter_local_notifications plugin

# Find the flutter_local_notifications plugin directory
PLUGIN_DIR=$(find ~/.pub-cache -path "*flutter_local_notifications-8.2.0*" -type d | grep -v "example" | head -n 1)
JAVA_FILE="$PLUGIN_DIR/android/src/main/java/com/dexterous/flutterlocalnotifications/FlutterLocalNotificationsPlugin.java"

if [ -z "$PLUGIN_DIR" ]; then
  echo "Could not find flutter_local_notifications plugin directory"
  exit 1
fi

echo "Found plugin at: $PLUGIN_DIR"
echo "Java file: $JAVA_FILE"

# Create a backup of the original Java file
cp "$JAVA_FILE" "$JAVA_FILE.bak"

# Fix the bigLargeIcon ambiguity issue
sed -i '' 's/bigPictureStyle.bigLargeIcon(null);/bigPictureStyle.bigLargeIcon((Bitmap) null);/g' "$JAVA_FILE"

echo "Fixed bigLargeIcon ambiguity issue"

# Check if the change was successful
if grep -q "bigLargeIcon((Bitmap) null)" "$JAVA_FILE"; then
  echo "bigLargeIcon fix applied successfully"
else
  echo "Failed to apply bigLargeIcon fix"
  exit 1
fi

echo "bigLargeIcon fix completed"
