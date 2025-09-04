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

The directory structure of the project repository is as follows:
```
database-system/
├── .env                        # Centralized environment variables & secrets
├── .env.example                # Example environment file
├── .gitignore                  # Git ignore file
├── docker-compose.yml          # Main orchestrator (all services)
├── ingest_yellow_taxi_data.py  # CSV ingestion script
├── README.md                   # Documentation
│
├── db/                         # PostgreSQL cluster
│   ├── init/                   # Initialization SQL scripts
│   │   ├── 01_create_users.sql
│   │   └── 02_create_schema.sql
│   └── pgpool/                 # pgPool-II configuration
│       └── pgpool.conf
│
├── monitoring/                 # Monitoring stack
│   ├── prometheus.yml          # Prometheus scrape configs
│   └── grafana/
│       ├── dashboards/
│       │   └── postgres_overview.json
│       └── provisioning/
│           ├── dashboards/
│           └── datasources/
│
├── analytics/                  # BI / visualization layer
│   ├── materialized_views/
│   │   ├── dataloader_mv_execution.sql
│   │   ├── hourly_average_trip_duration.sql
│   │   ├── MoM_hourly_tips_change.sql
│   │   ├── QoQ_hourly_tips_change.sql
│   │   ├── taxy_density_per_square_km.sql
│   │   └── trips_per_day.sql
│   └── metabase/
│       ├── hourly_average_trip_duration.sql
│       ├── MoM_hourly_tips_change.sql
│       ├── QoQ_hourly_tips_change.sql
│       ├── taxy_density_per_square_km.sql
│       └── trips_per_day.sql
│
├── scripts/                    # Utility scripts
│   ├── backup.sh               # Manual/cron backup script
│   ├── ingest_helper.py        # Helper for ingestion
│   ├── ingest_run.sh           # Ingestion runner
│   └── restore.sh              # Restore from backups
```

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
wget https://raw.githubusercontent.com/ellykadenyo/database-system/main/scripts/install-docker.sh
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
git clone https://github.com/ellykadenyo/database-system.git
cd database-system
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

## 5. How To

### Quick Start

1. **Copy environment file:**
   
   Copy `.env.example` to `.env` and fill in all required values.

2. **Make helper scripts executable:**
   
   ```bash
   chmod +x db/coordinator-init.sh
   chmod +x scripts/ingest_run.sh
   chmod +x scripts/ingest_helper.py
   chmod +x scripts/ingest_and_setup.sh
   chmod +x scripts/backup.sh
   chmod +x scripts/restore.sh
   ```

3. **Start the stack:**
   
   ```bash
   docker compose up -d
   ```

4. **Tail logs to watch initialization:**
   
   ```bash
   docker compose logs -f
   # Or specific services
   docker compose logs -f citus_coordinator pgpool prometheus grafana metabase
   ```

5. **Ingest data:**
   
   After the stack is up, copy CSV files into `./data/` and run:
   
   ```bash
   ./scripts/ingest_and_setup.sh
   ```

6. **Access services (host port mapping from .env):**
   
   - Metabase:   `http://<vm-ip>:${METABASE_PORT}`
   - Grafana:    `http://<vm-ip>:${GRAFANA_PORT}`
   - Prometheus: `http://<vm-ip>:${PROMETHEUS_PORT}`
   - Postgres/Citus coordinator: `postgresql://<vm-ip>:${COORDINATOR_PORT}/tripdata` (use `POSTGRES_USER` and `POSTGRES_PASSWORD`)

7. **Logging tips:**
   
   All scripts are verbose and include timestamps. For deep debugging, check the coordinators’ container logs:
   
   ```bash
   docker logs citus_coordinator
   docker logs citus_worker1
   docker logs pgpool
   docker logs postgres_exporter
   ```

---

## 6. Proposed Future Improvements
- Add monitoring using **Prometheus + Grafana** for database and container metrics.  
- Extend PostgreSQL cluster with **Citus** or explore **YugabyteDB/CockroachDB** for multi-writer scalability.  
- Add **automatic backup & restore** pipelines for the database.  
- Secure deployment with **TLS/SSL** and role-based access control.  
- Introduce CI/CD pipeline for automated testing and deployment of updates.  

---
