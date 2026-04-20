<!-- https://developers.home-assistant.io/docs/apps/presentation#keeping-a-changelog -->
## 1.0.3

- Clean up baked config: drop options that matched plugin defaults (`appendyeartoalbumcontainer`, `appendyeartoalbumview`, `prependnumberinalbumlist`, `showemptyfavorites`, `showemptyplaylists`, `allowgenreinalbumcontainer`, `artistalbumnewestfirst`, `subsonicautostart`). Remove two silently-ignored legacy names: `subsonicappendyeartoalbumsearchres` (actual: `…searchresult`) and `subsonicallowappendgenreinalbumview` (actual: `allowgenreinalbumview`) — both also matched defaults. Result: config file is shorter and every remaining line is a real override.

## 1.0.2

- Flatten HEOS browse hierarchy: bake `subsonicdisablenavigablealbum = 1` (drops the "Focus" layer between album and tracks) and `subsonicmaxartistsperpage = 500` (defeats A-Z letter paging for typical library sizes) into the default config. The "ArtistRoles" intermediate (Artist/AlbumArtist/Composer) remains — no upstream config knob for it.

## 1.0.1

- Drop the `/cache` → `/data/cache` symlink attempt. `/cache` is declared as a VOLUME in the upstream image and is already mounted when the entrypoint runs, so `rm -rf /cache` failed with "Device or resource busy". Cover-art cache now lives in Docker's anonymous volume.

## 1.0.0

- Initial release. Wraps `giof71/upmpdcli` as a Home Assistant app with Subsonic/HEOS-tuned defaults.
