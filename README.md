# GitOps Repository - Demo Flask App

This repository contains the Kubernetes manifests and GitOps configuration for the Demo Flask App. It serves as the single source of truth for the deployed application state and is monitored by ArgoCD for automatic synchronization.

## Overview

This repository follows GitOps principles where:

- **Git is the source of truth** for application deployment state
- **All changes are declarative** using Kubernetes manifests
- **ArgoCD automatically syncs** changes to the cluster
- **CI pipeline updates** this repo when new versions are built
- **Deployment history is auditable** through Git commits

### GitOps Workflow

```
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│  Developer   │────────▶│  app-repo    │────────▶│ GitHub       │
│  changes     │ pushes  │  CI/CD       │ updates │ Actions      │
│  app code    │         │  pipeline    │         │              │
└──────────────┘         └──────────────┘         └──────┬───────┘
                                                           │
                                                           │ commits
                                                           ▼
                         ┌──────────────┐         ┌──────────────┐
                         │  Kubernetes  │◀────────│  gitops-repo │
                         │  Cluster     │  syncs  │  (this repo) │
                         └──────────────┘         └──────┬───────┘
                                ▲                         │
                                │ reconciles              │
                                │                         │
                         ┌──────┴───────┐               │
                         │   ArgoCD     │◀──────────────┘
                         │  (watches)   │    monitors
                         └──────────────┘
```

## Repository Structure

```
gitops-repo/
├── k8s/
│   └── base/                      # Base Kustomize configuration
│       ├── namespace.yaml         # demo-app namespace definition
│       ├── deployment.yaml        # Application Deployment
│       ├── service.yaml           # Application Service
│       └── kustomization.yaml     # Kustomize configuration
├── argocd-application.yaml        # ArgoCD Application manifest
├── .gitignore
└── README.md                      # This file
```

### Folder Structure Explained

#### `k8s/base/`

Contains the base Kubernetes manifests for the application. This structure allows for future expansion with overlays for different environments.

**Current Structure (Single Environment)**:
- `base/` - Shared base configuration

**Future Multi-Environment Structure**:
```
k8s/
├── base/              # Shared base manifests
│   ├── deployment.yaml
│   ├── service.yaml
│   └── kustomization.yaml
└── overlays/          # Environment-specific overrides
    ├── dev/
    │   └── kustomization.yaml
    ├── staging/
    │   └── kustomization.yaml
    └── production/
        └── kustomization.yaml
```

#### `argocd-application.yaml`

Defines the ArgoCD Application resource that:
- Points to this Git repository
- Specifies the path to manifests (`k8s/base`)
- Configures sync policies (auto-sync, prune, self-heal)
- Defines the target cluster and namespace

## Kubernetes Resources

### Namespace (`namespace.yaml`)

Creates the `demo-app` namespace with labels for organization and ArgoCD management.

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: demo-app
  labels:
    name: demo-app
    managed-by: argocd
```

### Deployment (`deployment.yaml`)

Defines the application Deployment with:

- **Replicas**: 2 (for high availability)
- **Container Image**: Placeholder that gets updated by CI pipeline
- **Environment Variables**:
  - `APP_VERSION`: Application version displayed in UI
  - `APP_NAME`: Application name
- **Resource Limits**: Conservative limits for demo purposes
  - Requests: 128Mi memory, 100m CPU
  - Limits: 256Mi memory, 500m CPU
- **Probes**:
  - **Liveness Probe**: Checks `/healthz` endpoint
  - **Readiness Probe**: Ensures pod is ready to receive traffic
- **Security Context**:
  - Runs as non-root user (UID 1000)
  - Drops all capabilities
  - Prevents privilege escalation

### Service (`service.yaml`)

Exposes the application within the cluster:

- **Type**: ClusterIP (internal cluster access)
- **Port**: 80 (external) → 5000 (container)
- **Selector**: Routes traffic to pods with `app: demo-flask-app` label

### Kustomization (`kustomization.yaml`)

Kustomize configuration that:

- **Resources**: Lists all manifests to include
- **Namespace**: Ensures all resources are created in `demo-app`
- **Images**: Defines the image name that CI will update
- **Common Labels**: Applies standard labels to all resources
- **Common Annotations**: Adds metadata for documentation

## ArgoCD Configuration

### Application Manifest

The `argocd-application.yaml` configures how ArgoCD manages this application:

#### Key Configuration Sections

**Source**:
```yaml
source:
  repoURL: https://github.com/YOUR_ORG/gitops-repo.git
  targetRevision: main
  path: k8s/base
