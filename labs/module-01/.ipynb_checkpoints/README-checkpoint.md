# Lab 1: CI/CD Pipeline Architecture

> **Track posture for this README.** This workbench reference is **Local-Labs-primary**. All prose, code, and verification steps default to the Local Labs stack — Gitea Actions running on your VM, using `.gitea/workflows/ci.yml`. Cloud Labs equivalents (GitHub Actions, `.github/workflows/ci.yml`) appear inside `::: cloud-lab` fences. The workflow YAML itself is **byte-identical** across tracks because Gitea Actions implements the GitHub Actions specification 1:1 — the runners execute the same `actions/checkout`, `actions/setup-node`, matrix strategy, and `secrets.X` syntax. Only the repo location and the UI URL differ.

## Overview

This lab builds a production-shaped CI pipeline around a small Node.js service: three sequential jobs first, then caching, then parallelisation, then a scoped secret, then a matrix test fan-out. You practise each of the pipeline-architecture patterns covered in Module 1 — SHA-pinned actions, least-privilege `permissions`, job DAG shape, and step-level secret scoping — against a real repository you own. By the end you will have a `.gitea/workflows/ci.yml` (Local Labs) or `.github/workflows/ci.yml` (Cloud Labs) with five jobs (`lint`, `test`, `build`, `deploy`, and a matrixed `test`) passing on every push, caching npm dependencies across runs, and injecting a repository secret only into the step that needs it. This is the foundation for every later lab: Module 2 containerises, Module 3 provisions with Terraform, and Module 7 stitches them together — all starting from the job-structure vocabulary you build here.

### Time Budget

| Task | Estimated Time |
|------|---------------|
| Setup and orientation | 3 min |
| Task 1: Basic multi-stage pipeline | 7 min |
| Task 2: Add dependency caching | 5 min |
| Task 3: Parallel execution | 4 min |
| Task 4: Secret injection | 4 min |
| Task 5: Matrix build | 5 min |
| Review and teardown | 2 min |
| **Total** | **30 min** |

## Objectives

- Build a multi-stage CI pipeline (Gitea Actions locally, GitHub Actions on Cloud) with lint, test, and build jobs
- Configure dependency caching to reduce pipeline run time
- Restructure jobs for parallel execution
- Inject secrets securely into a deployment step

## Prerequisites

- Gitea account on your Local Labs VM (`http://<hostname>.labs.decoded.com:8100` — replace `<hostname>` with the output of `hostname`; from the VM terminal: `http://localhost:8100`) with repository creation permissions
- Git installed locally
- Node.js 20 installed (for local testing of the app)
- A text editor

::: cloud-lab
**Cloud Labs prerequisites (in place of the Gitea account above):**

- GitHub account with repository creation permissions
:::

## Setup (summary)

> Your lab environment is pre-configured. If you encounter issues, ask your instructor.

On Local Labs, create a `cicd-lab-01` repo in Gitea (`http://<hostname>.labs.decoded.com:8100/<your-user>/cicd-lab-01`), copy the starter files into it, and add a `DEPLOY_TOKEN` repository secret (value `lab-secret-value-12345`).

- Lab-scoped (Local Labs): create the `cicd-lab-01` repo in Gitea at `http://<hostname>.labs.decoded.com:8100` (replace `<hostname>` with the output of `hostname`; from the VM terminal: `http://localhost:8100`), copy the starter files from `<course-repo>/labs/module-01/starter/` (including the `.gitea/workflows/` directory), and add the `DEPLOY_TOKEN` repo secret under **Settings → Secrets → Actions**.

::: cloud-lab
**Cloud Labs setup.** On the Cloud Labs track, replace the lab-scoped step above with: in GitHub, create the `cicd-lab-01` repo under your account, copy the starter files from `<course-repo>/labs/module-01/starter/` (including the `.github/workflows/` directory), and add `DEPLOY_TOKEN` as a repo secret under **Settings → Secrets and variables → Actions**. Cloud Labs uses `.github/workflows/ci.yml` as the canonical workflow path; the starter includes both `.gitea/workflows/` and `.github/workflows/` so either path works.
:::

## Task 1: Basic multi-stage pipeline

Create `.gitea/workflows/ci.yml` with three sequential jobs: `lint`, `test`, and `build`. (The starter already scaffolds this file — open it and complete the TODOs.)

::: cloud-lab
**Cloud Labs path.** Use `.github/workflows/ci.yml` instead — the starter also scaffolds this file with identical content. Gitea Actions also reads `.github/workflows/`, but `.gitea/workflows/` is the canonical path on Local Labs and `.github/workflows/` is canonical on Cloud Labs.
:::

Requirements:

- Trigger on push to `main` and on pull requests to `main`
- Set `permissions: contents: read` at the workflow level
- Pin `actions/checkout` and `actions/setup-node` to commit SHAs (see starter file for SHAs)
- Use `ubuntu-24.04` as the runner (not `ubuntu-latest`)
- Lint job runs `npm ci` then `npm run lint`
- Test job runs `npm ci` then `npm test`, and depends on lint
- Build job runs `npm ci` then `npm run build`, and depends on test

Push your changes and verify all three jobs pass in the **Actions** tab of your repo (Gitea: `http://<hostname>.labs.decoded.com:8100/<your-user>/cicd-lab-01/actions`; GitHub: `https://github.com/<your-user>/cicd-lab-01/actions`).

## Task 2: Add dependency caching

Modify each job to cache npm dependencies:

- Add `cache: npm` to the `actions/setup-node` step in each job

