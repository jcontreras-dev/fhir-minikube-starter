#!/usr/bin/env bash
set -euo pipefail
REPO_URL=${1:-""}
if [[ -z "$REPO_URL" ]]; then
  echo "Usage: $0 <git-repo-url>"
  exit 1
fi
WORKDIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$WORKDIR"
if [ ! -d ".git" ]; then git init; fi
git add .
git commit -m "Add FHIR Secure Lab: HAPI + Keycloak + Envoy + Helm" || true
git branch -M main || true
git remote remove origin 2>/dev/null || true
git remote add origin "$REPO_URL"
git push -u origin main
