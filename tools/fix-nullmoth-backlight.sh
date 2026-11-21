#!/bin/bash
# Fix NullMoth screen-brightness persistence.
# Root cause: /Library/NullMoth/backlight.sh cur() extracts
# "GUID:nullmoth-backlight" from `nvram -x -p`, but that output has no GUID
# prefix, so the parse always fails and backlight.level is never written.
# Usage: sudo bash tools/fix-nullmoth-backlight.sh
# The script backs up /Library/NullMoth/backlight.sh before patching.
set -euo pipefail

F=/Library/NullMoth/backlight.sh
STAMP=$(date +%Y%m%d-%H%M%S)
BAK="$F.bak-$STAMP"

[ -f "$F" ] || { echo "STOP: $F not found"; exit 1; }
cp -p "$F" "$BAK"
echo "backup: $BAK"

python3 - "$F" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
pat = re.compile(r'nvram -x -p 2>/dev/null\s*\|\s*plutil -extract\s+"\$V:nullmoth-backlight"')
new = 'nvram -x nullmoth-backlight 2>/dev/null | plutil -extract nullmoth-backlight'
s2, n = pat.subn(new, s)
if n != 1:
    sys.exit("STOP: expected exactly 1 match, got %d" % n)
open(p, 'w', encoding='utf-8').write(s2)
print("patched: cur() now reads the key without the GUID prefix")
PY

bash -n "$F" || { echo "STOP: syntax check failed, restoring"; cp -p "$BAK" "$F"; exit 1; }
echo "syntax: OK"

LEVEL=$(nvram -x nullmoth-backlight 2>/dev/null \
  | plutil -extract nullmoth-backlight raw -o - - 2>/dev/null \
  | base64 -D 2>/dev/null \
  | od -An -tx1 | tr -d ' \n')
case "$LEVEL" in
  02[0-9a-f][0-9a-f][0-9a-f][0-9a-f])
    printf '%s\n' "$LEVEL" > /Library/NullMoth/backlight.level
    chmod 644 /Library/NullMoth/backlight.level
    echo "seeded: /Library/NullMoth/backlight.level = $LEVEL"
    ;;
  *)
    echo "note: NVRAM level is '$LEVEL', not seeding backlight.level"
    ;;
esac

launchctl kickstart -k system/com.nullmoth.backlight
sleep 1
echo "daemon:"
launchctl print system/com.nullmoth.backlight 2>/dev/null | grep -E 'state =|runs =|program =' | head -5
echo "RESULT: ok"
