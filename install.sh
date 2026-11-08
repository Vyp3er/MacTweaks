#!/bin/bash
# MacTweaks-Installer
#
# Lädt die neuesten Versionen von KeyFlow, TidyMac, MacBuddy und NotchIsland
# aus den GitHub-Releases und legt sie in den Programme-Ordner.
#
#   curl -fsSL https://raw.githubusercontent.com/Vyp3er/MacTweaks/main/install.sh | bash
#   curl -fsSL … | bash -s -- TidyMac NotchIsland   # nur bestimmte Apps
#   curl -fsSL … | bash -s -- --list                # nur anzeigen, was es gibt
#
# Ohne sudo. Jede ZIP wird gegen die SHA-256 von GitHub geprüft, die Signatur der
# App wird kontrolliert, und eine ältere Version landet im Papierkorb, nichts
# wird endgültig gelöscht. Apps, die auf diesem Mac nicht laufen (macOS zu alt,
# Intel statt Apple Silicon), werden übersprungen.
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Vincent Schmitt

set -o pipefail

OWNER="Vyp3er"
APPS=(KeyFlow TidyMac MacBuddy NotchIsland)

DEST=""
FORCE=0
LIST_ONLY=0
LAUNCH=1
TARGETS=()
INSTALLED=()
CURRENT=()
SKIPPED=()
FAILED=()
TMP=""

say()  { printf '%s\n' "$*"; }
info() { printf '   %s\n' "$*"; }
warn() { printf '   ⚠︎  %s\n' "$*"; }

usage() {
    cat <<EOF
MacTweaks-Installer: installiert ${APPS[*]}

Aufruf: install.sh [Optionen] [App …]

  App …          nur diese Apps installieren (Standard: alle)
  --list         nur anzeigen, welche Versionen verfügbar und installiert sind
  --dest ORDNER  Zielordner (Standard: /Applications, sonst ~/Applications)
  --force        auch installieren, wenn die Version schon aktuell ist
  --no-launch    aktualisierte Apps danach nicht wieder starten
  -h, --help     diese Hilfe

Beispiel: curl -fsSL https://raw.githubusercontent.com/$OWNER/MacTweaks/main/install.sh | bash -s -- TidyMac
EOF
}

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

canonical_name() {
    local a
    for a in "${APPS[@]}"; do
        if [[ "$(lower "$a")" == "$(lower "$1")" ]]; then printf '%s' "$a"; return 0; fi
    done
    return 1
}

guide_url() {
    case "$1" in
        NotchIsland) printf 'https://github.com/%s/NotchIsland/blob/main/INSTALLATION.md' "$OWNER" ;;
        *)           printf 'https://github.com/%s/%s/blob/main/INSTALL.md' "$OWNER" "$1" ;;
    esac
}

# Nur lesen: PlistBuddy würde eine fehlende Datei sonst anlegen.
plist_get() { [[ -f "$1" ]] || return 1; /usr/libexec/PlistBuddy -c "Print :$2" "$1" 2>/dev/null; }

# "v1.2.0" → "1.2"
norm_version() {
    local v="${1#[vV]}"
    v="${v%%[-+ ]*}"
    while [[ "$v" == *.0 ]]; do v="${v%.0}"; done
    printf '%s' "$v"
}

