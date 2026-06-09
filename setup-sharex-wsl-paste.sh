#!/usr/bin/env bash
# Configure ShareX (Windows) so screenshots paste into Claude Code in WSL.
#
# Flow it sets up: Ctrl+Shift+S -> ShareX saves a PNG and runs an after-capture
# action that puts the file's /mnt path on the clipboard -> Ctrl+V in a WSL
# terminal pastes that path, which Claude resolves into an [Image].
#
# Prerequisites on the new PC:
#   1. Install ShareX (winget install ShareX.ShareX) and launch it once so its
#      config files exist.
#   2. Run this script from inside WSL:  bash setup-sharex-wsl-paste.sh
#
# Idempotent: safe to re-run. Backs up ShareX config before editing.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: setup-sharex-wsl-paste.sh [-h]

Configures ShareX on the Windows side to make screenshots pasteable in Claude
Code under WSL. Install + first-run ShareX before running this. Run from WSL.
EOF
}
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { usage; exit 0; }

PS_FULL='C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'

echo "==> Detecting Windows user profile..."
WINPROFILE_WIN="$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r')"
WINPROFILE_WSL="$(wslpath -u "$WINPROFILE_WIN")"
echo "    USERPROFILE = $WINPROFILE_WIN  ($WINPROFILE_WSL)"

# Screenshots folder lives under the Windows profile.
SHOTS_WSL="$WINPROFILE_WSL/claude-screenshots"
SHOTS_WIN="$(wslpath -w "$WINPROFILE_WSL")\\claude-screenshots"
mkdir -p "$SHOTS_WSL"
echo "    screenshots -> $SHOTS_WIN"

