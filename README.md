# FHIR + Minikube + Nginx (CRUD simple)

Proyecto educativo para mostrar **programación declarativa** con Kubernetes:
- Despliega un servidor **FHIR (HAPI)** en Minikube.
- Pone **Nginx** como balanceador de carga simple.
- Ejecuta **CRUD** de *Patient* y *Practitioner* con `curl`.
- Todo listo para subir a GitHub.

## Requisitos
- macOS, Linux o WSL2
- Docker (recomendado) y **Minikube** + **kubectl**
- Bash

## 1) Despliegue
```bash
cd scripts
chmod +x start.sh status.sh stop.sh
./start.sh
# Salida esperada al final:
# URL del FHIR (vía Nginx): http://<MINIKUBE_IP>:30080
```

## 2) Probar CRUD
```bash
cd ../crud
chmod +x curl-crud.sh
export BASE_URL=$(../scripts/print-url.sh)  # o copia la URL del paso anterior y exporta BASE_URL
./curl-crud.sh
```
El script crea, lee, actualiza y elimina **Patient** y **Practitioner**. Muestra los IDs y códigos HTTP.

## 3) Ver estado o limpiar
```bash
cd ../scripts
./status.sh     # pods, services y endpoints
./stop.sh       # elimina todo el namespace 'fhir-demo'
```

## 4) Notas
- FHIR base URL usada por el CRUD: `http://<MINIKUBE_IP>:30080/fhir`
- Si `BASE_URL` no está definido, el script intentará detectarlo.
- Este paquete usa **NodePort 30080** para simplificar en Minikube.
- Nginx balancea hacia el Service interno de HAPI. Para clase se usa 1 réplica. Puedes subir a 2 para ilustrar balanceo.

## 5) Estructura
```
k8s/
  00-namespace.yaml
  10-hapi-deployment.yaml
  20-hapi-service.yaml
  30-nginx-configmap.yaml
  31-nginx-deployment.yaml
  32-nginx-service.yaml
scripts/
  start.sh  status.sh  stop.sh  print-url.sh
crud/
  curl-crud.sh
data/
  patient.json
  practitioner.json
  update-patient.json
```

## 6) Siguientes pasos
- Cambia réplicas de HAPI para mostrar balanceo (escala Nginx si quieres).
- Reemplaza NodePort por Ingress si ya manejan ese concepto.
