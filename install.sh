#!/bin/bash
#===============================================================================
# CS2 Server Installation Script
# For Ubuntu 22.04/24.04 on Azure
# 
# Features:
# - All game modes (Competitive, Casual, Deathmatch, Arms Race, Wingman)
# - 5-minute match duration for applicable modes
# - Map voting at end of match
#===============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   CS2 Server Installation Script${NC}"
echo -e "${GREEN}========================================${NC}"

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Please do not run as root. Run as a regular user with sudo privileges.${NC}"
    exit 1
fi

# Variables
STEAM_USER="$USER"
INSTALL_DIR="$HOME/cs2-server"
STEAMCMD_DIR="$HOME/steamcmd"

# Get login token from argument or prompt
if [ -n "$1" ]; then
    LOGIN_TOKEN="$1"
else
    echo -e "${YELLOW}Enter your Steam Game Server Login Token (GSLT):${NC}"
    read -r LOGIN_TOKEN
fi

echo -e "${YELLOW}[1/7] Updating system and installing dependencies...${NC}"
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install -y lib32gcc-s1 lib32stdc++6 libsdl2-2.0-0:i386 curl wget tar screen

echo -e "${YELLOW}[2/7] Installing SteamCMD...${NC}"
mkdir -p "$STEAMCMD_DIR"
cd "$STEAMCMD_DIR"
if [ ! -f "steamcmd.sh" ]; then
    wget -q https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
    tar -xzf steamcmd_linux.tar.gz
    rm steamcmd_linux.tar.gz
fi

echo -e "${YELLOW}[3/7] Creating server directory...${NC}"
mkdir -p "$INSTALL_DIR"

echo -e "${YELLOW}[4/7] Downloading CS2 Dedicated Server (this may take a while)...${NC}"
cd "$STEAMCMD_DIR"
./steamcmd.sh +force_install_dir "$INSTALL_DIR" +login anonymous +app_update 730 validate +quit

echo -e "${YELLOW}[5/7] Configuring server...${NC}"

# Create cfg directory
mkdir -p "$INSTALL_DIR/game/csgo/cfg"

# Copy config files if they exist in script directory
if [ -d "$SCRIPT_DIR/cfg" ]; then
    echo "Copying configuration files..."
    cp -v "$SCRIPT_DIR/cfg/"*.cfg "$INSTALL_DIR/game/csgo/cfg/" 2>/dev/null || true
    cp -v "$SCRIPT_DIR/cfg/gamemodes_server.txt" "$INSTALL_DIR/game/csgo/" 2>/dev/null || true
else
    # Create default server.cfg if no cfg directory
    cat > "$INSTALL_DIR/game/csgo/cfg/server.cfg" << 'SERVERCFG'
hostname "CS2 Server"
sv_cheats 0
sv_lan 0
mp_autoteambalance 1
mp_friendlyfire 0
bot_quota 0
mp_endmatch_votenextmap 1
mp_endmatch_votenextleveltime 20
rcon_password "changeme123"
SERVERCFG
fi

# Create autoexec.cfg
cat > "$INSTALL_DIR/game/csgo/cfg/autoexec.cfg" << 'AUTOEXEC'
// Auto-execute on server start
exec server.cfg
AUTOEXEC

# Save login token
echo "$LOGIN_TOKEN" > "$INSTALL_DIR/.gslt_token"
chmod 600 "$INSTALL_DIR/.gslt_token"

echo -e "${YELLOW}[6/7] Creating management scripts...${NC}"

# Create start script with config loading
cat > "$INSTALL_DIR/start.sh" << 'STARTSCRIPT'
#!/bin/bash
#===============================================================================
# CS2 Server Start Script
# Supports: competitive, casual, deathmatch, armsrace, demolition, wingman
#===============================================================================

INSTALL_DIR="$(dirname "$(readlink -f "$0")")"
TOKEN=$(cat "$INSTALL_DIR/.gslt_token" 2>/dev/null)

if [ -z "$TOKEN" ]; then
    echo "Error: No GSLT token found. Please run install.sh first."
    exit 1
fi

# Check if already running
if screen -list | grep -q "cs2server"; then
    echo "Server is already running. Stop it first with ./stop.sh"
    exit 1
fi

cd "$INSTALL_DIR"

