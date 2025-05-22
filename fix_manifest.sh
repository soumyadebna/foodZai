#!/bin/bash

# This script fixes the AndroidManifest.xml file in the flutter_local_notifications plugin

# Find the flutter_local_notifications plugin directory
PLUGIN_DIR=$(find ~/.pub-cache -path "*flutter_local_notifications-8.2.0*" -type d | grep -v "example" | head -n 1)
MANIFEST_FILE="$PLUGIN_DIR/android/src/main/AndroidManifest.xml"

if [ -z "$PLUGIN_DIR" ]; then
  echo "Could not find flutter_local_notifications plugin directory"
  exit 1
fi

echo "Found plugin at: $PLUGIN_DIR"
echo "Manifest file: $MANIFEST_FILE"

# Create a backup of the original manifest file
cp "$MANIFEST_FILE" "$MANIFEST_FILE.bak"

# Read the manifest file
MANIFEST_CONTENT=$(cat "$MANIFEST_FILE")

# Check if the receiver element exists
if [[ $MANIFEST_CONTENT == *"<receiver android:name=\"com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver\""* ]]; then
  # Add android:exported="false" to the receiver element
  UPDATED_MANIFEST=$(echo "$MANIFEST_CONTENT" | sed 's/<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"/<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver" android:exported="false"/g')
  
  # Write the updated manifest file
  echo "$UPDATED_MANIFEST" > "$MANIFEST_FILE"
  
  echo "Added android:exported=\"false\" to ScheduledNotificationBootReceiver"
else
  echo "Could not find ScheduledNotificationBootReceiver in manifest file"
  exit 1
fi

# Check if the change was successful
if grep -q "android:exported=\"false\"" "$MANIFEST_FILE"; then
  echo "Manifest fix applied successfully"
else
  echo "Failed to apply manifest fix"
  exit 1
fi

echo "Manifest fix completed"
