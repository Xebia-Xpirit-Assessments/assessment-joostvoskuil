#!/usr/bin/env bash

# Run in a second Codespaces terminal while the failing AppHost is still running.
# Pass the kubeconfig path printed by that AppHost run, not a previous session.
set -euo pipefail

if [[ $# -ne 1 || ! -r "$1" ]]; then
    echo "Usage: bash .devcontainer/diagnose-dcp.sh /tmp/aspire.<current-session>/kubeconfig" >&2
    echo "Keep AppHost running and use its latest 'Successfully read Kubernetes configuration' path." >&2
    exit 2
fi

# DCP generates a single-cluster kubeconfig. Read ONLY its server field:
# never print certificate data, client keys, tokens, or other environment values.
server=$(awk '$1 == "server:" { print $2; exit }' "$1")
server=${server%\"}
server=${server#\"}
server=${server%\'}
server=${server#\'}

# Do not send diagnostic requests to arbitrary hosts, or URLs with credentials.
if [[ ! "$server" =~ ^https://(127\.0\.0\.1|localhost|\[::1\]):([0-9]+)/?$ ]]; then
    echo "Expected an HTTPS loopback endpoint in DCP's server field; no requests sent." >&2
    exit 2
fi
port=${BASH_REMATCH[2]}

echo "=== Runtime ==="
date -u
uname -srm
if command -v dotnet >/dev/null 2>&1; then
    dotnet --version
fi
curl --version
if command -v openssl >/dev/null 2>&1; then
    openssl version
fi

echo
echo "=== DCP endpoint ==="
echo "$server"

echo
echo "=== Process names (no command-line arguments) ==="
ps -eo pid,comm | awk 'NR == 1 || /dcp|dotnet/'

echo
echo "=== DCP listening socket ==="
if command -v ss >/dev/null 2>&1; then
    ss -ltnp "sport = :$port" || true
else
    echo "ss unavailable; listener check skipped."
fi

echo
echo "=== Proxy variables (presence only; values not printed) ==="
for name in HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY http_proxy https_proxy all_proxy no_proxy; do
    if [[ -n "${!name:-}" ]]; then
        printf '%s is set\n' "$name"
    else
        printf '%s is unset or empty\n' "$name"
    fi
done

probe() {
    local label=$1
    shift
    echo
    printf '=== Direct TLS probe: %s ===\n' "$label"
    local result=0
    # --disable ignores ~/.curlrc; --noproxy bypasses all HTTP proxies.
    # --insecure applies ONLY to this unauthenticated diagnostic request.
    # No client credentials are sent and no response body is printed.
    curl --disable --noproxy '*' --insecure --verbose \
        --connect-timeout 5 --max-time 10 --output /dev/null \
        --write-out '\nHTTP status: %{http_code}; remote IP: %{remote_ip}\n' \
        "$@" "${server%/}/version" || result=$?
    printf 'curl exit code: %s\n' "$result"
}

probe "default negotiation"
probe "TLS 1.2 only" --tlsv1.2 --tls-max 1.2
probe "TLS 1.3 only" --tlsv1.3 --tls-max 1.3

echo
echo "An HTTP response (including 401/403) means TLS completed for that probe."
echo "A client-certificate-required alert can be expected without DCP client credentials."
echo "Successful curl probes do not prove AppHost's certificate validation will succeed."
echo "Share this output and any earlier dcpd errors, NOT the full kubeconfig."