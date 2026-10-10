#!/bin/bash

##setup command=wget -q "--no-check-certificate"https://raw.githubusercontent.com/Ham-ahmed/G12/refs/heads/main/MagicPanelGold-install.sh -O - | /bin/sh

######### Only This line to edit with new version ######
version='12.0'
##############################################################

TMPPATH=/tmp/MagicPanelMax
GITHUB_BASE="https://raw.githubusercontent.com/Ham-ahmed/G/refs/heads/main"
GITHUB_RAW="${GITHUB_BASE}"

# Check architecture and set plugin path
if [ ! -d /usr/lib64 ]; then
    PLUGINPATH="/usr/lib/enigma2/python/Plugins/Extensions/MagicPanelMax"
else
    PLUGINPATH="/usr/lib64/enigma2/python/Plugins/Extensions/MagicPanelMax"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to restart Enigma2
restart_enigma2() {
    print_message $YELLOW "> Restarting Enigma2..."
    sleep 2
    
    # Try different methods to restart enigma2
    if command_exists systemctl; then
        systemctl restart enigma2
    elif command_exists init; then
        init 4
        sleep 2
        init 3
    elif command_exists restart; then
        restart
    elif command_exists wland; then
        wland &
    elif [ -f /etc/rc.local ]; then
        /etc/rc.local &
    else
        killall -9 enigma2
        sleep 2
        if command_exists enigma2; then
            enigma2 >/dev/null 2>&1 &
        fi
    fi
    
    # Wait a moment to ensure restart starts
    sleep 3
}

# Function to check for updates
check_for_updates() {
    print_message $BLUE "> Checking for updates..."
    
    # Try multiple methods to get latest version
    LATEST_VERSION=$(wget -q --timeout=20 --tries=3 --no-check-certificate -O - "${GITHUB_BASE}/version.txt" 2>/dev/null | head -n 1 | tr -d '\r' | tr -d ' ' | grep -E '^[0-9.]+$')
    
    if [ -z "$LATEST_VERSION" ]; then
        LATEST_VERSION=$(curl -s --connect-timeout 10 --max-time 15 "${GITHUB_BASE}/version.txt" 2>/dev/null | head -n 1 | tr -d '\r' | tr -d ' ' | grep -E '^[0-9.]+$')
    fi
    
    if [ -z "$LATEST_VERSION" ]; then
        print_message $YELLOW "> Cannot check for updates. Proceeding with installation..."
        return 1
    fi
    
    # Compare versions
    if [ "$version" != "$LATEST_VERSION" ]; then
        echo ""
        print_message $GREEN "####################################################"
        print_message $BLUE "#              New version available!               #"
        printf "${YELLOW}#       Current version: %-23s#${NC}\n" "$version        "
        printf "${BLUE}#       Latest version: %-27s#${NC}\n" "$LATEST_VERSION    "     
        print_message $YELLOW "#    Please download latest version from:         #"
        print_message $BLUE "#      https://github.com/Ham-ahmed/G12             #"
        print_message $GREEN "####################################################"
        echo ""
        print_message $YELLOW "> Press Ctrl+C to cancel and download latest version"
        print_message $YELLOW "> Continuing with current version in 10 seconds..."
        sleep 10
        return 0
    else
        print_message $GREEN "> You have the latest version ($version)"
        return 1
    fi
}

# Function to install package with error handling
install_package() {
    local package=$1
    local package_name=$2
    
    print_message $BLUE "> Installing $package_name..."
    
    if [ "$OSTYPE" = "DreamOs" ]; then
        if command_exists apt-get; then
            apt-get update >/dev/null 2>&1 && apt-get install "$package" -y >/dev/null 2>&1
            return $?
        else
            print_message $RED "> apt-get not found!"
            return 1
        fi
    else
        if command_exists opkg; then
            opkg update >/dev/null 2>&1 && opkg install "$package" >/dev/null 2>&1
            return $?
        else
            print_message $RED "> opkg not found!"
            return 1
        fi
    fi
}

# Function to check package status
check_package() {
    local package=$1
    if [ -f /var/lib/dpkg/status ]; then
        grep -qs "Package: $package" /var/lib/dpkg/status
    elif [ -f /var/lib/opkg/status ]; then
        grep -qs "Package: $package" /var/lib/opkg/status
    else
        return 1
    fi
}

# Function to download with multiple fallback methods
download_file() {
    local url=$1
    local output=$2
    local max_attempts=3
    
    for attempt in $(seq 1 $max_attempts); do
        print_message $BLUE "> Download attempt $attempt of $max_attempts..."
        
        # Try wget
        if command_exists wget; then
            if wget -q --no-check-certificate --timeout=30 --tries=2 "$url" -O "$output" 2>/dev/null; then
                if [ -s "$output" ]; then
                    return 0
                fi
            fi
        fi
        
        # Try curl if wget fails
        if command_exists curl; then
            if curl -s --connect-timeout 20 --max-time 30 --insecure "$url" -o "$output" 2>/dev/null; then
                if [ -s "$output" ]; then
                    return 0
                fi
            fi
        fi
        
        # Wait before retry
        sleep 2
    done
    
    return 1
}

