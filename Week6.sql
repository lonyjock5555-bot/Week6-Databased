# ==========================================
# HANDS-ON LAB: BACKUPS, PITR AND REPLICATION
# ==========================================

# STEP 1: TAKE AND VERIFY A LOGICAL BACKUP

mkdir -p ~/backups

pg_dump -Fc -f ~/backups/bootcamp.dump bootcamp

pg_restore --list ~/backups/bootcamp.dump | head

createdb bootcamp_check

pg_restore -d bootcamp_check ~/backups/bootcamp.dump


# STEP 2: ENABLE WAL ARCHIVING

mkdir -p ~/backups/wal
mkdir -p ~/backups/base

# Add to postgresql.conf:
# wal_level = replica
# archive_mode = on
# archive_command = 'test ! -f /home/lonyjock/backups/wal/%f && cp %p /home/lonyjock/backups/wal/%f'

sudo systemctl restart postgresql

pg_basebackup -D ~/backups/base -Ft -z -Xs -P


# STEP 3: SIMULATE A DISASTER AND RECOVER

# Run in PostgreSQL:
SELECT now();

DELETE FROM students;

# Add to postgresql.conf:
# restore_command = 'cp /home/lonyjock/backups/wal/%f %p'
# recovery_target_time = 'YYYY-MM-DD HH:MM:SS'
# recovery_target_action = 'pause'

# Stop PostgreSQL:
sudo systemctl stop postgresql

# Restore the base backup into the PostgreSQL data directory.
# Create the recovery signal file:
sudo -u postgres touch /path/to/data_directory/recovery.signal

# Start PostgreSQL:
sudo systemctl start postgresql

# Verify recovery:
SELECT count(*) FROM students;


# STEP 4: SET UP STREAMING REPLICATION

# Run on the primary database:
# CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'reppass';

# Add to pg_hba.conf:
# host replication replicator 127.0.0.1/32 scram-sha-256

sudo systemctl reload postgresql

# Build the standby replica:
mkdir -p ~/standby

pg_basebackup -h 127.0.0.1 -U replicator -D ~/standby -R -P


# STEP 5: MONITOR REPLICATION HEALTH

# Run on the primary database:
SELECT
    application_name,
    state,
    pg_wal_lsn_diff(sent_lsn, replay_lsn) AS lag_bytes
FROM pg_stat_replication;


# ==========================================
# WRAP-UP
# ==========================================

# 1. Created and verified a logical backup.
# 2. Enabled WAL archiving and took a base backup.
# 3. Performed Point-in-Time Recovery.
# 4. Set up a streaming standby replica.
# 5. Monitored replication health and lag.
