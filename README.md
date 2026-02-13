# ark-playwright-mcp

Playwright browser automation for [ARK](https://mckinsey.github.io/agents-at-scale-ark/) (Agentic Runtime for Kubernetes) via Microsoft's MCP server.

## What is this?

This package deploys Microsoft's production-ready [@playwright/mcp](https://github.com/microsoft/playwright) server to Kubernetes, enabling ARK agents to:
- Navigate web pages and interact with elements
- Take screenshots and generate PDFs
- Fill forms and test workflows
- Capture network requests and console logs
- Execute JavaScript in page context

**29 built-in tools** including `browser-navigate`, `browser-click`, `browser-screenshot`, `browser-snapshot`, `browser-console-messages`, and more.

## Quick Install

**Prerequisites:** Kubernetes cluster with [ARK installed](https://mckinsey.github.io/agents-at-scale-ark/), kubectl, Helm 3.x

### One-Line Install

```bash
curl -fsSL https://raw.githubusercontent.com/skokaina/ark-playwright-mcp/main/scripts/install.sh | bash
```

**What gets installed:**
- ✅ Playwright MCP server (Chromium browser)
- ✅ MCPServer CRD resource (auto-discovered by ARK)
- ✅ 29 browser automation tools
- ✅ 5Gi persistent storage for artifacts

### Manual Install

```bash
# Latest version
helm install ark-playwright oci://ghcr.io/skokaina/charts/ark-playwright-mcp

# Specific version
helm install ark-playwright oci://ghcr.io/skokaina/charts/ark-playwright-mcp --version 0.1.0

# Local development (OrbStack/Docker Desktop)
git clone https://github.com/skokaina/ark-playwright-mcp.git
cd ark-playwright-mcp
make quick-install-local
```

### Verify Installation

```bash
# Check MCPServer
kubectl get mcpserver playwright-browser
# Should show: AVAILABLE=True, TOOLS=29

# Check pod
kubectl get pods -l app=ark-playwright-mcp
# Should show: 1/1 Running

# View logs
kubectl logs -l app=ark-playwright-mcp
```

---

## Browser Modes

### Cluster Browser (Default)
Browser runs inside Kubernetes pod (headless Chromium).

**Pros:** Isolated, consistent, production-ready
**Cons:** Can't see what the browser is doing

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
```

**2. Deploy with CDP endpoint:**
```bash
helm upgrade ark-playwright chart/ \
  --set app.playwright.cdpEndpoint=http://host.docker.internal:9222 \
  --set app.playwright.headless=false
```

**3. Test:**
```bash
kubectl apply -f samples/ark-resources/query-screenshot.yaml
# Watch your local Chrome navigate to example.com!
```

---

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

---

## Test with ARK Agent

```bash
# Create agent
kubectl apply -f samples/ark-resources/agent-web-scraper.yaml

# Verify agent is available
kubectl get agent web-scraper

# Submit query
kubectl apply -f samples/ark-resources/query-screenshot.yaml

# Watch execution
kubectl get query test-screenshot -w

# View results (when completed)
kubectl get query test-screenshot -o jsonpath='{.status.response.content}'
```

---

## Available Tools (29)

**Navigation:** navigate, navigate-back, close, resize, tabs
**Interaction:** click, type, fill-form, select-option, drag, hover, press-key, file-upload
**Mouse:** mouse-click-xy, mouse-move-xy, mouse-drag-xy, mouse-down, mouse-up, mouse-wheel
**Inspection:** snapshot, take-screenshot, console-messages, network-requests
**Advanced:** evaluate, run-code, handle-dialog, pdf-save, install, wait-for

Full docs: [Microsoft Playwright MCP](https://github.com/microsoft/playwright)

---

## Quick Commands

```bash
# Local development (OrbStack/Docker Desktop)
make quick-install-local   # Build and deploy
make status                # Check deployment
make logs                  # View logs
make clean-local           # Remove deployment

# Verify cluster setup
make orbstack-setup        # OrbStack verification

# k3d cluster (for testing)
make e2e-setup            # Create k3d cluster
make quick-install        # Build and deploy to k3d
```

---

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

---

## Further Reading

### User Guides
- **[Architecture](docs/ARCHITECTURE.md)** - System design and integration
- **[Configuration](docs/CONFIGURATION.md)** - All Helm values and options
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

### Developer Guides
- **[Development](docs/DEVELOPMENT.md)** - Local development and testing

### Reference
- [Microsoft Playwright MCP](https://github.com/microsoft/playwright) - Upstream project
- [ARK Documentation](https://mckinsey.github.io/agents-at-scale-ark/) - ARK platform docs
- [Playwright Docs](https://playwright.dev/) - Playwright browser automation

---

## License

Apache-2.0 - see [LICENSE](LICENSE)
