# CS2 Server Setup for Ubuntu (Azure)

Scripts para instalar y administrar un servidor dedicado de Counter-Strike 2 en Ubuntu.

## 🎮 Características

- ✅ Instalación automatizada de SteamCMD y CS2
- ✅ Todos los mapas predeterminados del juego
- ✅ Cambio fácil entre modos de juego
- ✅ Gestión de bots (añadir, quitar, dificultad)
- ✅ Scripts de administración incluidos
- ✅ Compatible con Ubuntu 22.04/24.04 en Azure

## 📋 Requisitos Previos

1. **Máquina Virtual Ubuntu** (22.04 o 24.04 LTS)
   - Mínimo: 2 vCPUs, 4GB RAM, 50GB disco
   - Recomendado: 4 vCPUs, 8GB RAM, 100GB disco

2. **Steam Game Server Login Token (GSLT)**
   - Obtener en: https://steamcommunity.com/dev/managegameservers
   - App ID para CS2: `730`

3. **Puertos abiertos** (firewall/NSG de Azure):
   - `27015/tcp` - Conexión de jugadores
   - `27015/udp` - Conexión de jugadores
   - `27020/udp` - SourceTV (opcional)
   - `27005/udp` - Cliente Steam

## 🚀 Instalación Rápida

```bash
# Clonar repositorio
git clone https://github.com/luiscarlosge/csgo-server-setup.git
cd csgo-server-setup

# Ejecutar instalación (reemplaza TOKEN con tu GSLT)
chmod +x install.sh
./install.sh YOUR_GSLT_TOKEN
```

La instalación descargará ~35GB, puede tomar 15-30 minutos.

## 🎯 Uso

### Iniciar el Servidor

```bash
cd ~/cs2-server

# Iniciar con configuración por defecto (competitive, de_dust2)
./start.sh

# Iniciar con modo y mapa específico
./start.sh competitive de_mirage
./start.sh casual de_inferno
./start.sh deathmatch de_dust2
```

### Comandos Básicos

| Comando | Descripción |
|---------|-------------|
| `./start.sh [modo] [mapa]` | Iniciar servidor |
| `./stop.sh` | Detener servidor |
| `./status.sh` | Ver estado del servidor |
| `./console.sh` | Acceder a la consola |
| `./update.sh` | Actualizar CS2 |
| `./gamemode.sh` | Cambiar modo de juego |
| `./bots.sh` | Gestionar bots |

## 🎮 Modos de Juego

```bash
./gamemode.sh <modo> [mapa]
```

| Modo | Descripción |
|------|-------------|
| `competitive` | Competitivo clásico (5v5, 30 rondas) |
| `casual` | Casual (10v10, reglas relajadas) |
| `deathmatch` | Deathmatch libre |
| `armsrace` | Carrera de armas |
| `demolition` | Demolición |
| `wingman` | Wingman (2v2) |

### Ejemplos

```bash
./gamemode.sh competitive de_mirage    # Competitivo en Mirage
./gamemode.sh deathmatch de_dust2      # Deathmatch en Dust2
./gamemode.sh wingman de_inferno       # Wingman en Inferno
```

## 🤖 Gestión de Bots

```bash
./bots.sh <comando> [opciones]
```

| Comando | Descripción |
|---------|-------------|
| `add <team> [n]` | Añadir bots (t/ct/both) |
| `remove <team\|all>` | Quitar bots |
| `difficulty <0-3>` | Dificultad (0=fácil, 3=experto) |
| `quota <n>` | Mantener n jugadores (rellena con bots) |
| `stop` | Desactivar bots |

### Ejemplos

```bash
./bots.sh add ct 3          # Añadir 3 bots CT
./bots.sh add both 5        # Añadir 5 bots a cada equipo
./bots.sh remove all        # Quitar todos los bots
./bots.sh difficulty 2      # Dificultad media-alta
./bots.sh quota 10          # Mantener 10 jugadores total
```

## 🗺️ Mapas Disponibles

### Mapas de Defusa
- `de_dust2` - Dust II (clásico)
- `de_mirage` - Mirage
- `de_inferno` - Inferno
- `de_nuke` - Nuke
- `de_overpass` - Overpass
- `de_ancient` - Ancient
- `de_anubis` - Anubis
- `de_vertigo` - Vertigo

### Mapas de Rehenes
- `cs_office` - Office
- `cs_italy` - Italy

### Mapas Wingman
- `de_inferno`
- `de_overpass`
- `de_vertigo`
- `de_nuke`

## ⚙️ Configuración Avanzada

### Editar configuración del servidor

```bash
nano ~/cs2-server/game/csgo/cfg/server.cfg
```

### Configuraciones importantes

```
hostname "Mi Servidor CS2"      # Nombre del servidor
rcon_password "tu_password"     # Contraseña de admin remoto
sv_password "password"          # Contraseña para entrar (vacío = público)
```

### Cambiar GSLT Token

```bash
echo "NUEVO_TOKEN" > ~/cs2-server/.gslt_token
```

## 🔧 Solución de Problemas

### El servidor no inicia
```bash
# Verificar logs
screen -r cs2server

# Reinstalar/actualizar
./update.sh
```

### No aparece en la lista de servidores
- Verificar que el GSLT token sea válido
- Verificar puertos abiertos en Azure NSG
- El servidor tarda unos minutos en aparecer

### Desconexiones frecuentes
```bash
# Editar server.cfg y ajustar rates
sv_maxrate 0
sv_minrate 128000
```

## 📊 Monitoreo

```bash
# Ver si está corriendo
./status.sh

# Ver uso de recursos
htop

# Ver conexiones activas
netstat -an | grep 27015
```

## 🔄 Actualizaciones

CS2 se actualiza frecuentemente. Para actualizar:

```bash
./update.sh
```

Esto detendrá el servidor, descargará actualizaciones y podrás reiniciarlo después.

## 📝 Licencia

MIT License - Libre para usar y modificar.

## 🙏 Créditos

- Valve Software por CS2
- SteamCMD
- Comunidad de servidores de CS
