#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting custom deployment script..."

# Define source and destination directories
SOURCE_DIR="$HOME/site/repository" # Kudu places your Git repo content here
TARGET_DIR="$HOME/site/wwwroot"    # This is where your app needs to be deployed

# --- Build your Maven application ---
echo "Running Maven build..."
# Navigate to the repository root where your pom.xml is
cd "$SOURCE_DIR"

# Clean and package your Maven project
# This will create your WAR/JAR and the 'azure-app-service-agent' directory in 'target/'
mvn clean package -DskipTests

# Check if the main artifact exists (e.g., your WAR or JAR)
# Adjust the filename pattern based on your project's packaging (e.g., *.war or *.jar)
MAIN_ARTIFACT=$(find target -name "*.jar" -print -quit) # Or "*.jar" for Spring Boot

if [ -z "$MAIN_ARTIFACT" ]; then
    echo "[ERROR] Main application artifact not found after Maven build. Exiting."
    exit 1
fi

echo "Main artifact found: $MAIN_ARTIFACT"

# --- Deploy the main application artifact ---
echo "Clearing previous deployment in wwwroot..."
# Remove everything from wwwroot before copying new files
rm -rf "$TARGET_DIR"/*

echo "Copying main application artifact to wwwroot..."
# Copy the main WAR/JAR file directly to wwwroot
cp "$MAIN_ARTIFACT" "$TARGET_DIR/"

# --- Copy the Contrast agent directory ---
AGENT_SOURCE_DIR="$SOURCE_DIR/target/azure-app-service-agent"
AGENT_DEST_DIR="$TARGET_DIR/azure-app-service-agent" # This will be /home/site/wwwroot/azure-app-service-agent

echo "Checking for Contrast agent directory at $AGENT_SOURCE_DIR..."
if [ -d "$AGENT_SOURCE_DIR" ]; then
    echo "Copying Contrast agent directory to $AGENT_DEST_DIR..."
    mkdir -p "$AGENT_DEST_DIR" # Ensure destination directory exists
    cp -r "$AGENT_SOURCE_DIR"/* "$AGENT_DEST_DIR/" # Copy contents
    echo "Contrast agent copied successfully."
else
    echo "[WARNING] Contrast agent directory ($AGENT_SOURCE_DIR) not found. Agent will not be deployed."
fi

echo "Custom deployment script finished."

# Kudu will automatically restart the web app if new files are detected in wwwroot
