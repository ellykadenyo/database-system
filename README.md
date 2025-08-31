# PostgreSQL Analytics Demo with Docker

## 1. Introduction
This project demonstrates a small-scale **data analytics deployment** using Docker.  
The architecture brings together a **PostgreSQL cluster**, **pgPool-II** for connection pooling and load balancing, and **Metabase** for visualization.  
Additionally, a **CSV ingestion service** is included to showcase real-time loading of structured data into PostgreSQL for analytics.  

The deployment is intended as a **demo and proof-of-concept**. It is not optimized for production use at very high scale (e.g., >1M inserts/sec). However, it illustrates how modern data analytics stacks can be containerized, orchestrated, and shared reproducibly through Docker Compose.

---

## 2. Architecture and Tools
The project includes the following components:
- **PostgreSQL Cluster**: A primary database with one or more replicas to support analytics queries.
- **pgPool-II**: Middleware that provides connection pooling, load balancing (for reads), and failover management.
- **Metabase**: An open-source BI and analytics platform used for dashboarding and visualization of ingested data.
- **CSV Ingestion Service**: A lightweight process/container to read CSV files and load them into PostgreSQL tables for querying.
- **Docker Compose**: Used to define and run the multi-container application.

---

## 3. Installations
### Docker & Docker Compose
A helper Bash script (`install-docker.sh`) is provided to set up the latest Docker Engine and Docker Compose plugin on Ubuntu.  
The script:
- Adds Docker’s official APT repository.  
- Installs **docker-ce**, **docker-compose-plugin**, and related utilities.  
- Configures the current user to join the **docker** group for rootless usage.  
- Installs useful Linux packages (`git`, `jq`, `unzip`, `make`, etc.).  

#### Usage
On an Ubuntu machine (e.g., AWS EC2):
```bash
wget https://raw.githubusercontent.com/your-repo/install-docker.sh
bash install-docker.sh
newgrp docker
docker run hello-world
```

⚠️ **Note**: This script is designed for Ubuntu. Other Linux distributions will require different installation steps.

---

## 4. Deployments
Deployments are defined in `docker-compose.yaml` files (to be provided in the project).  

To deploy the stack:
```bash
git clone https://github.com/your-repo/postgres-analytics-demo.git
cd postgres-analytics-demo
docker compose up -d
```

The services will include:
- **Postgres primary + replicas**
- **pgPool-II middleware**
- **Metabase dashboard (default port: 3000)**
- **CSV ingestion container**

Logs can be viewed with:
```bash
docker compose logs -f
```

To stop the stack:
```bash
docker compose down
```

---

## 5. System Usage
- Connect to PostgreSQL via pgPool-II endpoint for database queries.  
- Place CSV files in the `data/` directory (mounted into ingestion container) for automatic ingestion.  
- Access **Metabase** at `http://<server-public-ip>:3000` to explore and visualize data.  
- Use Docker commands (`docker ps`, `docker logs`, etc.) to monitor containers.

---

## 6. Proposed Future Improvements
- Add monitoring using **Prometheus + Grafana** for database and container metrics.  
- Extend PostgreSQL cluster with **Citus** or explore **YugabyteDB/CockroachDB** for multi-writer scalability.  
- Add **automatic backup & restore** pipelines for the database.  
- Secure deployment with **TLS/SSL** and role-based access control.  
- Introduce CI/CD pipeline for automated testing and deployment of updates.  

---
