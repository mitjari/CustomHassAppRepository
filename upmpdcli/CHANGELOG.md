<!-- https://developers.home-assistant.io/docs/apps/presentation#keeping-a-changelog -->
## 1.0.1

- Drop the `/cache` → `/data/cache` symlink attempt. `/cache` is declared as a VOLUME in the upstream image and is already mounted when the entrypoint runs, so `rm -rf /cache` failed with "Device or resource busy". Cover-art cache now lives in Docker's anonymous volume.

## 1.0.0

- Initial release. Wraps `giof71/upmpdcli` as a Home Assistant app with Subsonic/HEOS-tuned defaults.
