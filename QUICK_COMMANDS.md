# Quick Start Commands

## Check Cluster Status
```bash
# View cluster
kind get clusters

# Check ArgoCD pods
kubectl get pods -n argocd

# Wait for ArgoCD to be ready (run this and wait 2-3 minutes)
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
```

## Get ArgoCD Password
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
```

## Access ArgoCD UI
```bash
# Terminal 1: Port-forward ArgoCD (keep running)
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Terminal 2: Open in browser
open https://localhost:8080
# OR
# Visit: https://localhost:8080
# Username: admin
# Password: (from command above)
```

## Deploy the Application
```bash
# Create namespace
kubectl create namespace demo-app

# Deploy ArgoCD Application
kubectl apply -f argocd-application.yaml

# Watch ArgoCD sync (will auto-sync within 3 minutes)
kubectl get applications -n argocd --watch

# Check application pods
kubectl get pods -n demo-app --watch
```

## Access the Application
```bash
# Terminal 1: Port-forward app (keep running)
kubectl port-forward -n demo-app service/demo-flask-app 8081:80

# Terminal 2: Test the app
curl http://localhost:8081/healthz
# OR open in browser
open http://localhost:8081
```

## Useful Commands
```bash
# Check application status in ArgoCD
kubectl get applications -n argocd
kubectl describe application demo-flask-app -n argocd

# Check pods
kubectl get pods -n demo-app
kubectl logs -n demo-app -l app=demo-flask-app

# Check all resources
kubectl get all -n demo-app

# Force ArgoCD sync (if needed)
kubectl patch application demo-flask-app -n argocd \
  -p '{"spec":{"syncPolicy":{"automated":null}}}' --type merge
kubectl patch application demo-flask-app -n argocd \
  -p '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}' --type merge
```

## Clean Up
```bash
# Delete the kind cluster
kind delete cluster --name gitops-demo
```
