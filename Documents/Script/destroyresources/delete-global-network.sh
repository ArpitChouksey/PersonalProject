#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# delete-global-network.sh
# Tears down an AWS Network Manager Global Network that is blocked by a
# Cloud WAN Core Network (FieldValidationFailed: coreNetworkId).
#
# Order: connect peers -> attachments -> peerings -> core network
#        -> TGW registrations, connections, CGW/link associations,
#           links, devices, sites -> global network
#
# Compatible with macOS default bash 3.2 (no mapfile / assoc arrays).
#
# Usage:
#   chmod +x delete-global-network.sh
#   ./delete-global-network.sh <global-network-id>            # real run
#   ./delete-global-network.sh <global-network-id> --dry-run  # print only
#   ./delete-global-network.sh                                # lists GNs
# -----------------------------------------------------------------------------
set -uo pipefail

PROFILE="network"
REGION="us-west-2"          # Network Manager home region (commercial AWS)
POLL_INTERVAL=20            # seconds between status checks
MAX_WAIT=1800               # max seconds to wait per phase (30 min)

GN="${1:-}"
DRY_RUN=false
[ "${2:-}" = "--dry-run" ] && DRY_RUN=true

AWS="aws --profile ${PROFILE} --region ${REGION} networkmanager"

log()  { printf '\033[1;34m[%s]\033[0m %s\n' "$(date +%H:%M:%S)" "$*"; }
warn() { printf '\033[1;33m[WARN]\033[0m %s\n' "$*"; }
err()  { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; }

run() {
  if $DRY_RUN; then
    echo "  DRY-RUN: $*"
  else
    eval "$@" >/dev/null || warn "Command failed (continuing): $*"
  fi
}

# Return list output, stripping the "None" AWS CLI prints for null values
q() { eval "$@" 2>/dev/null | tr '\t' '\n' | grep -v '^None$' | grep -v '^$' || true; }

wait_until_empty() {
  # $1 = description, $2 = command that prints remaining IDs
  local desc="$1" cmd="$2" waited=0 remaining
  $DRY_RUN && return 0
  while :; do
    remaining=$(q "$cmd" | wc -l | tr -d ' ')
    [ "$remaining" -eq 0 ] && { log "All ${desc} deleted."; return 0; }
    if [ "$waited" -ge "$MAX_WAIT" ]; then
      err "Timed out waiting for ${desc} (${remaining} remaining)."; exit 1
    fi
    log "Waiting for ${remaining} ${desc} to finish deleting..."
    sleep "$POLL_INTERVAL"; waited=$((waited + POLL_INTERVAL))
  done
}

# --- Preflight ---------------------------------------------------------------
command -v aws >/dev/null || { err "AWS CLI not installed (brew install awscli)."; exit 1; }

if ! aws sts get-caller-identity --profile "$PROFILE" >/dev/null 2>&1; then
  err "Profile '${PROFILE}' is not authenticated. Try: aws sso login --profile ${PROFILE}"
  exit 1
fi

if [ -z "$GN" ]; then
  log "No global network ID given. Available global networks:"
  $AWS describe-global-networks \
    --query "GlobalNetworks[].{Id:GlobalNetworkId,State:State,Desc:Description}" --output table
  echo "Re-run: $0 <global-network-id> [--dry-run]"
  exit 0
fi

ACCOUNT=$(aws sts get-caller-identity --profile "$PROFILE" --query Account --output text)
log "Account: ${ACCOUNT} | Profile: ${PROFILE} | Global Network: ${GN}"
$DRY_RUN && log "DRY-RUN mode: nothing will be deleted."

if ! $DRY_RUN; then
  printf 'Type the global network ID to confirm PERMANENT deletion: '
  read -r CONFIRM < /dev/tty
  CONFIRM=$(printf '%s' "$CONFIRM" | tr -d '[:space:]')
  [ "$CONFIRM" = "$GN" ] || { err "Confirmation mismatch (got: '${CONFIRM}'). Aborting."; exit 1; }
fi

# --- 1-4. Core networks ------------------------------------------------------
CORE_NETWORKS=$(q "$AWS list-core-networks \
  --query \"CoreNetworks[?GlobalNetworkId=='${GN}'].CoreNetworkId\" --output text")

