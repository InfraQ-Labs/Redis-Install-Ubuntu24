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
---

  ```
make -j $(nproc)
sudo make install
  ```
---
Verify installation:
  ```
redis-server --version
redis-cli --version
  ```

## 3. Configure Redis

Create the Redis configuration directory and copy the default configuration file:
```
sudo mkdir /etc/redis
sudo cp /usr/src/redis-8.0.0/redis.conf /etc/redis
sudo nano /etc/redis/redis.conf
  ```
In the configuration file, modify the following settings.

###Set bind address:
For local-only access (recommended):
  ```
bind 127.0.0.1
  ```
For public access (use with firewall/ACLs):
  ```
bind 0.0.0.0
 ```
 Tip: Keep this default unless you have a controlled environment and understand the security implications.

### Enable systemd supervision
  ```
supervised systemd
  ```
### Enable append-only file for persistence:
  ```
appendonly yes
  ```
⚠️ Warning: Enabling appendonly yes on an existing Redis database can lead to data loss if done by editing the config file and restarting the server.
To safely convert an existing database to AOF, use the CONFIG command on a live server first. More details: https://redis.io/docs/latest/operate/oss_and_stack/management/persistence/

### Add snapshot save rules:
  ```
save 900 1
save 300 10
save 60 10000
  ```
### To customize the defalt port:
  ```
port 6379
  ```

### Configure Redis working directory

Redis uses this directory to store persistent data.
  ```
dir /var/lib/redis
  ```
Save and close the file.

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

✅ Notes

* Redis binaries: /usr/local/bin/redis-server
* Configuration file: /etc/redis/redis.conf
* Data directory: /var/lib/redis
* Systemd service name: redis.service
* Default port: 6379













