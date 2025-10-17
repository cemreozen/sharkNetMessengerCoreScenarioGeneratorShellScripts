#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# regenerate scenarios (keep original behavior)
java -jar "$SCRIPT_DIR/scriptgenerator.jar"

read -p "Type IP address: " ip

# basic presence checks
if [[ ! -f "$SCRIPT_DIR/runTCPCoreScenario.sh" || ! -f "$SCRIPT_DIR/SharkNetMessengerCLI.jar" ]]; then
  echo "Missing required files (runTCPCoreScenario.sh or SharkNetMessengerCLI.jar) in $SCRIPT_DIR"
  exit 1
fi

have_hub=0
if [[ -f "$SCRIPT_DIR/runHubCoreScenario.sh" ]]; then
  have_hub=1
fi

# iterate top-level directories
for f in "$SCRIPT_DIR"/*/; do
  [[ -d "$f" ]] || continue
  dirbase="$(basename "$f")"

  if [[ "$dirbase" == "tcpChain" ]]; then
    for g in "$f"*/; do
      [[ -d "$g" ]] || continue
      cp -a "$SCRIPT_DIR/runTCPCoreScenario.sh" "$g"
      cp -a "$SCRIPT_DIR/SharkNetMessengerCLI.jar" "$g"
      chmod +x "$g/runTCPCoreScenario.sh" || true
      (cd "$g" && ./runTCPCoreScenario.sh "$ip") &
    done

  elif [[ "$dirbase" == "hub" && $have_hub -eq 1 ]]; then
    for g in "$f"*/; do
      [[ -d "$g" ]] || continue
      cp -a "$SCRIPT_DIR/runHubCoreScenario.sh" "$g"
      cp -a "$SCRIPT_DIR/SharkNetMessengerCLI.jar" "$g"
      chmod +x "$g/runHubCoreScenario.sh" || true
      (cd "$g" && ./runHubCoreScenario.sh "$ip") &
    done
  fi
done

wait
echo "All scenarios executed."