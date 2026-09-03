# CI/CD Pipeline: GitHub Actions → Ansible → Docker Compose on AWS EC2

This project deploys a **backend** and **frontend** application as Docker containers to a target **AWS EC2 VM**, triggered automatically by a **GitHub Actions** workflow that hands off the actual deployment work to an **Ansible controller node**.

---

## 1. Architecture / How It All Fits Together

There are **three machines** involved:

| Machine | Role |
|---|---|
| **GitHub Actions runner** (`ubuntu-latest`) | Builds Docker images, pushes them to Docker Hub, then SSHes into the Ansible controller to trigger the playbook |
| **Ansible Controller node** (your own VM/server) | Holds this repo (`deployment_by_Ansible`), runs `ansible-playbook`, and manages the target EC2 |
| **Target EC2 instance(s)** (`webservers` / dynamic AWS inventory) | Where the app actually runs via `docker compose` |

```
Push to GitHub
      │
      ▼
GitHub Actions workflow (deployment_via_ansible.yml)
      │  1. Build backend & frontend Docker images (--no-cache)
      │  2. Push both images to Docker Hub
      │  3. SSH into Ansible Controller node
      ▼
Ansible Controller node
      │  Runs: ansible-playbook docker_deployment.yml -e "host=app_GitHub" -i inventory
      ▼
Target EC2 instance (matched via AWS dynamic inventory, tag Application=GitHub)
      │  1. Clone/verify app repo
      │  2. Install Docker if missing
      │  3. docker compose down → pull → up -d --force-recreate
      ▼
App is live
```

---

## 2. Repository / File Breakdown

### A. In your GitHub repo
| File | Purpose |
|---|---|
| `.github/workflows/deployment_via_ansible.yml` | The GitHub Actions workflow. Builds and pushes the two Docker images, then SSHes into the Ansible controller to kick off the playbook. |

