# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Home Assistant **apps** repository (custom store) — not integrations and not classic add-ons. See https://developers.home-assistant.io/docs/apps. `repository.yaml` is the store manifest; each top-level directory (e.g. `example/`, `upmpdcli/`) is a single app.

**Distribution model: build-on-device, not publish-to-registry.** No `image:` key in any app's `config.yaml`. Supervisor clones this repo on each HA device and builds the Dockerfile locally. There are no image-publishing CI workflows — only linting runs in CI. The `upmpdcli/` app relies on this: it `FROM`s `giof71/upmpdcli` and layers a wrapper on top.

## App anatomy

Each app directory is self-contained:

- `config.yaml` — app manifest (`name`, `version`, `slug`, `arch`, `options`, `schema`). `slug` **must** equal the directory name. Supervisor detects updates by comparing the git-repo `version:` against installed; bump it (and add a `CHANGELOG.md` entry) on every change you want devices to pick up.
- `Dockerfile` — either `FROM ghcr.io/home-assistant/base:<ver>` with an s6-overlay service tree (`example/`), or `FROM` an upstream image with a thin wrapper entrypoint (`upmpdcli/`). Both patterns are valid.
- `rootfs/` — everything under this dir is `COPY`'d to `/` in the image. For s6-style apps: services live at `rootfs/etc/services.d/<slug>/run`. For wrapper-style apps: the wrapper script lives wherever the image expects (e.g. `rootfs/app/bin/ha-wrapper.sh` for upmpdcli).
- `translations/<lang>.yaml` — option labels shown in the HA options UI.
- `apparmor.txt` (optional), `icon.png`, `logo.png`, `DOCS.md`, `README.md`, `CHANGELOG.md`.

The wrapper pattern (upmpdcli): entrypoint reads HA options from `/data/options.json` with `jq`, renders them into the format the upstream binary expects, then `exec`s upstream's original entrypoint. Use this when wrapping a maintained upstream image beats reimplementing it on `home-assistant/base`.

## Local development

Dev loop is the HA devcontainer (`.devcontainer.json` → `ghcr.io/home-assistant/devcontainer:5-apps`) driving the Supervisor. VS Code tasks (`.vscode/tasks.json`):

- **Start Home Assistant** — `supervisor_run` (boots Supervisor inside the devcontainer).
- **Install App** — `ha apps install "local_<slug>"` (note the `local_` prefix for local-mode apps).
- **Start App** — stop/start + tail logs.
- **Rebuild and Start App** — `ha apps rebuild --force` then start + tail logs. Use after any Dockerfile/rootfs change.

The `appName` picker in `tasks.json` is a hardcoded list — **when adding a new app, add its slug to the `options` array** or it won't appear in the picker.

## CI

Only `.github/workflows/lint.yaml` runs: `frenck/action-addon-linter` on every discovered app directory (auto-discovered via `home-assistant/actions/helpers/find-addons`). No build/publish workflows exist by design — see distribution model above.

## Update flow on a device

1. Bump `version:` in the app's `config.yaml`, add a changelog entry, push to `main`.
2. On the device, Supervisor periodically re-clones the repo (trigger immediately via UI **Reload** or `ha store reload`).
3. Supervisor compares the refreshed `version:` to what's installed; newer → "Update available" in UI.
4. User clicks update (or `ha apps update local_<slug>`) → Supervisor rebuilds the image from the Dockerfile and restarts the container.

Without a version bump, pushed changes are invisible to the device.

## Adding a new app

1. Copy `example/` to a new directory named after the app's slug.
2. Edit `config.yaml`: set `name`, `slug` (= dir name), `version` `1.0.0`, the `options`/`schema` pair. Do **not** add an `image:` key.
3. Rewrite the Dockerfile and `rootfs/` for your app (s6-style or wrapper-style).
4. Add the slug to the `appName` picker in `.vscode/tasks.json`.
5. Refresh `CHANGELOG.md`, `icon.png`, `logo.png`, `translations/en.yaml`, `DOCS.md`, `README.md`.
6. List the app in the root `README.md`.