```
- Points to this repository
- Monitors the `main` branch
- Uses manifests from `k8s/base` directory

**Destination**:
```yaml
destination:
  server: https://kubernetes.default.svc
  namespace: demo-app
```
- Deploys to the same cluster where ArgoCD runs
- Target namespace is `demo-app`

**Sync Policy**:
```yaml
syncPolicy:
  automated:
    prune: true        # Delete resources removed from Git
    selfHeal: true     # Revert manual cluster changes
  syncOptions:
    - CreateNamespace=true
```

**Automated Sync Behavior**:
- **Prune**: Resources deleted from Git are removed from cluster
- **Self-Heal**: Manual changes to cluster resources are reverted to match Git
- **CreateNamespace**: Automatically creates namespace if missing

**Sync Options**:
- Validates resources before applying
- Creates namespace automatically
- Retries failed syncs with exponential backoff

## Image Tag Management

### How Image Tags Are Updated

The CI pipeline in `app-repo` updates the image tag in this repository:

1. **Pipeline builds** new Docker image with tag: `{sha}-{run-number}`
2. **Pipeline clones** this gitops-repo
3. **Pipeline runs** `kustomize edit set image` to update `kustomization.yaml`
4. **Pipeline commits** and pushes the change
5. **ArgoCD detects** the Git change (within 3 minutes by default)
6. **ArgoCD syncs** the new image to the cluster

### Current Image Configuration

In `k8s/base/kustomization.yaml`:

```yaml
images:
  - name: demo-flask-app
    newName: DOCKERHUB_USERNAME/demo-flask-app
    newTag: latest
```

**Initial Setup**: Replace `DOCKERHUB_USERNAME` with your actual Docker Hub username.

**After CI Updates**: The `newTag` field will be updated to specific version tags like:
```yaml
newTag: abc1234-42  # {git-sha}-{run-number}
```

### Manual Image Update (Optional)

You can manually update the image tag:

```bash
# Install kustomize
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash

# Navigate to base directory
cd k8s/base

# Update image tag
./kustomize edit set image demo-flask-app=your-dockerhub-username/demo-flask-app:v2.0.0

# Commit and push
git add kustomization.yaml
git commit -m "Update to version v2.0.0"
git push origin main

# ArgoCD will detect and sync automatically
```

## Setup Instructions

### Prerequisites

- Kind cluster running (see `app-repo` setup script)
- ArgoCD installed in the cluster
- kubectl configured to access the cluster
- This repository cloned locally

### Initial Deployment

1. **Update repository URL** in `argocd-application.yaml`:
   ```yaml
   spec:
     source:
       repoURL: https://github.com/YOUR_ORG/gitops-repo.git  # Update this
   ```

2. **Update Docker Hub username** in `k8s/base/kustomization.yaml`:
   ```yaml
   images:
     - name: demo-flask-app
       newName: YOUR_DOCKERHUB_USERNAME/demo-flask-app  # Update this
       newTag: latest
   ```

3. **Apply the ArgoCD Application**:
   ```bash
   kubectl apply -f argocd-application.yaml
   ```

4. **Verify the application** in ArgoCD:
   ```bash
   # Check application status
   kubectl get application demo-flask-app -n argocd
   
   # Describe for detailed status
   kubectl describe application demo-flask-app -n argocd
   ```

5. **Watch synchronization**:
   ```bash
   # Watch pods being created
   kubectl get pods -n demo-app -w
   
   # Or view in ArgoCD UI at https://localhost:8080
   ```

### Verifying Deployment

```bash
# Check all resources in demo-app namespace
kubectl get all -n demo-app

# Expected output:
# NAME                                   READY   STATUS    RESTARTS   AGE
# pod/demo-flask-app-xxxxxxxxxx-xxxxx   1/1     Running   0          1m
# pod/demo-flask-app-xxxxxxxxxx-xxxxx   1/1     Running   0          1m
#
# NAME                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
# service/demo-flask-app   ClusterIP   10.96.xxx.xxx   <none>        80/TCP    1m
#
# NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
# deployment.apps/demo-flask-app   2/2     2            2           1m

# Check deployment image
kubectl get deployment demo-flask-app -n demo-app \
  -o jsonpath='{.spec.template.spec.containers[0].image}'; echo
```

### Accessing the Application

```bash
# Port forward to access locally
kubectl port-forward -n demo-app svc/demo-flask-app 9090:80

# Test endpoints
curl http://localhost:9090/healthz
# Expected: {"status":"ok"}

curl http://localhost:9090
# Expected: HTML page with version info

