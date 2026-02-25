#!/usr/bin/env bash
set -euo pipefail
NS="fhir-lab"
minikube addons enable ingress || true
kubectl create ns "$NS" 2>/dev/null || true
helm upgrade --install fhir-secure-lab charts/fhir-secure-lab -n "$NS"
kubectl -n "$NS" rollout status deployment/hapi-fhir --timeout=300s
kubectl -n "$NS" rollout status deployment/keycloak --timeout=300s
kubectl -n "$NS" rollout status deployment/envoy --timeout=300s
echo "$(minikube ip) fhir.local"
