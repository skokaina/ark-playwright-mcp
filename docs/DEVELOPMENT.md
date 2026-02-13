# Development

## Prerequisites

- Docker
- kubectl
- Helm 3.x
- OrbStack/k3d

## Setup

**OrbStack:**
```bash
make orbstack-setup
make quick-install-local
```

**k3d:**
```bash
make e2e-setup
make quick-install
```

## Workflow

```bash
# Make changes

# Rebuild and redeploy
make quick-install-local

# View logs
make logs

# Test
kubectl apply -f samples/ark-resources/query-screenshot.yaml
```

## Project Structure

```
ark-playwright-mcp/
├── Dockerfile              # Container image
├── Makefile               # Build automation
├── chart/                 # Helm chart
│   ├── templates/        # K8s manifests
│   └── values.yaml       # Configuration
├── docs/                 # Documentation
├── samples/              # Example resources
└── scripts/              # Helper scripts
```

## Testing

```bash
# Build
make build

# Test container
make test

# Deploy
make quick-install-local

# Check status
make status

# View logs
make logs
```

## Debugging

**Shell into pod:**
```bash
kubectl exec -it deployment/ark-playwright-mcp -- /bin/bash
```

**Test MCP endpoint:**
```bash
kubectl exec deployment/ark-playwright-mcp -- \
  curl http://localhost:8931/mcp
```

**Helm template:**
```bash
helm template ark-playwright chart/ --debug
```

**Enable debug logging:**
```bash
helm upgrade ark-playwright chart/ \
  --set app.playwright.consoleLevel=debug \
  --set app.playwright.saveTrace=true
```

## Release

```bash
# Update version in package.json and Chart.yaml
# Tag release
git tag v0.1.0
git push origin v0.1.0

# GitHub Actions will build and publish
```

## Cleanup

```bash
make clean-local        # Remove deployment
make clean-cluster      # Delete k3d cluster
```