# Default values
GAMEMODE="${1:-competitive}"
MAP="${2:-de_dust2}"
MAXPLAYERS="${3:-16}"

echo "========================================"
echo "Starting CS2 Server"
echo "========================================"
echo "  Mode: $GAMEMODE"
echo "  Map: $MAP"
echo "  Max Players: $MAXPLAYERS"
echo "========================================"

# Game mode mapping
case "$GAMEMODE" in
    competitive)
        GAMETYPE=0
        GAMEMODE_ID=1
        MAPGROUP="mg_active"
        CONFIG_FILE="gamemode_competitive.cfg"
        ;;
    casual)
        GAMETYPE=0
        GAMEMODE_ID=0
        MAPGROUP="mg_active"
        CONFIG_FILE="gamemode_casual.cfg"
        ;;
    deathmatch)
        GAMETYPE=1
        GAMEMODE_ID=2
        MAPGROUP="mg_deathmatch"
        CONFIG_FILE="gamemode_deathmatch.cfg"
        ;;
    armsrace|gunmode|gungame)
        GAMETYPE=1
        GAMEMODE_ID=0
        MAPGROUP="mg_armsrace"
        CONFIG_FILE="gamemode_armsrace.cfg"
        # Use armsrace map if none specified
        if [ "$MAP" = "de_dust2" ]; then
            MAP="ar_shoots"
        fi
        ;;
    demolition)
        GAMETYPE=1
        GAMEMODE_ID=1
        MAPGROUP="mg_active"
        CONFIG_FILE="gamemode_casual.cfg"
        ;;
    wingman)
        GAMETYPE=0
        GAMEMODE_ID=2
        MAPGROUP="mg_wingman"
        MAXPLAYERS=4
        CONFIG_FILE="gamemode_wingman.cfg"
        ;;
    *)
        echo "Unknown game mode: $GAMEMODE"
        echo "Available: competitive, casual, deathmatch, armsrace, demolition, wingman"
        exit 1
        ;;
esac

# Set library path (required for CS2)
export LD_LIBRARY_PATH="$INSTALL_DIR/game/bin/linuxsteamrt64:$LD_LIBRARY_PATH"

# Build exec command
EXEC_CMD="server.cfg"
if [ -f "$INSTALL_DIR/game/csgo/cfg/$CONFIG_FILE" ]; then
    EXEC_CMD="$CONFIG_FILE"
    echo "  Config: $CONFIG_FILE"
fi

echo "  MapGroup: $MAPGROUP"
echo ""

screen -dmS cs2server ./game/bin/linuxsteamrt64/cs2 \
    -dedicated \
    -console \
    -usercon \
    +game_type $GAMETYPE \
    +game_mode $GAMEMODE_ID \
    +mapgroup $MAPGROUP \
    +map $MAP \
    +sv_setsteamaccount $TOKEN \
    -maxplayers $MAXPLAYERS \
    +exec $EXEC_CMD

echo "✅ Server started in screen session 'cs2server'"
echo ""
echo "Commands:"
echo "  screen -r cs2server  - View console"
echo "  Ctrl+A, D            - Detach from console"
echo "  ./stop.sh            - Stop server"
echo "  ./status.sh          - Check status"
STARTSCRIPT
chmod +x "$INSTALL_DIR/start.sh"

# Create stop script
cat > "$INSTALL_DIR/stop.sh" << 'STOPSCRIPT'
#!/bin/bash
echo "Stopping CS2 Server..."
screen -S cs2server -X quit 2>/dev/null
pkill -f "cs2 -dedicated" 2>/dev/null
echo "✅ Server stopped."
STOPSCRIPT
chmod +x "$INSTALL_DIR/stop.sh"

# Create update script
cat > "$INSTALL_DIR/update.sh" << 'UPDATESCRIPT'
#!/bin/bash
INSTALL_DIR="$(dirname "$(readlink -f "$0")")"
STEAMCMD_DIR="$HOME/steamcmd"

echo "Stopping server if running..."
"$INSTALL_DIR/stop.sh"

echo "Updating CS2 Server..."
cd "$STEAMCMD_DIR"
./steamcmd.sh +force_install_dir "$INSTALL_DIR" +login anonymous +app_update 730 validate +quit

echo "✅ Update complete!"
UPDATESCRIPT
chmod +x "$INSTALL_DIR/update.sh"

