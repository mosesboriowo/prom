#!/bin/bash

# This script installs Prometheus, Grafana, and Node Exporter on an Ubuntu server

# Update package list and upgrade packages
echo "Updating package lists..."
sudo apt-get update -y
sudo apt-get upgrade -y

# Install dependencies
echo "Installing dependencies..."
sudo apt-get install -y wget curl lsb-release software-properties-common

# --- Installing Prometheus ---
echo "Installing Prometheus..."

# Prometheus version
PROMETHEUS_VERSION="2.43.0"

# Create a user for Prometheus
sudo useradd --no-create-home --shell /bin/false prometheus

# Download Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz

# Extract and move files
tar -xvzf prometheus-${PROMETHEUS_VERSION}.linux-amd64.tar.gz
cd prometheus-${PROMETHEUS_VERSION}.linux-amd64

# Move Prometheus binaries to the appropriate location
sudo mv prometheus /usr/local/bin/
sudo mv promtool /usr/local/bin/

# Move configuration files
sudo mkdir /etc/prometheus
sudo mv prometheus.yml /etc/prometheus/

# Set the correct permissions
sudo chown -R prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool /etc/prometheus

# Create Prometheus systemd service
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<EOL
[Unit]
Description=Prometheus
After=network.target

[Service]
User=prometheus
Group=prometheus
ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus/ --web.listen-address=:9090

[Install]
WantedBy=multi-user.target
EOL

# Reload systemd, enable, and start Prometheus
sudo systemctl daemon-reload
sudo systemctl enable prometheus
sudo systemctl start prometheus

# --- Installing Grafana ---
echo "Installing Grafana..."

# Grafana version

# Add Grafana APT repository
sudo apt-get install -y apt-transport-https software-properties-common wget
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null

#Add repo for stable release
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

#update the packages
# Updates the list of available packages
sudo apt-get update

# Install Grafana
sudo apt-get install grafana -y

# Enable and start Grafana service
sudo systemctl enable grafana-server
sudo systemctl start grafana-server

# --- Installing Node Exporter ---
echo "Installing Node Exporter..."

# Node Exporter version
NODE_EXPORTER_VERSION="1.3.1"

# Download Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

# Extract Node Exporter
tar -xvzf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
cd node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64

# Move binary to the appropriate location
sudo mv node_exporter /usr/local/bin/

# Create a systemd service for Node Exporter
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOL
[Unit]
Description=Node Exporter
After=network.target

[Service]
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=default.target
EOL

# Reload systemd, enable, and start Node Exporter
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

# --- Prometheus Configuration ---
echo "Configuring Prometheus to scrape Node Exporter..."

# Edit prometheus.yml to include node exporter scrape config
sudo tee -a /etc/prometheus/prometheus.yml > /dev/null <<EOL
- job_name: 'node_exporter'
  static_configs:
    - targets: ['localhost:9100']
EOL

# Restart Prometheus to apply the changes
sudo systemctl restart prometheus

# --- Final Steps ---
echo "Installation complete! Prometheus, Grafana, and Node Exporter are installed."

echo "You can now access Grafana at http://<your-server-ip>:3000 (default username: admin, password: admin)"
echo "Prometheus is running at http://<your-server-ip>:9090"
echo "Node Exporter is running at http://<your-server-ip>:9100"
