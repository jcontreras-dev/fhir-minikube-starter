#!/usr/bin/env bash
set -euo pipefail
NS="fhir-lab"
helm uninstall fhir-secure-lab -n "$NS" || true
kubectl delete ns "$NS" || true