# Or open in browser: http://localhost:9090
```

## ArgoCD UI Verification

### Accessing ArgoCD

```bash
# Port forward ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d; echo
```

Open https://localhost:8080 and log in with:
- Username: `admin`
- Password: (from command above)

### ArgoCD Application View

In the ArgoCD UI, you'll see:

1. **Application Card**: Shows sync status, health, and last sync time
2. **Resource Tree**: Visual representation of all Kubernetes resources
3. **Sync Status**:
   - **Synced**: Git state matches cluster state
   - **OutOfSync**: Git has changes not yet applied
   - **Syncing**: Currently applying changes
4. **Health Status**:
   - **Healthy**: All resources are running correctly
   - **Progressing**: Deployment in progress
   - **Degraded**: Some resources have issues

### Triggering Manual Sync

If auto-sync is disabled or you want to sync immediately:

```bash
# Via kubectl
kubectl patch application demo-flask-app -n argocd \
  --type merge \
  -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'

# Or use ArgoCD CLI
argocd app sync demo-flask-app
```

## Monitoring Changes

### Watch for Git Commits

ArgoCD polls this repository every 3 minutes by default. To see when changes are detected:

```bash
# Watch application status
watch kubectl get application demo-flask-app -n argocd

# View sync history
kubectl describe application demo-flask-app -n argocd | grep -A 10 "Sync Status"
```

### View Sync History

```bash
# Get recent sync operations
kubectl get application demo-flask-app -n argocd \
  -o jsonpath='{.status.operationState}' | jq

# Or view in ArgoCD UI > Application > History
```

### Check Deployed Version

```bash
# See current image tag
kubectl get deployment demo-flask-app -n demo-app \
  -o jsonpath='{.spec.template.spec.containers[0].image}'; echo

# See environment variable version
kubectl get deployment demo-flask-app -n demo-app \
  -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="APP_VERSION")].value}'; echo
```

## Rollback Procedures

### Git-Based Rollback (Recommended)

Roll back by reverting to a previous Git commit:

```bash
# View commit history
git log --oneline

# Revert to previous commit
git revert HEAD

# Or reset to specific commit (careful!)
git reset --hard <commit-hash>
git push --force origin main

# ArgoCD will automatically sync the old version
```

### ArgoCD Rollback

Roll back to a previous sync using ArgoCD:

```bash
# Via ArgoCD UI:
# 1. Go to Application > History
# 2. Find the desired revision
# 3. Click "Rollback"

# Via ArgoCD CLI:
argocd app rollback demo-flask-app <revision-number>
```

## Multi-Environment Setup

### Adding Environment Overlays

To support multiple environments (dev, staging, production):

1. **Create overlay directories**:
   ```bash
   mkdir -p k8s/overlays/{dev,staging,production}
   ```

2. **Create environment-specific kustomization.yaml**:

   **`k8s/overlays/dev/kustomization.yaml`**:
   ```yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   
   namespace: demo-app-dev
   
   bases:
     - ../../base
   
   replicas:
     - name: demo-flask-app
       count: 1  # Single replica for dev
   
   namePrefix: dev-
   
   commonLabels:
     environment: dev
   ```

   **`k8s/overlays/production/kustomization.yaml`**:
   ```yaml
   apiVersion: kustomize.config.k8s.io/v1beta1
   kind: Kustomization
   
   namespace: demo-app-prod
   
   bases:
     - ../../base
   
   replicas:
     - name: demo-flask-app
       count: 3  # More replicas for production
   
   namePrefix: prod-
   
   commonLabels:
     environment: production
   
   # Additional production configurations
   patchesStrategicMerge:
     - resources.yaml  # Higher resource limits
   ```

3. **Create separate ArgoCD Applications**:

   **`argocd-application-dev.yaml`**:
   ```yaml
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: demo-flask-app-dev
     namespace: argocd
   spec:
     project: default
     source:
       repoURL: https://github.com/YOUR_ORG/gitops-repo.git
       targetRevision: main
       path: k8s/overlays/dev  # Dev overlay
     destination:
       server: https://kubernetes.default.svc
       namespace: demo-app-dev
     syncPolicy:
       automated:
         prune: true
         selfHeal: true
   ```

   **`argocd-application-prod.yaml`**:
   ```yaml
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: demo-flask-app-prod
     namespace: argocd
   spec:
     project: default
     source:
       repoURL: https://github.com/YOUR_ORG/gitops-repo.git
       targetRevision: main  # Or 'production' branch
       path: k8s/overlays/production  # Production overlay
     destination:
       server: https://kubernetes.default.svc
       namespace: demo-app-prod
     syncPolicy:
       automated:
         prune: false  # Manual pruning in prod
         selfHeal: false  # No auto-healing in prod
   ```

### Environment Promotion Strategy

**Option 1: Branch-Based**:
- `main` branch → dev environment
- `staging` branch → staging environment
- `production` branch → production environment
- Promote by merging branches

**Option 2: Tag-Based**:
- All environments use `main` branch
- Production uses specific Git tags
- Promote by updating `targetRevision` in ArgoCD Application

**Option 3: Directory-Based** (Current Structure):
- All environments in `main` branch
- Different overlay directories
- Promote by updating image tags in specific overlays

## Troubleshooting

### Application Out of Sync

**Symptoms**: ArgoCD shows "OutOfSync" status

**Check**:
```bash
# See what's different
kubectl get application demo-flask-app -n argocd \
  -o jsonpath='{.status.sync.status}'

