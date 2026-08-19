#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] === openDesk Predictive Agent (Docker) v${OPERATOR_VERSION:-4.0.0-docker} starting ==="
echo "[INFO] LLM Backend: ${LLM_BACKEND:-ollama}"
echo "[INFO] Ollama URL: ${OLLAMA_URL:-http://ollama:11434}"
echo "[INFO] Ollama Model: ${OLLAMA_MODEL:-qwen3-30b-a3b:latest}"
echo "[INFO] Watch namespaces: ${OPERATOR_WATCH_NAMESPACES:-opendesk,opendesk-edu,default}"
echo "[INFO] Reconcile interval: ${RECONCILE_INTERVAL:-60}s"
echo "[INFO] Health probe: ${OPERATOR_HEALTH_PROBE_BIND_ADDRESS:-0.0.0.0:8081}"
echo "[INFO] Metrics bind: ${OPERATOR_METRICS_BIND_ADDRESS:-0.0.0.0:8080}"

mkdir -p /var/lib/opendesk /var/log/opendesk /var/cache/opendesk /run/opendesk /tmp /home/opendesk

export PYTHONPATH=/opt/predictive-agent:${PYTHONPATH:-}

exec python3 -m predictive_agent.main "$@"
