#install updates
sudo apt-get updates

#Add groups for prometheus
sudo groupadd --system prometheus

#Add a user
sudo useradd -s /sbin/nologin --system -g prometheus prometheus

#install prometheus my-sql exporter
curl -s https://api.github.com/repos/prometheus/mysqld_exporter/releases/latest   | grep browser_download_url   | grep linux-amd64 | cut -d '"' -f 4   | wget -qi -
tar xvf mysqld_exporter*.tar.gz
sudo mv  mysqld_exporter-*.linux-amd64/mysqld_exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/mysqld_exporter

#checkn  node-exporter version
mysqld_exporter  --version