# version_ge A B: ist A >= B?
version_ge() {
    local IFS=.
    local -a a=($1) b=($2)
    local i n=${#a[@]} x y
    (( ${#b[@]} > n )) && n=${#b[@]}
    for (( i = 0; i < n; i++ )); do
        x=${a[i]:-0}; y=${b[i]:-0}
        x=${x//[^0-9]/}; y=${y//[^0-9]/}
        x=${x:-0}; y=${y:-0}
        (( 10#$x > 10#$y )) && return 0
        (( 10#$x < 10#$y )) && return 1
    done
    return 0
}

is_apple_silicon() { [[ "$(sysctl -n hw.optional.arm64 2>/dev/null)" == 1 ]]; }

# Läuft die Programmdatei auf diesem Mac?
arch_ok() {
    local desc
    desc=$(file -b "$1" 2>/dev/null)
    if is_apple_silicon; then
        [[ "$desc" == *arm64* || "$desc" == *x86_64* ]]
    else
        [[ "$desc" == *x86_64* ]]
    fi
}

regex_escape() { printf '%s' "$1" | sed -e 's/[][\.*^$+?(){}|]/\\&/g'; }

# PIDs der Prozesse, die genau aus diesem App-Bundle laufen
running_pids() {
    local exe
    exe=$(plist_get "$1/Contents/Info.plist" CFBundleExecutable) || return 0
    [[ -n "$exe" ]] || return 0
    pgrep -f -- "^$(regex_escape "$1/Contents/MacOS/$exe")( |$)" 2>/dev/null
}

setup_tmp() {
    TMP=$(mktemp -d "${TMPDIR:-/tmp}/mactweaks.XXXXXX") || { say "Kein temporärer Ordner möglich."; exit 1; }
    trap 'rm -rf "$TMP"' EXIT

    # Release-JSON lesen: Tag, Asset-Name, Download-URL, Digest (tab-getrennt)
    cat > "$TMP/release.js" <<'JS'
ObjC.import('Foundation');
function run(argv) {
    const s = $.NSString.stringWithContentsOfFileEncodingError(argv[0], $.NSUTF8StringEncoding, null);
    if (s.isNil()) return '';
    let r;
    try { r = JSON.parse(s.js); } catch (e) { return ''; }
    if (!r || !r.tag_name) return '';
    const want = argv[1].toLowerCase();
    const zips = (r.assets || []).filter(a => /\.zip$/i.test(a.name));
    const a = zips.find(z => z.name.toLowerCase().startsWith(want)) || zips[0];
    if (!a) return [r.tag_name, '', '', ''].join('\t');
    return [r.tag_name, a.name, a.browser_download_url, a.digest || ''].join('\t');
}
JS

    # In den Papierkorb legen (wie im Finder), gibt bei Erfolg "ok" aus
    cat > "$TMP/trash.js" <<'JS'
ObjC.import('Foundation');
function run(argv) {
    const ok = $.NSFileManager.defaultManager.trashItemAtURLResultingItemURLError($.NSURL.fileURLWithPath(argv[0]), null, null);
    return ok ? 'ok' : '';
}
JS

    # Genau diesen Prozess normal beenden (wie „Beenden“ im Menü)
    cat > "$TMP/quit.js" <<'JS'
ObjC.import('AppKit');
function run(argv) {
    const app = $.NSRunningApplication.runningApplicationWithProcessIdentifier(parseInt(argv[0], 10));
    if (app.isNil()) return 'gone';
    return app.terminate ? 'ok' : 'fail';
}
JS
}

trash_item() { osascript -l JavaScript "$TMP/trash.js" "$1" </dev/null 2>/dev/null; }

quit_app() {
    local pid
    for pid in $(running_pids "$1"); do
        osascript -l JavaScript "$TMP/quit.js" "$pid" </dev/null >/dev/null 2>&1
    done
    local i
    for (( i = 0; i < 40; i++ )); do
        [[ -z "$(running_pids "$1")" ]] && return 0
        sleep 0.5
    done
    return 1
}

process_app() {
    local app="$1"
    local json="$TMP/$app.json" code release tag asset url digest
    say ""
    say "■ $app"

    code=$(curl -sSL --retry 3 --retry-delay 2 -o "$json" -w '%{http_code}' \
        -H 'Accept: application/vnd.github+json' \
        "https://api.github.com/repos/$OWNER/$app/releases/latest" </dev/null)
    if [[ $? -ne 0 ]]; then warn "GitHub ist nicht erreichbar."; FAILED+=("$app"); return; fi
    case "$code" in
        200) ;;
        404) info "Noch kein Release veröffentlicht: https://github.com/$OWNER/$app"; SKIPPED+=("$app"); return ;;
        403|429) warn "GitHub-Anfragelimit erreicht. Bitte in einer Stunde noch einmal versuchen."; FAILED+=("$app"); return ;;
        *) warn "GitHub antwortet mit Status $code."; FAILED+=("$app"); return ;;
    esac

    release=$(osascript -l JavaScript "$TMP/release.js" "$json" "$app" </dev/null 2>/dev/null)
    IFS=$'\t' read -r tag asset url digest <<< "$release"
    if [[ -z "$tag" ]]; then warn "Die Release-Daten sind unlesbar."; FAILED+=("$app"); return; fi
    if [[ -z "$url" ]]; then warn "Release $tag enthält keine ZIP-Datei."; FAILED+=("$app"); return; fi

    local latest target="$DEST/$app.app" installed=""
    latest=$(norm_version "$tag")
    [[ -d "$target" ]] && installed=$(plist_get "$target/Contents/Info.plist" CFBundleShortVersionString)

    if (( LIST_ONLY )); then
        info "verfügbar:   ${tag#[vV]} ($asset)"
        info "installiert: ${installed:-–}"
        return
    fi

    if [[ -n "$installed" && $FORCE -eq 0 ]] && version_ge "$(norm_version "$installed")" "$latest"; then
        info "Version $installed ist schon installiert."
        CURRENT+=("$app")
        return
    fi

    info "Lade $asset …"
    local zip="$TMP/$app.zip"
    if ! curl -fsSL --retry 3 --retry-delay 2 -o "$zip" "$url" </dev/null; then
        warn "Der Download ist fehlgeschlagen."; FAILED+=("$app"); return
    fi

    if [[ "$digest" == sha256:* ]]; then
        local sum
        sum=$(shasum -a 256 "$zip" | cut -d' ' -f1)
        if [[ "sha256:$sum" != "$digest" ]]; then
            warn "Die Prüfsumme stimmt nicht. Die Datei wurde verworfen."; FAILED+=("$app"); return
        fi
        info "Prüfsumme stimmt."
    else
        info "GitHub liefert keine Prüfsumme, Prüfung übersprungen."
    fi

    local x="$TMP/$app.unpacked" new
    mkdir -p "$x"
    if ! ditto -x -k "$zip" "$x" </dev/null; then
        warn "Die ZIP-Datei lässt sich nicht entpacken."; FAILED+=("$app"); return
    fi
    new=$(find "$x" -maxdepth 2 -type d -name "$app.app" | head -1)
    if [[ -z "$new" ]]; then warn "In der ZIP-Datei ist keine $app.app."; FAILED+=("$app"); return; fi

    if ! codesign --verify --deep --strict "$new" >/dev/null 2>&1; then
        warn "Die Signatur der App ist ungültig. Nicht installiert."; FAILED+=("$app"); return
    fi

    local minos exe newver
    minos=$(plist_get "$new/Contents/Info.plist" LSMinimumSystemVersion)
    exe=$(plist_get "$new/Contents/Info.plist" CFBundleExecutable)
    newver=$(plist_get "$new/Contents/Info.plist" CFBundleShortVersionString)
    if [[ -n "$minos" ]] && ! version_ge "$OS_VERSION" "$minos"; then
        warn "$app braucht macOS $minos oder neuer (dieser Mac: $OS_VERSION). Übersprungen."; SKIPPED+=("$app"); return
    fi
    if ! arch_ok "$new/Contents/MacOS/$exe"; then
        warn "$app braucht einen Mac mit Apple Silicon. Übersprungen."; SKIPPED+=("$app"); return
    fi

    # Neue Version erst neben die alte legen, dann tauschen
    local staging="$DEST/.$app.app.mactweaks-new"
    rm -rf "$staging"
    if ! ditto "$new" "$staging" </dev/null; then
        rm -rf "$staging"
        warn "Kopieren nach $DEST ist fehlgeschlagen."; FAILED+=("$app"); return
    fi

    local was_running=0
    if [[ -e "$target" ]]; then
        if [[ -n "$(running_pids "$target")" ]]; then
            was_running=1
            info "Beende das laufende $app …"
            if ! quit_app "$target"; then
                rm -rf "$staging"
                warn "$app lässt sich nicht beenden. Bitte selbst beenden und den Befehl noch einmal ausführen."
                FAILED+=("$app"); return
            fi
        fi
        trash_item "$target" >/dev/null
        # Entscheidend ist, ob die alte Version wirklich weg ist, nicht die Ausgabe.
        if [[ -e "$target" ]]; then
            rm -rf "$staging"
            warn "Die alte Version ließ sich nicht in den Papierkorb legen. Nichts geändert."
            (( was_running && LAUNCH )) && open "$target" </dev/null
            FAILED+=("$app"); return
        fi
        info "Alte Version ${installed:+$installed }liegt im Papierkorb."
    fi

    if ! mv "$staging" "$target"; then
        warn "Konnte $target nicht anlegen. Die neue Version liegt unter $staging."
        FAILED+=("$app"); return
    fi
    info "✓ $app ${newver:-${tag#[vV]}} installiert: $target"
    INSTALLED+=("$app")

    if (( was_running && LAUNCH )); then
        open "$target" </dev/null && info "$app wurde wieder gestartet."
    fi
}

join() { local out="" s; for s in "$@"; do out="${out:+$out, }$s"; done; printf '%s' "$out"; }

main() {
    while (( $# )); do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            --list) LIST_ONLY=1 ;;
            --force) FORCE=1 ;;
            --no-launch) LAUNCH=0 ;;
            --dest)
                [[ -n "${2:-}" ]] || { say "--dest braucht einen Ordner."; exit 2; }
                DEST="$2"; shift ;;
            -*) say "Unbekannte Option: $1"; usage; exit 2 ;;
            *)
                local name
                if ! name=$(canonical_name "$1"); then
                    say "Unbekannte App: $1 (verfügbar: ${APPS[*]})"; exit 2
                fi
                TARGETS+=("$name") ;;
        esac
        shift
    done
    (( ${#TARGETS[@]} )) || TARGETS=("${APPS[@]}")

    if [[ "$(uname -s)" != Darwin ]]; then say "MacTweaks gibt es nur für macOS."; exit 1; fi
    OS_VERSION=$(sw_vers -productVersion)

    if [[ -z "$DEST" ]]; then
        if [[ -w /Applications ]]; then DEST=/Applications; else DEST="$HOME/Applications"; fi
    fi
    if (( ! LIST_ONLY )); then
        mkdir -p "$DEST" || { say "Zielordner $DEST lässt sich nicht anlegen."; exit 1; }
        [[ -w "$DEST" ]] || { say "Keine Schreibrechte für $DEST. Mit --dest einen anderen Ordner wählen."; exit 1; }
    fi
    [[ -d "$DEST" ]] && DEST=$(cd "$DEST" && pwd -P)

    setup_tmp
    say "MacTweaks: $(join "${TARGETS[@]}") → $DEST (macOS $OS_VERSION)"

    local app
    for app in "${TARGETS[@]}"; do process_app "$app"; done

    (( LIST_ONLY )) && exit 0

    say ""
    say "Fertig."
    (( ${#INSTALLED[@]} )) && say "  Installiert:   $(join "${INSTALLED[@]}")"
    (( ${#CURRENT[@]} ))   && say "  Schon aktuell: $(join "${CURRENT[@]}")"
    (( ${#SKIPPED[@]} ))   && say "  Übersprungen:  $(join "${SKIPPED[@]}")"
    (( ${#FAILED[@]} ))    && say "  Fehler:        $(join "${FAILED[@]}")"

    if (( ${#INSTALLED[@]} )); then
        say ""
        say "Beim ersten Start richtest du jede App kurz ein (Berechtigungen, ggf. Claude):"
        for app in "${INSTALLED[@]}"; do say "  $app: $(guide_url "$app")"; done
        say "Nach einem Update musst du Berechtigungen wie Bedienungshilfen oder"
        say "Festplattenvollzugriff eventuell einmal aus- und wieder einschalten."

        local needs_claude=0
        for app in "${INSTALLED[@]}"; do [[ "$app" == MacBuddy || "$app" == TidyMac ]] && needs_claude=1; done
        if (( needs_claude )) && [[ ! -x "$HOME/.local/bin/claude" ]] && ! command -v claude >/dev/null 2>&1; then
            say ""
            say "MacBuddy (und optional TidyMac) nutzen Claude Code mit deinem Claude-Abo:"
            say "  curl -fsSL https://claude.ai/install.sh | bash"
            say "  ~/.local/bin/claude auth login"
        fi
    fi

    (( ${#FAILED[@]} == 0 ))
}

# MACTWEAKS_NO_MAIN=1 lädt nur die Funktionen (für Tests).
[[ "${MACTWEAKS_NO_MAIN:-}" == 1 ]] || main "$@"
