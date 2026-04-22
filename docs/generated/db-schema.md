# Planned DB Schema

## run_sessions

- `id` TEXT PRIMARY KEY
- `started_at` TEXT NOT NULL
- `ended_at` TEXT
- `distance_m` REAL NOT NULL
- `duration_ms` INTEGER NOT NULL
- `source_summary` TEXT NOT NULL

## run_points

- `session_id` TEXT NOT NULL
- `lat` REAL NOT NULL
- `lng` REAL NOT NULL
- `timestamp_rel_ms` INTEGER NOT NULL
- `pace_sec_per_km` REAL
- `source` TEXT NOT NULL
