# Planned DB Schema

## run_sessions

- `id` TEXT PRIMARY KEY
- `started_at` TEXT NOT NULL
- `ended_at` TEXT
- `distance_m` REAL NOT NULL
- `duration_ms` INTEGER NOT NULL
- `source_summary` TEXT NOT NULL
- `average_cadence_spm` REAL
- `calories_kcal` REAL
- `record_source` TEXT NOT NULL
  - `appLocal`
  - `healthConnect`
  - `healthKit`
- `capture_source` TEXT NOT NULL
  - `phoneGps`
  - `wearOs`
  - `watchOs`
- `external_id` TEXT
- `last_synced_at` TEXT
- `sync_status` TEXT NOT NULL
  - `localOnly`
  - `synced`
  - `syncSkipped`
  - `syncFailed`
- `ghost_summary_json` TEXT
- `shoe_id` TEXT

## app_settings

- `key` TEXT PRIMARY KEY
- `value` TEXT NOT NULL

## run_shoes

- `id` TEXT PRIMARY KEY
- `name` TEXT NOT NULL
- `brand` TEXT NOT NULL
- `distance_limit_km` REAL NOT NULL
- `retired` INTEGER NOT NULL
- `deleted` INTEGER NOT NULL DEFAULT 0
- `image_path` TEXT
- `created_at` TEXT NOT NULL

## run_points

- `session_id` TEXT NOT NULL
- `sequence_index` INTEGER NOT NULL
- `lat` REAL NOT NULL
- `lng` REAL NOT NULL
- `timestamp_rel_ms` INTEGER NOT NULL
- `pace_sec_per_km` REAL
- `speed_mps` REAL
- `elevation_m` REAL
- `heart_rate_bpm` INTEGER
- `source` TEXT NOT NULL

## Indexes

- `idx_run_sessions_started_at` on `run_sessions(started_at)`
- `idx_run_sessions_external` on `run_sessions(record_source, external_id)`
