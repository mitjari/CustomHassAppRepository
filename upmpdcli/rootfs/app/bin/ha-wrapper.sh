#!/bin/bash
# HA app wrapper: render options.json → upmpdcli-additional.txt, then hand off
# to upstream's entrypoint. The upstream image appends anything in
# /user/config/*.txt onto the generated /etc/upmpdcli/upmpdcli.conf at startup.
set -euo pipefail

OPTIONS_FILE="/data/options.json"
CONFIG_DIR="/user/config"
CONFIG_FILE="${CONFIG_DIR}/upmpdcli-additional.txt"
UPSTREAM_ENTRYPOINT="/app/bin/run-upmpdcli.sh"

mkdir -p "${CONFIG_DIR}"

# Persist upstream's /cache across container restarts by pointing it at /data.
mkdir -p /data/cache
if [ ! -L /cache ]; then
    rm -rf /cache
    ln -s /data/cache /cache
fi

if [ -f "${OPTIONS_FILE}" ]; then
    friendly_name=$(jq -r '.friendly_name // "HomeMusicLibrary"' "${OPTIONS_FILE}")
    subsonic_url=$(jq -r '.subsonic_url // empty' "${OPTIONS_FILE}")
    subsonic_port=$(jq -r '.subsonic_port // 4533' "${OPTIONS_FILE}")
    subsonic_user=$(jq -r '.subsonic_user // empty' "${OPTIONS_FILE}")
    subsonic_password=$(jq -r '.subsonic_password // empty' "${OPTIONS_FILE}")
    subsonic_title=$(jq -r '.subsonic_title // "Music"' "${OPTIONS_FILE}")
    extra_config=$(jq -r '.extra_config // empty' "${OPTIONS_FILE}")

    cat > "${CONFIG_FILE}" <<EOF
# Rendered by the Home Assistant upmpdcli app wrapper — do not edit by hand.
# Appended to the image-generated /etc/upmpdcli/upmpdcli.conf (last wins).

msfriendlyname = ${friendly_name}

# Disable the UPnP media renderer; this app is only a Subsonic bridge.
upnpav = 0
openhome = 0

# Land UPnP browsers directly inside the Subsonic plugin (HEOS-friendly).
msrootalias = 0\$subsonic\$

# Subsonic plugin
subsonicuser = ${subsonic_user}
subsonicpassword = ${subsonic_password}
subsonicautostart = 1
subsonicbaseurl = ${subsonic_url}
subsonicport = ${subsonic_port}
subsonictitle = ${subsonic_title}

# HEOS-friendly browsing tweaks
subsonicitemsperpage = 50
subsonicappendyeartoalbumcontainer = 1
subsonicappendyeartoalbumview = 0
subsonicappendyeartoalbumsearchres = 0
subsonicprependnumberinalbumlist = 0
subsonicshowemptyfavorites = 0
subsonicshowemptyplaylists = 0
subsonicallowgenreinalbumcontainer = 0
subsonicallowappendgenreinalbumview = 0
subsonicartistalbumnewestfirst = 1

# Cover-art caching
webserverdocumentroot = 1
subsonicenableimagecaching = 1
subsonicenablecachedimageagelimit = 1
subsoniccachedimagemaxagedays = 30
subsonicallowartistcoverart = 0

# Streaming: HEOS handles HTTP 302 fine; switch to "proxy" if a renderer trips.
plgproxymethod = redirect
EOF

    if [ -n "${extra_config}" ]; then
        printf '\n# --- extra_config from HA options ---\n%s\n' "${extra_config}" >> "${CONFIG_FILE}"
    fi
fi

exec "${UPSTREAM_ENTRYPOINT}" "$@"
