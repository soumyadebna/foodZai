#!/bin/bash

# FoodAI Release Build Script
# This script builds the app for release on Android and iOS

# Set colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== FoodAI Release Build Script ===${NC}"
echo -e "${YELLOW}This script will build the app for release on Android and iOS${NC}"
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Flutter is not installed or not in PATH${NC}"
    exit 1
fi

# Navigate to the project directory
cd "$(dirname "$0")"

# Clean the project
echo -e "${YELLOW}Cleaning project...${NC}"
flutter clean
echo -e "${GREEN}Project cleaned successfully${NC}"

# Get dependencies
echo -e "${YELLOW}Getting dependencies...${NC}"
flutter pub get
echo -e "${GREEN}Dependencies updated successfully${NC}"

# Run Flutter doctor to check if everything is set up correctly
echo -e "${YELLOW}Running Flutter doctor...${NC}"
flutter doctor -v

# Build Android APK
echo -e "${YELLOW}Building Android APK...${NC}"
flutter build apk --release

# Check if the build was successful
if [ $? -eq 0 ]; then
    APK_PATH="$(pwd)/build/app/outputs/flutter-apk/app-release.apk"
    echo -e "${GREEN}Android APK built successfully!${NC}"
    echo -e "${GREEN}APK location: ${APK_PATH}${NC}"
    
    # Copy APK to Downloads folder
    if [ -d "$HOME/Downloads" ]; then
        cp "$APK_PATH" "$HOME/Downloads/foodai.apk"
        echo -e "${GREEN}APK copied to Downloads folder: $HOME/Downloads/foodai.apk${NC}"
    fi
else
    echo -e "${RED}Failed to build Android APK${NC}"
fi

# Ask if user wants to build for iOS
echo ""
read -p "Do you want to build for iOS? (y/n): " BUILD_IOS

if [[ $BUILD_IOS == "y" || $BUILD_IOS == "Y" ]]; then
    # Check if running on macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        echo -e "${RED}iOS builds can only be created on macOS${NC}"
    else
        # Build iOS
        echo -e "${YELLOW}Building iOS app...${NC}"
        flutter build ios --release --no-codesign
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}iOS build completed successfully!${NC}"
            echo -e "${YELLOW}To complete the iOS build process:${NC}"
            echo -e "1. Open the Xcode workspace: ${YELLOW}open ios/Runner.xcworkspace${NC}"
            echo -e "2. Select a development team in the Signing & Capabilities tab"
            echo -e "3. Build and archive the app for App Store submission"
        else
            echo -e "${RED}Failed to build iOS app${NC}"
        fi
    fi
fi

echo ""
echo -e "${GREEN}Build process completed!${NC}"
