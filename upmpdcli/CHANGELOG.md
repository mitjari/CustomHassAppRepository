<!-- https://developers.home-assistant.io/docs/apps/presentation#keeping-a-changelog -->
## 1.0.6

- Replace the default "Artists" root tile (hardwired to the ArtistRoles → A-Z initial → Artist chain, not defeated by `maxartistsperpage`) with the flat `ALL_ARTISTS_UNSORTED` tile via `subsonictaginitialpageenabledARTISTS = 0` / `…ALL_ARTISTS_UNSORTED = 1`. Clicking the resulting "All Artists" tile goes straight to a paginated artist list; combined with `subsonicmaxartistsperpage = 500` the list fits on one page for typical libraries. The upstream plugin has no knob for the `ARTIST_FOCUS` intermediate between an artist and their albums — that layer remains.

## 1.0.5

- Fix: bake `subsonicpreloadsongs = 0` to stop `sqlite3.OperationalError: database is locked` during early browsing. The plugin's three-stage preload writes artists → albums → songs into its SQLite cache; the song stage writes thousands of rows over ~30s and its `BEGIN IMMEDIATE` write locks collide with the browse-path identifier encoder (also a writer). Artist/album preload is fast and still runs; tracks are fetched on-demand when an album is opened.

## 1.0.4

- Fix: move inline comments off the same line as config values. upmpdcli's parser reads everything after `=` verbatim (no trailing-`#` stripping), so `subsonicitemsperpage = 50    # plugin default 20` was parsed as the value `"50             # plugin default 20"` and crashed the subsonic plugin with `ValueError: invalid literal for int()`.

## 1.0.3

- Clean up baked config: drop options that matched plugin defaults (`appendyeartoalbumcontainer`, `appendyeartoalbumview`, `prependnumberinalbumlist`, `showemptyfavorites`, `showemptyplaylists`, `allowgenreinalbumcontainer`, `artistalbumnewestfirst`, `subsonicautostart`). Remove two silently-ignored legacy names: `subsonicappendyeartoalbumsearchres` (actual: `…searchresult`) and `subsonicallowappendgenreinalbumview` (actual: `allowgenreinalbumview`) — both also matched defaults. Result: config file is shorter and every remaining line is a real override.

## 1.0.2

- Flatten HEOS browse hierarchy: bake `subsonicdisablenavigablealbum = 1` (drops the "Focus" layer between album and tracks) and `subsonicmaxartistsperpage = 500` (defeats A-Z letter paging for typical library sizes) into the default config. The "ArtistRoles" intermediate (Artist/AlbumArtist/Composer) remains — no upstream config knob for it.

## 1.0.1

- Drop the `/cache` → `/data/cache` symlink attempt. `/cache` is declared as a VOLUME in the upstream image and is already mounted when the entrypoint runs, so `rm -rf /cache` failed with "Device or resource busy". Cover-art cache now lives in Docker's anonymous volume.

## 1.0.0

- Initial release. Wraps `giof71/upmpdcli` as a Home Assistant app with Subsonic/HEOS-tuned defaults.