# Create status script
cat > "$INSTALL_DIR/status.sh" << 'STATUSSCRIPT'
#!/bin/bash
if screen -list | grep -q "cs2server"; then
    echo "✅ CS2 Server is RUNNING"
    echo ""
    echo "To view console: screen -r cs2server"
else
    echo "❌ CS2 Server is NOT running"
fi
STATUSSCRIPT
chmod +x "$INSTALL_DIR/status.sh"

# Create console script
cat > "$INSTALL_DIR/console.sh" << 'CONSOLESCRIPT'
#!/bin/bash
if screen -list | grep -q "cs2server"; then
    echo "Attaching to server console..."
    echo "Press Ctrl+A, then D to detach"
    sleep 2
    screen -r cs2server
else
    echo "Server is not running."
fi
CONSOLESCRIPT
chmod +x "$INSTALL_DIR/console.sh"

# Create gamemode script
cat > "$INSTALL_DIR/gamemode.sh" << 'GAMEMODESCRIPT'
#!/bin/bash
INSTALL_DIR="$(dirname "$(readlink -f "$0")")"

show_help() {
    echo "========================================"
    echo "CS2 Game Mode Manager"
    echo "========================================"
    echo ""
    echo "Usage: ./gamemode.sh <mode> [map]"
    echo ""
    echo "Available modes:"
    echo "  competitive  - Classic competitive (short match ~5 min)"
    echo "  casual       - Casual mode (short match ~5 min)"
    echo "  deathmatch   - Free-for-all deathmatch (5 min)"
    echo "  armsrace     - Arms Race / Gun Game (5 min)"
    echo "  demolition   - Demolition mode"
    echo "  wingman      - 2v2 competitive (short match)"
    echo ""
    echo "Maps by mode:"
    echo "  Arms Race:   ar_baggage, ar_pool_day, ar_shoots"
    echo "  Competitive: de_dust2, de_mirage, de_inferno, de_ancient,"
    echo "               de_anubis, de_nuke, de_overpass, de_vertigo"
    echo "  Wingman:     de_inferno, de_overpass, de_vertigo, de_nuke"
    echo ""
    echo "Features:"
    echo "  ✓ 5-minute matches (deathmatch, armsrace)"
    echo "  ✓ Short rounds (competitive, casual, wingman)"
    echo "  ✓ Map voting at end of match"
    echo ""
    echo "Examples:"
    echo "  ./gamemode.sh armsrace ar_shoots"
    echo "  ./gamemode.sh deathmatch de_dust2"
    echo "  ./gamemode.sh competitive de_mirage"
}

if [ -z "$1" ]; then
    show_help
    exit 0
fi

MODE="$1"
MAP="$2"

echo "Changing game mode to: $MODE"
"$INSTALL_DIR/stop.sh"
sleep 2

if [ -n "$MAP" ]; then
    "$INSTALL_DIR/start.sh" "$MODE" "$MAP"
else
    "$INSTALL_DIR/start.sh" "$MODE"
fi
GAMEMODESCRIPT
chmod +x "$INSTALL_DIR/gamemode.sh"

# Create bots script
cat > "$INSTALL_DIR/bots.sh" << 'BOTSSCRIPT'
#!/bin/bash

show_help() {
    echo "CS2 Bot Manager"
    echo ""
    echo "Usage: ./bots.sh <command> [options]"
    echo ""
    echo "Commands:"
    echo "  add <team> [count]   - Add bots (team: t/ct/both, count: default 1)"
    echo "  remove <team|all>    - Remove bots"
    echo "  difficulty <0-3>     - Set bot difficulty (0=easy, 3=expert)"
    echo "  quota <number>       - Set bot quota (auto-fill to this number)"
    echo "  stop                 - Disable bot quota"
    echo ""
    echo "Examples:"
    echo "  ./bots.sh add ct 3      - Add 3 CT bots"
    echo "  ./bots.sh add both 5    - Add 5 bots to each team"
    echo "  ./bots.sh remove all    - Remove all bots"
    echo "  ./bots.sh difficulty 2  - Set medium-hard difficulty"
    echo "  ./bots.sh quota 10      - Keep 10 players total (fill with bots)"
}

send_command() {
    if screen -list | grep -q "cs2server"; then
        screen -S cs2server -X stuff "$1\n"
        echo "Command sent: $1"
    else
        echo "Error: Server is not running"
        exit 1
    fi
}

