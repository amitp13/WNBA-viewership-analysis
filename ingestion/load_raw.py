"""Load the raw files in data/raw/ into Snowflake (WNBA.RAW), unchanged.

Each source becomes one table. Yearly files of the same source are
stacked together, e.g. wnba_schedule_2023/2024/2025.parquet -> WNBA_SCHEDULE.
Tables are replaced on every run, so rerunning always gives the same result.
Credentials come from ~/.dbt/profiles.yml plus the SNOWFLAKE_KEY_PASSPHRASE
environment variable, the same ones dbt uses.
"""
import json
import os
import re
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
import pandas as pd
import snowflake.connector
import yaml
from snowflake.connector.pandas_tools import write_pandas

RAW_DIR = Path(__file__).resolve().parent.parent / "data" / "raw"
PROFILE = "wnba_dbt"  # the profile name in dbt_project.yml


def connect():
    """Sign in as the dbt service user with its key pair."""
    text = (Path.home() / ".dbt" / "profiles.yml").read_text()
    # profiles.yml uses dbt's {{ env_var('NAME') }} syntax; fill those in like dbt does
    text = re.sub(
        r"\{\{\s*env_var\(\s*['\"](\w+)['\"]\s*\)\s*\}\}",
        lambda m: os.environ[m.group(1)].replace("\\", "/"),
        text,
    )
    profile = yaml.safe_load(text)[PROFILE]
    cfg = profile["outputs"][profile["target"]]
    return snowflake.connector.connect(
        account=cfg["account"],
        user=cfg["user"],
        role=cfg["role"],
        warehouse=cfg["warehouse"],
        database=cfg["database"],
        schema="RAW",
        private_key_file=os.path.expanduser(cfg["private_key_path"]),
        private_key_file_pwd=os.environ["SNOWFLAKE_KEY_PASSPHRASE"],
    )

def to_text(value):
    """Turn list/dict cells into JSON text so Snowflake can store them."""
    if isinstance(value, np.ndarray):
        value = value.tolist()
    if isinstance(value, (list, dict)):
        return json.dumps(value, default=str)
    return value


def read_file(path):
    df = pd.read_parquet(path) if path.suffix == ".parquet" else pd.read_csv(path)
    for col in df.columns[df.dtypes == object]:
        df[col] = df[col].map(to_text)
    df["_source_file"] = path.name  # which file each row came from
    return df


def main():
    # Group files by source: strip a trailing _YYYY from the file name.
    sources = {}
    for path in sorted(RAW_DIR.iterdir()):
        if path.suffix in (".parquet", ".csv"):
            table = re.sub(r"_\d{4}$", "", path.stem).upper()
            sources.setdefault(table, []).append(path)

    loaded_at = datetime.now(timezone.utc)
    conn = connect()
    try:
        for table, paths in sources.items():
            df = pd.concat([read_file(p) for p in paths], ignore_index=True)
            df.columns = [c.upper() for c in df.columns]
            df["_LOADED_AT"] = loaded_at  # when this load ran
            _, _, rows, _ = write_pandas(
                conn,
                df,
                table,
                auto_create_table=True,  # build the table from the data's columns
                overwrite=True,          # replace whatever was there before
                use_logical_type=True,   # keep dates/timestamps as real timestamps
            )
            print(f"RAW.{table}: {rows:,} rows from {len(paths)} file(s)")
    finally:
        conn.close()


if __name__ == "__main__":
    main()