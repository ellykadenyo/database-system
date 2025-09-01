#!/usr/bin/env python3
#Ensure it is executable # chmod +x scripts/ingest_helper.py
"""
ingest_helper.py
Simple CSV ingestion helper that loads CSVs from /data into the yellow_tripdata table using COPY.
This script is intentionally simple and logs progress to stdout for troubleshooting.
"""

import os
import sys
import psycopg2
from psycopg2 import sql
import glob
import time

DB_HOST = os.environ.get("DATALOADER_DB_HOST", "localhost")
DB_PORT = int(os.environ.get("DATALOADER_DB_PORT", "5432"))
DB_NAME = os.environ.get("DATALOADER_DB_NAME", "tripdata")
DB_USER = os.environ.get("DATALOADER_DB_USER")
DB_PASSWORD = os.environ.get("DATALOADER_DB_PASSWORD")

def log(msg):
    print(f"{time.strftime('%Y-%m-%dT%H:%M:%SZ')} [dataloader] {msg}", flush=True)

def connect():
    conn = psycopg2.connect(host=DB_HOST, port=DB_PORT, dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD)
    conn.autocommit = True
    return conn

def main():
    log("Starting ingestion helper")
    data_files = glob.glob("/data/*.csv")
    if not data_files:
        log("No CSV files found in /data; exiting")
        return

    conn = connect()
    cur = conn.cursor()
    for f in data_files:
        log(f"Loading file: {f}")
        # Use COPY for efficiency; assume CSV header aligns with table columns
        try:
            with open(f, 'r') as fh:
                cur.copy_expert(sql.SQL("COPY public.yellow_tripdata FROM STDIN WITH CSV HEADER"), fh)
            log(f"Finished loading {f}")
        except Exception as e:
            log(f"Error loading {f}: {e}")
    cur.close()
    conn.close()
    log("Ingestion helper complete")

if __name__ == "__main__":
    main()