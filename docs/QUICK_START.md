# Quick Start Guide

Get your local GitOps environment up and running in 5 minutes!

## Prerequisites

Install these tools (if not already installed):

```bash
# macOS
brew install docker kind kubectl

# Linux
# Follow official installation guides:
# - Docker: https://docs.docker.com/engine/install/
# - kind: https://kind.sigs.k8s.io/docs/user/quick-start/#installation
# - kubectl: https://kubernetes.io/docs/tasks/tools/
```

**Important:** Make sure Docker Desktop is running!

## Option 1: Automated Setup (Recommended) ⭐

### One Command Setup

```bash
# Clone repositories (if not already done)
git clone https://github.com/banicr/demo-app-repo.git app-repo
git clone https://github.com/banicr/demo-gitops-repo.git gitops-repo

# Run automated setup
cd app-repo
./scripts/setup-local-cluster.sh
```

That's it! The script will:
- ✅ Create kind cluster with proper configuration
- ✅ Install ArgoCD
- ✅ Deploy the demo Flask application
- ✅ Verify everything is working
- ✅ Save ArgoCD credentials to `argocd-credentials.txt`

### What You Get

After the script completes, you'll have:

- **Kind cluster**: `gitops-demo` 
- **ArgoCD**: Running in `argocd` namespace
- **Demo App**: Running in `demo-app` namespace
- **Credentials**: Saved in `argocd-credentials.txt`

### Access Your Environment

**1. Access the Application:**
```bash
# Application is exposed via NodePort on port 30080
open http://localhost:30080

# Test health endpoint
curl http://localhost:30080/healthz
# Should return: {"status":"ok"}

# Test root endpoint
curl http://localhost:30080/
# Should show HTML page with version
```

**2. Access ArgoCD UI:**
```bash
# Start port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open in browser (in another terminal)
open https://localhost:8080

# Login credentials:
# Username: admin
# Password: (see app-repo/scripts/argocd-credentials.txt)
```

**3. Watch for Changes:**
```bash
# Watch ArgoCD sync status
kubectl get application -n argocd demo-flask-app -w

# Watch application pods
kubectl get pods -n demo-app -w
```

## Option 2: Manual Setup

If you prefer to understand each step:

### Step 1: Create Kind Cluster

```bash
kind create cluster --name gitops-demo --config - <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30080
    hostPort: 30080
    protocol: TCP
EOF
```

### Step 2: Install ArgoCD

```bash
# Create namespace and install
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo
```

### Step 3: Deploy Application

```bash
# Apply ArgoCD Application manifest
kubectl apply -f gitops-repo/argocd-application.yaml

# Verify application is created
kubectl get application -n argocd demo-flask-app

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=demo-flask-app -n demo-app --timeout=180s
```

## Trigger a New Deployment

Now that your local environment is set up, trigger the full CI/CD pipeline:

### Step 1: Make a Change

```bash
cd app-repo

# Make a simple change (e.g., add a comment)
echo "# Version update test" >> app/main.py

# Or make a meaningful change:
# Edit app/main.py and modify the HTML in the home() function
```

### Step 2: Commit and Push

```bash
git add app/main.py
git commit -m "chore: Bump version to v2.1.0"
git push
```

### Step 3: Monitor the Pipeline

**Watch GitHub Actions:**
```bash
# Visit: https://github.com/banicr/demo-app-repo/actions
open https://github.com/banicr/demo-app-repo/actions
```

The pipeline will:
1. ✅ **Stage 1 - Lint**: Run flake8 and pylint
2. ✅ **Stage 2 - Test**: Run pytest with coverage
3. ✅ **Stage 3 - Build**: Build multi-platform Docker image and push to GHCR
4. ✅ **Stage 4 - E2E Test**: Test in ephemeral kind cluster
5. ✅ **Stage 5 - GitOps Update**: Update gitops-repo values.yaml with new image tag

Then:
6. ✅ **gitops-repo validation**: 6-job validation pipeline runs
7. ✅ **ArgoCD sync**: Auto-syncs to your local cluster within 3 minutes

**Watch Local Deployment:**
```bash
# Monitor gitops-repo for updates
cd ../gitops-repo
watch -n 5 'git pull && cat helm/demo-flask-app/values.yaml | grep tag:'

# Watch ArgoCD sync the changes
kubectl get application -n argocd demo-flask-app -w

# Watch pods rolling update
kubectl get pods -n demo-app -w
```

### Step 4: Verify New Version

```bash
# Check deployed image version
kubectl get deployment demo-flask-app -n demo-app -o jsonpath='{.spec.template.spec.containers[0].image}'
echo

# Should show: ghcr.io/banicr/demo-flask-app:{sha}-{run-number}

# Test the updated app via NodePort
curl http://localhost:30080/

# Check health
curl http://localhost:30080/healthz
```

## Common Commands

### Cluster Management

