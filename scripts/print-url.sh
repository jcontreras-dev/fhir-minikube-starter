#!/usr/bin/env bash
set -euo pipefail
if [ -f "$(dirname "$0")/.url" ]; then
  cat "$(dirname "$0")/.url"
else
  minikube service nginx-lb -n fhir-demo --url | head -n1
fi