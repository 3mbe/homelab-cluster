#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

log() {
  printf '[%s] [deploy] %s\n' "$(date +%H:%M:%S)" "$*" >&2
}

die() {
  log "ERROR: $*"
  exit 1
}

require_cmd() {
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      die "Required command '$cmd' not found in PATH"
    fi
  done
}

check_docker_running() {
  if ! docker info >/dev/null 2>&1; then
    die "Docker is installed but not responding. Is the daemon/service running?"
  fi
}

ensure_k9s() {
  if command -v k9s >/dev/null 2>&1; then
    log "k9s: $(command -v k9s)"
    return
  fi

  log "k9s is not installed."
  if command -v brew >/dev/null 2>&1; then
    log "Install it with: brew install derailed/k9s/k9s"
  else
    log "See installation options: https://k9scli.io/topics/install/"
  fi
}

create_cluster() {
  local cluster_name="${1:-}"
  local args=(cluster create)

  if [[ -n "$cluster_name" ]]; then
    args+=(--name "$cluster_name")
  fi

  talosctl "${args[@]}"
}

preflight_up() {
  require_cmd talosctl docker kubectl
  check_docker_running
  ensure_k9s
}

preflight_destroy() {
  require_cmd talosctl docker
  check_docker_running
}

preflight_status() {
  require_cmd kubectl
}

cmd_up() {
  preflight_up

  local cluster_name="${1:-${CLUSTER_NAME:-}}"

  if [[ -n "$cluster_name" ]]; then
    log "Using cluster name: ${cluster_name}"
  else
    log "No cluster name provided; using talosctl's default behavior."
  fi

  create_cluster "$cluster_name"

  local ctx
  ctx="$(kubectl config current-context 2>/dev/null || echo 'unknown')"

  log "Cluster is ready."
  log "Context: ${ctx}"

  if command -v k9s >/dev/null 2>&1; then
    log "Hint: run 'k9s -n kube-system' to explore the cluster."
  fi

  if [[ "${AUTO_K9S:-0}" = "1" ]] \
     && command -v k9s >/dev/null 2>&1 \
     && [[ -t 1 ]]; then
    k9s -n kube-system || true
  fi
}

cmd_destroy() {
  preflight_destroy

  local cluster_name="${1:-${CLUSTER_NAME:-}}"
  if [[ -z "$cluster_name" ]]; then
    die "Cluster name required for destroy (arg or CLUSTER_NAME)."
  fi

  log "Destroying cluster: ${cluster_name}"
  talosctl cluster destroy --name "$cluster_name"
}

cmd_status() {
  preflight_status

  log "kubectl context:"
  kubectl config current-context || true

  log "Nodes:"
  kubectl get nodes -o wide || true
}

usage() {
  local self
  self="$(basename "$0")"

  cat <<EOF
Usage:
  $self up [cluster-name]
  $self destroy <cluster-name>
  $self status

Commands:
  up         Create a Talos cluster (default command)
  destroy    Destroy a Talos cluster by name
  status     Show current kubectl context and nodes

Examples:
  $self up
  $self up mycluster
  CLUSTER_NAME=mycluster $self destroy
  $self status

Environment Variables:
  CLUSTER_NAME   Optional cluster name
  AUTO_K9S=1     Auto-launch k9s -n kube-system after cluster creation
EOF
}

main() {
  local cmd="${1:-up}"
  shift || true

  case "$cmd" in
    up)
      cmd_up "$@"
      ;;
    destroy)
      cmd_destroy "$@"
      ;;
    status)
      cmd_status "$@"
      ;;
    -h|--help)
      usage
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