```bash
# List all kind clusters
kind get clusters

# Get current kubectl context
kubectl config current-context

# Switch to gitops-demo cluster
kubectl config use-context kind-gitops-demo

# Delete cluster (cleanup)
kind delete cluster --name gitops-demo
```

### ArgoCD Management

```bash
# Get ArgoCD password (saved during setup)
cat app-repo/scripts/argocd-credentials.txt

# Or retrieve directly from cluster
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# Port forward to ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Stop port forward (in another terminal)
pkill -f "port-forward.*argocd"

# View application status
kubectl get application -n argocd demo-flask-app

# Force sync
kubectl patch application demo-flask-app -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

### Application Management

```bash
# View all resources in demo-app namespace
kubectl get all -n demo-app

# View pods with image info
kubectl get pods -n demo-app -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'

# View application logs
kubectl logs -n demo-app -l app.kubernetes.io/name=demo-flask-app --tail=50

# Follow logs in real-time
kubectl logs -n demo-app -l app.kubernetes.io/name=demo-flask-app -f

# Describe pod for troubleshooting
kubectl describe pod -n demo-app -l app.kubernetes.io/name=demo-flask-app
```

### Testing Endpoints

```bash
# Test via NodePort (easiest - direct from host)
curl http://localhost:30080/healthz
curl http://localhost:30080/

# Test from within cluster (using internal service)
kubectl run test-curl --rm -i --restart=Never --image=curlimages/curl -- \
  curl -s http://demo-flask-app.demo-app.svc.cluster.local:8000/healthz

# Test with verbose output
curl -v http://localhost:30080/healthz
```

## Troubleshooting

### Pods in ImagePullBackOff

```bash
# Check what image the deployment is trying to use
kubectl get deployment demo-flask-app -n demo-app -o jsonpath='{.spec.template.spec.containers[0].image}'

# Check if image exists in GHCR
open https://github.com/banicr?tab=packages

# Force ArgoCD to refresh
kubectl delete application demo-flask-app -n argocd
kubectl apply -f gitops-repo/argocd-application.yaml
```

### ArgoCD Not Syncing

**Most Common Issue:** ArgoCD Application using inline helm values instead of valueFiles.

```bash
# Check application status
kubectl get application demo-flask-app -n argocd -o yaml

# Look for this in spec.source.helm:
# Should have: valueFiles: [values.yaml]
# Should NOT have: values: |

# Check ArgoCD controller logs (not server)
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller --tail=50

# Force sync
kubectl patch application demo-flask-app -n argocd \
  --type merge \
  --patch '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"normal"}}}'

# Or use argocd CLI
argocd app sync demo-flask-app
```

### Pipeline Failures

```bash
# Check GitHub Actions logs
open https://github.com/banicr/demo-app-repo/actions

# Common issues:
# 1. GITOPS_PAT secret not configured
# 2. Docker buildx issues
# 3. E2E test failures
# 4. Helm linting errors
```

### Cluster Issues

```bash
# Restart the cluster
kind delete cluster --name gitops-demo
cd app-repo
./scripts/setup-local-cluster.sh

# Check Docker is running
docker info

# Check kind cluster status
kind get clusters
kubectl cluster-info --context kind-gitops-demo

# Verify nodes are ready
kubectl get nodes
```

## Next Steps

Now that you have the basic setup working:

1. **Explore ArgoCD UI** - See real-time sync status and application health
2. **Make Code Changes** - Try modifying the Flask app and watch it deploy automatically
3. **Review Architecture** - Read `DEVOPS_ARCHITECTURE_GUIDE.md` for complete system overview
4. **Study the Implementation** - Read `PROJECT_RECREATION_GUIDE.md` to understand how it was built
5. **Add Monitoring** - Follow Phase 4 in the architecture guide to add Prometheus/Grafana (planned)
6. **Enhance Security** - Follow Phase 5 for network policies and security scanning (planned)

## Useful Links

- **ArgoCD UI**: https://localhost:8080 (after port-forward)
- **App Repository**: https://github.com/banicr/demo-app-repo
- **GitOps Repository**: https://github.com/banicr/demo-gitops-repo
- **GHCR Packages**: https://github.com/banicr?tab=packages
- **GitHub Actions**: https://github.com/banicr/demo-app-repo/actions

## Documentation

All documentation is in `gitops-repo/docs/`:

- `QUICK_START.md` - This file - 5-minute setup guide
- `SETUP_GUIDE.md` - Detailed setup instructions with all options
- `DEVOPS_ARCHITECTURE_GUIDE.md` - Complete architecture guide reflecting current implementation
- `PROJECT_RECREATION_GUIDE.md` - Step-by-step guide to recreate this system with AI prompts
- `PROJECT_README.md` - Overall project architecture and workflow

In repositories:
- `app-repo/README.md` - Application repository documentation
- `gitops-repo/README.md` - GitOps repository documentation

---

**Need Help?** Check the troubleshooting section or review the detailed guides above.

**Happy GitOps-ing! 🚀**