# Detect OS type and package manager status
if [ -f /var/lib/dpkg/status ]; then
    STATUS="/var/lib/dpkg/status"
    OSTYPE="DreamOs"
else
    STATUS="/var/lib/opkg/status"
    OSTYPE="Dream"
fi

# Clear screen and show banner
clear
echo ""
print_message $CYAN "======================================================"
print_message $YELLOW "           MagicPanelMax Installer v$version"
print_message $CYAN "======================================================"
echo ""

# Detect Python version
PYTHON="PY2"
Packagesix=""
Packagerequests="python-requests"

if command_exists python3; then
    print_message $GREEN "> You have Python3 image"
    PYTHON="PY3"
    Packagesix="python3-six"
    Packagerequests="python3-requests"
elif command_exists python2; then
    print_message $GREEN "> You have Python2 image"
    PYTHON="PY2"
    Packagerequests="python-requests"
elif command_exists python; then
    if python --version 2>&1 | grep -q '^Python 3\.'; then
        print_message $GREEN "> You have Python3 image"
        PYTHON="PY3"
        Packagesix="python3-six"
        Packagerequests="python3-requests"
    else
        print_message $GREEN "> You have Python2 image"
        PYTHON="PY2"
        Packagerequests="python-requests"
    fi
else
    print_message $RED "> Python not found! Please install Python first."
    exit 1
fi

# Check for updates before proceeding
check_for_updates

# Install required packages
echo ""
print_message $BLUE "> Checking required packages..."

if [ "$PYTHON" = "PY3" ] && [ ! -z "$Packagesix" ]; then
    if ! check_package "$Packagesix"; then
        print_message $YELLOW "> Required package $Packagesix not found, installing..."
        if ! install_package "$Packagesix" "python3-six"; then
            print_message $YELLOW "> Failed to install $Packagesix, continuing without it..."
        fi
    fi
fi

echo ""
if ! check_package "$Packagerequests"; then
    print_message $YELLOW "> $Packagerequests must be installed"
    if ! install_package "$Packagerequests" "python-requests"; then
        print_message $RED "> Failed to install $Packagerequests"
        exit 1
    fi
fi

echo ""

# Cleanup previous installations
print_message $BLUE "> Cleaning previous installations..."
[ -d "$TMPPATH" ] && rm -rf "$TMPPATH" > /dev/null 2>&1
[ -d "$PLUGINPATH" ] && rm -rf "$PLUGINPATH" > /dev/null 2>&1

# Download and install plugin
print_message $BLUE "> Downloading MagicPanelMax v$version..."
mkdir -p "$TMPPATH"
cd "$TMPPATH" || exit 1

# Detect OE version
if [ -f /var/lib/dpkg/status ]; then
    print_message $GREEN "# Your image is OE2.5/2.6 #"
else
    print_message $GREEN "# Your image is OE2.0 #"
fi

echo ""

# Define possible download URLs
DOWNLOAD_URLS=(
    "${GITHUB_BASE}/MagicPanelMax_v${version}.tar.gz"
    "https://https://raw.githubusercontent.com/Ham-ahmed/G10/refs/heads/main/MagicPanelMax_v${version}.tar.gz"
    "${GITHUB_BASE}/MagicPanelMax_v${version}.tgz"
    "https://github.com/Ham-ahmed/G10/raw/main/MagicPanelMax_v${version}.tar.gz"
)

# Try downloading from all URLs
DOWNLOAD_SUCCESS=0
for url in "${DOWNLOAD_URLS[@]}"; do
    print_message $BLUE "> Trying to download from: $url"
    if download_file "$url" "MagicPanelMax_v${version}.tar.gz"; then
        if [ -f "MagicPanelMax_v${version}.tar.gz" ] && [ -s "MagicPanelMax_v${version}.tar.gz" ]; then
            # التحقق من صحة الملف باستخدام tar بدلاً من file
            if tar -tzf "MagicPanelMax_v${version}.tar.gz" >/dev/null 2>&1; then
                DOWNLOAD_SUCCESS=1
                print_message $GREEN "✓ Download successful and file validated from: $url"
                break
            else
                print_message $YELLOW "✗ Downloaded file is not a valid tar.gz archive"
                rm -f "MagicPanelMax_v${version}.tar.gz"
            fi
        fi
    fi
    sleep 1
done

# Check if download was successful
if [ $DOWNLOAD_SUCCESS -eq 0 ] || [ ! -f "MagicPanelMax_v${version}.tar.gz" ] || [ ! -s "MagicPanelMax_v${version}.tar.gz" ]; then
    print_message $RED "✗ Complete download failure!"
    print_message $YELLOW "> Possible reasons:"
    print_message $YELLOW "  1. No internet connection"
    print_message $YELLOW "  2. GitHub repository is unavailable"
    print_message $YELLOW "  3. Version $version does not exist"
    print_message $YELLOW "  4. File is corrupted on server"
    echo ""
    print_message $YELLOW "> Troubleshooting steps:"
    print_message $YELLOW "  1. Check your internet connection"
    print_message $YELLOW "  2. Verify the version number is correct"
    print_message $YELLOW "  3. Try downloading manually from GitHub"
    print_message $YELLOW "  4. Check if the repository is accessible"
    
    # Clean up
    cd /
    rm -rf "$TMPPATH" > /dev/null 2>&1
    exit 1