### B. On the Ansible Controller node (`deployment_by_Ansible/`)
| File | Purpose |
|---|---|
| `ansible.cfg` | Ansible's core config — sets the default inventory, disables host key checking, sets the SSH remote user, sets the private key path, and enables `sudo` privilege escalation. |
| `docker_deployment.yml` | The playbook itself. Clones/updates the app repo on the target host, installs Docker if not present, and brings the app up with `docker compose`. |
| `inventory/aws_ec2.yml` | A **dynamic** AWS EC2 inventory — auto-discovers running EC2 instances in `us-east-1` and groups them by their `Application` / `Environment` tags (e.g. `app_GitHub`, `env_prod`). |
| `inventory/hosts` | A **static** fallback inventory (manually listed IPs) — only used if you're not using the dynamic AWS inventory. |
| `README.md` | (this file's counterpart in that folder — currently empty in the zip) |

> ⚠️ Note the `-e` on its own line at the end of both `ansible.cfg` and `docker_deployment.yml` in the extracted files — that's a stray/incomplete line and should be removed; it isn't valid syntax on its own.

---

## 3. Prerequisites

### 3.1 GitHub side
1. A GitHub repository containing:
   - `./backend` and `./frontend` folders, each with a `Dockerfile`
   - The workflow file at `.github/workflows/deployment_via_ansible.yml`
2. **Docker Hub account** to host the built images.
3. **GitHub Repository Secrets** (Settings → Secrets and variables → Actions):

   | Secret name | Value |
   |---|---|
   | `DOCKER_USERNAME` | Your Docker Hub username |
   | `DOCKER_PASSWORD` | Your Docker Hub password or access token |
   | `Ansible_VM` | Public IP / hostname of the Ansible controller node |
   | `Ansible_VM_USER` | SSH username for the Ansible controller (e.g. `ubuntu`) |
   | `Ansible_VM_SSH_KEY` | Private SSH key (PEM contents) to log into the Ansible controller |

   > Your notes (`ans.txt`) list these as `ANSIBLE_VM`, `ANSIBLE_VM_SSH_KEY`, `ANSIBLE_VM_USER`, but the workflow YAML references `secrets.Ansible_VM`, `secrets.Ansible_VM_USER`, `secrets.Ansible_VM_SSH_KEY`. **GitHub secret names are case-sensitive** — make sure the names you create in GitHub exactly match what's referenced in the workflow file.

### 3.2 Ansible Controller node
1. **Ansible** installed:
   ```bash
   sudo apt update && sudo apt install -y ansible
   ```
2. **`amazon.aws` collection** installed (required for the dynamic `aws_ec2.yml` inventory):
   ```bash
   ansible-galaxy collection install amazon.aws
   pip install boto3 botocore
   ```
3. **AWS CLI installed and configured** with credentials that can describe EC2 instances:
   ```bash
   aws configure
   ```
4. **This `deployment_by_Ansible` folder** placed on the controller, e.g. at `/opt/ansible/github_actions/`, matching the path used in the workflow's SSH script step.
5. **SSH reachability** from the controller to the target EC2 instance(s).
6. **PEM file** for the target EC2 instance(s), placed on the controller (e.g. `/home/ubuntu/pemfile/AwsPrivateKey.pem`).

### 3.3 Target EC2 instance(s)
1. Must be **tagged** appropriately so the dynamic inventory can find them — the playbook is invoked with `-e "host=app_GitHub"`, which (per `aws_ec2.yml`'s `keyed_groups`) means the instance needs an EC2 tag:
   ```
   Application = GitHub
   ```
2. Security group must allow **inbound SSH (port 22)** from the Ansible controller's IP.
3. Ubuntu-based AMI (the playbook assumes `ubuntu` user and uses `apt`-oriented Docker install logic via `docker_installation.sh`).
4. A `docker_installation.sh` script must exist inside the cloned repo at the target (`{{ project_dir }}/docker_installation.sh`) — the playbook runs this to install Docker if it's missing. **This script is not included in the provided zip; you must add it to your app repo.**
5. A `docker-compose.yml`/`compose.yaml` file must exist in the cloned repo (`GitHub_action_assignment`), since the playbook runs `docker compose pull` / `up` from `project_dir`.

---

## 4. Setup Steps

### Step 1 — Prepare your application repo
Make sure `https://github.com/Yashwanthgowdam123/GitHub_action_assignment.git` (or your own repo, if you rename it) contains:
- `backend/Dockerfile`
- `frontend/Dockerfile`
- `docker-compose.yml` (referencing the images pushed to Docker Hub)
- `docker_installation.sh` (a shell script that installs Docker + Docker Compose on Ubuntu)

### Step 2 — Set up the Ansible Controller node
```bash
# 1. Install Ansible + AWS collection
sudo apt update && sudo apt install -y ansible python3-pip
pip3 install boto3 botocore
ansible-galaxy collection install amazon.aws

# 2. Configure AWS CLI credentials
aws configure

# 3. Download the Ansible project onto the controller
sudo mkdir -p /opt/ansible/github_actions
cd /opt/ansible/github_actions
git clone https://github.com/Yashwanthgowdam123/GitHub_action_assignment.git .
# (or copy the deployment_by_Ansible folder contents here directly)

# 4. Place your target EC2 PEM key on the controller
mkdir -p /home/ubuntu/pemfile
cp /path/to/AwsPrivateKey.pem /home/ubuntu/pemfile/
chmod 400 /home/ubuntu/pemfile/AwsPrivateKey.pem
```

### Step 3 — Update `ansible.cfg`
Edit the private key path to match wherever you actually placed the PEM file:
```ini
private_key_file = /home/ubuntu/pemfile/AwsPrivateKey.pem
```
Also remove the stray trailing `-e` line — it's not valid config.

### Step 4 — Update the dynamic inventory (`inventory/aws_ec2.yml`)
- Set `regions` to match where your EC2 instance actually lives (currently `us-east-1`).
- Tag your target EC2 instance in AWS with `Application = GitHub` so it lands in the `app_GitHub` group the workflow targets (`-e "host=app_GitHub"`).

### Step 5 — Verify the dynamic inventory resolves correctly
From the Ansible controller:
```bash
cd /opt/ansible/github_actions
ansible-inventory -i inventory/aws_ec2.yml --graph
```
You should see your target instance under `@app_GitHub`.

### Step 6 — Add GitHub Secrets
In your GitHub repo → **Settings → Secrets and variables → Actions**, add all five secrets listed in section 3.1.

### Step 7 — Test manually before relying on the pipeline
On the controller, dry-run the playbook once by hand:
```bash
ansible-playbook /opt/ansible/github_actions/docker_deployment.yml \
  -e "host=app_GitHub" \
  -i /opt/ansible/github_actions/inventory
```
Confirm it clones the repo, installs Docker, and brings the compose stack up on the target EC2.

### Step 8 — Trigger the pipeline
Push to the GitHub repo (any branch, since the workflow triggers on `push` with no branch filter) or run it manually via **Actions → CI-CD Pipeline via Ansible → Run workflow** (enabled by the `workflow_dispatch` trigger).

---

## 5. End-to-End Workflow Summary

1. **Trigger** — A `git push` (or manual dispatch) starts the GitHub Actions workflow.
2. **Checkout** — The runner checks out your repo code.
3. **Docker Hub login** — Authenticates using `DOCKER_USERNAME` / `DOCKER_PASSWORD`.
4. **Build images** — Builds `backend` and `frontend` images with `--no-cache` (forces a full rebuild, notably useful to avoid stale Angular frontend builds), tagged `:v1.0`.
5. **Push images** — Both images are pushed to Docker Hub under your username.
6. **SSH to Ansible Controller** — Using `Ansible_VM` / `Ansible_VM_USER` / `Ansible_VM_SSH_KEY`, the runner SSHes into your Ansible controller node.
7. **Run the playbook** — On the controller, it executes:
   ```bash
   ansible-playbook /opt/ansible/github_actions/docker_deployment.yml -e "host=app_GitHub" -i /opt/ansible/github_actions/inventory
   ```
8. **Playbook logic on the target EC2:**
   - Checks whether the app repo is already cloned; clones it if not.
   - Checks whether Docker is installed; installs it via `docker_installation.sh` if not.
   - Runs `docker compose down` (ignoring failure if nothing is running).
   - Runs `docker compose pull` to fetch the freshly pushed `:v1.0` images.
   - Runs `docker compose up -d --force-recreate` to restart containers with the new images.
9. **Done** — The updated app is running on the target EC2 instance.

---

## 6. Known Gaps to Fix Before Production Use

- **Fixed image tag `:v1.0`** — every build overwrites the same tag. Consider using `${{ github.sha }}` or a version bump strategy so old images aren't clobbered and rollbacks are possible.
- **`docker_installation.sh` is referenced but not included** in the provided zip — it must exist in the app repo.
- **`docker-compose.yml` is not included** — it must exist in the app repo and should reference the `:v1.0` (or dynamic) image tags pushed by the workflow.
- **Stray `-e` lines** in `ansible.cfg` and `docker_deployment.yml` should be removed.
- **Secret name casing mismatch** between your notes (`ANSIBLE_VM`) and the workflow file (`Ansible_VM`) — use the exact casing from the workflow file when creating GitHub secrets.
- **`inventory/hosts` static file** is unused unless you switch `ansible.cfg`'s `inventory =` line away from `aws_ec2.yml` — keep only the one you actually intend to use to avoid confusion.
