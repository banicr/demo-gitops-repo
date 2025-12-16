# CI/CD + GitOps Setup Guide

## Overview

This project implements a complete CI/CD pipeline with GitOps principles:

```
Developer pushes to app-repo
    ↓
GitHub Actions CI/CD Pipeline:
  1. Run Tests (pytest)
  2. Build & Push Docker Image (to GHCR)
  3. Update GitOps Manifests (commit to gitops-repo)
    ↓
ArgoCD (running in kind cluster)
  - Detects manifest change
  - Automatically syncs to cluster
    ↓
Application deployed with new version
```

## Prerequisites

### 1. Create GitHub Personal Access Token (PAT)

The app-repo needs permission to update gitops-repo manifests.

**Steps:**
1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token with these scopes:
   - `repo` (Full control of private repositories)
   - `workflow` (Update GitHub Action workflows)
3. Copy the token (you'll only see it once!)

### 2. Add Secret to app-repo

1. Go to your `app-repo` on GitHub
2. Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Name: `GITOPS_PAT`
5. Value: Paste your PAT token
6. Click "Add secret"

## Setup Instructions

### Step 1: Setup Local Kind Cluster with ArgoCD

#### Option A: Automated Script (Recommended) ⭐

Run the comprehensive setup script from the app-repo:

```bash
# From the app-repo directory
cd app-repo
./scripts/setup-local-cluster.sh
```

**What this script does:**
- ✅ Checks prerequisites (Docker, kind, kubectl, helm)
- ✅ Cleans up existing clusters (if any)
- ✅ Creates kind cluster named `gitops-demo` with port mapping (30080:30080)
- ✅ Installs ArgoCD using official manifests
- ✅ Waits for ArgoCD components to be ready (two-phase waiting)
- ✅ Retrieves and saves ArgoCD admin credentials to `scripts/argocd-credentials.txt`
- ✅ Deploys the demo Flask application via ArgoCD
- ✅ Verifies deployment with health checks
- ✅ Provides next steps and useful commands

**Features:**
- Colored output with progress indicators
- Comprehensive error handling
- Setup time: 5-7 minutes

**Optional:** Specify a custom cluster name:
```bash
./scripts/setup-local-cluster.sh my-custom-cluster
```

#### Option B: Manual Setup

**1. Create Kind Cluster**

```bash
# Create cluster with port mapping for NodePort services
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

**2. Install ArgoCD**

```bash
# Create argocd namespace and install
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD server to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

**3. Get ArgoCD Admin Password**

```bash
# Extract the initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo  # Add newline
```

**4. Apply ArgoCD Application**

```bash
# Apply the Application manifest to sync with gitops-repo
kubectl apply -f ../gitops-repo/argocd-application.yaml

# Verify application is created
kubectl get application -n argocd demo-flask-app
```

**5. Access ArgoCD UI (Optional)**

```bash
# Port forward to access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &

# Open in browser: https://localhost:8080
# Username: admin
# Password: (from step 3)
```

**6. Verify Deployment**

```bash
# Check if application synced
kubectl get application -n argocd demo-flask-app

# Check pods are running
kubectl get pods -n demo-app

# Test health endpoint via NodePort
curl http://localhost:30080/healthz

# Or test from within cluster
kubectl run test-curl --rm -i --restart=Never --image=curlimages/curl -- \
  curl -s http://demo-flask-app.demo-app.svc.cluster.local:8000/healthz
```

Expected output: `{"status":"ok"}`

---

### Step 2: Trigger CI/CD Pipeline

After your local cluster is set up, any push to `app-repo` main branch will trigger the full CI/CD pipeline.

The pipeline will automatically:
1. Run linting (flake8, pylint)
2. Run unit tests (pytest)
3. Build multi-platform Docker image
4. Run E2E tests in ephemeral kind cluster
5. Push image to GHCR
6. Update gitops-repo Helm values with new image tag
7. ArgoCD detects change and auto-syncs to your local cluster

**To trigger a pipeline run:**

```bash
cd app-repo

# Make a simple change
echo "# Test change" >> README.md

# Or make a meaningful code change
# Edit app/main.py to modify the HTML content

# Commit and push
git add .
git commit -m "test: Trigger CI/CD pipeline"
git push

# Monitor pipeline at: https://github.com/banicr/demo-app-repo/actions
```

---

### Step 3: Monitor Deployment

**Watch ArgoCD sync the changes:**

```bash
# Watch application sync status
kubectl get application -n argocd demo-flask-app -w

# Watch pods rolling update
kubectl get pods -n demo-app -w

# Check application health
kubectl get application -n argocd demo-flask-app -o jsonpath='{.status.health.status}'
```

**Test the deployed application:**

```bash
# Test via NodePort (easiest - from host machine)
curl http://localhost:30080/healthz
curl http://localhost:30080/

# Or test from within cluster
kubectl run test-curl --rm -i --restart=Never --image=curlimages/curl -- \
  curl -s http://demo-flask-app.demo-app.svc.cluster.local:8000/healthz

# Get current image version
kubectl get deployment demo-flask-app -n demo-app -o jsonpath='{.spec.template.spec.containers[0].image}'
echo

# Should show: ghcr.io/banicr/demo-flask-app:{sha}-{run-number}
# Example: ghcr.io/banicr/demo-flask-app:064193f-32
```

---

## Cleanup

**Delete the kind cluster:**

```bash
kind delete cluster --name gitops-demo
```

**Stop ArgoCD port-forward (if running):**

```bash
# Find and kill port-forward process
ps aux | grep "port-forward.*argocd" | grep -v grep | awk '{print $2}' | xargs kill
```

---

## Troubleshooting

### Pods stuck in ImagePullBackOff

```bash
# Check deployment image
kubectl get deployment demo-flask-app -n demo-app -o jsonpath='{.spec.template.spec.containers[0].image}'

# Check if image exists in GHCR
# Visit: https://github.com/banicr?tab=packages

# Force ArgoCD to refresh
kubectl delete application demo-flask-app -n argocd
kubectl apply -f ../gitops-repo/argocd-application.yaml
```

### ArgoCD not syncing

**Most Common Issue:** Application manifest using inline helm values instead of valueFiles.

```bash
# Check application status
kubectl get application -n argocd demo-flask-app -o yaml

# Verify spec.source.helm uses valueFiles (not inline values)
# Should have:
#   helm:
#     valueFiles:
#       - values.yaml
# Should NOT have:
#   helm:
#     values: |
#       ...

# Force sync/refresh
kubectl patch application demo-flask-app -n argocd \
  --type merge \
  --patch '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"normal"}}}'

# Check ArgoCD application controller logs (not server)
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller --tail=50

# Or use argocd CLI
argocd app sync demo-flask-app
```

### Pipeline failures

```bash
# Check GitHub Actions logs
# Visit: https://github.com/banicr/demo-app-repo/actions

# Common issues:
# - GITOPS_PAT secret not configured
# - Image build failures (check Docker buildx)
# - E2E test failures (check kind cluster creation in CI)
```

---

## Quick Reference

**Useful Commands:**

```bash
# List all kind clusters
kind get clusters

# Get kubectl context
kubectl config current-context

# Switch to gitops-demo cluster
kubectl config use-context kind-gitops-demo

# View all resources in demo-app namespace
kubectl get all -n demo-app

# View ArgoCD applications
kubectl get applications -n argocd

# Get ArgoCD password (saved during setup)
cat app-repo/scripts/argocd-credentials.txt

# Or retrieve directly from cluster
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# Port forward to ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access application via NodePort
curl http://localhost:30080/healthz
```

**Important URLs:**
- ArgoCD UI: https://localhost:8080
- App Repo: https://github.com/banicr/demo-app-repo
- GitOps Repo: https://github.com/banicr/demo-gitops-repo
- GHCR Packages: https://github.com/banicr?tab=packages

---

## Additional Information

### Current Implementation Status

**Completed (Phases 1-3):**
- ✅ Application development (Python Flask)
- ✅ Containerization (Docker multi-platform)
- ✅ CI/CD Pipeline (5-stage GitHub Actions)
- ✅ GitOps manifests (Helm charts)
- ✅ ArgoCD setup and configuration
- ✅ Automated local setup script
- ✅ Comprehensive documentation

**Planned (Phases 4-7):**
- 🔄 Observability (Prometheus, Grafana, Loki)
- 🔄 Security Hardening (NetworkPolicies, image scanning)
- 🔄 Progressive Delivery (Argo Rollouts, canary)
- 🔄 Advanced Features (HPA, multi-environment)

### Repository Structure

**app-repo:** Application code and CI/CD
```
app-repo/
├── .github/workflows/ci.yml    # 5-stage CI/CD pipeline
├── app/                         # Flask application
├── tests/                       # Unit tests
├── scripts/
│   └── setup-local-cluster.sh  # Automated setup
├── Dockerfile                   # Multi-stage build
└── requirements.txt            # Dependencies
```

**gitops-repo:** Kubernetes manifests and documentation
```
gitops-repo/
├── .github/workflows/
│   └── validate.yml            # 6-job validation
├── helm/demo-flask-app/        # Helm chart
│   ├── values.yaml            # Auto-updated by CI
│   └── templates/             # K8s templates
├── docs/                       # Documentation
├── argocd-application.yaml    # ArgoCD config
└── README.md
```

---

## Deprecated GitHub Actions Setup (Old Method)

This creates:
- Kind cluster named `gitops-demo` (or your custom name)
- ArgoCD installed and configured
- Demo application deployed
- ArgoCD watching this gitops-repo for changes

**Note:** This is a **one-time setup**. You don't need to run this for every deployment.

### Step 2: Get ArgoCD Credentials

After the setup workflow completes:

1. Check the workflow summary for ArgoCD admin password
2. Or get it manually:
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret \
     -o jsonpath="{.data.password}" | base64 -d
   ```

### Step 3: Access ArgoCD UI (Optional)

```bash
# Port-forward ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access at: https://localhost:8080
# Username: admin
# Password: (from step 2)
```

### Step 4: Access the Application

```bash
# Port-forward the application
kubectl port-forward -n demo-app service/demo-flask-app 8081:80

# Test health endpoint
curl http://localhost:8081/healthz
# Returns: {"status":"ok"}

# View in browser
open http://localhost:8081
```

## CI/CD Workflow

### Automatic Deployment Flow

When you push code to `app-repo`:

1. **Test Stage**
   - Runs pytest unit tests
   - Must pass before proceeding

2. **Build Stage**
   - Builds Docker image
   - Tags with `{short-sha}-{run-number}` and `latest`
   - Pushes to GitHub Container Registry (GHCR)

3. **GitOps Update Stage** (main branch only)
   - Checks out `gitops-repo`
   - Updates `k8s/base/kustomization.yaml` with new image tag
   - Updates `k8s/base/deployment.yaml` APP_VERSION
   - Commits and pushes changes to `gitops-repo`

4. **ArgoCD Auto-Sync**
   - Detects manifest change in `gitops-repo`
   - Syncs new version to cluster automatically
   - Updates deployment with new image
   - Health checks confirm successful deployment

### Example: Making a Change

```bash
# 1. Make a code change in app-repo
cd app-repo
echo "# Updated" >> app/main.py

# 2. Commit and push
git add .
git commit -m "feat: Update application"
git push

# 3. Watch the pipeline
# Go to GitHub → app-repo → Actions
# See the 3-stage pipeline run

# 4. Watch ArgoCD sync
# In ArgoCD UI or CLI:
kubectl get applications -n argocd --watch

# 5. Verify deployment
kubectl get pods -n demo-app
kubectl port-forward -n demo-app service/demo-flask-app 8081:80
curl http://localhost:8081/healthz
```

## Architecture

### Current Repository Structure

**app-repo/** (Application Code & CI/CD)
- `app/` - Flask application source code
- `tests/` - Unit tests with pytest
- `scripts/setup-local-cluster.sh` - Automated setup script
- `.github/workflows/ci.yml` - 5-stage CI/CD pipeline
- `Dockerfile` - Multi-stage, multi-platform container build
- `requirements.txt` - Application dependencies
- `pytest.ini` - Test configuration

**gitops-repo/** (Deployment Manifests & Documentation)
- `helm/demo-flask-app/` - Helm chart for deployment
  - `Chart.yaml` - Chart metadata
  - `values.yaml` - Configuration values (auto-updated by CI)
  - `templates/` - Kubernetes resource templates
    - `deployment.yaml` - Application deployment
    - `service.yaml` - Service (NodePort on 30080)
    - `serviceaccount.yaml` - Service account
    - `namespace.yaml` - Namespace creation
    - `_helpers.tpl` - Helm template helpers
- `k8s/base/` - Kustomize alternative (backup)
- `docs/` - Complete documentation suite
- `argocd-application.yaml` - ArgoCD Application (uses valueFiles)
- `.github/workflows/validate.yml` - 6-job validation pipeline

### Image Tagging Strategy

**Current Format:** `{short-sha}-{run-number}`

**Example:** `064193f-32`
- `064193f` = First 7 characters of git commit SHA
- `32` = GitHub Actions run number

**Registry:** `ghcr.io/banicr/demo-flask-app:{tag}`

**Benefits:**
- ✅ Unique per build
- ✅ Traceable to source commit
- ✅ Supports easy rollback
- ✅ No "latest" tag ambiguity
- ✅ Sequential run numbers for ordering

### GitOps Principles

1. **Git as Single Source of Truth**
   - All deployment configuration in `gitops-repo`
   - Infrastructure and apps defined declaratively

2. **Declarative Configuration**
   - Kubernetes manifests describe desired state
   - ArgoCD ensures cluster matches manifests

3. **Automated Synchronization**
   - ArgoCD continuously monitors `gitops-repo`
   - Auto-syncs changes to cluster
   - Self-healing if manual changes made

4. **Version Control**
   - Every deployment has git commit history
   - Easy rollback: revert commit, ArgoCD syncs
   - Audit trail of all changes

## Troubleshooting

### Pipeline Fails at Test Stage

```bash
# Run tests locally
cd app-repo
pip install -r requirements.txt -r requirements-test.txt
pytest tests/ -v
```

### Pipeline Fails at GitOps Update

Check if `GITOPS_PAT` secret is set:
1. Go to app-repo → Settings → Secrets → Actions
2. Verify `GITOPS_PAT` exists
3. If missing, follow "Prerequisites" section above

### ArgoCD Not Syncing

```bash
# Check ArgoCD application status
kubectl get applications -n argocd

# View application details
kubectl describe application demo-flask-app -n argocd

# Check ArgoCD logs
kubectl logs -n argocd deployment/argocd-application-controller

# Manually trigger sync
kubectl patch application demo-flask-app -n argocd \
  --type merge -p '{"spec":{"syncPolicy":{"automated":null}}}'
kubectl patch application demo-flask-app -n argocd \
  --type merge -p '{"spec":{"syncPolicy":{"automated":{"prune":true,"selfHeal":true}}}}'
```

### Application Not Running

```bash
# Check pods
kubectl get pods -n demo-app

# View pod logs
kubectl logs -n demo-app -l app=demo-flask-app

# Describe pod for events
kubectl describe pod -n demo-app -l app=demo-flask-app

# Check image pull status
kubectl get events -n demo-app --sort-by='.lastTimestamp'
```

### Image Pull Errors

If you see `ImagePullBackOff`:

1. Verify image exists in GHCR:
   ```bash
   # Check GitHub packages
   # Go to: https://github.com/banicr?tab=packages
   ```

2. Check if image is public:
   - Go to package settings
   - Make package public if needed

3. Verify image tag in manifests:
   ```bash
   cd gitops-repo
   cat k8s/base/kustomization.yaml | grep newTag
   ```

## Cleanup

```bash
# Delete the kind cluster
kind delete cluster --name gitops-demo

# Or if using custom name
kind delete cluster --name <your-cluster-name>
```

## Next Steps

### Explore the System

1. **Access ArgoCD UI:** See real-time sync status
2. **Make Code Changes:** Watch automated deployment
3. **Review Logs:** Check application and ArgoCD logs
4. **Test Rollback:** Revert a commit and watch ArgoCD sync

### Extend the Implementation

**Phase 4: Add Observability (Planned)**
- Install Prometheus & Grafana
- Add application metrics
- Create dashboards
- Set up alerting

**Phase 5: Enhance Security (Planned)**
- Add NetworkPolicies
- Implement image scanning (Trivy)
- Add OPA Gatekeeper policies
- Configure External Secrets Operator

**Phase 6: Progressive Delivery (Planned)**
- Install Argo Rollouts
- Implement canary deployments
- Add automatic rollback on failure

### Multi-Environment Setup

Extend to multiple environments using Helm:

```
gitops-repo/
  helm/demo-flask-app/
    values.yaml           # Base values
    values-dev.yaml       # Development overrides
    values-staging.yaml   # Staging overrides
    values-prod.yaml      # Production overrides
```

### Notifications

Add Slack/email notifications:
- In app-repo CI for build failures
- In ArgoCD for sync status

### Advanced ArgoCD Features

- **Sync Waves**: Control deployment order
- **Sync Hooks**: Pre/post sync actions
- **Health Checks**: Custom health assessments
- **Rollback**: Automated rollback on failure

## References

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kustomize Documentation](https://kustomize.io/)
- [Kind Documentation](https://kind.sigs.k8s.io/)
- [GitOps Principles](https://www.gitops.tech/)



✅ Persistent Local Cluster

Kind cluster gitops-demo is running on your machine
ArgoCD is installed and accessible at https://localhost:8080
Username: admin
Password: oqQiD2mSHQpls6OL
✅ ArgoCD Application Deployed

Application demo-flask-app is registered in ArgoCD
ArgoCD is watching gitops-repo for changes
Auto-sync is enabled
✅ CI/CD Pipeline Complete

Test stage: Runs pytest ✅
Build stage: Builds Docker image ✅
GitOps stage: Updates manifests in gitops-repo ✅
✅ GitOps Flow Working

Pushed code to app-repo
CI updated gitops-repo with new image tag 72c2efb-21
ArgoCD detected the change and synced