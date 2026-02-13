# ark-playwright-mcp

Playwright browser automation for ARK agents via Microsoft's MCP server.

## Quick Install

**OrbStack/Docker Desktop:**
```bash
make orbstack-setup        # Verify Kubernetes
make quick-install-local   # Build and deploy
```

**k3d:**
```bash
make e2e-setup      # Create cluster
make quick-install  # Build and deploy
```

**Production:**
```bash
helm install ark-playwright oci://ghcr.io/skokaina/charts/ark-playwright-mcp
```

## Verify Installation

```bash
# Check deployment
kubectl get mcpserver playwright-browser
# Should show: AVAILABLE=True, TOOLS=29

# Check pod
kubectl get pods -l app=ark-playwright-mcp
# Should show: 1/1 Running

# View logs
kubectl logs -l app=ark-playwright-mcp
```

## Browser Modes

### Cluster Browser (Default)

Browser runs inside Kubernetes pod (headless Chromium).

**Pros**: Isolated, consistent, production-ready
**Cons**: Can't see what the browser is doing

### Local Browser (Debug Mode)

Connect to your local Chrome browser to see agent actions in real-time.

**1. Start Chrome with remote debugging:**
```bash
# macOS
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9222 \
  --user-data-dir=/tmp/chrome-debug

# Linux
google-chrome --remote-debugging-port=9222 \
  --user-data-dir=/tmp/chrome-debug

# Windows
"C:\Program Files\Google\Chrome\Application\chrome.exe" \
  --remote-debugging-port=9222 \
  --user-data-dir=C:\temp\chrome-debug
```

**2. Deploy with CDP endpoint:**
```bash
helm upgrade ark-playwright chart/ \
  --set app.image.repository=ark-playwright-mcp \
  --set app.image.tag=latest \
  --set app.image.pullPolicy=IfNotPresent \
  --set app.playwright.cdpEndpoint=http://host.docker.internal:9222 \
  --set app.playwright.headless=false
```

**3. Test:**
```bash
kubectl apply -f samples/ark-resources/query-screenshot.yaml
# Watch your local Chrome navigate to example.com!
```

**Verify CDP connection:**
```bash
# Check logs for CDP connection
kubectl logs -l app=ark-playwright-mcp | grep -i cdp
```

## Access Artifacts

Artifacts (screenshots, PDFs, traces, videos) are stored in `/app/artifacts` inside the pod.

**List artifacts:**
```bash
kubectl exec deployment/ark-playwright-mcp -- ls -la /app/artifacts
```

**Download screenshot:**
```bash
POD=$(kubectl get pod -l app=ark-playwright-mcp -o jsonpath='{.items[0].metadata.name}')
kubectl cp $POD:/app/artifacts/screenshot.png ./screenshot.png
open screenshot.png  # macOS
```

**Download all artifacts:**
```bash
kubectl cp $POD:/app/artifacts ./artifacts
```

**Enable video recording:**
```bash
helm upgrade ark-playwright chart/ \
  --set app.playwright.saveVideo="1280x720"
# Videos saved as .webm files
```

**Enable trace recording:**
```bash
helm upgrade ark-playwright chart/ \
  --set app.playwright.saveTrace=true
# View traces at https://trace.playwright.dev/
```

## Test with ARK Agent

```bash
# Create agent
kubectl apply -f samples/ark-resources/agent-web-scraper.yaml

# Submit query
kubectl apply -f samples/ark-resources/query-screenshot.yaml

# Watch execution
kubectl get query test-screenshot -w

# View results
kubectl get query test-screenshot -o jsonpath='{.status.response}'
```

## Configuration

Key settings in `chart/values.yaml`:

```yaml
app:
  playwright:
    headless: true              # false = show browser UI
    browser: chromium           # chrome, firefox, webkit
    cdpEndpoint: ""             # Remote browser CDP URL
    saveTrace: false            # Enable trace recording
    saveVideo: ""               # e.g. "1280x720" to enable
    allowedOrigins: []          # Whitelist domains

  resources:
    requests:
      cpu: 500m
      memory: 1Gi
    limits:
      cpu: 2000m
      memory: 2Gi
```

## Available Tools (29)

**Navigation**: navigate, navigate-back, close, resize, tabs
**Interaction**: click, type, fill-form, select-option, drag, hover, press-key, file-upload
**Mouse**: mouse-click-xy, mouse-move-xy, mouse-drag-xy, mouse-down, mouse-up, mouse-wheel
**Inspection**: snapshot, take-screenshot, console-messages, network-requests
**Advanced**: evaluate, run-code, handle-dialog, pdf-save, install, wait-for

Full docs: [Microsoft Playwright MCP](https://github.com/microsoft/playwright)

## Troubleshooting

**Pod not starting:**
```bash
kubectl describe pod -l app=ark-playwright-mcp
kubectl logs -l app=ark-playwright-mcp
```

**MCPServer not available:**
```bash
kubectl get mcpserver playwright-browser -o yaml
# Check status.conditions for errors
```

**Connection refused:**
```bash
# Test endpoint
kubectl run test --rm -it --image=curlimages/curl --restart=Never -- \
  curl http://ark-playwright-mcp:8931/mcp
```

**CDP not connecting (local browser):**
```bash
# Verify Chrome is running with debugging
curl http://localhost:9222/json/version

# Check OrbStack can reach host
kubectl run test --rm -it --image=curlimages/curl --restart=Never -- \
  curl http://host.docker.internal:9222/json/version
```

## Development

```bash
# Fast iteration
make quick-install-local

# View status
make status

# View logs
make logs

# Clean up
make clean-local
```

## Documentation

- [Architecture](docs/ARCHITECTURE.md) - System design
- [Configuration](docs/CONFIGURATION.md) - All options
- [Development](docs/DEVELOPMENT.md) - Local development
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues

## License

Apache-2.0 - see [LICENSE](LICENSE)
