#!/bin/bash

PORT=${PORT-7787}
QUERYPORT=${QUERYPORT-27165}
RCONPORT=${RCONPORT-21114}
FIXEDMAXPLAYERS=${FIXEDMAXPLAYERS-80}
FIXEDMAXTICKRATE=${FIXEDMAXTICKRATE-50}
RANDOM=${RANDOM-NONE}

if [ -n "${STEAM_BETA_BRANCH}" ]; then
  echo "Loading Steam Beta Branch"
  bash "${STEAMCMDDIR}/steamcmd.sh" \
    +@sSteamCmdForcePlatformType windows \
    +force_install_dir "${STEAMAPPDIR}" \
    +login anonymous \
    +app_update "${STEAM_BETA_APP}" \
    -beta "${STEAM_BETA_BRANCH}" \
    -betapassword "${STEAM_BETA_PASSWORD}" \
    +quit
else
  echo "Loading Steam Release Branch"
  bash "${STEAMCMDDIR}/steamcmd.sh" \
    +@sSteamCmdForcePlatformType windows \
    +force_install_dir "${STEAMAPPDIR}" \
    +login anonymous \
    +app_update "${STEAMAPPID}" \
    +quit
fi

# Change rcon port on first launch, because the default config overwrites the commandline parameter (you can comment this out if it has done it's purpose)
sed -i -e 's/Port=21114/'"Port=${RCONPORT}"'/g' "${STEAMAPPDIR}/SquadGame/ServerConfig/Rcon.cfg"

echo "Clearing Mods..."
# Clear all workshop mods:
# find all folders / files in mods folder which are numeric only;
# remove the workshop mods
if [ -f "${MODPATH}" ]; then
  find "${MODPATH}"/* -maxdepth 0 -regextype posix-egrep -regex ".*/[[:digit:]]+" | xargs -0 -d"\n" rm -R 2>/dev/null
fi

install_mod() {
  modid="$1"
  "${STEAMCMDDIR}/steamcmd.sh" \
    +@sSteamCmdForcePlatformType windows \
    +force_install_dir "${STEAMAPPDIR}" +login anonymous +workshop_download_item "${WORKSHOPID}" "${modid}" validate +quit
  if [ $? -eq 0 ]; then
    echo "> Mod installed"
  else
    echo "> Failed to install mod, non zero exit code, retrying"
    install_mod "$1"
  fi
}

# Install mods (if defined)
declare -a MODS="${MODS}"
if ((${#MODS[@]})); then
  echo "Installing Mods..."
  for MODID in "${MODS[@]}"; do
    echo "> Install mod '${MODID}'"

    install_mod "$MODID"

    echo -e "\n> Link mod content '${MODID}'"
    ln -s "${STEAMAPPDIR}/steamapps/workshop/content/${WORKSHOPID}/${MODID}" "${MODPATH}/${MODID}"
  done
fi

port_arg="Port=${PORT}"
query_port_arg="QueryPort=${QUERYPORT}"
rcon_port_arg="RCONPORT=${RCONPORT}"
fixed_max_players_arg="FIXEDMAXPLAYERS=${FIXEDMAXPLAYERS}"
fixed_max_tickrate_arg="FIXEDMAXTICKRATE=${FIXEDMAXTICKRATE}"
random_arg="RANDOM=${RANDOM}"

beacon_port_arg=""
if [[ -v BEACONPORT ]]; then
  beacon_port_arg="beaconport=${BEACONPORT}"
fi

crash_dump_arg=""
if [[ -v FULLCRASHDUMP ]]; then
  crash_dump_arg="-fullcrashdump"
fi

wine "${STEAMAPPDIR}/SquadGameServer.exe" \
  "$port_arg" \
  "$query_port_arg" \
  "$rcon_port_arg" \
  "$beacon_port_arg" \
  "$fixed_max_players_arg" \
  "$fixed_max_tickrate_arg" \
  "$random_arg" \
  "$crash_dump_arg" \
  "\nogui"
