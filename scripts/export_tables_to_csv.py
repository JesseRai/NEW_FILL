#!/usr/bin/env python3
"""
Export all tables from a PostgreSQL database to individual CSV files.

Update the connection parameters and output directory below before running.
"""

import os
import csv
import psycopg2

# Database connection parameters
conn_params = {
    'dbname': 'Greencycles',
    'user': 'postgres',
    'password': 'Spoon',
    'host': 'localhost',
    'port': '5432'
}

# Output directory (change to where you want the CSV files written)
output_dir = "/path/to/output/directory"


def main() -> None:
    """Connect to the database, enumerate tables and export each to a CSV file."""
    # Ensure the output directory exists
    os.makedirs(output_dir, exist_ok=True)

    with psycopg2.connect(**conn_params) as conn:
        with conn.cursor() as cur:
            # Get a list of tables in the public schema
            cur.execute(
                """
                SELECT table_name
                FROM information_schema.tables
                WHERE table_schema = 'public';
                """
            )
            tables = [row[0] for row in cur.fetchall()]

            # Export each table as a CSV
            for table_name in tables:
                cur.execute(f"SELECT * FROM {table_name};")
                rows = cur.fetchall()
                columns = [desc[0] for desc in cur.description]

                file_path = os.path.join(output_dir, f"{table_name}.csv")
                with open(file_path, 'w', newline='', encoding='utf-8') as csvfile:
                    csvwriter = csv.writer(csvfile)
                    csvwriter.writerow(columns)
                    csvwriter.writerows(rows)

                print(f"Exported {table_name} to {file_path}")


if __name__ == "__main__":
    main()
