#!/usr/bin/env bash
set -euo pipefail
echo "== Pods =="
kubectl -n fhir-demo get pods -o wide || true
echo "== Services =="
kubectl -n fhir-demo get svc || true
echo "== Endpoints =="
kubectl -n fhir-demo get endpoints || true
