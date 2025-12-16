# Project Recreation Guide

**Complete Guide to Recreating This CI/CD + GitOps System from Scratch**

This document provides step-by-step instructions, AI prompts, and configuration details to help you recreate this entire CI/CD + GitOps system, either for learning, customization, or adapting to your own projects.

---

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)
2. [Phase 1: Planning & Requirements](#phase-1-planning--requirements)
3. [Phase 2: Application Development](#phase-2-application-development)
4. [Phase 3: Containerization](#phase-3-containerization)
5. [Phase 4: CI/CD Pipeline](#phase-4-cicd-pipeline)
6. [Phase 5: GitOps Repository](#phase-5-gitops-repository)
7. [Phase 6: ArgoCD Setup](#phase-6-argocd-setup)
8. [Phase 7: Testing & Validation](#phase-7-testing--validation)
9. [Phase 8: Documentation](#phase-8-documentation)
10. [AI Prompts Library](#ai-prompts-library)
11. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Required Knowledge

- **Basic**: Git, GitHub, command line
- **Intermediate**: Python, Docker, Kubernetes concepts
- **Advanced**: CI/CD pipelines, GitOps principles

### Required Tools

Install these before starting:

```bash
# macOS
brew install git docker kubectl kind helm

# Verify installations
git --version
docker --version
kubectl version --client
kind version
helm version
```

### Required Accounts

1. **GitHub Account** - For repositories and GitHub Actions
2. **GitHub Container Registry** - For storing Docker images (included with GitHub)

### Time Estimate

- **Quick Recreation**: 5-7 minutes (using automated setup script)
- **Manual Recreation**: 2-3 hours (following this guide step by step)
- **Learning & Customization**: 8-16 hours (understanding and modifying)
- **From Scratch with AI**: 16-24 hours (using AI prompts to build)

---

## Phase 1: Planning & Requirements

### Step 1.1: Define Your Application

**What You're Building:**
- Simple Flask web application
- Health check endpoint for Kubernetes probes
- Version display for deployment verification

**AI Prompt to Start:**
```
I want to create a production-ready Python Flask application that will be deployed to Kubernetes. The application should:
1. Have a health check endpoint at /healthz that returns JSON {"status": "ok"}
2. Have a root endpoint / that shows the application name and version
3. Be suitable for containerization
4. Include proper logging and error handling
5. Follow Python best practices

Please create the initial Flask application structure with main.py and requirements.txt.
```

### Step 1.2: Plan Your CI/CD Pipeline

**Pipeline Stages:**
1. **Lint**: Code quality checks (flake8, pylint)
2. **Test**: Unit tests (pytest)
3. **Build**: Docker image (multi-platform)
4. **E2E**: End-to-end validation (ephemeral kind cluster)
5. **Deploy**: Update GitOps repository

**AI Prompt:**
```
Design a GitHub Actions CI/CD pipeline for a Python Flask application with these requirements:
- Stage 1: Run linting (flake8 and pylint)
- Stage 2: Run pytest unit tests
- Stage 3: Build multi-platform Docker image (amd64, arm64) and push to GitHub Container Registry
- Stage 4: Run E2E tests in an ephemeral kind cluster
- Stage 5: Update a separate GitOps repository with the new image tag

Each stage should only run if previous stages succeed. Provide the complete workflow YAML structure.
```

### Step 1.3: Design GitOps Structure

**Repository Strategy:**
- **app-repo**: Application code + CI/CD pipeline
- **gitops-repo**: Kubernetes manifests + ArgoCD configuration

**AI Prompt:**
```
Explain the best practices for structuring a GitOps repository that uses Helm charts for Kubernetes deployments. Include:
- Directory structure for Helm charts
- Where to store ArgoCD Application manifests
- How to organize values files for different environments
- Best practices for secrets management (without storing actual secrets)
```

---

## Phase 2: Application Development

### Step 2.1: Create Flask Application

**Directory Structure:**
```
app-repo/
├── .github/workflows/
│   └── ci.yml                # 5-stage CI/CD pipeline
├── app/
│   ├── __init__.py
│   └── main.py
├── tests/
│   ├── __init__.py
│   └── test_app.py
├── scripts/
│   └── setup-local-cluster.sh  # Automated setup script
├── Dockerfile
├── .dockerignore
├── .gitignore
├── requirements.txt
├── requirements-test.txt
├── pytest.ini
└── README.md
```

**AI Prompt for main.py:**
```
Create a production-ready Flask application (app/main.py) with:
1. Health check endpoint at /healthz returning JSON {"status": "ok"} with HTTP 200
2. Root endpoint / returning HTML page showing application name and version
3. Version from environment variable APP_VERSION (default: v1.0.0)
4. Proper logging configuration
5. Running with gunicorn when deployed
6. Security headers
7. Non-root user support
Include proper docstrings and comments.
```

**AI Prompt for requirements.txt:**
```
Create a requirements.txt file for a Flask application that will run in production with:
- Flask web framework
- gunicorn WSGI server
- Any necessary security libraries
Keep it minimal and production-focused.
```

### Step 2.2: Create Unit Tests

**AI Prompt:**
```
Create pytest unit tests (tests/test_app.py) for a Flask application with:
1. Test for /healthz endpoint (expects JSON {"status": "ok"} and status 200)
2. Test for / root endpoint (expects status 200)
3. Test that version is displayed on root endpoint
4. Use Flask test client
5. Include proper test fixtures and setup/teardown
6. Follow pytest best practices
```

### Step 2.3: Create Test Configuration

**AI Prompt:**
```
Create a pytest.ini configuration file for a Python Flask project with:
- Test discovery pattern
- Coverage reporting
- Output verbosity settings
- Any recommended pytest plugins for Flask testing
```

---

## Phase 3: Containerization

### Step 3.1: Create Dockerfile

**AI Prompt:**
```
Create a production-ready multi-stage Dockerfile for a Python Flask application with these requirements:
1. Use Python 3.11-slim as base image
2. Multi-stage build to keep final image small
3. Run as non-root user (uid 1000)
4. Install dependencies from requirements.txt
5. Copy application code
6. Use gunicorn with 2 workers and 4 threads
7. Expose port 5000
8. Set proper environment variables
9. Include health check instruction
10. Optimize for layer caching
Include comments explaining each section.
```

### Step 3.2: Test Docker Build Locally

**Commands:**
```bash
# Build image
docker build -t demo-flask-app:local .

# Test locally
docker run -p 5000:5000 demo-flask-app:local

# Test health endpoint
curl http://localhost:5000/healthz

# Test root endpoint
curl http://localhost:5000/
```

**AI Prompt for Troubleshooting:**
```
My Docker container for Flask application is failing with [ERROR MESSAGE]. The Dockerfile is:
[PASTE DOCKERFILE]

Help me debug and fix this issue. Consider:
- Permission issues
- Port binding problems
- Missing dependencies
- User context issues
```

---

## Phase 4: CI/CD Pipeline

### Step 4.1: Create GitHub Actions Workflow

**AI Prompt for Complete Pipeline:**
```
Create a complete GitHub Actions workflow (.github/workflows/ci.yml) for a Python Flask application with these 5 stages:

Stage 1 - Lint:
- Run flake8 for PEP 8 compliance
- Run pylint for code quality
- Fail pipeline if any issues found

Stage 2 - Test:
- Run pytest with coverage
- Upload coverage report
- Fail if tests don't pass

Stage 3 - Build:
- Generate image tag: {short-sha}-{run-number} (e.g., 064193f-32)
- Use docker buildx for multi-platform (linux/amd64, linux/arm64)
- Push to ghcr.io/banicr/demo-flask-app:{tag}
- Registry: GitHub Container Registry (GHCR)
- Only run on main branch

Stage 4 - E2E Test:
- Create ephemeral kind cluster
- Load built image
- Deploy application
- Test /healthz endpoint
- Test / endpoint
- Cleanup cluster
- Only run if build succeeds

Stage 5 - Update GitOps:
- Clone separate gitops repository using PAT
- Update helm/app-name/values.yaml with new image tag
- Commit and push changes
- Only run if E2E tests pass

Include proper job dependencies, error handling, and status reporting.
```

### Step 4.2: Configure GitHub Secrets

**Required Secrets (app-repo):**
1. `GITOPS_PAT` - Personal Access Token for updating gitops-repo

**Creating the PAT:**
1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Required scopes:
   - `repo` - Full control of private repositories
   - `workflow` - Update GitHub Action workflows (if needed)
4. Copy the token and save it securely
5. In app-repo: Settings → Secrets and variables → Actions → New repository secret
   - Name: `GITOPS_PAT`
   - Value: [paste token]

**Usage in workflow:**
```yaml
- name: Checkout gitops repo
  uses: actions/checkout@v4
  with:
    repository: banicr/demo-gitops-repo
    token: ${{ secrets.GITOPS_PAT }}
    path: gitops-repo
```

### Step 4.3: Test Pipeline

**Testing Strategy:**
```bash
# Make a small change
echo "# Test" >> README.md

# Commit and push
git add README.md
git commit -m "test: Trigger CI/CD pipeline"
git push

# Monitor at: https://github.com/{owner}/{repo}/actions
```

**AI Prompt for Debugging:**
```
My GitHub Actions pipeline is failing at [STAGE] with error:
[PASTE ERROR MESSAGE]

The workflow file is:
[PASTE WORKFLOW YAML]

Help me debug and fix this issue. Consider:
- Permission issues
- Authentication problems
- Resource limitations
- Syntax errors
- Dependency issues
```

---

## Phase 5: GitOps Repository

### Step 5.1: Create Helm Chart Structure

**Directory Structure:**
```
gitops-repo/
├── .github/workflows/
│   └── validate.yml          # 6-job validation pipeline
├── helm/
│   └── demo-flask-app/
│       ├── Chart.yaml
│       ├── values.yaml       # Auto-updated by CI/CD
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── serviceaccount.yaml
│           ├── namespace.yaml
│           └── _helpers.tpl
├── k8s/base/                 # Kustomize alternative
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── namespace.yaml
│   └── kustomization.yaml
├── docs/                     # Documentation
│   ├── DEVOPS_ARCHITECTURE_GUIDE.md
│   ├── PROJECT_RECREATION_GUIDE.md
│   ├── PROJECT_README.md
│   ├── QUICK_START.md
│   └── SETUP_GUIDE.md
├── argocd-application.yaml   # Uses valueFiles (not inline)
├── .gitignore
└── README.md
```

**AI Prompt for Helm Chart:**
```
Create a complete Helm chart for a Flask application with:

Chart.yaml:
- Name: demo-flask-app
- Description, version, appVersion
- Kubernetes version constraints

values.yaml:
- Replica count: 2
- Image repository and tag (parameterized)
- Service type: ClusterIP, port: 80 → 5000
- Resources: requests (100m CPU, 128Mi memory), limits (200m CPU, 256Mi memory)
- Liveness/readiness probes on /healthz
- Security context: run as user 1000, read-only root filesystem
- Environment variables (APP_VERSION, APP_NAME)

templates/deployment.yaml:
- Use values from values.yaml
- Rolling update strategy
- Proper labels and selectors
- Security contexts
- Resource limits
- Probes with proper timing

templates/service.yaml:
- ClusterIP service
- Proper selectors
- Port mapping

templates/serviceaccount.yaml:
- Optional service account

templates/_helpers.tpl:
- Common label templates
- Name helpers
- Selector templates

Include all necessary Helm templating functions and follow best practices.
```

### Step 5.2: Create ArgoCD Application Manifest

**Current Implementation (argocd-application.yaml):**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: demo-flask-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/banicr/demo-gitops-repo.git
    targetRevision: HEAD
    path: helm/demo-flask-app
    helm:
      valueFiles:
        - values.yaml  # ✅ IMPORTANT: Use valueFiles, NOT inline values
  destination:
    server: https://kubernetes.default.svc
    namespace: demo-app
  syncPolicy:
    automated:
      prune: true      # Remove resources not in Git
      selfHeal: true   # Auto-correct drift
    syncOptions:
      - CreateNamespace=true
```

**Critical Learning:** Using `helm.valueFiles` instead of inline `helm.values` allows ArgoCD to detect changes in values.yaml and auto-sync. Inline values override the file and prevent auto-sync.

### Step 5.3: Create GitOps Validation Pipeline

**AI Prompt:**
```
Create a GitHub Actions workflow for gitops-repo that validates:

Job 1 - Helm Lint:
- Run `helm lint --strict` on chart
- Check for syntax errors

Job 2 - Helm Validate:
- Render templates with `helm template`
- Verify all resources have required fields

Job 3 - Kubernetes Validate:
- Use kubeval to validate against K8s schemas
- Use kubeconform for additional validation

Job 4 - Security Check:
- Verify security contexts are present
- Verify probes are configured
- Verify resource limits are set

Job 5 - ArgoCD Validate:
- Validate argocd-application.yaml syntax
- Check required fields are present

Job 6 - Summary:
- Aggregate results from all jobs
- Generate validation report

All jobs should run in parallel and workflow should fail if any job fails.
```

---

## Phase 6: ArgoCD Setup

### Step 6.1: Install ArgoCD Locally

**Manual Installation:**
```bash
# Create kind cluster (automated in setup script)
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

# Or simply run the automated script:
cd app-repo
./scripts/setup-local-cluster.sh

# Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Get password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

**Current Automated Script:**

The `setup-local-cluster.sh` script is already implemented and includes:

1. ✅ Prerequisites checking (docker, kind, kubectl, helm)
2. ✅ Cleanup of existing clusters
3. ✅ Kind cluster creation with port mapping (30080:8000)
4. ✅ ArgoCD installation and waiting for readiness
5. ✅ Two-phase pod waiting (existence check + readiness)
6. ✅ ArgoCD password extraction and saving
7. ✅ ArgoCD Application deployment
8. ✅ Deployment verification
9. ✅ Next steps and useful commands
10. ✅ Colored output with progress indicators
11. ✅ Comprehensive error handling

**Usage:**
```bash
cd app-repo
./scripts/setup-local-cluster.sh

# Or with custom cluster name
./scripts/setup-local-cluster.sh my-cluster
```

**Features:**
- Saves credentials to `scripts/argocd-credentials.txt`
- Creates cluster named `gitops-demo` by default
- Application accessible at http://localhost:30080
- ArgoCD UI at https://localhost:8080 (after port-forward)

### Step 6.2: Deploy Application via ArgoCD

**Commands:**
```bash
# Apply ArgoCD Application
kubectl apply -f gitops-repo/argocd-application.yaml

# Watch sync status
kubectl get application -n argocd demo-flask-app -w

# Check pods
kubectl get pods -n demo-app
```

**AI Prompt for Troubleshooting:**
```
My ArgoCD Application is showing status [STATUS] with error:
[ERROR MESSAGE]

The ArgoCD Application manifest is:
[PASTE YAML]

The Helm values are:
[PASTE VALUES]

Help me debug and fix this issue. Consider:
- Repository access issues
- Manifest syntax errors
- Resource conflicts
- Namespace issues
- RBAC problems
```

---

## Phase 7: Testing & Validation

### Step 7.1: Test Application Endpoints

**AI Prompt for Test Script:**
```
Create a bash script that tests a Kubernetes-deployed application:
1. Check if pods are running in namespace demo-app
2. Test /healthz endpoint (expect {"status":"ok"})
3. Test / endpoint (expect HTTP 200)
4. Verify correct image tag is deployed
5. Check pod logs for errors
6. Verify service endpoints are healthy
7. Test rolling update process

Use kubectl commands and provide clear pass/fail output.
```

### Step 7.2: Test CI/CD Flow

**Test Checklist:**
```
□ Make code change in app-repo
□ Push to main branch
□ Verify lint stage passes
□ Verify test stage passes
□ Verify build stage creates image
□ Verify E2E tests pass in ephemeral cluster
□ Verify gitops-repo is updated with new tag
□ Verify gitops validation pipeline runs
□ Verify ArgoCD detects change
□ Verify ArgoCD syncs application
□ Verify pods roll out with new image
□ Verify application health checks pass
□ Verify no downtime during update
```

### Step 7.3: Test Failure Scenarios

**AI Prompt:**
```
Create test scenarios to verify our CI/CD pipeline handles failures correctly:

1. Failing unit test - What happens?
2. Failing Docker build - What happens?
3. E2E test failure - What happens?
4. Invalid Helm chart - What happens?
5. ArgoCD sync failure - What happens?

For each scenario, explain:
- What should happen
- How to test it
- How to verify the pipeline stopped at the right place
- How to recover
```

---

## Phase 8: Documentation

### Step 8.1: Create README Files

**AI Prompt for app-repo/README.md:**
```
Create a comprehensive README.md for an application repository that includes:
1. Project title and description
2. Architecture diagram (ASCII art)
3. Features list
4. Prerequisites
5. Local development setup
6. Running tests
7. Docker build instructions
8. CI/CD pipeline explanation
9. Deployment process
10. Troubleshooting section
11. Contributing guidelines
12. License

Make it beginner-friendly but thorough enough for production use.
```

**AI Prompt for gitops-repo/README.md:**
```
Create a comprehensive README.md for a GitOps repository that includes:
1. What is GitOps explanation
2. Repository structure
3. Helm chart documentation
4. ArgoCD setup instructions
5. How to update deployments
6. Environment management
7. Secrets management approach
8. Rollback procedures
9. Monitoring and observability
10. Disaster recovery
11. Best practices

Focus on operational aspects and GitOps principles.
```

### Step 8.2: Create Quick Start Guide

**AI Prompt:**
```
Create a QUICK_START.md that gets someone from zero to deployed application in 5 minutes:
1. Prerequisites check
2. One-command setup (using our automation script)
3. Verification steps
4. How to trigger a deployment
5. How to access the application
6. Common commands cheat sheet

Make it extremely concise with copy-paste commands.
```

### Step 8.3: Create Architecture Guide

**AI Prompt:**
```
Create a DEVOPS_ARCHITECTURE_GUIDE.md that explains:
1. Overall architecture with detailed diagrams
2. Design decisions and rationale
3. Technology choices
4. Pipeline stages deep dive
5. GitOps workflow explanation
6. Security considerations
7. Scalability approaches
8. Monitoring and observability strategy
9. Disaster recovery plan
10. Future improvements

This should be comprehensive enough for a new DevOps engineer to understand and operate the system.
```

---

## AI Prompts Library

### Category: Initial Setup

**Prompt: Repository Structure**
```
Create a repository structure for a GitOps-based application deployment with:
- Application code repository (app-repo)
- GitOps configuration repository (gitops-repo)
- What should go in each repository
- How they should interact
- Branching strategy
- Tagging strategy
Include directory structures and .gitignore files.
```

**Prompt: Environment Setup**
```
What tools do I need to install for developing and deploying a Python Flask application to Kubernetes using GitOps? Provide:
- List of required tools with version recommendations
- Installation commands for macOS and Linux
- Verification commands
- Common issues and solutions
```

### Category: Application Development

**Prompt: Flask App with Best Practices**
```
Create a production-ready Flask application following these best practices:
- 12-factor app principles
- Proper logging with structured logs
- Health check endpoints
- Graceful shutdown handling
- Security headers
- Environment-based configuration
- Error handling and recovery
- Metrics exposure (Prometheus format)
Include code with comments explaining each practice.
```

**Prompt: Testing Strategy**
```
Design a comprehensive testing strategy for a Flask application that will be deployed to Kubernetes:
- Unit tests (what to test, how to structure)
- Integration tests
- E2E tests
- Load tests
- Security tests
Provide pytest examples and CI/CD integration approach.
```

### Category: Docker & Containers

**Prompt: Secure Dockerfile**
```
Create a secure, production-ready Dockerfile for a Python application with:
- Minimal attack surface
- No root user
- Scan for vulnerabilities
- Multi-stage build
- Proper layer caching
- Security hardening
Explain each security measure.
```

**Prompt: Multi-Platform Builds**
```
Explain how to set up Docker buildx for multi-platform builds in GitHub Actions:
- Supporting amd64 and arm64
- Caching strategies
- Build time optimization
- Pushing to multiple registries
- Troubleshooting common issues
Include complete GitHub Actions workflow example.
```

### Category: CI/CD Pipeline

**Prompt: Pipeline Best Practices**
```
Design a CI/CD pipeline following DevOps best practices:
- Stage separation and dependencies
- Fail-fast principles
- Caching strategies
- Secret management
- Artifact versioning
- Deployment strategies
- Rollback capabilities
- Monitoring and notifications
Provide GitHub Actions examples.
```

**Prompt: E2E Testing in CI**
```
How do I run E2E tests for a Kubernetes application in a GitHub Actions pipeline using ephemeral kind clusters?
- Creating disposable clusters
- Loading images efficiently
- Running tests
- Collecting logs on failure
- Cleanup strategies
- Resource optimization
Include complete workflow example.
```

### Category: Kubernetes & Helm

**Prompt: Production-Ready Helm Chart**
```
Create a production-ready Helm chart for a web application with:
- Proper resource management
- Liveness and readiness probes
- Rolling update strategy
- HPA support
- Network policies
- Pod security policies
- Affinity rules
- ConfigMap and Secret management
Include all templates and values file with detailed comments.
```

**Prompt: Helm Chart Testing**
```
How do I test Helm charts to ensure they're production-ready?
- Unit testing with helm unittest
- Linting with helm lint
- Schema validation
- Dry-run deployments
- Integration testing
Include examples and CI/CD integration.
```

### Category: GitOps & ArgoCD

**Prompt: ArgoCD Setup**
```
Provide a complete guide for setting up ArgoCD in a Kubernetes cluster:
- Installation methods
- Initial configuration
- Repository connection (HTTPS, SSH)
- Application manifest creation
- Sync policies and strategies
- RBAC configuration
- Monitoring and alerting
- Backup and disaster recovery
Include production-ready examples.
```

**Prompt: GitOps Best Practices**
```
Explain GitOps best practices for managing Kubernetes deployments:
- Repository structure
- Branching strategy
- Environment promotion
- Secret management
- Drift detection and remediation
- Audit trail
- Disaster recovery
- Multi-cluster management
Provide practical examples.
```

### Category: Troubleshooting

**Prompt: Debug Pipeline Failures**
```
My CI/CD pipeline is failing at [STAGE] with this error:
[ERROR MESSAGE]

Help me debug this by:
1. Analyzing the error message
2. Identifying the root cause
3. Providing step-by-step fix
4. Explaining how to prevent it in future
5. Adding better error handling
```

**Prompt: Debug Kubernetes Issues**
```
My pods in Kubernetes are in [STATE] status. Help me debug:
- What logs should I check?
- What kubectl commands should I run?
- Common causes for this state
- How to fix it
- How to prevent it
Provide diagnostic commands and interpretation guide.
```

**Prompt: Debug ArgoCD Sync Issues**
```
My ArgoCD Application is not syncing properly. Status shows [STATUS]. Help me:
1. Understand what this status means
2. Debug the issue
3. Check application manifest
4. Verify Helm chart
5. Check RBAC permissions
6. Fix the issue
Provide complete diagnostic approach.
```

### Category: Security

**Prompt: Security Hardening**
```
Review my Kubernetes deployment for security issues and provide hardening recommendations:
[PASTE DEPLOYMENT YAML]

Check for:
- Pod security context
- Network policies
- Resource limits
- Image vulnerabilities
- Secret management
- RBAC policies
- Service account permissions
Provide specific fixes.
```

**Prompt: CI/CD Security**
```
How do I secure my CI/CD pipeline to prevent:
- Credential leakage
- Unauthorized access
- Supply chain attacks
- Malicious code injection
- Secret exposure in logs

Provide concrete examples for GitHub Actions.
```

### Category: Documentation

**Prompt: Architecture Documentation**
```
Create comprehensive architecture documentation for my CI/CD + GitOps system that explains:
- System overview
- Component interactions
- Data flow diagrams
- Decision rationale
- Deployment process
- Operational procedures
- Troubleshooting guides

Make it suitable for onboarding new team members.
```

**Prompt: Runbook Creation**
```
Create operational runbooks for common tasks:
- Deploying new version
- Rolling back deployment
- Scaling application
- Troubleshooting failures
- Disaster recovery
- Secret rotation

Each runbook should have:
- Prerequisites
- Step-by-step instructions
- Verification steps
- Rollback procedures
- Common issues
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue 1: Docker Build Fails in CI

**Symptoms:**
```
Error: failed to solve: process "/bin/sh -c pip install -r requirements.txt" did not complete successfully
```

**AI Prompt:**
```
My Docker build is failing in GitHub Actions with the error above. The Dockerfile is:
[PASTE DOCKERFILE]

The requirements.txt is:
[PASTE REQUIREMENTS]

This works locally but fails in CI. Help me:
1. Identify why it works locally but not in CI
2. Fix the Dockerfile for CI environment
3. Add proper caching
4. Improve build time
```

**Common Causes:**
- Missing dependencies in slim base image
- Network issues in CI environment
- Permission problems
- Caching issues

**Solution Template:**
```dockerfile
# Use specific version for reproducibility
FROM python:3.11-slim AS builder

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.11-slim
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
# ... rest of Dockerfile
```

#### Issue 2: Kind Cluster Creation Fails

**Symptoms:**
```
ERROR: failed to create cluster: failed to ensure docker network: command "docker network create..."
```

**AI Prompt:**
```
My kind cluster creation is failing with the error above. Help me:
1. Diagnose the issue
2. Check Docker daemon status
3. Fix network conflicts
4. Provide working kind configuration
5. Add retry logic
```

**Common Causes:**
- Docker not running
- Network conflicts
- Insufficient resources
- Previous cluster not cleaned up

**Solution:**
```bash
# Clean up first
kind delete cluster --name gitops-demo
docker network prune -f

# Check Docker
docker info

# Create with explicit config
kind create cluster --name gitops-demo --config=kind-config.yaml
```

#### Issue 3: ArgoCD Not Syncing

**Symptoms:**
- Application shows "OutOfSync" but doesn't auto-sync
- Manual sync works but auto-sync doesn't

**AI Prompt:**
```
My ArgoCD Application is showing OutOfSync status but automated sync is not working. The Application manifest is:
[PASTE YAML]

Help me:
1. Verify sync policy is correct
2. Check ArgoCD logs
3. Verify repository access
4. Test manual sync
5. Fix auto-sync configuration
```

**Common Causes:**
- syncPolicy.automated not properly configured
- Repository access issues
- Helm value parsing errors
- ArgoCD controller not healthy
- **Most Common**: Using inline `helm.values` instead of `helm.valueFiles`

**Critical Fix:**
If ArgoCD Application has hardcoded inline values, it will NOT auto-sync when values.yaml changes:

```yaml
# ❌ WRONG - Prevents auto-sync
helm:
  values: |
    image:
      tag: "hardcoded-tag"

# ✅ CORRECT - Enables auto-sync
helm:
  valueFiles:
    - values.yaml
```

This was the actual issue encountered and fixed in commit f427c55.

**Solution Checklist:**
```bash
# Check Application status
kubectl get application -n argocd demo-flask-app -o yaml

# Check sync policy
# Should have:
#   syncPolicy:
#     automated:
#       prune: true
#       selfHeal: true

# Check ArgoCD controller logs
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller --tail=100

# Force refresh
kubectl patch application demo-flask-app -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"HEAD"}}}'
```

#### Issue 4: E2E Tests Timing Out

**Symptoms:**
```
Error: Timed out waiting for pods to be ready
```

**AI Prompt:**
```
My E2E tests in GitHub Actions are timing out when waiting for pods. The workflow is:
[PASTE WORKFLOW]

Help me:
1. Identify timing issues
2. Add proper waits
3. Improve pod readiness detection
4. Add debugging output
5. Optimize test execution
```

**Common Causes:**
- Image pull delays
- Insufficient wait time
- Probes taking too long
- Resource constraints in CI

**Solution:**
```yaml
# Add explicit waits
- name: Wait for pods
  run: |
    # Wait for deployment to exist
    timeout 60 kubectl wait --for=jsonpath='{.status.replicas}'=2 deployment/demo-flask-app -n demo-app
    
    # Wait for pods to be ready
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=demo-flask-app -n demo-app --timeout=180s
    
    # Verify
    kubectl get pods -n demo-app
```

#### Issue 5: GITOPS_PAT Permission Denied

**Symptoms:**
```
Error: Permission denied (publickey). fatal: Could not read from remote repository.
```

**AI Prompt:**
```
My CI/CD pipeline can't push to gitops-repo with error above. Help me:
1. Verify PAT permissions
2. Check PAT scope
3. Fix repository access
4. Test PAT locally
5. Update workflow to use PAT correctly
```

**Common Causes:**
- PAT expired or revoked
- Insufficient PAT permissions
- Wrong PAT used in workflow
- Repository URL incorrect

**Solution:**
```bash
# Required PAT scopes:
# - repo (Full control of private repositories)
# - workflow (Update GitHub Action workflows)

# Test PAT locally
export GITOPS_PAT="your-token-here"
git clone https://${GITOPS_PAT}@github.com/owner/gitops-repo.git

# In workflow:
- name: Checkout gitops repo
  uses: actions/checkout@v4
  with:
    repository: ${{ github.repository_owner }}/demo-gitops-repo
    token: ${{ secrets.GITOPS_PAT }}
    path: gitops-repo
```

---

## Next Steps After Recreation

### 0. Current Working Implementation

**Repositories:**
- App Repository: https://github.com/banicr/demo-app-repo
- GitOps Repository: https://github.com/banicr/demo-gitops-repo
- Image Registry: ghcr.io/banicr/demo-flask-app
- Current Image Tag: 064193f-32 (example)

**Status:**
- ✅ Phases 1-3: Complete (Foundation, CI/CD, GitOps)
- 🔄 Phase 4: Observability (Planned)
- 🔄 Phase 5: Security Hardening (Planned)
- 🔄 Phase 6: Progressive Delivery (Planned)
- 🔄 Phase 7: Advanced Features (Planned)

### 1. Customize for Your Application

**AI Prompt:**
```
I've recreated the CI/CD + GitOps system and want to customize it for my application which is [DESCRIPTION]. Help me:
1. Adapt the Flask application to my use case
2. Modify the Dockerfile for my dependencies
3. Update CI/CD pipeline for my testing needs
4. Adjust Helm chart for my requirements
5. Configure proper resource limits for my workload

Provide specific modifications needed.
```

### 2. Add Monitoring

**AI Prompt:**
```
Add Prometheus and Grafana monitoring to my GitOps setup:
1. Install Prometheus using Helm
2. Configure ServiceMonitor for application
3. Add custom metrics to Flask app
4. Install Grafana
5. Create dashboards for:
   - Application health
   - Request rates
   - Error rates
   - Resource usage
6. Set up alerting rules

Provide complete configuration and integration steps.
```

### 3. Implement Multi-Environment

**AI Prompt:**
```
Extend my GitOps repository to support multiple environments (dev, staging, prod):
1. Repository structure for environments
2. Helm values override strategy
3. ArgoCD Applications for each environment
4. Promotion workflow between environments
5. Environment-specific secrets
6. RBAC per environment

Provide complete implementation guide.
```

### 4. Add Security Scanning

**AI Prompt:**
```
Integrate security scanning into my CI/CD pipeline:
1. Container image scanning (Trivy)
2. Dependency vulnerability scanning
3. SAST (Static Application Security Testing)
4. Kubernetes manifest scanning
5. Secret detection
6. License compliance checking

Provide GitHub Actions integration for each tool.
```

### 5. Implement Observability

**AI Prompt:**
```
Add comprehensive observability to my application:
1. Structured logging with JSON format
2. Distributed tracing (OpenTelemetry)
3. Custom metrics (Prometheus)
4. Log aggregation (Loki)
5. APM (Application Performance Monitoring)
6. Dashboards and alerts

Provide implementation guide for each component.
```

---

## Additional Resources

### Official Documentation
- **Flask**: https://flask.palletsprojects.com/
- **Docker**: https://docs.docker.com/
- **Kubernetes**: https://kubernetes.io/docs/
- **Helm**: https://helm.sh/docs/
- **ArgoCD**: https://argo-cd.readthedocs.io/
- **GitHub Actions**: https://docs.github.com/en/actions

### Community Resources
- **DevOps Roadmap**: https://roadmap.sh/devops
- **GitOps Guide**: https://www.gitops.tech/
- **Kubernetes Patterns**: https://k8spatterns.io/

### Books
- "Kubernetes in Action" by Marko Lukša
- "Continuous Delivery" by Jez Humble and David Farley
- "Site Reliability Engineering" by Google

---

## Key Learnings from Implementation

### 1. ArgoCD valueFiles vs Inline Values
**Problem:** Application wouldn't auto-sync when CI/CD updated values.yaml  
**Cause:** ArgoCD Application had inline `helm.values` that overrode values.yaml  
**Solution:** Changed to `helm.valueFiles: [values.yaml]`  
**Commit:** f427c55 in gitops-repo

### 2. Setup Script Pod Waiting
**Problem:** Script failed when waiting for pods that didn't exist yet  
**Cause:** `kubectl wait` fails if resources don't exist  
**Solution:** Two-phase waiting - first check existence, then wait for readiness  
**Commit:** 064193f in app-repo

### 3. Image Tagging Strategy
**Problem:** Need uniqueness and traceability  
**Solution:** Use `{short-sha}-{run-number}` format  
**Benefits:** Unique, traceable to commit, supports rollback

### 4. CI/CD Pipeline Updates
**Problem:** Pipeline was updating both values.yaml AND argocd-application.yaml  
**Cause:** Confusion about where image tag should be managed  
**Solution:** Only update values.yaml, keep ArgoCD Application static  
**Commit:** 4a83545 in app-repo

### 5. Automated Setup Value
**Problem:** Manual setup too time-consuming and error-prone  
**Solution:** Created comprehensive setup script with all steps automated  
**Result:** 5-7 minute setup instead of 30+ minutes manual

## Conclusion

This guide provides everything needed to recreate this CI/CD + GitOps system from scratch. The AI prompts are designed to be specific enough to get working code while being generic enough to adapt to your needs.

**Key Success Factors:**
1. Start simple and iterate
2. Test each component independently
3. Use AI prompts to generate boilerplate
4. Understand the generated code
5. Customize for your specific needs
6. Document as you go

**Remember:**
- The AI prompts are starting points - review and modify the output
- Test thoroughly at each phase before proceeding
- Keep security in mind throughout
- Document decisions and configurations
- Version control everything

**Happy Building! 🚀**

For questions or issues, refer to the troubleshooting section or ask AI with specific error messages and context.
