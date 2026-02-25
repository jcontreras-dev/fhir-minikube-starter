# FHIR Secure Lab (HAPI + Keycloak + Envoy) on Minikube

Este paquete instala:
- **HAPI FHIR JPA Server** (R4) con **PostgreSQL**.
- **Keycloak** (OIDC/OAuth2) con **realm importado** para flujos `Client Credentials` y `Authorization Code + PKCE` (tipo SMART-like).
- **Envoy** como **API Gateway** que **valida JWT** (contra JWKS de Keycloak) antes de pasar a HAPI.
- **Ingress NGINX** (addon de Minikube) para exponer `http://fhir.local`.

> Objetivo didáctico: comparar flujos de seguridad (Server-to-Server vs. User Auth con PKCE) usando **Postman** y observar cómo el **gateway** bloquea/acepta peticiones en función del token JWT.

## Requisitos
- Minikube y kubectl (`minikube start`)
- Helm 3 (`helm version`)
- Addon ingress habilitado: `minikube addons enable ingress`
- Entrada en `/etc/hosts`: `$(minikube ip)  fhir.local`

## Instalación
```bash
kubectl create ns fhir-lab || true
helm upgrade --install fhir-secure-lab charts/fhir-secure-lab -n fhir-lab
kubectl -n fhir-lab rollout status deployment/hapi-fhir --timeout=300s
kubectl -n fhir-lab rollout status deployment/keycloak --timeout=300s
kubectl -n fhir-lab rollout status deployment/envoy --timeout=300s
```

## Probar sin token (debe FALLAR)
```bash
curl -i http://fhir.local/fhir/metadata
# 401 Unauthorized (Envoy jwt_authn lo exige)
```

## Obtener token (Client Credentials)
**Datos** (por defecto del realm importado):
- Token endpoint (vía port-forward recomendado): `http://localhost:8081/realms/fhir-lab/protocol/openid-connect/token`
- Client ID: `server-confidential`
- Client Secret: busca `serverClientSecret` en `charts/fhir-secure-lab/values.yaml`

```bash
kubectl -n fhir-lab port-forward svc/keycloak 8081:8080 &

KC=http://localhost:8081/realms/fhir-lab/protocol/openid-connect/token
CLIENT_ID=server-confidential
CLIENT_SECRET=<pega-tu-secreto>

ACCESS_TOKEN=$(curl -s -X POST $KC   -d "grant_type=client_credentials&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET"   | python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])")

curl -i -H "Authorization: Bearer $ACCESS_TOKEN" http://fhir.local/fhir/metadata
```

## Obtener token (Authorization Code + PKCE) – Postman
1. En **Postman**, crea una **Nueva Autorización OAuth 2.0**:
   - Auth URL: `http://localhost:8081/realms/fhir-lab/protocol/openid-connect/auth`
   - Token URL: `http://localhost:8081/realms/fhir-lab/protocol/openid-connect/token`
   - Client ID: `postman-public`
   - Client Type: **Public**
   - Callback URL: `https://oauth.pstmn.io/v1/callback`
   - Scope: `openid profile email`
   - **Use PKCE:** S256
2. `Get New Access Token` → login: **student / student**.
3. `Use Token` → prueba:
   ```bash
   curl -i -H "Authorization: Bearer <token>" http://fhir.local/fhir/Patient
   ```

## SMART on FHIR (nota)
Este lab emula un flujo SMART **simplificado**: genera un **JWT** con scopes OIDC (puedes agregar scopes SMART como `patient/*.read` en Keycloak). **Envoy** valida firma y `aud` si lo configuras en `values.yaml`. Para un servidor SMART completo, necesitarás un Authorization Server con soporte SMART y metadatos SMART; aquí nos centramos en **validación de JWT** previa al backend FHIR.

## Limpieza
```bash
helm uninstall fhir-secure-lab -n fhir-lab
kubectl delete ns fhir-lab
```

## Estructura
```
charts/fhir-secure-lab/
  Chart.yaml
  values.yaml
  templates/
    00-namespace.yaml
    10-postgres-hapi.yaml
    20-hapi.yaml
    30-keycloak.yaml
    40-envoy.yaml
    90-ingress.yaml
postman/
  FHIR_Secure_Lab.postman_collection.json
scripts/
  install.sh
  uninstall.sh
  push_to_github.sh
```

**Advertencia:** Todos los secretos en `values.yaml` son **demo**. Cambia contraseñas, secrets y usa HTTPS si publicas fuera de Minikube.

---

## Variante 2: **oauth2-proxy** (sesión por cookies, sin JWT hacia HAPI)
Habilita el subchart en `values.yaml` y reinstala:
```bash
# Edita charts/fhir-secure-lab/values.yaml
# oauth2Proxy:
#   enabled: true

helm upgrade --install fhir-secure-lab charts/fhir-secure-lab -n fhir-lab
echo "$(minikube ip) fhir-proxy.local"   # añade a /etc/hosts
```

- Navega a `http://fhir-proxy.local/` → redirige a Keycloak para login (OIDC).
- Tras autenticación, oauth2-proxy mantiene **sesión por cookie** y **proxy** al backend `hapi-fhir`.
- Útil para comparar con la **Variante 1 (Envoy + JWT)** que exige **Bearer Token**.

**Datos OIDC** (por defecto):
- Issuer: `http://keycloak.fhir-lab.svc:8080/realms/fhir-lab` (usa port-forward si lo accedes desde tu host)
- Client ID: `oauth2-proxy`
- Client Secret: en `Secret keycloak-secrets` (campo `OAUTH_PROXY_CLIENT_SECRET`)
