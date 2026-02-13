# Configuration

## Helm Values Reference

```yaml
app:
  name: ark-playwright-mcp
  image:
    repository: ghcr.io/skokaina/ark-playwright-mcp
    tag: latest
    pullPolicy: IfNotPresent
  port: 8931

  playwright:
    # Browser
    headless: true                 # false = show browser UI
    browser: chromium              # chromium, firefox, webkit, chrome, edge
    cdpEndpoint: ""                # Remote browser CDP URL (overrides browser)
    noSandbox: true                # Required in containers

    # Timeouts (milliseconds)
    actionTimeout: 5000            # Click, type, etc.
    navigationTimeout: 60000       # Page navigation

    # Logging
    consoleLevel: info             # error, warning, info, debug

    # Artifacts
    outputDir: /app/artifacts
    saveTrace: false               # Playwright trace
    saveVideo: ""                  # e.g. "1280x720"

    # Network
    allowedOrigins: []             # Whitelist (empty = allow all)
    blockedOrigins: []             # Blacklist

    # Performance
    snapshotMode: incremental      # incremental, full, none

    # Capabilities
    capabilities:
      vision: true                 # Mouse/coordinate control
      pdf: true                    # PDF generation
      devtools: false              # DevTools integration

  resources:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 2000m
      memory: 2Gi

mcp:
  enabled: true
  timeout: 90s

storage:
  enabled: true
  size: 5Gi
  mountPath: /app/artifacts
  storageClass: ""                 # Use cluster default

securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL

service:
  type: ClusterIP
  port: 8931
  annotations: {}
```

## Common Configurations

### Production
```yaml
app:
  playwright:
    headless: true
    consoleLevel: warning
    saveTrace: false
    saveVideo: ""
  resources:
    requests:
      cpu: 500m
      memory: 1Gi
```

### Debug
```yaml
app:
  playwright:
    headless: false
    consoleLevel: debug
    saveTrace: true
    saveVideo: "1280x720"
  resources:
    limits:
      cpu: 4000m
      memory: 4Gi
```

### Local Browser
```yaml
app:
  playwright:
    headless: false
    cdpEndpoint: http://host.docker.internal:9222
```

### Cost-Optimized
```yaml
app:
  playwright:
    headless: true
    consoleLevel: error
  resources:
    requests:
      cpu: 250m
      memory: 512Mi
    limits:
      cpu: 1000m
      memory: 1Gi
storage:
  enabled: false
```

## Apply Configuration

```bash
# Custom values file
helm upgrade ark-playwright chart/ -f my-values.yaml

# Inline values
helm upgrade ark-playwright chart/ \
  --set app.playwright.headless=false \
  --set app.playwright.saveVideo="1280x720"
```
