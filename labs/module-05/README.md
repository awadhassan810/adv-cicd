# Lab 5: GitOps Workflows

> **Which track are you following?**
>
> - **Cloud Labs** → Use the standard files and instructions below.
> - **Local Labs** → See the "Local Labs" callouts for alternative paths.

## Overview

This lab puts Git at the centre of cluster state. You write an ArgoCD `Application` resource that points at your `gitops-lab-05` repository, let ArgoCD reconcile an nginx deployment into an `app` namespace, then drive a change through the Git workflow and watch ArgoCD sync it. You finish by inducing configuration drift with a manual `kubectl scale` and observing self-heal revert it — proving that Git, not the cluster, is the source of truth. By the end you will have a committed `argocd/application.yaml` with automated sync, prune, and self-heal enabled; an nginx workload running under ArgoCD management; and hands-on evidence of both sync-from-Git and drift-revert behaviour. This lab operationalises the Module 5 GitOps principles (declarative state, pull-based reconciliation, continuous drift correction) that together replace the imperative `kubectl apply` habits from Labs 3 and 4.

### Time Budget

| Task | Estimated Time |
|------|---------------|
| Setup and orientation | 8 min |
| Task 1: Deploy via ArgoCD | 10 min |
| Task 2: Update via Git | 8 min |
| Task 3: Detect and resolve drift | 7 min |
| **Total** | **33 min** |

## Objectives

- Deploy a sample application to Kubernetes using ArgoCD as the GitOps controller
- Update the application by committing changes to Git and observing ArgoCD's automatic sync
- Induce configuration drift by manually modifying the live cluster, then resolve it through Git

## Prerequisites

- Kubernetes cluster running (Local Labs: K3s on your VM; Cloud Labs: client-provided or managed cluster)
- `kubectl` installed and configured to access the cluster
- **ArgoCD must be installed in the cluster before starting this lab** (installed during the break between Module 04 and Module 05 -- see Setup step 5 if you still need to install it)
- `argocd` CLI installed (see ArgoCD CLI Installation below)
- Git installed locally
- GitHub account with repository creation permissions

> **Important:** ArgoCD server must be running in your cluster before you begin. This is a mandatory prerequisite, not an optional setup step. If you did not install ArgoCD during the break, complete Setup steps 5-6 first.

## Setup (summary)

> Your lab environment is pre-configured. If you encounter issues, ask your instructor.

On Local Labs, K3s and ArgoCD are provisioned on your VM before delivery. An ArgoCD server should already be running in your cluster, port-forwarded on `8080`, with `argocd login` completed for you. The `gitops-lab-05` repo (GitHub Cloud track) or Gitea repo (Local Labs track) is also pre-created.

> **Reminder:** ArgoCD server must be running in your cluster before you begin Task 1. The Application you create in Task 1 uses `CreateNamespace=true`, so the `app` namespace is created automatically.

## Task 1: Deploy an application via ArgoCD

Open `argocd/application.yaml` in the starter files. This file is a stub with placeholder values.

**Requirements:**

1. Fill in the ArgoCD Application resource with these values:
   - `repoURL`: your `gitops-lab-05` repository URL
   - `path`: `apps/nginx`
   - `targetRevision`: `main`
   - `destination.server`: `https://kubernetes.default.svc`
   - `destination.namespace`: `app`
   - Sync policy: automated, with prune and selfHeal both enabled
   - Sync option: `CreateNamespace=true`

2. Apply the Application resource:

```bash
kubectl apply -f argocd/application.yaml
```

3. Verify the application is synced and healthy:

```bash
argocd app get nginx-app
```

4. Confirm the resources exist in the cluster:

```bash
kubectl get deployments -n app
kubectl get services -n app
```

**Expected outcome:** The nginx Deployment shows 2/2 ready replicas. The Service shows a ClusterIP on port 80. ArgoCD reports Sync Status: Synced and Health Status: Healthy.

## Task 2: Update via Git and observe sync

1. Open `apps/nginx/deployment.yaml` and change the image tag from `nginx:1.27.4-alpine` to `nginx:1.27.3-alpine`.

2. Commit and push:

```bash
git add apps/nginx/deployment.yaml
git commit -m "Update nginx image to 1.27.3-alpine"
git push origin main
```

3. Wait for ArgoCD to detect the change (up to 3 minutes with default polling, or trigger a manual refresh):

```bash
argocd app get nginx-app --refresh
```

4. Verify the running pods use the new image:

```bash
kubectl get pods -n app -o jsonpath='{.items[*].spec.containers[0].image}'
```

**Expected outcome:** ArgoCD detects the Git change, syncs, and the running pods report `nginx:1.27.3-alpine`.

## Task 3: Detect and resolve configuration drift

