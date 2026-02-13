#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CHART_REPO="oci://ghcr.io/skokaina/charts"
CHART_NAME="ark-playwright-mcp"
RELEASE_NAME="ark-playwright"
NAMESPACE="default"

echo -e "${GREEN}=== ark-playwright-mcp Installation ===${NC}\n"

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}Error: kubectl not found. Please install kubectl.${NC}"
    exit 1
fi

if ! command -v helm &> /dev/null; then
    echo -e "${RED}Error: helm not found. Please install Helm 3.x.${NC}"
    exit 1
fi

# Check kubectl connectivity
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster. Please configure kubectl.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Prerequisites met${NC}\n"

# Get current context
CONTEXT=$(kubectl config current-context)
echo -e "Current Kubernetes context: ${YELLOW}${CONTEXT}${NC}"
read -p "Continue with this context? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled."
    exit 1
fi

# Prompt for namespace
read -r -p "Enter namespace (default: ${NAMESPACE}): " INPUT_NAMESPACE
if [ -n "$INPUT_NAMESPACE" ]; then
    NAMESPACE=$INPUT_NAMESPACE
fi

# Create namespace if it doesn't exist
if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo "Creating namespace ${NAMESPACE}..."
    kubectl create namespace "$NAMESPACE"
fi

# Install or upgrade
echo -e "\n${GREEN}Installing ${CHART_NAME}...${NC}"

if helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
    echo "Existing installation found. Upgrading..."
    helm upgrade "$RELEASE_NAME" "$CHART_REPO/$CHART_NAME" \
        --namespace "$NAMESPACE" \
        --wait
else
    echo "Installing fresh..."
    helm install "$RELEASE_NAME" "$CHART_REPO/$CHART_NAME" \
        --namespace "$NAMESPACE" \
        --create-namespace \
        --wait
fi

# Verify installation
echo -e "\n${GREEN}Verifying installation...${NC}"

# Wait for deployment
kubectl wait --for=condition=available \
    --timeout=120s \
    deployment/ark-playwright-mcp \
    -n "$NAMESPACE" || true

# Check MCPServer
if kubectl get mcpserver playwright-browser -n "$NAMESPACE" &> /dev/null; then
    echo -e "${GREEN}✓ MCPServer created${NC}"
else
    echo -e "${YELLOW}⚠ MCPServer not found (may require ARK to be installed)${NC}"
fi

# Show status
echo -e "\n${GREEN}=== Installation Complete ===${NC}\n"
echo "Resources created:"
kubectl get deployment,service,mcpserver,pvc -n "$NAMESPACE" -l app=ark-playwright-mcp

echo -e "\n${GREEN}Next Steps:${NC}"
echo "1. Check deployment status:"
echo "   kubectl get pods -n ${NAMESPACE} -l app=ark-playwright-mcp"
echo ""
echo "2. View logs:"
echo "   kubectl logs -n ${NAMESPACE} -l app=ark-playwright-mcp -f"
echo ""
echo "3. Create an ARK agent:"
echo "   kubectl apply -f https://raw.githubusercontent.com/skokaina/ark-playwright-mcp/main/samples/ark-resources/agent-web-scraper.yaml"
echo ""
echo "For more information, see: https://github.com/skokaina/ark-playwright-mcp"
