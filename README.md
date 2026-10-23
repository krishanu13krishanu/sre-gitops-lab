# SRE Lab: Azure Hosting and Local GitOps

This repository contains two separate SRE demonstrations:

1. A publicly accessible Node.js application deployed to Azure App Service using Terraform.
2. A local Kubernetes GitOps demonstration using kind, Helm, and Argo CD.

The two deployments are independent. Azure App Service serves the public application; the local kind cluster demonstrates the GitOps workflow.

---

## 1. Azure public application

### Public URL

- Application: https://krishanu-sre-hp2ixy.azurewebsites.net
- Health check: https://krishanu-sre-hp2ixy.azurewebsites.net/health

### Architecture

```text
Terraform
   ↓
Azure Resource Group
   ↓
Azure Linux App Service Plan (Free F1)
   ↓
Azure Linux App Service
   ↓
Public HTTPS Node.js application
```

### Terraform resources

The `terraform/` directory provisions:

- Resource Group
- Linux App Service Plan on Free F1 tier
- Linux App Service with Node.js 22
- HTTPS-only access
- Minimum TLS version 1.2
- FTP and WebDeploy basic authentication disabled

Run from `terraform/`:

```bash
terraform init
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
```

The Node.js application source is in `app/`.

---

## 2. Local Kubernetes GitOps demonstration

### Architecture

```text
GitHub repository
   ↓
Argo CD Application
   ↓
Argo CD running in local kind Kubernetes cluster
   ↓
Helm chart in helm/webapp
   ↓
ConfigMap + Deployment + NodePort Service
   ↓
Local NGINX pods
```

### Helm chart

The Helm chart in `helm/webapp/` deploys:

- Unprivileged NGINX container
- ConfigMap containing a local static demo page
- Deployment with resource requests and limits
- Readiness and liveness probes
- NodePort Service

### Argo CD

The Argo CD Application definition is in:

```text
argocd/webapp-application.yaml
```

It tracks the `main` branch and deploys `helm/webapp` to the local `webapp` namespace.

GitOps settings:

- Automated sync
- `prune: true`
- `selfHeal: true`
- Automatic namespace creation

### Demonstrating GitOps

Change a value in:

```text
helm/webapp/values.yaml
```

For example, change `replicaCount`, then commit and push:

```bash
git add helm/webapp/values.yaml
git commit -m "Scale webapp replicas"
git push
```

Argo CD detects the Git revision, renders the Helm chart, and reconciles the local cluster automatically.

Check status:

```bash
kubectl get applications -n argocd
kubectl get pods -n webapp
```

### Local access

```bash
kubectl port-forward -n webapp service/webapp 8081:80
```

Open `http://localhost:8081`.

The local GitOps page is not public. The Azure App Service URL is the public deliverable.

---

## Repository structure

```text
.
├── app/                 # Node.js source for Azure App Service
├── terraform/           # Azure infrastructure as code
├── helm/webapp/         # Local Kubernetes Helm chart
├── argocd/              # Argo CD Application definition
└── README.md
```

## Cleanup

Remove Azure resources:

```bash
cd terraform
terraform destroy
```

Remove the local cluster:

```bash
kind delete cluster --name sre-lab
```

## Security controls implemented

- Enforced HTTPS for the Azure App Service with `https_only = true`.
- Set the Azure App Service minimum TLS version to `1.2`.
- Disabled FTP publishing basic authentication.
- Disabled WebDeploy publishing basic authentication.
- Used the authenticated Azure CLI/Entra ID session for Terraform and Azure deployment; no Azure credentials or client secrets are stored in Git.
- Excluded Terraform state files, saved plans, kubeconfig files, deployment ZIP files, and local Node.js dependencies through `.gitignore`.
- Used the `nginxinc/nginx-unprivileged` image for the local Kubernetes workload.
- Disabled privilege escalation for the NGINX container.
- Dropped all Linux capabilities from the NGINX container.
- Mounted static HTML content from the ConfigMap as read-only.
- Configured CPU and memory requests/limits for the Kubernetes pod.
- Added readiness and liveness probes to ensure traffic reaches only healthy pods and unhealthy containers are restarted.
- Kept Argo CD UI access local through `kubectl port-forward`; it is not publicly exposed.
- Enabled Argo CD `selfHeal` to revert manual Kubernetes drift back to the Git-defined state.
- Enabled Argo CD `prune` to remove managed resources deleted from Git.
- Kept the GitHub repository and NGINX image public, so no Git credentials or image-pull secrets are required for this lab.