echo "==> Writing the path-converter script..."
cat > "$SHOTS_WSL/to-wsl-clip.ps1" <<'PS1'
# ShareX after-capture action: take the just-saved screenshot's Windows path,
# convert it to the WSL /mnt path, and put that on the clipboard so Ctrl+V in a
# WSL terminal pastes a path Claude Code can read. Logs every run for diagnosis.
param([string]$Path)
$log = Join-Path $PSScriptRoot 'to-wsl-clip.log'
$ts  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
try {
    if ([string]::IsNullOrWhiteSpace($Path)) {
        Add-Content -Path $log -Value "$ts  NO-INPUT (ShareX called the action but passed an empty argument)"
        exit 1
    }
    # Normalize: ShareX's $input token can leave a trailing '$' and may wrap the path in quotes.
    $Path  = $Path.Trim().Trim('"').TrimEnd('$').Trim()
    $drive = $Path.Substring(0, 1).ToLower()
    $rest  = $Path.Substring(2).Replace('\', '/')
    $wsl   = "/mnt/$drive$rest"
    Set-Clipboard -Value $wsl
    Add-Content -Path $log -Value "$ts  OK   in=[$Path]  ->  clip=[$wsl]"
} catch {
    Add-Content -Path $log -Value "$ts  ERR  in=[$Path]  $($_.Exception.Message)"
    exit 1
}
PS1
PS1_WIN="$SHOTS_WIN\\to-wsl-clip.ps1"
echo "    converter -> $PS1_WIN"

echo "==> Locating ShareX config + executable..."
SX_DIR=""
for cand in "$WINPROFILE_WSL/Documents/ShareX" "$WINPROFILE_WSL/OneDrive/Documents/ShareX"; do
  [[ -f "$cand/ApplicationConfig.json" ]] && { SX_DIR="$cand"; break; }
done
[[ -z "$SX_DIR" ]] && { echo "ERROR: ShareX config not found. Install ShareX and launch it once, then re-run."; exit 1; }
echo "    config dir -> $SX_DIR"

SX_EXE=""
for cand in "/mnt/c/Program Files/ShareX/ShareX.exe" "/mnt/c/Program Files (x86)/ShareX/ShareX.exe"; do
  [[ -f "$cand" ]] && { SX_EXE="$cand"; break; }
done
[[ -z "$SX_EXE" ]] && echo "    (ShareX.exe not found in Program Files; you'll need to start ShareX manually after this)"

echo "==> Backing up config..."
cp -f "$SX_DIR/ApplicationConfig.json" "$SX_DIR/ApplicationConfig.json.bak"
cp -f "$SX_DIR/HotkeysConfig.json"     "$SX_DIR/HotkeysConfig.json.bak"

echo "==> Closing ShareX so edits aren't overwritten on exit..."
/mnt/c/Windows/System32/taskkill.exe /IM ShareX.exe /F >/dev/null 2>&1 || true
sleep 2

echo "==> Patching ApplicationConfig.json (path + after-capture job + action)..."
python3 - "$SX_DIR/ApplicationConfig.json" "$SHOTS_WIN" "$PS_FULL" "$PS1_WIN" <<'PY'
import json, sys
cfgp, shots_win, ps_full, ps1_win = sys.argv[1:5]
d = json.load(open(cfgp, encoding='utf-8-sig'))

# Paths tab: custom screenshots folder
d["UseCustomScreenshotsPath"] = True
d["CustomScreenshotsPath"] = shots_win

ts = d["DefaultTaskSettings"]
# After-capture: save to file + perform actions, and NOT copy image to clipboard
ts["AfterCaptureJob"] = "SaveImageToFile, PerformActions"

# The WSL clipboard action (full powershell path is REQUIRED; bare name is silently skipped)
action = {
    "IsActive": True,
    "Name": "WSL clipboard path",
    "Path": ps_full,
    "Args": '"$input"',
    "OutputExtension": None,
    "Extensions": None,
    "HiddenWindow": True,
    "DeleteInputFile": False,
}
eps = ts.setdefault("ExternalPrograms", [])
for i, e in enumerate(eps):
    if e.get("Name") == "WSL clipboard path":
        eps[i] = action
        break
else:
    eps.append(action)

json.dump(d, open(cfgp, "w", encoding="utf-8"), indent=4)
print("    AfterCaptureJob:", ts["AfterCaptureJob"])
print("    action path    :", ps_full)
PY

echo "==> Patching HotkeysConfig.json (bind Ctrl+Shift+S region capture to perform actions)..."
python3 - "$SX_DIR/HotkeysConfig.json" <<'PY'
import json, sys
cfgp = sys.argv[1]
d = json.load(open(cfgp, encoding='utf-8-sig'))
hotkeys = d.setdefault("Hotkeys", [])
region = [h for h in hotkeys if h.get("TaskSettings", {}).get("Job") == "RectangleRegion"]
for h in region:
    ts = h["TaskSettings"]
    ts["UseDefaultAfterCaptureJob"] = False
    ts["AfterCaptureJob"] = "SaveImageToFile, PerformActions"
    ts["UseDefaultActions"] = True
# Bind the first region-capture hotkey to Ctrl+Shift+S
if region:
    region[0].setdefault("HotkeyInfo", {})["Hotkey"] = "S, Shift, Control"
    print("    bound region capture -> Ctrl+Shift+S; perform actions ON")
else:
    print("    NOTE: no RectangleRegion hotkey found; add one in ShareX > Hotkey settings")
json.dump(d, open(cfgp, "w", encoding="utf-8"), indent=4)
PY

echo "==> Validating JSON..."
python3 -c "import json;json.load(open('$SX_DIR/ApplicationConfig.json'));json.load(open('$SX_DIR/HotkeysConfig.json'));print('    OK')"

if [[ -n "$SX_EXE" ]]; then
  echo "==> Relaunching ShareX..."
  nohup "$SX_EXE" >/dev/null 2>&1 & disown 2>/dev/null || true
fi

cat <<EOF

Done. Test it:
  1. Press Ctrl+Shift+S, select a region.
  2. In Claude Code (WSL), press Ctrl+V.

If it misbehaves, check the log:  $SHOTS_WSL/to-wsl-clip.log
Backups:  $SX_DIR/ApplicationConfig.json.bak , HotkeysConfig.json.bak
EOF
