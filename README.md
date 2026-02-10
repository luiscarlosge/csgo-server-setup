# CS2 Server Setup

Automated CS2 (Counter-Strike 2) dedicated server installation for Ubuntu 22.04/24.04.

## Features

- ✅ **All Game Modes**: Competitive, Casual, Deathmatch, Arms Race (Gun Game), Demolition, Wingman
- ✅ **5-Minute Matches**: Quick games for Deathmatch and Arms Race
- ✅ **Short Matches**: Reduced rounds for Competitive, Casual, and Wingman
- ✅ **Map Voting**: Players vote for next map at end of match
- ✅ **Easy Management**: Simple scripts to start/stop/change modes

## Quick Install

```bash
# Clone the repository
git clone https://github.com/luiscarlosge/csgo-server-setup.git
cd csgo-server-setup

# Run installer (requires GSLT token from Steam)
chmod +x install.sh
./install.sh YOUR_GSLT_TOKEN
```

Get your GSLT token at: https://steamcommunity.com/dev/managegameservers

## Game Modes

| Mode | Command | Duration | Description |
|------|---------|----------|-------------|
| **Arms Race** | `./start.sh armsrace ar_shoots` | 5 min | Gun Game - progress through weapons |
| **Deathmatch** | `./start.sh deathmatch de_dust2` | 5 min | Free-for-all respawn |
| **Competitive** | `./start.sh competitive de_mirage` | ~10 rounds | Short competitive match |
| **Casual** | `./start.sh casual de_inferno` | ~8 rounds | Relaxed rules |
| **Wingman** | `./start.sh wingman de_overpass` | ~8 rounds | 2v2 competitive |
| **Demolition** | `./start.sh demolition de_dust2` | Standard | Mixed mode |

## Maps

### Arms Race
- `ar_baggage`
- `ar_pool_day`
- `ar_shoots`

### Active Duty (Competitive/Casual/DM)
- `de_dust2`, `de_mirage`, `de_inferno`
- `de_ancient`, `de_anubis`, `de_nuke`
- `de_overpass`, `de_vertigo`

### Wingman
- `de_inferno`, `de_overpass`
- `de_vertigo`, `de_nuke`

## Management Scripts

```bash
# Start server
./start.sh <mode> <map> [maxplayers]

# Stop server
./stop.sh

# Check status
./status.sh

# View console
./console.sh

# Change game mode
./gamemode.sh <mode> [map]

# Manage bots
./bots.sh add both 5      # Add 5 bots per team
./bots.sh remove all      # Remove all bots
./bots.sh quota 10        # Auto-fill to 10 players
./bots.sh difficulty 2    # Set difficulty (0-3)

# Update server
./update.sh
```

## Configuration Files

Located in `cfg/`:

| File | Description |
|------|-------------|
| `server.cfg` | Base server settings |
| `gamemode_armsrace.cfg` | Arms Race settings (5 min) |
| `gamemode_deathmatch.cfg` | Deathmatch settings (5 min) |
| `gamemode_casual.cfg` | Casual settings (short) |
| `gamemode_competitive.cfg` | Competitive settings (short) |
| `gamemode_wingman.cfg` | Wingman settings (short) |
| `gamemodes_server.txt` | Map groups for voting |

## Map Voting

Map voting is enabled by default. At the end of each match:
- Players see a vote screen with available maps
- 20 seconds to vote
- Next map is selected based on votes

## Firewall

Open these ports on your firewall/cloud provider:

```bash
# Required
27015/udp  # Game traffic
27015/tcp  # RCON

# Optional
27020/udp  # SourceTV
```

## Azure Setup

1. Create Ubuntu 22.04/24.04 VM (minimum 2 vCPU, 4GB RAM, 80GB disk)
2. Open ports 27015/udp and 27015/tcp
3. SSH in and run the installer
4. Server accessible at `VM_PUBLIC_IP:27015`

## Requirements

- Ubuntu 22.04 or 24.04 (64-bit)
- ~65GB disk space
- 4GB+ RAM recommended
- Steam GSLT token

## Troubleshooting

**Server won't start?**
```bash
# Check for errors
./console.sh

# Verify token
cat ~/cs2-server/.gslt_token
```

**Can't connect?**
```bash
# Check if running
./status.sh

# Verify ports are open
sudo ufw status
```

**Update failed?**
```bash
# Stop and retry
./stop.sh
./update.sh
```

## License

MIT

## Author

Luis Carlos Galvis Espitia
