#!/usr/bin/env bash
set -euo pipefail
echo "[*] Eliminando namespace fhir-demo..."
kubectl delete ns fhir-demo --ignore-not-found
echo "[*] Listo."
