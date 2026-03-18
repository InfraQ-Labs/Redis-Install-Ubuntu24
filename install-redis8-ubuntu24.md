# Install Redis on Ubuntu

This guide shows how to install Redis 8 on Ubuntu 24 from source, with systemd service and production-ready configuration.

---

## 1. Install required build dependencies

Install required packages needed to compile Redis.
  ```
sudo apt-get update

sudo apt install -y \
build-essential \
tcl \
curl \
pkg-config \
libssl-dev \
git \
cmake \
clang \
automake \
autoconf \
libtool
  ```
---

## 2. Download latest Redis

Download Redis source, extract, compile Redis and install

  ```
cd /usr/src
sudo wget https://github.com/redis/redis/archive/refs/tags/8.0.0.tar.gz
sudo tar -xzf 8.0.0.tar.gz
cd redis-8.0.0
  ```

  ```
make -j $(nproc)
sudo make install
  ```

Verify installation:
  ```
redis-server --version
redis-cli --version
  ```
---
## 3. Configure Redis

Create the Redis configuration directory and copy the default configuration file:
```
sudo mkdir /etc/redis
sudo cp /usr/src/redis-8.0.0/redis.conf /etc/redis
sudo nano /etc/redis/redis.conf
  ```

🔧 Required Configuration Changes

Below are the important changes you must make in the configuration file.
1. Enable systemd supervision

By default, this setting is commented or set to no.

Location: ~Line 328

* Default:
  ```
  # supervised no
  ```
* Change to:
  ```
  supervised systemd
  ```
Reason:
Allows Redis to integrate properly with systemd, ensuring reliable service management (start/stop/restart). Without this, Redis may fail under systemd.

2. Enable Append-Only File (AOF) persistence

Location: ~Line 1405
* Default:
  ```
  appendonly no
  ```
* Change to:
  ```
  appendonly yes
  ```
Reason:
* Enables durable persistence. Data is written to disk on every write operation, reducing risk of data loss compared to snapshot-only (RDB).

  ** ⚠️ Important Warning:
  * Enabling appendonly yes on an existing database via config change + service restart can lead to data loss.
  * This setting should ideally be configured during the initial database setup.

* For existing databases, enable it safely using:
  ```
  redis-cli CONFIG SET appendonly yes
  ```
  * More info: https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/

3. Configure working directory
Location: ~Line 516
* Default:
  ```
  dir ./
  ```
* Change to:
  ```
  dir /var/lib/redis
  ```
Reason:
* Ensures Redis stores persistent data in a proper system directory instead of a relative path, which can break under systemd.

4. Configure bind address
Location: ~Line 88

* Default:
  ```
  bind 127.0.0.1 ::1
  ```
* Recommended (secure, local-only):
  ```
  bind 127.0.0.1
  ```
* Optional (public access):
  ```
  bind 0.0.0.0
  ```
Reason:
* 127.0.0.1 → restricts access to localhost (safe default)
* 0.0.0.0 → allows external access (must secure with firewall/auth)
* ⚠️ Exposing Redis publicly without security controls is dangerous.

5. Add snapshot (RDB) save rules

Add these lines if not already present:
  ```
save 900 1
save 300 10
save 60 10000
  ```
Reason:
* Defines when Redis should create snapshots (RDB backups) based on write activity.

6. Verify port configuration

Default:
  ```
  port 6379
  ```
Reason:
* Default Redis port. Change only if required.

7. Configure Redis Password (Authentication)

Location: ~Line 1068
* Default:
  ```
  # requirepass foobared
  ```
* Change to:
  ```
  requirepass YourStrongPasswordHere
  ```
Reason:
* Adds authentication to Redis, preventing unauthorized access — especially critical if Redis is exposed outside localhost.

  ** ⚠️ Security Note:
  * Always set a strong password if Redis is accessible externally
  * Combine with firewall rules (ufw) for better protection
  * Never expose Redis publicly without authentication
    
✔️ Save and exit the file

---

## 4. Configure systemd Service

Create a systemd service file for Redis.
  ```
sudo nano /etc/systemd/system/redis.service
  ```

Add the following configuration:
  ```
[Unit]
Description=Redis In-Memory Data Store
After=network.target

[Service]
User=redis
Group=redis
ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
ExecStop=/usr/local/bin/redis-cli shutdown
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
  ```

Save and exit.

---

## 5. Create Redis user and directories

Create a dedicated Redis system user and configure permissions.
  ```
sudo adduser --system --group --no-create-home redis
sudo mkdir /var/lib/redis
sudo chown redis:redis /var/lib/redis
sudo chmod 770 /var/lib/redis
  ```
---

## 6. Start Redis and enable it on boot

Reload systemd and start the Redis service.
  ```
sudo systemctl daemon-reload
sudo systemctl start redis
sudo systemctl enable redis
  ```
---

## 7. Verify Redis Installation

Check Redis service status.
  ```
sudo systemctl status redis
  ```
Test Redis connectivity.
  ```
redis-cli ping
# Expected output: PONG
  ```
---
✅ Notes

* Redis binaries: /usr/local/bin/redis-server
* Configuration file: /etc/redis/redis.conf
* Data directory: /var/lib/redis
* Systemd service name: redis.service
* Default port: 6379