Push and observe the second run. The `npm ci` step should show "Cache restored" in the logs. (Local Labs runners use the Gitea Actions cache service; `cache: npm` works without extra configuration.)

## Task 3: Parallel execution

Restructure the pipeline so that `test` and `build` run in parallel after `lint`:

- Change `build` to depend on `lint` instead of `test`
- Test and build should both start as soon as lint passes

Push and verify in the Actions tab that test and build start at the same time.

## Task 4: Secret injection

Add a `deploy` job that:

- Depends on both `test` and `build`
- Uses the `DEPLOY_TOKEN` secret as an environment variable scoped to a single step
- Runs a script that prints `Deploying with token length: ${#DEPLOY_TOKEN}` (prints the length, not the value)
- The secret must NOT be available to the lint, test, or build jobs

> **Where the secret lives.** On Local Labs, set `DEPLOY_TOKEN` under repo **Settings → Secrets → Actions** in Gitea (`http://<hostname>.labs.decoded.com:8100/<your-user>/cicd-lab-01/settings/secrets/actions`). On Cloud Labs, set it under **Settings → Secrets and variables → Actions** in GitHub. The `secrets.DEPLOY_TOKEN` reference in YAML is identical across both.

Push and verify that:

- The deploy job runs after test and build both pass
- The deploy step logs show the token length (not the token value)

## Task 5: Matrix build

Convert the `test` job to run across multiple Node.js versions using a matrix strategy:

- Test against Node.js 20 and 22
- Use `${{ matrix.node-version }}` in the `setup-node` step
- All matrix combinations must pass

Push and verify in the Actions tab that two separate test jobs run (one per Node.js version). (Gitea Actions on Local Labs and GitHub Actions on Cloud Labs both render matrix jobs as separate entries in the workflow run view.)

## Acceptance Criteria

- [ ] Pipeline triggers on push to `main` and on pull requests to `main`
- [ ] `permissions: contents: read` is set at workflow level
- [ ] All actions are pinned to commit SHAs (no mutable tags like `@v4`)
- [ ] Runner is `ubuntu-24.04` (not `ubuntu-latest`)
- [ ] Lint, test, and build jobs all pass
- [ ] npm dependency caching is configured and restores on second run
- [ ] Test and build jobs run in parallel after lint
- [ ] Deploy job depends on both test and build
- [ ] `DEPLOY_TOKEN` secret is scoped to the deploy step only (not workflow or job level)
- [ ] No secrets are printed in plain text in logs
- [ ] Test job uses a matrix strategy across Node.js 20 and 22

## Recap & Takeaways

You built a five-job CI pipeline from scratch — `lint`, `test`, `build`, `deploy`, plus a matrixed variant of `test` — and you shaped each of the four pipeline-architecture levers from Module 1 along the way: job dependencies (the DAG), caching (speed), parallelisation (wall-clock), and secret scoping (blast radius). You practised SHA-pinning actions and setting workflow-level `permissions: contents: read`, which are the two cheap security moves every pipeline you write from here on should start with. The `ci.yml` you end up with is the seed every later lab extends — and because Gitea Actions and GitHub Actions run the same YAML spec, the file you author on Local Labs ports to Cloud Labs (and vice versa) with zero code changes.

- You now have a working multi-job pipeline with npm caching, parallel `test`/`build`, and a step-scoped `DEPLOY_TOKEN`.
- You practised the DAG-then-optimise refactor — shipping the sequential version first, then loosening dependencies for parallel execution.
- You know where commit-SHA pinning lives and how to look up a new action's SHA when you need one.

## Hints

<details><summary>Hint 1: Finding commit SHAs for actions</summary>

The starter file includes the SHAs you need in comments. For future reference: go to the action's repository on GitHub, click Releases, find the version tag, and copy the full 40-character commit SHA.

For this lab:

- `actions/checkout` v4.2.2: `11bd71901bbe5b1630ceea73d27597364c9af683`
- `actions/setup-node` v4.4.0: `49933ea5288caeca8642d1e84afbd3f7d6820020`

</details>

<details><summary>Hint 2: Scoping secrets to a single step</summary>

Use the `env:` key at step level, not job level:

```yaml
steps:
  - name: Deploy
    env:
      DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
    run: echo "Token length: ${#DEPLOY_TOKEN}"
```

</details>

<details><summary>Hint 3: Parallel execution structure</summary>

For test and build to run in parallel, both must depend on lint but NOT on each other:

```yaml
test:
  needs: lint
build:
  needs: lint
deploy:
  needs: [test, build]
```

</details>

<details><summary>Hint 4: Verifying cache hit</summary>

In the Actions tab, expand the "Setup Node.js" step. On a cache hit, you will see a line like:
`Cache restored from key: npm-Linux-...`

The first run will show "Cache not found". The second run should show the restored cache.

</details>

<details><summary>Hint 5: Matrix build syntax</summary>

Add a `strategy` block to the test job:

```yaml
test:
  needs: lint
  strategy:
    matrix:
      node-version: [20, 22]
  runs-on: ubuntu-24.04
  steps:
    - uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683
    - uses: actions/setup-node@49933ea5288caeca8642d1e84afbd3f7d6820020
      with:
        node-version: ${{ matrix.node-version }}
        cache: npm
    - run: npm ci
    - run: npm test
```

Each matrix combination runs as a separate job. The deploy job will wait for all three to pass.

</details>

## Teardown

No cloud resources to destroy on either track. There is no persistent state on your laptop from this lab. Repo cleanup (optionally delete the `cicd-lab-01` repo from Gitea on Local Labs, or from GitHub on Cloud Labs) is handled by the instructor at end-of-cohort.
