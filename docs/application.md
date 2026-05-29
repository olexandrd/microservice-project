# Application

## Django Project

Path: `django`

The application is a minimal Django project named `olexandr_hw`. It exposes the Django admin route:

```text
/admin/
```

Runtime dependencies are listed in `django/requirements.txt`:

```text
Django==4.2
psycopg2-binary
```

The settings file reads PostgreSQL connection values from environment variables:

| Environment variable | Default |
| --- | --- |
| `POSTGRES_HOST` | `localhost` |
| `POSTGRES_PORT` | `5432` |
| `POSTGRES_DB` | `postgres` |
| `POSTGRES_USER` | `postgres` |
| `POSTGRES_PASSWORD` | empty string |

Note: the Helm chart currently uses `POSTGRES_NAME`, while Django settings read `POSTGRES_DB`. Align these names before relying on the chart-provided database name. Postgress password is 111111.

## Run Locally

From the `django` directory:

```sh
python -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt

export POSTGRES_HOST=localhost
export POSTGRES_PORT=5432
export POSTGRES_DB=postgres
export POSTGRES_USER=postgres
export POSTGRES_PASSWORD=replace-me

python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

If you do not have PostgreSQL available locally, either run one with Docker or temporarily switch the Django database settings to SQLite for local-only development.

## Docker Image

The Dockerfile is `django/Dockerfile`.

It uses:

- Base image: `python:3.13-alpine`
- Working directory: `/app`
- Exposed runtime command: `python manage.py runserver 0.0.0.0:8000`

Build locally:

```sh
docker build -t django-app:local django
```

Run locally:

```sh
docker run --rm -p 8000:8000 \
  -e POSTGRES_HOST=host.docker.internal \
  -e POSTGRES_PORT=5432 \
  -e POSTGRES_DB=postgres \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=replace-me \
  django-app:local
```

## Helm Chart

Path: `charts/django-app`

The chart deploys:

- `Deployment`
- `Service`
- `Ingress`
- `HorizontalPodAutoscaler`
- `ConfigMap`
- Optional Bitnami PostgreSQL dependency

Default image values:

```yaml
image:
  repository: 290480495560.dkr.ecr.us-east-2.amazonaws.com/app
  tag: latest
  pullPolicy: Always
```

Default service values:

```yaml
service:
  type: ClusterIP
  port: 8000
```

Default ingress host:

```text
django.stage.fixer.tools
```

Render the chart:

```sh
helm dependency update charts/django-app
helm template django charts/django-app
```

Install or upgrade:

```sh
helm upgrade --install django charts/django-app \
  --namespace default \
  --set image.repository=<ecr-repo-url> \
  --set image.tag=<tag> \
  --set ingress.host=<your-domain>
```

Use the optional PostgreSQL dependency for test environments:

```sh
helm upgrade --install django charts/django-app \
  --namespace default \
  --set postgresql.enabled=true \
  --set config.POSTGRES_HOST=django-postgresql
```

## CI Pipeline

Pipeline file: `django/Jenkinsfile`

Stages:

1. `Build & Push Docker Image`
   - Runs Kaniko in a Kubernetes agent pod.
   - Builds from `django/Dockerfile`.
   - Pushes to ECR.

2. `Update Chart Tag in Git`
   - Clones the GitHub repository.
   - Creates branch `cd`.
   - Updates `charts/django-app/values.yaml`.
   - Commits the new image tag.
   - Force-pushes `cd`.

The image tag format is:

```text
v1.0.<BUILD_NUMBER>
```

Argo CD watches the `cd` branch and automatically syncs the Helm chart.

## Operational Checks

Check the app deployment:

```sh
kubectl get deploy,svc,ingress,hpa -n default
```

Check app logs:

```sh
kubectl logs deploy/django-django -n default
```

Port-forward the service:

```sh
kubectl port-forward svc/django-django 8000:8000 -n default
```

Then open:

```text
http://localhost:8000/admin/
```

## Production Hardening Checklist

- Move the Django `SECRET_KEY` to an environment variable or secret manager.
- Set `DEBUG = False`.
- Configure `ALLOWED_HOSTS` from runtime configuration.
- Store database credentials in Kubernetes Secrets instead of ConfigMaps.
- Use a production WSGI server such as Gunicorn instead of `runserver`.
- Add health probes to the Deployment.
- Align `POSTGRES_NAME` and `POSTGRES_DB` configuration naming.
- Avoid hardcoded AWS account IDs and repository URLs in reusable chart or pipeline code.
