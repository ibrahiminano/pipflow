#!/bin/bash

# Kill any existing app instances
pkill -f "Pipflow.app" || true

# Wait a moment
sleep 1

# Open the app using the simulator's open command
xcrun simctl openurl booted pipflow://launch || {
    echo "Failed to launch app. Make sure to build and run from Xcode first."
    exit 1
}

echo "App launch requested. Check the simulator."