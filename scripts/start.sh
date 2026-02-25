#!/usr/bin/env bash
set -euo pipefail
THIS_DIR="$(cd "$(dirname "$0")" && pwd)"
K8S_DIR="$THIS_DIR/../k8s"

echo "[*] Iniciando Minikube si es necesario..."
minikube status >/dev/null 2>&1 || minikube start

echo "[*] Aplicando manifiestos..."
kubectl apply -f "$K8S_DIR/00-namespace.yaml"
kubectl apply -f "$K8S_DIR/10-hapi-deployment.yaml"
kubectl apply -f "$K8S_DIR/20-hapi-service.yaml"
kubectl apply -f "$K8S_DIR/30-nginx-configmap.yaml"
kubectl apply -f "$K8S_DIR/31-nginx-deployment.yaml"
kubectl apply -f "$K8S_DIR/32-nginx-service.yaml"

echo "[*] Esperando disponibilidad..."
kubectl -n fhir-demo rollout status deploy/hapi
kubectl -n fhir-demo rollout status deploy/nginx-lb

IP="$(minikube ip)"
URL="$(minikube service nginx-lb -n fhir-demo --url | head -n1)"
echo "${URL}" > "$THIS_DIR/.url"
echo "[*] URL del FHIR (vía Nginx): ${URL}"
echo "[*] Base FHIR para CRUD: ${URL}/fhir"
