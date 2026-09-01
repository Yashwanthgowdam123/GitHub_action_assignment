# 🚀 " MEAN Stack DevOps Deployment"

This project demonstrates **end-to-end DevOps implementation** for deploying a full-stack **MEAN (MongoDB, Express, Angular, Node.js)** application using containerization, CI/CD automation, and cloud infrastructure.

The deployment uses the following technologies:

* **Docker & Docker Compose** for containerization
* **Nginx Reverse Proxy** for application routing
* **AWS EC2 (Ubuntu)** for infrastructure hosting
* **Docker Hub** as the container image registry.
* **GitHub Actions** for CI/CD automation
* **Git** for source control management.

The objective of this project is to build a **production-style deployment workflow** where application updates automatically trigger a **build → container image push → deployment process**.

---
## Workflow Diagram

![Workflow Diagram](presentation/WorkflowDiagram.png)

# 📌 Project Overview

The application consists of multiple components deployed as containers.

| Component         | Technology        | Purpose                        |
| ----------------- | ----------------- | ------------------------------ |
| Frontend          | Angular           | User Interface                 |
| Backend           | Node.js + Express | REST API                       |
| Database          | MongoDB           | Data persistence               |
| Reverse Proxy     | Nginx             | Traffic routing                |
| Container Runtime | Docker            | Containerization               |
| Orchestration     | Docker Compose    | Multi-container deployment     |
| CI/CD             | GitHub Actions    | Automated build and deployment |
| Infrastructure    | AWS EC2           | Cloud hosting                  |

---

# 📂 Project Structure

```text
crud-dd-task-mean-app
│
├── backend
│   ├── app
│   ├── dockerfile
│   ├── package.json
│   └── server.js
│
├── frontend
│   ├── Dockerfile
│   ├── angular.json
│   ├── package.json
│   └── src
│
├── nginx
│   └── default.conf
│
├── docker-compose.yml
└── README.md
```

---

# 🛠️ Implementation Workflow

This section explains the **complete step-by-step process followed to implement the project**.

---

# 1️⃣ Downloading the Application Code

The application source code was provided via **Google Drive**.

Steps followed:

1. Downloaded the project archive file

```
crud-dd-task-mean-app.zip
```

2. Extracted the ZIP archive locally.

After extraction, the project contained separate folders for:

* frontend
* backend
* nginx configuration
* docker compose file

---

# 2️⃣ Uploading Code to EC2 Server

The extracted project was uploaded to the cloud server using **SCP (Secure Copy Protocol)**.

Example command:

```bash
scp -i mykey.pem -r crud-dd-task-mean-app ubuntu@<EC2-IP>:/home/ubuntu/
```

This copied the project files into the EC2 instance.

---

# ☁️ Cloud Infrastructure

The application is deployed on **AWS EC2**.

### Instance Configuration

| Parameter     | Value        |
| ------------- | ------------ |
| Instance Type | t3.medium    |
| vCPU          | 2            |
| RAM           | 4 GB         |
| Storage       | 20GB EBS     |
| OS            | Ubuntu 22.04 |

### Why t3.medium?

The t3.medium instance was chosen because the deployment requires:

* Docker runtime
* Multiple container images
* MongoDB storage
* CI/CD deployment artifacts

The **20GB storage** allows space for Docker images and persistent MongoDB data.

---

# 3️⃣ Preparing the Server Environment

Connected to EC2 via SSH:

```bash
ssh -i mykey.pem ubuntu@<EC2-IP>
```

Installed Docker:

```bash
sudo apt update
sudo apt install docker.io -y
```

Enabled Docker service:

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

Verify Docker installation:

```bash
docker --version
```

Installed Docker Compose:

```bash
sudo apt install docker-compose -y
```

---

# 🔁 Git Workflow

Git was used for **version control and code management**.

### Configure Git

```bash
git config --global user.name "Karthik R"
git config --global user.email "your-email@example.com"
```

Initialize repository:

```bash
git init
```

Add remote GitHub repository:

```bash
git remote add origin <github-repo-url>
```

---

### Push Code to GitHub

Add files:

```bash
git add .
```

Commit changes:

```bash
git commit -m "Initial commit of MEAN stack project"
```

Push to GitHub:

```bash
git push origin main
```

At this stage the **GitHub repository connection was successfully established**.

---

# 🐳 Docker Containerization

The application was containerized using **Docker**.

Separate Docker images were created for:

* Backend API
* Angular Frontend
* MongoDB database

---

# Backend Docker Image

Build backend image:

```bash
docker build -t <dockerhub-username>/mean-backend ./backend
```

Purpose:

* Install Node.js dependencies
* Run Express API server
* Expose backend port

---

# Frontend Docker Image

Build frontend image:

