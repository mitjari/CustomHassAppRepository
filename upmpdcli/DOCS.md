# Home Assistant App: upmpdcli

## What it does

Runs [upmpdcli](https://www.lesbonscomptes.com/upmpdcli/) as a UPnP/DLNA media server that fronts a Subsonic-compatible backend (Navidrome, Airsonic, Gonic, …). UPnP renderers such as HEOS and Sonos can then browse and stream the library without speaking Subsonic natively.

This app is a thin wrapper around the upstream [giof71/upmpdcli](https://github.com/GioF71/upmpdcli-docker) image. Defaults are tuned for HEOS browsing; tweak via **Extra config** if needed.

## Configuration

| Option | Required | Description |
| --- | --- | --- |
| `friendly_name` | yes | Name advertised on UPnP (visible in the renderer UI). |
| `subsonic_url` | yes | Base URL of the Subsonic server, e.g. `http://navidrome.local`. |
| `subsonic_port` | yes | TCP port of the Subsonic server. |
| `subsonic_user` | yes | Subsonic account username. |
| `subsonic_password` | yes | Subsonic account password. |
| `subsonic_title` | no | Label shown at the library root. Defaults to `Music`. |
| `extra_config` | no | Extra `upmpdcli.conf` directives, one `key = value` per line. Appended verbatim. |

## Networking

The app runs with `host_network: true` because UPnP/DLNA discovery requires multicast on the LAN. No port mappings are needed.

## Persistence

Upstream's `/cache` (cover-art cache, plugin credentials) lives in a Docker-managed anonymous volume. It survives container restarts but may be rebuilt if Supervisor recreates the container (e.g. on app update). This is only a performance cache — nothing important is lost.

## Troubleshooting

- **Renderer doesn't see the library** — confirm the Home Assistant host has LAN multicast reachable and nothing is firewalling UDP 1900 / 5353.
- **"Artists at root fails" on HEOS** — already mitigated; the wrapper sets `msrootalias = 0$subsonic$`.
- **Playback stutters on a specific renderer** — add `plgproxymethod = proxy` to **Extra config** to override the default `redirect`.
