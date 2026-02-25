#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-}"
if [ -z "${BASE_URL}" ]; then
  # intenta leer del fichero generado por start.sh
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  if [ -f "${SCRIPT_DIR}/../scripts/.url" ]; then
    BASE_URL="$(cat "${SCRIPT_DIR}/../scripts/.url")/fhir"
  else
    BASE_URL="http://$(minikube ip):30080/fhir"
  fi
fi

echo "[*] Usando BASE_URL=${BASE_URL}"

extract_id() {
  # Extrae el id desde el header Location de FHIR: .../ResourceType/ID/_history/...
  sed -E 's#.*/(Patient|Practitioner)/([^/]+)/.*#\2#'
}

# --- Patient: CREATE ---
echo "[*] Creando Patient..."
PATIENT_LOC="$(curl -sS -D - -o /dev/null -H 'Content-Type: application/fhir+json' -X POST "${BASE_URL}/Patient" --data-binary "@../data/patient.json" | grep -i '^Location: ' | tr -d '\r')"
PATIENT_ID="$(echo "${PATIENT_LOC}" | extract_id || true)"
echo "    Location: ${PATIENT_LOC}"
echo "    Patient ID: ${PATIENT_ID}"

# READ
echo "[*] Leyendo Patient ${PATIENT_ID}..."
curl -sS -o /dev/null -w "    HTTP %{http_code}\n" "${BASE_URL}/Patient/${PATIENT_ID}"

# UPDATE
echo "[*] Actualizando Patient ${PATIENT_ID}..."
curl -sS -o /dev/null -w "    HTTP %{http_code}\n" -H 'Content-Type: application/fhir+json' -X PUT "${BASE_URL}/Patient/${PATIENT_ID}" --data-binary "@../data/update-patient.json"

# DELETE
echo "[*] Eliminando Patient ${PATIENT_ID}..."
curl -sS -o /dev/null -w "    HTTP %{http_code}\n" -X DELETE "${BASE_URL}/Patient/${PATIENT_ID}"

# --- Practitioner: CREATE ---
echo "[*] Creando Practitioner..."
PRAC_LOC="$(curl -sS -D - -o /dev/null -H 'Content-Type: application/fhir+json' -X POST "${BASE_URL}/Practitioner" --data-binary "@../data/practitioner.json" | grep -i '^Location: ' | tr -d '\r')"
PRAC_ID="$(echo "${PRAC_LOC}" | extract_id || true)"
echo "    Location: ${PRAC_LOC}"
echo "    Practitioner ID: ${PRAC_ID}"

# READ
echo "[*] Leyendo Practitioner ${PRAC_ID}..."
curl -sS -o /dev/null -w "    HTTP %{http_code}\n" "${BASE_URL}/Practitioner/${PRAC_ID}"

# UPDATE (reutilizamos el mismo recurso para simplicidad)
echo "[*] Actualizando Practitioner ${PRAC_ID} (mismo payload de ejemplo)..."
curl -sS -o /dev/null -w "    HTTP %{http_code}\n" -H 'Content-Type: application/fhir+json' -X PUT "${BASE_URL}/Practitioner/${PRAC_ID}" --data-binary "@../data/practitioner.json"

# DELETE
echo "[*] Eliminando Practitioner ${PRAC_ID}..."
curl -sS -o /dev/null -w "    HTTP %{http_code}\n" -X DELETE "${BASE_URL}/Practitioner/${PRAC_ID}"

echo "[*] CRUD completo."