1. Manually scale the deployment to 5 replicas:

```bash
kubectl scale deployment nginx -n app --replicas=5
```

2. Immediately check ArgoCD's sync status:

```bash
argocd app get nginx-app
```

3. Observe what happens over the next 10 seconds. With `selfHeal: true`, ArgoCD should revert the replica count to 2.

4. Verify the replica count has been corrected:

```bash
kubectl get deployment nginx -n app -o jsonpath='{.spec.replicas}'
# Expected output: 2
```

5. Now make the change persistent through Git. Open `apps/nginx/deployment.yaml`, change `replicas: 2` to `replicas: 3`, commit, and push:

```bash
git add apps/nginx/deployment.yaml
git commit -m "Scale nginx to 3 replicas"
git push origin main
```

6. Wait for ArgoCD to sync and verify:

```bash
argocd app get nginx-app --refresh
kubectl get deployment nginx -n app -o jsonpath='{.spec.replicas}'
# Expected output: 3
```

**Expected outcome:** Manual scaling is reverted by self-heal. The Git-committed change persists after sync.

## Acceptance Criteria

- [ ] ArgoCD Application resource (`argocd/application.yaml`) is correctly configured with all required fields
- [ ] `argocd app get nginx-app` reports Sync Status: Synced and Health Status: Healthy after initial deployment
- [ ] nginx Deployment is running with 2 replicas in the `app` namespace
- [ ] nginx Service is accessible on ClusterIP port 80 in the `app` namespace
- [ ] Image tag update via Git commit is automatically applied to the running pods
- [ ] Manual `kubectl scale` is detected as drift (OutOfSync) by ArgoCD
- [ ] Self-heal reverts the manual scaling within seconds
- [ ] Git-committed replica change (3 replicas) persists after sync

## Recap & Takeaways

You created an ArgoCD `Application` resource pointing at your `gitops-lab-05` repository, let the controller reconcile an nginx deployment into the `app` namespace with `CreateNamespace=true`, drove an image-tag change through the Git workflow, and then induced drift with a manual `kubectl scale` — proving first-hand that self-heal reverts the cluster back to what Git says. That is the Module 5 definition of GitOps in three words: declarative, pull-based, continuously reconciled. Every imperative `kubectl apply` habit from Labs 3 and 4 is now replaced by a commit-and-push flow.

- You have a working ArgoCD `Application` with automated sync, prune, and self-heal enabled.
- You observed the two canonical GitOps behaviours end-to-end: Git-driven sync and drift-revert.
- You know that for managed resources Git is the source of truth, and ad-hoc `kubectl` commands against ArgoCD-owned objects will be undone within seconds.

## Stretch Goals

- Add a second ArgoCD Application that deploys the Bitnami nginx Helm chart (`https://charts.bitnami.com/bitnami`, chart `nginx`) with manual sync (no auto-sync) and observe how the workflow differs from plain-manifest deployment
- Configure `ignoreDifferences` on the nginx Application to exclude `spec.replicas` from drift detection (simulating an HPA scenario)
- Set up a GitHub webhook to notify ArgoCD on push, reducing sync delay from 3 minutes to seconds
- Explore the ArgoCD web UI at `https://localhost:8080` (open from the VM terminal's browser or via an SSH tunnel; ArgoCD is not exposed on a public port) and compare the visual status with CLI output

## Hints

<details><summary>Hint 1: Application YAML structure</summary>

The `spec` section needs: `project`, `source` (with `repoURL`, `path`, `targetRevision`), `destination` (with `server`, `namespace`), `syncPolicy` (with `automated` containing `prune` and `selfHeal`), and `syncOptions`.

</details>

<details><summary>Hint 2: Forcing ArgoCD to refresh</summary>

If you do not want to wait for the 3-minute polling interval, use:

```bash
argocd app get nginx-app --refresh
```

Or, for a hard refresh that re-clones the repository:

```bash
argocd app get nginx-app --hard-refresh
```

</details>

<details><summary>Hint 3: Debugging sync failures</summary>

If the application shows sync errors, check the ArgoCD application events:

```bash
argocd app get nginx-app --show-operation
```

And check Kubernetes events in the target namespace:

```bash
kubectl get events -n app --sort-by='.lastTimestamp'
```

</details>

## Teardown

Leaving the `nginx-app` Application alive means ArgoCD keeps self-healing; delete it before moving on:

```bash
# Delete the ArgoCD Application (this also deletes managed resources with prune)
argocd app delete nginx-app --cascade

# Verify resources are removed
kubectl get all -n app

# Delete the app namespace
kubectl delete namespace app
```

> ArgoCD-server uninstall and the `gitops-lab-05` repo cleanup are handled by the instructor at end-of-cohort.
