#!/bin/bash

# Define the URL to download the application
APP_URL="https://example.com/your_app.deb"

# Define the name of the application package
APP_PACKAGE="falcon-sensor*"

# Define the installation directory
INSTALL_DIR="/opt/Crowdstrike"

# Define the temporary folder
TEMP_FOLDER="/tmp/Crowdstrike"

# Check if the temporary folder exists, if not, create it
if [ ! -d "$TEMP_FOLDER" ]; then
    echo "Creating temporary folder: $TEMP_FOLDER"
    mkdir -p "$TEMP_FOLDER"
fi

# Check if the application is already installed
if [ -d "$INSTALL_DIR" ]; then
    echo "The application is already installed in $INSTALL_DIR. Exiting."
    exit 1
fi

# Download the application package
echo "Downloading $APP_PACKAGE from $APP_URL"
wget -q "$APP_URL" -P "$TEMP_FOLDER"

# Install the application
echo "Installing $APP_PACKAGE"
sudo dpkg -i "$TEMP_FOLDER/$APP_PACKAGE"

# Check if the installation was successful
if [ $? -eq 0 ]; then
    echo "Installation completed successfully."
else
    echo "Installation failed. Please check for errors."
fi

# Clean up - remove the temporary folder
echo "Cleaning up"
rm -r "$TEMP_FOLDER"

# Optional: You may want to add additional configuration or post-installation steps here

# Exit the script
exit 0
