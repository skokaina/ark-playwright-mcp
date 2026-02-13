# Troubleshooting

## Quick Diagnostics

```bash
# Check all resources
kubectl get deployment,pod,service,mcpserver,pvc -l app=ark-playwright-mcp

# View logs
kubectl logs -l app=ark-playwright-mcp --tail=100

# Describe pod
kubectl describe pod -l app=ark-playwright-mcp
```

## Common Issues

### Pod Not Starting

**Check status:**
```bash
kubectl get pods -l app=ark-playwright-mcp
kubectl describe pod -l app=ark-playwright-mcp
```

**Common causes:**
- **Image pull error**: Check image name/registry
- **Resource limits**: Increase memory/CPU
- **PVC not bound**: Check storage class

**Fix:**
```bash
# Disable storage if no PVC available
helm upgrade ark-playwright chart/ \
  --set storage.enabled=false
```

### Pod Crashing (CrashLoopBackOff)

**Check logs:**
```bash
kubectl logs -l app=ark-playwright-mcp --previous
```

**Common causes:**
- **Browser won't start**: Ensure `--no-sandbox` is set
- **Out of memory**: Increase memory limits
- **Permission denied**: Check security context

**Fix:**
```bash
# Increase memory
helm upgrade ark-playwright chart/ \
  --set app.resources.limits.memory=2Gi
```

### MCPServer Not Available

**Check status:**
```bash
kubectl get mcpserver playwright-browser -o yaml
```

**Common causes:**
- **Wrong transport**: Should be `http` not `sse`
- **Service not found**: Verify service exists
- **Connection refused**: Check pod is running

**Fix:**
```bash
# Verify service
kubectl get service ark-playwright-mcp

# Test endpoint
kubectl run test --rm -it --image=curlimages/curl --restart=Never -- \
  curl http://ark-playwright-mcp:8931/mcp
```

### Browser Timeout

**Error**: `Navigation timeout of 60000ms exceeded`

**Fix:**
```bash
# Increase timeout
helm upgrade ark-playwright chart/ \
  --set app.playwright.navigationTimeout=120000
```

### CDP Connection Failed (Local Browser)

**Verify Chrome is running:**
```bash
curl http://localhost:9222/json/version
```

**Check cluster can reach host:**
```bash
kubectl run test --rm -it --image=curlimages/curl --restart=Never -- \
  curl http://host.docker.internal:9222/json/version
```

**Fix:**
```bash
# Ensure Chrome started with debugging
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --remote-debugging-port=9222
```

### Artifacts Not Persisting

**Check PVC:**
```bash
kubectl get pvc ark-playwright-mcp-artifacts
kubectl describe pvc ark-playwright-mcp-artifacts
```

**Fix:**
```bash
# Increase PVC size
helm upgrade ark-playwright chart/ \
  --set storage.size=20Gi
```

## Error Messages

| Error | Fix |
|-------|-----|
| `ImagePullBackOff` | Check image name: `--set app.image.repository=ark-playwright-mcp` |
| `CrashLoopBackOff` | Check logs: `kubectl logs -l app=ark-playwright-mcp --previous` |
| `Pending` | Check PVC: `kubectl get pvc` |
| `OOMKilled` | Increase memory: `--set app.resources.limits.memory=2Gi` |
| `connection refused` | Check service: `kubectl get service ark-playwright-mcp` |
| `unknown option` | Check CLI args in deployment |

## Get Help

```bash
# Export diagnostics
kubectl logs -l app=ark-playwright-mcp > logs.txt
kubectl describe deployment ark-playwright-mcp > deployment.txt
kubectl describe pod -l app=ark-playwright-mcp > pod.txt
kubectl get mcpserver playwright-browser -o yaml > mcpserver.yaml
```
