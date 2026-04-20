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
# Only non-default overrides are set here; plugin defaults are left alone.

# ─── Identity & services ───
msfriendlyname = ${friendly_name}

# Act only as a UPnP Media Server (Subsonic bridge), not a Media Renderer.
upnpav = 0
openhome = 0

# Land UPnP browsers directly inside the Subsonic plugin — HEOS "Artists at
# root" fix.
msrootalias = 0\$subsonic\$

# ─── Subsonic plugin connection ───
subsonicuser = ${subsonic_user}
subsonicpassword = ${subsonic_password}
subsonicbaseurl = ${subsonic_url}
subsonicport = ${subsonic_port}
subsonictitle = ${subsonic_title}

# ─── Browsing tweaks ───
subsonicitemsperpage = 50
subsonicallowartistcoverart = 0
subsonicpreloadsongs = 0
subsonictaginitialpageenabledALL_ARTISTS_UNSORTED = 1
subsonictaginitialpageenabledARTISTS = 0
subsonicmaxartistsperpage = 500
subsonicdisablenavigablealbum = 1

# ─── Cover-art cache ───
subsonicenableimagecaching = 1
subsonicenablecachedimageagelimit = 1
subsoniccachedimagemaxagedays = 30
EOF

    if [ -n "${extra_config}" ]; then
        printf '\n# --- extra_config from HA options ---\n%s\n' "${extra_config}" >> "${CONFIG_FILE}"
    fi
fi

exec "${UPSTREAM_ENTRYPOINT}" "$@"
