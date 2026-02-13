# Architecture

## System Design

```
ARK Agent
    ↓ MCP Protocol (HTTP)
MCPServer CRD (playwright-browser)
    ↓ Service Discovery
Kubernetes Service (ClusterIP:8931)
    ↓ Load Balance
Pod: ark-playwright-mcp
    ↓ Runs
@playwright/mcp Server
    ↓ Controls
Chromium Browser (headless)
```

## Components

### 1. Playwright MCP Server
- **Source**: Microsoft's `@playwright/mcp` (npm package)
- **Protocol**: HTTP with JSON-RPC
- **Port**: 8931
- **Endpoint**: `/mcp`
- **Transport**: HTTP (not SSE)

### 2. Browser
- **Default**: Headless Chromium (in-cluster)
- **Optional**: Remote browser via CDP endpoint
- **Sandbox**: Disabled (`--no-sandbox`) for containers

### 3. MCPServer CRD
```yaml
apiVersion: ark.mckinsey.com/v1alpha1
kind: MCPServer
metadata:
  name: playwright-browser
spec:
  address:
    valueFrom:
      serviceRef:
        name: ark-playwright-mcp
        port: http
        path: /mcp
  transport: http
  timeout: 90s
```

### 4. Kubernetes Resources
- **Deployment**: Runs MCP server + browser
- **Service**: ClusterIP on port 8931
- **PVC**: Stores artifacts (5Gi default)
- **ConfigMap**: Configuration

## Data Flow

### Tool Invocation
```
1. Agent calls tool (e.g., browser_navigate)
   ↓
2. ARK MCP client → HTTP POST /mcp
   ↓
3. Playwright MCP server receives request
   ↓
4. Launches/controls Chromium browser
   ↓
5. Browser executes action
   ↓
6. Result returned via HTTP response
   ↓
7. Agent receives result
```

### Artifact Storage
```
Browser generates artifact
   ↓
Saved to /app/artifacts (container)
   ↓
Backed by PVC (persistent)
   ↓
Accessible via kubectl cp
```

## Browser Modes

### In-Cluster (Default)
```
Pod → Chromium → Headless → Isolated
```
- Self-contained
- Production-ready
- No external dependencies

### CDP Remote (Debug)
```
Pod → CDP Client → host.docker.internal:9222 → Local Chrome
```
- Visual debugging
- See agent actions live
- Requires local Chrome with `--remote-debugging-port`

## Security

### Container
- Non-root user (UID 1000)
- No privileged escalation
- All capabilities dropped
- Browser sandbox disabled (mitigated by container isolation)

### Network
- ClusterIP only (internal)
- Optional origin filtering
- TCP health probes

### Storage
- Read-only root filesystem (optional)
- Dedicated artifacts volume
- 5Gi default limit

## Integration

### ARK Discovery
```
1. MCPServer CRD created by Helm
2. ARK controller discovers service
3. Tests HTTP /mcp endpoint
4. Discovers 29 tools
5. Registers tools in cluster
6. Agents can now use tools
```

### Tool Execution
```
Agent spec:
  mcpServers: [playwright-browser]

ARK resolves:
  playwright-browser → http://ark-playwright-mcp:8931/mcp

Agent invokes tool:
  POST /mcp with tool name + args

MCP server executes:
  Browser automation via Playwright API

Returns:
  Result to agent
```

## Resource Requirements

### Baseline (1 browser)
- CPU: 500m request, 2000m limit
- Memory: 1Gi request, 2Gi limit
- Storage: 5Gi for artifacts

### Heavy (multiple tabs, video)
- CPU: 1000m request, 4000m limit
- Memory: 2Gi request, 4Gi limit
- Storage: 20Gi for artifacts

## Comparison

| Aspect | Custom Build | Microsoft @playwright/mcp |
|--------|-------------|---------------------------|
| Development | 2-3 weeks | 3-4 days |
| Tools | Manual implementation | 29 built-in |
| Maintenance | Full responsibility | Microsoft maintains |
| Testing | None initially | Production-tested |
| Risk | High | Low |

**Decision**: Use Microsoft's implementation, package for ARK.
