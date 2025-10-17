#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
folderName="$(basename "$SCRIPT_DIR")"
# strip single trailing underscore if present
folderName="${folderName%_}"
ip="${1:-localhost}"

if [[ $# -gt 1 ]]; then
  echo "Too many arguments supplied"
  exit 1
fi

# replace FILLER_IP in peer files when IP provided (macOS vs Linux sed)
if [[ $# -eq 1 ]]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' -e "s/FILLER_IP/$ip/g" "$SCRIPT_DIR/PeerA/${folderName}_PeerA.txt" "$SCRIPT_DIR/PeerB/${folderName}_PeerB.txt" || true
  else
    sed -i -e "s/FILLER_IP/$ip/g" "$SCRIPT_DIR/PeerA/${folderName}_PeerA.txt" "$SCRIPT_DIR/PeerB/${folderName}_PeerB.txt" || true
  fi
fi

# validate required files
if [[ ! -f "$SCRIPT_DIR/PeerA/${folderName}_PeerA.txt" || ! -f "$SCRIPT_DIR/PeerB/${folderName}_PeerB.txt" ]]; then
  echo "Required files $SCRIPT_DIR/PeerA/${folderName}_PeerA.txt or $SCRIPT_DIR/PeerB/${folderName}_PeerB.txt not found!"
  exit 1
fi

if [[ ! -f "$SCRIPT_DIR/SharkNetMessengerCLI.jar" ]]; then
  echo "Required SharkNetMessengerCLI.jar not found in $SCRIPT_DIR"
  exit 1
fi

# launch peers using absolute jar path
(cd "$SCRIPT_DIR/PeerA" && cat "${folderName}_PeerA.txt" | java -jar "$SCRIPT_DIR/SharkNetMessengerCLI.jar" PeerA > peerAsnmLog.txt 2>errorlogPeerA.txt) &
pidA=$!
(cd "$SCRIPT_DIR/PeerB" && cat "${folderName}_PeerB.txt" | java -jar "$SCRIPT_DIR/SharkNetMessengerCLI.jar" PeerB > peerBsnmLog.txt 2>errorlogPeerB.txt) &
pidB=$!

wait "$pidA" "$pidB"