for CN in $CORE_NETWORKS; do
  log "=== Core network: ${CN} ==="

  # Connect peers first (they block Connect attachments)
  for P in $(q "$AWS list-connect-peers --core-network-id $CN \
      --query 'ConnectPeers[?ConnectPeerState!=\`DELETING\`].ConnectPeerId' --output text"); do
    log "Deleting connect peer ${P}"
    run "$AWS delete-connect-peer --connect-peer-id $P"
  done
  wait_until_empty "connect peers" "$AWS list-connect-peers --core-network-id $CN \
    --query 'ConnectPeers[].ConnectPeerId' --output text"

  # Connect attachments before their transport (VPC) attachments
  for A in $(q "$AWS list-attachments --core-network-id $CN --attachment-type CONNECT \
      --query 'Attachments[?State!=\`DELETING\`].AttachmentId' --output text"); do
    log "Deleting CONNECT attachment ${A}"
    run "$AWS delete-attachment --attachment-id $A"
  done
  wait_until_empty "connect attachments" "$AWS list-attachments --core-network-id $CN \
    --attachment-type CONNECT --query 'Attachments[].AttachmentId' --output text"

  # All remaining attachments (VPC, VPN, TGW route table, DX gateway)
  for A in $(q "$AWS list-attachments --core-network-id $CN \
      --query 'Attachments[?State!=\`DELETING\`].AttachmentId' --output text"); do
    log "Deleting attachment ${A}"
    run "$AWS delete-attachment --attachment-id $A"
  done
  wait_until_empty "attachments" "$AWS list-attachments --core-network-id $CN \
    --query 'Attachments[].AttachmentId' --output text"

  # Peerings (TGW peerings)
  for P in $(q "$AWS list-peerings --core-network-id $CN \
      --query 'Peerings[?State!=\`DELETING\`].PeeringId' --output text"); do
    log "Deleting peering ${P}"
    run "$AWS delete-peering --peering-id $P"
  done
  wait_until_empty "peerings" "$AWS list-peerings --core-network-id $CN \
    --query 'Peerings[].PeeringId' --output text"

  # Core network itself
  log "Deleting core network ${CN}"
  run "$AWS delete-core-network --core-network-id $CN"
  wait_until_empty "core network ${CN}" "$AWS list-core-networks \
    --query \"CoreNetworks[?CoreNetworkId=='${CN}'].CoreNetworkId\" --output text"
done

[ -z "$CORE_NETWORKS" ] && log "No core networks found in ${GN}."

# --- 5. Other global network resources ---------------------------------------
log "=== Cleaning global network resources ==="

for T in $(q "$AWS get-transit-gateway-registrations --global-network-id $GN \
    --query 'TransitGatewayRegistrations[].TransitGatewayArn' --output text"); do
  log "Deregistering TGW ${T}"
  run "$AWS deregister-transit-gateway --global-network-id $GN --transit-gateway-arn $T"
done

for C in $(q "$AWS get-connections --global-network-id $GN \
    --query 'Connections[].ConnectionId' --output text"); do
  log "Deleting connection ${C}"
  run "$AWS delete-connection --global-network-id $GN --connection-id $C"
done

for CG in $(q "$AWS get-customer-gateway-associations --global-network-id $GN \
    --query 'CustomerGatewayAssociations[].CustomerGatewayArn' --output text"); do
  log "Disassociating customer gateway ${CG}"
  run "$AWS disassociate-customer-gateway --global-network-id $GN --customer-gateway-arn $CG"
done

# Link associations: "deviceId linkId" pairs, one per line
$AWS get-link-associations --global-network-id $GN \
  --query 'LinkAssociations[].[DeviceId,LinkId]' --output text 2>/dev/null |
while read -r DEV LNK; do
  [ -z "${DEV:-}" ] && continue
  log "Disassociating link ${LNK} from device ${DEV}"
  run "$AWS disassociate-link --global-network-id $GN --device-id $DEV --link-id $LNK"
done

for L in $(q "$AWS get-links --global-network-id $GN --query 'Links[].LinkId' --output text"); do
  log "Deleting link ${L}"
  run "$AWS delete-link --global-network-id $GN --link-id $L"
done

for D in $(q "$AWS get-devices --global-network-id $GN --query 'Devices[].DeviceId' --output text"); do
  log "Deleting device ${D}"
  run "$AWS delete-device --global-network-id $GN --device-id $D"
done

for S in $(q "$AWS get-sites --global-network-id $GN --query 'Sites[].SiteId' --output text"); do
  log "Deleting site ${S}"
  run "$AWS delete-site --global-network-id $GN --site-id $S"
done

# --- 6. Global network -------------------------------------------------------
log "=== Deleting global network ${GN} ==="
if $DRY_RUN; then
  echo "  DRY-RUN: $AWS delete-global-network --global-network-id $GN"
else
  if $AWS delete-global-network --global-network-id "$GN" >/dev/null; then
    log "Done. Global network ${GN} is deleting."
  else
    err "Global network delete failed. Re-run the script; a resource may still be finishing deletion."
    exit 1
  fi
fi