case "$1" in
    add)
        TEAM="${2:-both}"
        COUNT="${3:-1}"
        case "$TEAM" in
            t|terrorist)
                for i in $(seq 1 $COUNT); do send_command "bot_add_t"; done
                ;;
            ct|counter)
                for i in $(seq 1 $COUNT); do send_command "bot_add_ct"; done
                ;;
            both)
                for i in $(seq 1 $COUNT); do 
                    send_command "bot_add_t"
                    send_command "bot_add_ct"
                done
                ;;
            *)
                echo "Unknown team: $TEAM (use t, ct, or both)"
                ;;
        esac
        ;;
    remove)
        TEAM="${2:-all}"
        case "$TEAM" in
            t|terrorist)
                send_command "bot_kick t"
                ;;
            ct|counter)
                send_command "bot_kick ct"
                ;;
            all)
                send_command "bot_kick all"
                ;;
            *)
                echo "Unknown team: $TEAM"
                ;;
        esac
        ;;
    difficulty)
        DIFF="${2:-2}"
        send_command "bot_difficulty $DIFF"
        echo "Bot difficulty set to $DIFF"
        ;;
    quota)
        QUOTA="${2:-10}"
        send_command "bot_quota $QUOTA"
        send_command "bot_quota_mode fill"
        echo "Bot quota set to $QUOTA (fill mode)"
        ;;
    stop)
        send_command "bot_quota 0"
        send_command "bot_kick all"
        echo "Bots disabled"
        ;;
    *)
        show_help
        ;;
esac
BOTSSCRIPT
chmod +x "$INSTALL_DIR/bots.sh"

echo -e "${YELLOW}[7/7] Setting up map voting...${NC}"

# Ensure gamemodes_server.txt exists
if [ ! -f "$INSTALL_DIR/game/csgo/gamemodes_server.txt" ]; then
    cat > "$INSTALL_DIR/game/csgo/gamemodes_server.txt" << 'MAPGROUPS'
"gamemodes_server.txt"
{
    "mapgroups"
    {
        "mg_armsrace"
        {
            "name" "Arms Race Maps"
            "maps"
            {
                "ar_baggage" ""
                "ar_pool_day" ""
                "ar_shoots" ""
            }
        }
        "mg_deathmatch"
        {
            "name" "Deathmatch Maps"
            "maps"
            {
                "de_dust2" ""
                "de_mirage" ""
                "de_inferno" ""
                "de_ancient" ""
                "de_anubis" ""
                "de_nuke" ""
                "de_overpass" ""
            }
        }
        "mg_active"
        {
            "name" "Active Duty Maps"
            "maps"
            {
                "de_dust2" ""
                "de_mirage" ""
                "de_inferno" ""
                "de_ancient" ""
                "de_anubis" ""
                "de_nuke" ""
                "de_overpass" ""
                "de_vertigo" ""
            }
        }
        "mg_wingman"
        {
            "name" "Wingman Maps"
            "maps"
            {
                "de_inferno" ""
                "de_overpass" ""
                "de_vertigo" ""
                "de_nuke" ""
            }
        }
    }
}
MAPGROUPS
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Server installed in: $INSTALL_DIR"
echo ""
echo -e "${CYAN}Game Modes Available:${NC}"
echo "  ./start.sh competitive de_dust2  - Competitive (short)"
echo "  ./start.sh casual de_mirage      - Casual (short)"
echo "  ./start.sh deathmatch de_inferno - Deathmatch (5 min)"
echo "  ./start.sh armsrace ar_shoots    - Gun Game (5 min)"
echo "  ./start.sh wingman de_inferno    - 2v2 (short)"
echo ""
echo -e "${CYAN}Features:${NC}"
echo "  ✓ 5-minute matches for DM/Arms Race"
echo "  ✓ Short rounds for Competitive/Casual"
echo "  ✓ Map voting at end of match"
echo ""
echo -e "${CYAN}Management:${NC}"
echo "  ./stop.sh      - Stop server"
echo "  ./status.sh    - Check if running"
echo "  ./console.sh   - View server console"
echo "  ./gamemode.sh  - Change game mode"
echo "  ./bots.sh      - Manage bots"
echo "  ./update.sh    - Update server"
echo ""
echo "Server will be visible at: Your_Public_IP:27015"
echo ""
