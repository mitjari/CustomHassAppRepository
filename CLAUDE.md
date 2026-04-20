# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Home Assistant **apps** repository (custom store) — not integrations and not classic add-ons. See https://developers.home-assistant.io/docs/apps. `repository.yaml` is the store manifest; each top-level directory (e.g. `example/`) is a single app that gets built into a multi-arch OCI image and consumed by the Supervisor.

## App anatomy

Each app directory is self-contained and has this shape:

- `config.yaml` — app manifest (`name`, `version`, `slug`, `arch`, `options`, `schema`, `image`). `slug` **must** equal the directory name. Bumping `version` triggers a rebuild on push to `main`; update `CHANGELOG.md` alongside.
- `Dockerfile` — built `FROM ghcr.io/home-assistant/base:<ver>`; `COPY rootfs /` lays the s6-overlay service tree on top of the base image.
- `rootfs/etc/services.d/<slug>/run` — s6-overlay service entrypoint, written in `bashio`. Reads user config via `bashio::config '<key>'` (keys match `options`/`schema` in `config.yaml`) and `exec`s the actual program.
- `rootfs/usr/bin/<binary>` — the actual program the service runs.
- `translations/<lang>.yaml` — UI strings for the options schema.
- `apparmor.txt`, `icon.png`, `logo.png`, `DOCS.md`, `README.md`, `CHANGELOG.md` — standard sidecar files.

## Local development

The canonical dev loop is the Home Assistant devcontainer (`.devcontainer.json` → `ghcr.io/home-assistant/devcontainer:5-apps`) driving the Supervisor. Tasks in `.vscode/tasks.json`:

- **Start Home Assistant** — `supervisor_run` (boots the Supervisor inside the devcontainer).
- **Install App** — `ha apps install "local_<appName>"` (note the `local_` prefix — local-mode slug).
- **Start App** — `ha apps stop/start` + `ha apps logs -f`.
- **Rebuild and Start App** — `ha apps rebuild --force` then start + tail logs. Use this after Dockerfile/rootfs changes.

The `appName` picker in `tasks.json` is a hardcoded list — **when adding a new app directory, also add its slug to the `options` array** in `.vscode/tasks.json` or it won't appear in the picker.

**While iterating locally, comment out the `image:` key in the app's `config.yaml`** so the Supervisor builds locally instead of pulling from the registry. Restore it before pushing.

## CI / builds

Two workflows in `.github/workflows/`:

- `builder.yaml` (push/PR to `main`): diffs changed files against `MONITORED_FILES` (`config.json config.yaml config.yml Dockerfile rootfs`) per app directory, then fans out to `build-app.yaml` only for apps that actually changed. If `builder.yaml` or `build-app.yaml` themselves change, **all** apps rebuild. `publish: true` only on `push`, not PRs.
- `build-app.yaml` — multi-arch build via `home-assistant/builder`, pushes to the registry defined by `image:` in `config.yaml` with tags `<version>` and `latest`. Gated by `if: github.repository == 'mitjari/CustomHassAppRepository'` — keep this guard in sync if the repo is ever renamed, otherwise the build job is silently skipped.
- `lint.yaml` — runs `frenck/action-addon-linter` on every discovered app directory (matrix is auto-discovered via `home-assistant/actions/helpers/find-addons`).

## Adding a new app

1. Copy `example/` to a new directory named after the app's slug.
2. Edit `config.yaml`: set `name`, `slug` (= dir name), `version` starting at `1.0.0`, `image` pointing at your ghcr namespace, and the `options`/`schema` pair.
3. Rename the s6 service directory: `rootfs/etc/services.d/example/` → `rootfs/etc/services.d/<slug>/`.
4. Replace `rootfs/usr/bin/my_program` with the real program; update `run` to `exec` it.
5. Add the slug to the `appName` picker in `.vscode/tasks.json`.
6. Create/refresh `CHANGELOG.md`, `icon.png`, `logo.png`, `translations/en.yaml`.
