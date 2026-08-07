#!/bin/zsh
set -e
cd "$(dirname "$0")"
# Prefer packages already resolved at /tmp/gcp-spm if present
open "Gentler Coparent.xcodeproj"
osascript -e 'display notification "If packages still show missing: File → Packages → Resolve Package Versions" with title "Gentler Coparent"'
