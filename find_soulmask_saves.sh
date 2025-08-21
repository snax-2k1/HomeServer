#!/bin/bash
# SoulMask Save File Finder and Copier
# Run this script on your Windows machine to find and copy SoulMask saves

echo "SoulMask Save File Finder"
echo "========================="

# Common SoulMask save file locations (you'll need to check these manually on Windows)
echo "Please check these locations for your SoulMask save files:"
echo ""

echo "1. Steam Cloud Saves (if enabled):"
echo "   C:\\Program Files (x86)\\Steam\\userdata\\[USERID]\\2216494\\remote\\"
echo ""

echo "2. Local Steam Saves:"
echo "   C:\\Program Files (x86)\\Steam\\steamapps\\common\\SoulMask\\Saved\\"
echo "   D:\\SteamLibrary\\steamapps\\common\\SoulMask\\Saved\\"
echo ""

echo "3. AppData Locations:"
echo "   C:\\Users\\[USERNAME]\\AppData\\Local\\SoulMask\\"
echo "   C:\\Users\\[USERNAME]\\AppData\\LocalLow\\SoulMask\\"
echo "   C:\\Users\\[USERNAME]\\AppData\\Roaming\\SoulMask\\"
echo ""

echo "4. Documents folder:"
echo "   C:\\Users\\[USERNAME]\\Documents\\My Games\\SoulMask\\"
echo "   C:\\Users\\[USERNAME]\\Documents\\SoulMask\\"
echo ""

echo "5. Common save file patterns to look for:"
echo "   - *.sav files"
echo "   - *.save files" 
echo "   - SaveData folders"
echo "   - World folders"
echo "   - Player folders"
echo ""

# Check if we're running on a system with Steam installed
if [ -d "/c/Program Files (x86)/Steam" ]; then
    echo "Found Steam installation. Searching for SoulMask saves..."
    
    # Search for SoulMask directories
    find "/c/Program Files (x86)/Steam" -type d -iname "*soulmask*" 2>/dev/null
    find "/c/Users" -type d -iname "*soulmask*" 2>/dev/null
    
    # Search for .sav files that might be SoulMask related
    find "/c/Users" -name "*.sav" -exec ls -la {} \; 2>/dev/null | grep -i soul
    
elif [ -d "/mnt/c/Program Files (x86)/Steam" ]; then
    echo "Found Steam installation (WSL). Searching for SoulMask saves..."
    
    # WSL paths
    find "/mnt/c/Program Files (x86)/Steam" -type d -iname "*soulmask*" 2>/dev/null
    find "/mnt/c/Users" -type d -iname "*soulmask*" 2>/dev/null
    
else
    echo "Steam installation not found in expected locations."
    echo "Please manually check the paths listed above."
fi

echo ""
echo "INSTRUCTIONS:"
echo "============="
echo "1. Locate your SoulMask save files using the paths above"
echo "2. Copy the entire save directory to your HomeServer project folder:"
echo "   [HomeServer]\\soulmask_saves\\"
echo "3. When you run the Docker setup, use the migration script:"
echo "   ./soulmask_migrate.sh"
echo ""
echo "TIP: Look for recent .sav files or directories with names like:"
echo "- SavedWorlds"
echo "- PlayerData" 
echo "- Characters"
echo "- World_[numbers]"
