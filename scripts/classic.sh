#!/usr/bin/env bash
set -Eeuo pipefail

BLUEPRINT="blueprints/app/aws/classic"
TF=(terraform -chdir="$BLUEPRINT")
IP="$(${TF[@]} output -raw dev_ip 2>/dev/null || true)"
USER="$(${TF[@]} output -raw ssh_user 2>/dev/null || true)"
USER="${USER:-ubuntu}"
KEY="${SSH_PRIVATE_KEY_PATH:-$HOME/.ssh/id_ed25519}"

require_ip() {
  if [[ -z "$IP" || "$IP" == "null" ]]; then
    echo "No app server public IP is available." >&2
    exit 1
  fi
}

ssh_run() {
  require_ip
  ssh -i "$KEY" -o StrictHostKeyChecking=no "$USER@$IP" "$@"
}

case "${1:-}" in
  wait-nginx)
    require_ip
    echo "Waiting for nginx..."
    ssh_run 'cloud-init status --wait >/dev/null 2>&1 && until curl -fsS http://localhost >/dev/null 2>&1; do sleep 1; done'
    echo "Nginx is up: http://$IP"
    ;;
  connect)
    require_ip
    exec ssh -i "$KEY" -o StrictHostKeyChecking=no "$USER@$IP"
    ;;
  logs)
    ssh_run 'sudo cat /var/log/cloud-init-output.log'
    ;;
  status)
    ssh_run 'cloud-init status --long'
    ;;
  docker)
    ssh_run 'docker ps -a'
    ;;
  nginx)
    ssh_run 'sudo systemctl status nginx --no-pager'
    ;;
  *)
    echo "Usage: $0 {wait-nginx|connect|logs|status|docker|nginx}" >&2
    exit 2
    ;;
esac
