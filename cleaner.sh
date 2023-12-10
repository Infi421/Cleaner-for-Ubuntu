#!/bin/bash

# Function to remove old snap versions
remove_old_snaps() {
    echo "Removing old snap versions:"
    snap list --all | awk '/disabled/{print $1, $3}' | while read snapname revision; do
        sudo snap remove "$snapname" --revision="$revision"
    done
}

# Function to clear browser data
clear_browser_data() {
    browser=$1
    if command -v $browser &> /dev/null; then
        echo "Clearing browser data for $browser..."
        $browser --headless --clear-browser-cache --clear-browser-cookies
    else
        echo "Browser $browser not found. Skipping cleanup."
    fi
}

# Function to clean up various caches and temporary files
cleanup_system() {
    echo "Cleaning up system..."
    before_cleanup=$(df -h | grep '/dev/sda1' | awk '{print $4}')

    sudo apt update
    sudo apt autoremove --purge -y
    sudo apt clean

    remove_old_snaps

    rm -rf ~/snap

    # Clear old package versions
    sudo apt-get autoclean

    # Remove old configuration files
    sudo dpkg -l | grep '^rc' | awk '{print $2}' | xargs sudo dpkg --purge

    remove_old_snaps

    # Clear logs
    sudo find /var/log -type f -name "*.gz" -delete

    # Clean up thumbnail cache
    rm -rf ~/.cache/thumbnails/*

    # Remove old temporary files
    sudo rm -rf /tmp/*

    # Additional Cleanup Processes
    sudo apt-get install deborphan
    sudo apt-get remove --purge $(deborphan)

    # Clear cache for VSCode
    rm -rf ~/.vscode/extensions/*

    # Remove old Apache configuration files
    sudo rm -f /etc/apache2/sites-available/*-old

    # MySQL cleanup
    sudo mysql -e "PURGE BINARY LOGS BEFORE NOW() - INTERVAL 7 DAY;"

    # Remove old user files in the home directory
    find /home -type f -name "*.old" -delete

    # Security update check
    sudo unattended-upgrade

    after_cleanup=$(df -h | grep '/dev/sda1' | awk '{print $4}')
    freed_space=$(echo "$before_cleanup - $after_cleanup" | bc -l)
    echo "Freed space: $freed_space GB"
}

# Main cleanup routine
echo "Disk usage before cleanup:"
df -h

cleanup_system

clear_browser_data "firefox"
clear_browser_data "google-chrome-stable"
clear_browser_data "brave-browser"

# Additional cleanup tasks if needed...

echo "Disk usage after cleanup:"
df -h

echo "Cleanup completed."