# View in UI for visual diff
```

**Fix**:
- If expected: Wait for auto-sync or trigger manual sync
- If unexpected: Check recent Git commits

### Application Degraded

**Symptoms**: ArgoCD shows "Degraded" health status

**Check**:
```bash
# Check pod status
kubectl get pods -n demo-app

# Check pod logs
kubectl logs -n demo-app -l app=demo-flask-app

# Check events
kubectl get events -n demo-app --sort-by='.lastTimestamp'
```

**Common Issues**:
- Image pull errors: Check Docker Hub credentials/visibility
- Probe failures: Verify `/healthz` endpoint works
- Resource limits: Pods OOMKilled or CPU throttled

### ArgoCD Not Detecting Changes

**Symptoms**: Git commits not triggering sync

**Check**:
```bash
# Verify repository connection
kubectl get application demo-flask-app -n argocd \
  -o jsonpath='{.spec.source.repoURL}'

# Check ArgoCD repo-server logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-repo-server
```

**Fix**:
```bash
# Trigger manual refresh
kubectl patch application demo-flask-app -n argocd \
  --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"info":[{"name":"Reason","value":"Manual refresh"}]}}'

# Or increase polling frequency (default: 3 minutes)
# Edit argocd-cm ConfigMap
```

### Image Tag Not Updating

**Symptoms**: New image built but not deployed

**Check**:
```bash
# Verify kustomization.yaml in Git
cat k8s/base/kustomization.yaml

# Check if CI pipeline updated gitops-repo
git log --oneline -n 5
```

**Fix**:
- Verify CI pipeline has correct permissions
- Check GitHub Actions logs
- Manually update and commit image tag

## Security Considerations

### Current Security Features

- Non-root container execution (UID 1000)
- Dropped capabilities
- Read-only root filesystem (could be enhanced)
- Resource limits to prevent resource exhaustion
- Liveness/readiness probes for stability

### Production Enhancements

1. **Network Policies**:
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: demo-flask-app
     namespace: demo-app
   spec:
     podSelector:
       matchLabels:
         app: demo-flask-app
     ingress:
       - from:
           - namespaceSelector:
               matchLabels:
                 name: ingress-nginx
   ```

2. **Pod Security Standards**:
   ```yaml
   apiVersion: v1
   kind: Namespace
   metadata:
     name: demo-app
     labels:
       pod-security.kubernetes.io/enforce: restricted
   ```

3. **Secrets Management**:
   - Use Sealed Secrets or External Secrets Operator
   - Never commit plain secrets to Git
   - Rotate secrets regularly

4. **Image Security**:
   - Scan images for vulnerabilities (Trivy, Snyk)
   - Use specific image tags (not `latest`)
   - Sign images (Cosign)
   - Use private registry for sensitive apps

## Additional Resources

- [GitOps Principles](https://www.gitops.tech/)
- [ArgoCD Best Practices](https://argo-cd.readthedocs.io/en/stable/user-guide/best_practices/)
- [Kustomize Documentation](https://kubectl.docs.kubernetes.io/guides/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)

## Contributing

When making changes to this repository:

1. **Test locally** using `kubectl apply -k k8s/base`
2. **Verify syntax** with `kubectl apply --dry-run=client -k k8s/base`
3. **Document changes** in commit messages
4. **Follow conventions**:
   - Use semantic versioning for image tags
   - Keep manifests declarative
   - Avoid hard-coded values (use Kustomize)

---

**Questions or Issues?** Check the app-repo README or ArgoCD documentation.
# Trigger workflow - test public image pull
