#!/usr/bin/env python3
"""
High-throughput NYC Yellow Taxi CSV ingestion for Citus/PostgreSQL cluster.

Features:
- Downloads data from a URL (Kaggle API or direct URL)
- Extracts ZIP files
- Streams CSV data directly into Citus distributed table using COPY
- Modular, robust, with logging and error handling
- Reads DB credentials securely from a .env file

Author: Elly Kadenyo
"""

import os
import sys
import logging
import zipfile
import tempfile
import shutil
from pathlib import Path
import subprocess
import psycopg2
from dotenv import load_dotenv
import requests

# ------------------------------
# Setup logging
# ------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger(__name__)

# ------------------------------
# Load environment variables
# ------------------------------
load_dotenv()  # loads variables from .env in current dir

DB_HOST = os.getenv("DATALOADER_DB_HOST", "localhost")
DB_PORT = os.getenv("DATALOADER_DB_PORT", "5432")
DB_NAME = os.getenv("DATALOADER_DB_NAME")
DB_USER = os.getenv("DATALOADER_DB_USER")
DB_PASSWORD = os.getenv("DATALOADER_DB_PASSWORD")

# Validate essential variables
for var_name, var_value in [("DB_NAME", DB_NAME), ("DB_USER", DB_USER), ("DB_PASSWORD", DB_PASSWORD)]:
    if not var_value:
        logger.error(f"Missing required environment variable: {var_name}")
        sys.exit(1)

# ------------------------------
# Constants
# ------------------------------
DATA_URL = "https://www.kaggle.com/api/v1/datasets/download/elemento/nyc-yellow-taxi-trip-data"
DISTRIBUTED_TABLE = "yellow_tripdata"

# ------------------------------
# Helper functions
# ------------------------------
def download_zip(url: str, dest: Path) -> Path:
    """Download a ZIP file from a URL to a destination path."""
    local_zip = dest / "nyc-yellow-taxi-trip-data.zip"
    logger.info(f"Downloading {url} to {local_zip}...")
    response = requests.get(url, stream=True)
    response.raise_for_status()
    with open(local_zip, "wb") as f:
        for chunk in response.iter_content(chunk_size=8192):
            f.write(chunk)
    logger.info("Download completed.")
    return local_zip


def extract_zip(zip_path: Path, extract_to: Path) -> list[Path]:
    """Extract ZIP and return list of CSV files."""
    logger.info(f"Extracting {zip_path} to {extract_to}...")
    csv_files = []
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        zip_ref.extractall(extract_to)
        for file in zip_ref.namelist():
            if file.lower().endswith(".csv"):
                csv_files.append(extract_to / file)
    if not csv_files:
        raise FileNotFoundError("No CSV files found in the ZIP archive.")
    logger.info(f"Found {len(csv_files)} CSV file(s).")
    return csv_files


def load_csv_to_db(csv_path: Path):
    """Load CSV into Citus/Postgres using COPY for max throughput."""
    logger.info(f"Loading {csv_path} into {DISTRIBUTED_TABLE}...")
    conn = None
    try:
        conn = psycopg2.connect(
            dbname=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD,
            host=DB_HOST,
            port=DB_PORT
        )
        conn.autocommit = True
        with conn.cursor() as cur:
            with open(csv_path, "r") as f:
                cur.copy_expert(f"COPY {DISTRIBUTED_TABLE} FROM STDIN WITH CSV HEADER", f)
        logger.info(f"Successfully loaded {csv_path.name} into {DISTRIBUTED_TABLE}.")
    except Exception as e:
        logger.exception(f"Failed to load {csv_path}: {e}")
        raise
    finally:
        if conn:
            conn.close()


# ------------------------------
# Main orchestration
# ------------------------------
def main():
    tmp_dir = Path(tempfile.mkdtemp(prefix="nyc_taxi_ingest_"))
    logger.info(f"Using temporary directory: {tmp_dir}")
    try:
        zip_file = download_zip(DATA_URL, tmp_dir)
        csv_files = extract_zip(zip_file, tmp_dir)
        for csv_file in sorted(csv_files):
            load_csv_to_db(csv_file)
        logger.info("All files ingested successfully.")
    except Exception as e:
        logger.error(f"Ingestion process failed: {e}")
        sys.exit(1)
    finally:
        logger.info(f"Cleaning up temporary directory {tmp_dir}...")
        shutil.rmtree(tmp_dir, ignore_errors=True)


if __name__ == "__main__":
    main()