fi

# Verify downloaded file integrity (تحقق إضافي)
print_message $BLUE "> Verifying downloaded file integrity..."

# Check file size
FILE_SIZE=$(stat -c%s "MagicPanelMax_v${version}.tar.gz" 2>/dev/null || stat -f%z "MagicPanelMax_v${version}.tar.gz" 2>/dev/null)
if [ "$FILE_SIZE" -lt 1024 ]; then
    print_message $RED "> Downloaded file is too small ($FILE_SIZE bytes). File may be corrupted!"
    print_message $RED "> Complete download failure!"
    cd /
    rm -rf "$TMPPATH" > /dev/null 2>&1
    exit 1
fi

# Extract the plugin
print_message $BLUE "> Extracting files..."
if ! tar -xzf "MagicPanelMax_v${version}.tar.gz" 2>/dev/null; then
    print_message $RED "> Failed to extract files! Archive may be corrupted."
    print_message $RED "> Complete download failure!"
    cd /
    rm -rf "$TMPPATH" > /dev/null 2>&1
    exit 1
fi

# Install the plugin
print_message $BLUE "> Installing plugin..."

# Create plugin directory
mkdir -p "$PLUGINPATH"

# Look for the plugin files in common directory structures
FILES_COPIED=0
if [ -d "MagicPanelMax" ]; then
    cp -rf "MagicPanelMax"/* "$PLUGINPATH"/ 2>/dev/null
    FILES_COPIED=$?
elif [ -d "MagicPanelMax-main" ]; then
    if [ -d "MagicPanelMax-main/usr" ]; then
        cp -rf "MagicPanelMax-main/usr"/* "/usr/" 2>/dev/null
        FILES_COPIED=$?
    else
        cp -rf "MagicPanelMax-main"/* "$PLUGINPATH"/ 2>/dev/null
        FILES_COPIED=$?
    fi
elif [ -d "usr" ]; then
    cp -rf "usr"/* "/usr/" 2>/dev/null
    FILES_COPIED=$?
else
    # Find and copy all relevant files
    find . -name "*.py" -o -name "*.pyo" -o -name "*.pyc" -o -name "*.so" -o -name "*.png" -o -name "*.xml" -o -name "*.json" | while read -r file; do
        dest_dir="$PLUGINPATH/$(dirname "$file")"
        mkdir -p "$dest_dir"
        cp -f "$file" "$dest_dir/" 2>/dev/null
        FILES_COPIED=0
    done
    
    # Copy locale files if they exist
    if [ -d "locale" ]; then
        cp -rf "locale" "$PLUGINPATH/../" 2>/dev/null
    fi
fi

# Verify installation
print_message $BLUE "> Verifying installation..."

if [ ! -d "$PLUGINPATH" ] || [ -z "$(ls -A "$PLUGINPATH" 2>/dev/null)" ]; then
    print_message $YELLOW "> Plugin not found in expected location. Attempting alternative installation..."
    
    # Try to find and copy Python files manually
    find "$TMPPATH" -name "*.py" -exec cp {} "$PLUGINPATH"/ \; 2>/dev/null
    
    if [ -z "$(ls -A "$PLUGINPATH" 2>/dev/null)" ]; then
        print_message $RED "> Installation failed! Could not copy plugin files."
        exit 1
    fi
fi

# Set correct permissions
print_message $BLUE "> Setting file permissions..."
find "$PLUGINPATH" -type f -name "*.py" -exec chmod 644 {} \; 2>/dev/null
find "$PLUGINPATH" -type f -name "*.pyo" -exec chmod 644 {} \; 2>/dev/null
find "$PLUGINPATH" -type f -name "*.so" -exec chmod 755 {} \; 2>/dev/null
find "$PLUGINPATH" -type d -exec chmod 755 {} \; 2>/dev/null
chmod -R 755 "$PLUGINPATH" 2>/dev/null

# Cleanup
print_message $BLUE "> Cleaning temporary files..."
rm -rf "$TMPPATH" > /dev/null 2>&1
sync

# Success message
echo ""
print_message $CYAN "==================================================================="
print_message $GREEN "===              Installation Successful!                       ==="
printf "${YELLOW}===                 MagicPanelMax v%-24s===${NC}\n" "$version"
print_message $BLUE "===              Downloaded by  >>>>   HAMDY_AHMED               ==="
print_message $CYAN "==================================================================="
echo ""
print_message $YELLOW "Enigma2 will restart automatically after 5 seconds..."
print_message $BLUE "Press Ctrl+C to cancel"
echo ""

# Countdown before restart
for i in {5..1}; do
    printf "${YELLOW}Restarting in $i seconds...${NC}\r"
    sleep 1
done
echo ""

# Automatic restart
print_message $GREEN "========================================================="
print_message $YELLOW "===            Restarting Enigma2                     ==="
print_message $GREEN "========================================================="

# Call restart function
restart_enigma2

exit 0
