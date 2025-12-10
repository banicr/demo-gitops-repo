#!/bin/bash

set -e

CLUSTER_NAME="gitops-demo"

echo "🚀 Setting up local Kind cluster with ArgoCD..."
echo ""

# Check if kind is installed
if ! command -v kind &> /dev/null; then
    echo "❌ kind is not installed"
    echo "Install it with: brew install kind"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed"
    echo "Install it with: brew install kubectl"
    exit 1
fi

# Check if cluster already exists
if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
    echo "⚠️  Cluster '${CLUSTER_NAME}' already exists"
    read -p "Do you want to delete and recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Deleting existing cluster..."
        kind delete cluster --name ${CLUSTER_NAME}
    else
        echo "✅ Using existing cluster"
        kubectl cluster-info --context kind-${CLUSTER_NAME}
        exit 0
    fi
fi

echo "📦 Creating kind cluster: ${CLUSTER_NAME}..."
cat <<EOF | kind create cluster --name ${CLUSTER_NAME} --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 8080
    protocol: TCP
  - containerPort: 443
    hostPort: 8443
    protocol: TCP
EOF

echo "✅ Cluster created successfully"
echo ""

# Verify cluster
kubectl cluster-info --context kind-${CLUSTER_NAME}
kubectl get nodes
echo ""

# Install ArgoCD
echo "📦 Installing ArgoCD..."
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "⏳ Waiting for ArgoCD to be ready (this may take 2-3 minutes)..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

echo "✅ ArgoCD installed successfully"
echo ""

# Get ArgoCD password
echo "🔑 Getting ArgoCD admin password..."
sleep 5  # Wait for secret to be created
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 Setup Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 Cluster: ${CLUSTER_NAME}"
echo "🔐 ArgoCD Credentials:"
echo "   Username: admin"
echo "   Password: ${ARGOCD_PASSWORD}"
echo ""
echo "🌐 Access ArgoCD UI:"
echo "   1. Port-forward: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "   2. Open: https://localhost:8080"
echo "   3. Login with credentials above"
echo ""
echo "📦 Deploy the application:"
echo "   kubectl create namespace demo-app"
echo "   kubectl apply -f argocd-application.yaml"
echo ""
echo "🔍 Check application status:"
echo "   kubectl get applications -n argocd"
echo "   kubectl get pods -n demo-app"
echo ""
echo "🌐 Access the application:"
echo "   kubectl port-forward -n demo-app service/demo-flask-app 8081:80"
echo "   curl http://localhost:8081/healthz"
echo ""
echo "🗑️  To delete cluster later:"
echo "   kind delete cluster --name ${CLUSTER_NAME}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
