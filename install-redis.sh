#!/bin/bash

set -e

echo "🚀 Starting Redis 8 installation on Ubuntu 24..."

# --------------------------------------------------
# 1. Install dependencies
# --------------------------------------------------
echo "📦 Installing required dependencies..."
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

# --------------------------------------------------
# 2. Download and extract Redis
# --------------------------------------------------
echo "⬇️ Downloading Redis 8.0.0..."

cd /usr/src
sudo wget -q https://github.com/redis/redis/archive/refs/tags/8.0.0.tar.gz

echo "📦 Extracting Redis..."
sudo tar -xzf 8.0.0.tar.gz
cd redis-8.0.0

# --------------------------------------------------
# 3. Compile and install Redis
# --------------------------------------------------
echo "⚙️ Compiling Redis..."
make -j $(nproc)

echo "📥 Installing Redis..."
sudo make install

# Verify installation
echo "🔍 Verifying Redis installation..."
redis-server --version
redis-cli --version

# --------------------------------------------------
# 4. Configure Redis
# --------------------------------------------------
echo "⚙️ Setting up Redis configuration..."

sudo mkdir -p /etc/redis
sudo cp /usr/src/redis-8.0.0/redis.conf /etc/redis/redis.conf

CONFIG_FILE="/etc/redis/redis.conf"

# Backup config
sudo cp $CONFIG_FILE ${CONFIG_FILE}.bak

echo "🛠️ Applying exact-match configuration changes..."

# Enable systemd supervision
sudo sed -i 's|^# supervised no|supervised systemd|' $CONFIG_FILE

# Change working directory
sudo sed -i 's|^dir ./|dir /var/lib/redis|' $CONFIG_FILE

# Change bind address (public access)
sudo sed -i 's|^bind 127.0.0.1 ::1|bind 0.0.0.0|' $CONFIG_FILE

# Enable appendonly
sudo sed -i 's|^appendonly no|appendonly yes|' $CONFIG_FILE

# Add snapshot rules if missing
grep -q "^save 900 1" $CONFIG_FILE || echo "save 900 1" | sudo tee -a $CONFIG_FILE
grep -q "^save 300 10" $CONFIG_FILE || echo "save 300 10" | sudo tee -a $CONFIG_FILE
grep -q "^save 60 10000" $CONFIG_FILE || echo "save 60 10000" | sudo tee -a $CONFIG_FILE

echo "✅ Redis configuration updated"

# --------------------------------------------------
# 5. Create Redis user and directories
# --------------------------------------------------
echo "👤 Creating Redis user and directories..."

sudo adduser --system --group --no-create-home redis || true

sudo mkdir -p /var/lib/redis
sudo chown redis:redis /var/lib/redis
sudo chmod 770 /var/lib/redis

# --------------------------------------------------
# 6. Create systemd service
# --------------------------------------------------
echo "⚙️ Creating systemd service..."

sudo bash -c 'cat > /etc/systemd/system/redis.service <<EOF
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
EOF'

# --------------------------------------------------
# 7. Enable memory overcommit
# --------------------------------------------------
echo "🧠 Configuring kernel memory overcommit..."

sudo sysctl vm.overcommit_memory=1
echo "vm.overcommit_memory = 1" | sudo tee -a /etc/sysctl.conf

# --------------------------------------------------
# 8. Start Redis service
# --------------------------------------------------
echo "🚀 Starting Redis service..."

sudo systemctl daemon-reload
sudo systemctl enable redis
sudo systemctl restart redis

# --------------------------------------------------
# 9. Verify installation
# --------------------------------------------------
echo "🔍 Checking Redis status..."
sudo systemctl status redis --no-pager

echo "🔍 Testing Redis connection..."
redis-cli ping

echo ""
echo "✅ Redis installation completed successfully!"
echo ""

# --------------------------------------------------
# 10. Final Info
# --------------------------------------------------
echo "📌 Final Setup Details:"
echo "• Binary:      /usr/local/bin/redis-server"
echo "• Config:      /etc/redis/redis.conf"
echo "• Data Dir:    /var/lib/redis"
echo "• Service:     redis.service"
echo "• Port:        6379"

echo ""
echo "⚠️ NOTE:"
echo "This script uses exact-match config replacement."
echo "Ensure default redis.conf is not modified before running."