```bash
docker build -t <dockerhub-username>/mean-frontend ./frontend
```

Uses **multi-stage Docker build**.

Stage 1
Build Angular application.

Stage 2
Serve compiled static files using Nginx.

---

# 📦 Docker Hub Registry

Docker images were pushed to Docker Hub.

Login:

```bash
docker login
```

Push images:

```bash
docker push <dockerhub-username>/mean-backend
docker push <dockerhub-username>/mean-frontend
```

---

# 🐳 Docker Compose Deployment

Docker Compose was used to deploy all containers together.

Services included:

| Service  | Purpose             |
| -------- | ------------------- |
| mongodb  | Database container  |
| backend  | Node.js API         |
| frontend | Angular application |
| nginx    | Reverse proxy       |

Run deployment:

```bash
docker compose up -d
```

Verify containers:

```bash
docker ps
```

Expected output:

```
mongo
backend
frontend
nginx
```

---

# 🌐 Nginx Reverse Proxy

Nginx acts as the **entry point to the application**.

Configuration file:

```
nginx/default.conf
```

Responsibilities:

* Serve Angular frontend
* Route API calls to backend
* Expose application via port 80

Application URL:

```
http://<EC2-IP>
```

---

# 🔐 GitHub Secrets Configuration

To enable secure CI/CD deployment, GitHub Secrets were configured.

Navigate to:

```
Repository → Settings → Secrets and Variables → Actions
```

### Configured Secrets

| Secret Name     | Purpose             |
| --------------- | ------------------- |
| DOCKER_USERNAME | Docker Hub username |
| DOCKER_PASSWORD | Docker Hub password |
| VM_HOST         | EC2 public IP       |
| VM_USER         | EC2 SSH username    |
| VM_SSH_KEY      | SSH private key     |

These secrets allow the CI/CD pipeline to:

* Authenticate with Docker Hub
* Connect securely to EC2
* Deploy updated containers automatically

---

# ⚙️ CI/CD Pipeline (GitHub Actions)

The CI/CD pipeline was implemented using **GitHub Actions**.

Workflow location:

```
.github/workflows/docker-build.yml
```

Pipeline steps:

1️⃣ Checkout repository
2️⃣ Login to Docker Hub
3️⃣ Build Docker images
4️⃣ Push images to Docker Hub
5️⃣ SSH into EC2 server
6️⃣ Pull latest images
7️⃣ Restart containers

---

# 🔄 Continuous Deployment

Whenever code changes are pushed:

```bash
git add .
git commit -m "updated application"
git push origin main
```

GitHub Actions automatically:

* builds new Docker images
* pushes them to Docker Hub
* connects to EC2
* pulls latest images
* restarts containers

The application gets **updated automatically without manual deployment**.

---

# 📊 AWS Infrastructure Diagram

```
             Internet Users
                    │
                    ▼
            AWS Security Group
           (Allow 22 and 80 ports)
                    │
                    ▼
             AWS EC2 Instance
            (Ubuntu t3.medium)
                 20GB EBS
                    │
                    ▼
              Docker Engine
                    │
     ┌──────────────┼──────────────┐
     ▼              ▼              ▼
 Nginx Container Frontend Container Backend Container
      │                                   │
      └───────────────► MongoDB Container
```

---

# 🔄 CI/CD Pipeline Diagram

```
Developer
   │
   ▼
Local Code Changes
   │
   ▼
git add / commit / push
   │
   ▼
GitHub Repository
   │
   ▼
GitHub Actions Pipeline
   │
   ├─ Build Docker Images
   ├─ Push Images to Docker Hub
   └─ SSH into EC2
          │
          ▼
   Pull Latest Images
          │
          ▼
   Restart Containers
          │
          ▼
Updated Application Running
```

---

# 🐳 Docker Container Architecture

```
          User Browser
               │
               ▼
        Nginx Reverse Proxy
               │
     ┌─────────┴─────────┐
     ▼                   ▼
Angular Frontend      Node.js Backend
    Container           Container
                              │
                              ▼
                        MongoDB Database
                           Container
```

---

# 🧪 Deployment Verification

Open browser:
```
http://<EC2-IP>
```

Expected behavior:

* Angular UI loads
* Backend API responds
* MongoDB stores data

---

# 📊 Useful Debug Commands

Check containers:

```bash
docker ps
```

View logs:

```bash
docker logs backend
docker logs nginx
```

Restart containers:

```bash
docker compose up -d
```

Stop containers:

```bash
docker compose down
```

---

# 📈 Future Improvements

Potential improvements include:

* Kubernetes deployment
* HTTPS with SSL certificates
* Domain integration
* Monitoring using Prometheus and Grafana
* Infrastructure as Code using Terraform

---

# 👨‍💻 Author

Karthik R
DevOps Engineer
