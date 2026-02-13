.PHONY: help build test deploy quick-install quick-install-local orbstack-setup e2e-setup e2e clean clean-local lint

# Variables
IMAGE_NAME := ark-playwright-mcp
IMAGE_TAG := latest
REGISTRY := ghcr.io/skokaina
CHART_NAME := ark-playwright-mcp
NAMESPACE := default
RELEASE_NAME := ark-playwright

help: ## Show this help message
	@echo "Available targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-20s %s\n", $$1, $$2}'

build: ## Build Docker image
	@echo "Building Docker image..."
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) .
	@echo "Image built: $(IMAGE_NAME):$(IMAGE_TAG)"

build-multiarch: ## Build multi-architecture Docker image
	@echo "Building multi-arch Docker image..."
	docker buildx build --platform linux/amd64,linux/arm64 \
		-t $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG) \
		--push .

tag: ## Tag Docker image for registry
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

push: tag ## Push Docker image to registry
	@echo "Pushing image to registry..."
	docker push $(REGISTRY)/$(IMAGE_NAME):$(IMAGE_TAG)

lint: ## Lint Helm chart and shell scripts
	@echo "Linting Helm chart..."
	helm lint chart/
	@echo "Checking YAML syntax..."
	yamllint chart/ || true
	@echo "Checking shell scripts..."
	shellcheck scripts/*.sh || true

test: ## Run basic tests
	@echo "Testing Docker image..."
	docker run --rm -d --name $(IMAGE_NAME)-test -p 8931:8931 $(IMAGE_NAME):$(IMAGE_TAG)
	@sleep 5
	@echo "Checking health endpoint..."
	curl -f http://localhost:8931/health || (docker stop $(IMAGE_NAME)-test && exit 1)
	@echo "Stopping test container..."
	docker stop $(IMAGE_NAME)-test
	@echo "Tests passed!"

helm-template: ## Generate Helm templates
	@echo "Generating Helm templates..."
	helm template $(RELEASE_NAME) chart/ --namespace $(NAMESPACE)

helm-install: ## Install Helm chart
	@echo "Installing Helm chart..."
	helm install $(RELEASE_NAME) chart/ \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--wait

helm-upgrade: ## Upgrade Helm chart
	@echo "Upgrading Helm chart..."
	helm upgrade $(RELEASE_NAME) chart/ \
		--namespace $(NAMESPACE) \
		--wait

helm-uninstall: ## Uninstall Helm chart
	@echo "Uninstalling Helm chart..."
	helm uninstall $(RELEASE_NAME) --namespace $(NAMESPACE)

deploy: build helm-install ## Build and deploy to Kubernetes

quick-install: build ## Quick iteration (build + load to k3d + upgrade)
	@echo "Loading image to k3d..."
	k3d image import $(IMAGE_NAME):$(IMAGE_TAG) -c ark-cluster || true
	@echo "Upgrading Helm chart..."
	helm upgrade --install $(RELEASE_NAME) chart/ \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--set app.image.repository=$(IMAGE_NAME) \
		--set app.image.tag=$(IMAGE_TAG) \
		--set app.image.pullPolicy=Never \
		--wait

quick-install-local: build ## Quick local install (OrbStack/Docker Desktop/Minikube)
	@echo "Deploying to local Kubernetes (OrbStack/Docker Desktop)..."
	@echo "Current context: $$(kubectl config current-context)"
	@echo "Upgrading Helm chart..."
	helm upgrade --install $(RELEASE_NAME) chart/ \
		--namespace $(NAMESPACE) \
		--create-namespace \
		--set app.image.repository=$(IMAGE_NAME) \
		--set app.image.tag=$(IMAGE_TAG) \
		--set app.image.pullPolicy=IfNotPresent \
		--set storage.storageClass="" \
		--wait
	@echo ""
	@echo "✅ Deployment complete!"
	@echo ""
	@echo "Quick commands:"
	@echo "  make status  - Check deployment status"
	@echo "  make logs    - View logs"
	@echo "  kubectl get pods -l app=$(CHART_NAME)"

orbstack-setup: ## Verify OrbStack Kubernetes setup
	@echo "Checking OrbStack setup..."
	@echo ""
	@echo "Kubernetes context:"
	@kubectl config current-context
	@echo ""
	@echo "Kubernetes version:"
	@kubectl version --short 2>/dev/null || kubectl version --client
	@echo ""
	@echo "Nodes:"
	@kubectl get nodes
	@echo ""
	@echo "Storage classes:"
	@kubectl get storageclass
	@echo ""
	@echo "✅ OrbStack Kubernetes is ready!"
	@echo ""
	@echo "Next step: make quick-install-local"

e2e-setup: ## Create k3d cluster with ARK
	@echo "Creating k3d cluster..."
	k3d cluster create ark-cluster \
		--agents 1 \
		--port "8080:80@loadbalancer" \
		--port "8443:443@loadbalancer" || true
	@echo "Installing ARK..."
	@echo "Note: ARK installation steps would go here"
	@echo "Cluster ready!"

e2e: ## Run E2E tests
	@echo "Running E2E tests..."
	npm install --prefix e2e
	npm run test --prefix e2e

clean: helm-uninstall ## Remove deployment and clean artifacts
	@echo "Cleaning up..."
	docker rmi $(IMAGE_NAME):$(IMAGE_TAG) || true
	rm -rf artifacts/ screenshots/ videos/ traces/
	@echo "Cleanup complete!"

clean-local: ## Remove local deployment (OrbStack/Docker Desktop)
	@echo "Removing Helm release..."
	helm uninstall $(RELEASE_NAME) --namespace $(NAMESPACE) || true
	@echo "Cleaning up Docker image..."
	docker rmi $(IMAGE_NAME):$(IMAGE_TAG) || true
	@echo "Removing artifacts..."
	rm -rf artifacts/ screenshots/ videos/ traces/
	@echo "✅ Local cleanup complete!"

clean-cluster: ## Delete k3d cluster
	@echo "Deleting k3d cluster..."
	k3d cluster delete ark-cluster

status: ## Show deployment status
	@echo "Deployment status:"
	@kubectl get deployment,service,mcpserver,pvc -n $(NAMESPACE) -l app=$(CHART_NAME)

logs: ## Show pod logs
	@kubectl logs -n $(NAMESPACE) -l app=$(CHART_NAME) -f

version: ## Show current version
	@echo "Version: $(shell grep '^version:' chart/Chart.yaml | awk '{print $$2}')"
