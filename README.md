<img src="Resources/README-AppIcon.png" width=64 />

# Higitus Figitus

Ever dreamt to automatically organize your Transmission download folder? Then please say a warm welcome to Higitus Figitus !

This tool is built as a static binary, meant to run as Transmission's `script-torrent-done` hook, but you can also run it manually when needed.

It will parse your download filenames via [hunch](https://github.com/nazo6/hunch), fetch missing subtitles from [OpenSubtitles](https://www.opensubtitles.com), then move files to their dedicated folders with a reasonable structure.

### Config

All configuration is via `HIGITUS_*` environment variables, with matching `--flag` equivalents (a flag always wins over the environment). A `.env` or `higitus.env` file in the current directory is also read at startup.

| Flag | Environment variable | Required | Default | Description |
|---|---|---|---|---|
| `--path` | `HIGITUS_PATH` | Yes | — | Folder to organize |
| `--movies-path` | `HIGITUS_MOVIES_PATH` | Yes | — | Movies library folder (must already exist) |
| `--shows-path` | `HIGITUS_SHOWS_PATH` | Yes | — | Shows library folder (must already exist) |
| `--shows-folder-creation` | `HIGITUS_SHOWS_FOLDER_CREATION` | No | `seasonOnly` | `always` creates any missing folder; `seasonOnly` only auto-creates a trailing `Season N` folder — a brand-new show's own folder must already exist |
| `--subtitles-locales` | `HIGITUS_SUBTITLES_LOCALES` | No | `en,fr` | Comma-separated list of subtitle languages to ensure are present |
| `--opensubtitles-api-key` | `HIGITUS_OPENSUBTITLES_API_KEY` | Yes | — | OpenSubtitles API consumer key |
| `--opensubtitles-username` | `HIGITUS_OPENSUBTITLES_USERNAME` | Yes | — | OpenSubtitles account username |
| `--opensubtitles-password` | `HIGITUS_OPENSUBTITLES_PASSWORD` | Yes | — | OpenSubtitles account password |
| `--log-level` | `HIGITUS_LOG_LEVEL` | No | `info` | `debug`, `info`, `warning`, or `error` |

### Usage

```sh
OVERVIEW: Organizes your download folder.

USAGE: higitus <subcommand>

OPTIONS:
  --version               Show the version.
  -h, --help              Show help information.

SUBCOMMANDS:
  init                    Sets this script as a post-download hook
  figitus (default)       Organizes the given folder

  See 'higitus help <subcommand>' for detailed help.
```

Running `higitus` with no subcommand runs `figitus` directly (via `defaultSubcommand`) — this is what lets it be pointed at as a bare binary path from Transmission with no wrapper script needed.

### Setup

Higitus is meant to be bind-mounted straight into the stock `linuxserver/transmission`, here is how.

1. Mount required paths:

    - the `higitus` binary, e.g.: at `/usr/local/bin/higitus`
    - the `hunch` binary, e.g.: at `/usr/local/bin/hunch`
    - your movie storage, e.g.: `/mnt/data/Movies` to `/movies`
    - your shows storage, e.g.: `/mnt/data/Shows` to `/shows`

2. Create the following init script, and mount it at `/custom-cont-init.d/init-override.sh`

    ```sh
    #!/bin/sh
    set -e
    echo "------------"
  
    # gcompat is required for hunch, ffmpeg is required to use ffprobe and avoid download subtitles already embedded in the video file.
    apk add --no-cache gcompat ffmpeg
  
    # ensure higitus and hunch are executable
    chmod +x /usr/local/bin/higitus /usr/local/bin/hunch
  
    # `higitus init` patches `settings.json`'s `script-torrent-done-enabled`/`script-torrent-done-filename` to point at the bare binary path.
    /usr/local/bin/higitus init --transmission-config-path /config/settings.json
    echo "------------"
    ```

3. Configure your environment:

    - `HIGITUS_PATH=/downloads/done`
    - `HIGITUS_MOVIES_PATH=/movies`
    - `HIGITUS_SHOWS_PATH=/shows`
    - `HIGITUS_SHOWS_FOLDER_CREATION=always`
    - `HIGITUS_SUBTITLES_LOCALES=en,fr`
    - `HIGITUS_OPENSUBTITLES_API_KEY=...`
    - `HIGITUS_OPENSUBTITLES_USERNAME=...`
    - `HIGITUS_OPENSUBTITLES_PASSWORD=...`
    - `HIGITUS_LOG_LEVEL=info`

### License

MPL-2.0
