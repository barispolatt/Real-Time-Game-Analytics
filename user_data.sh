#!/bin/bash

# Loggin configurations
# Logs the status to /var/log/user_data.log file when setup.
exec > >(tee /var/log/user_data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo ">>> Setup starting"

# system update and needed tools
apt-get update -y
apt-get install -y apt-transport-https openjdk-17-jre-headless nginx apache2-utils

# Elastic Repo key ve storage
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-8.x.list

apt-get update -y

# ELK installation
apt-get install -y elasticsearch logstash kibana

# Elasticsearch configuretion
# it has to reachable just by local
cat <<EOF > /etc/elasticsearch/elasticsearch.yml
cluster.name: gamma-cluster
node.name: node-1
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 127.0.0.1
http.port: 9200
xpack.security.enabled: false
discovery.type: single-node
EOF

# JVM Heap setting (giving elastic 2GB RAM)
echo "-Xms2g" > /etc/elasticsearch/jvm.options.d/heap.options
echo "-Xmx2g" >> /etc/elasticsearch/jvm.options.d/heap.options

# Kibana configuration
# Listens localhost (on Nginx)
cat <<EOF > /etc/kibana/kibana.yml
server.port: 5601
server.host: "127.0.0.1"
elasticsearch.hosts: ["http://127.0.0.1:9200"]
EOF

# Logstash Pipeline
# receives JSON data from port 5044, processes it, and sends to Elasticsearch.
cat <<EOF > /etc/logstash/conf.d/main.conf
input {
  http {
    port => 5044
    codec => json
  }
}

filter {
  # Finding location (GeoIP) from IP address.
  if [ip] {
    geoip {
      source => "ip"
      target => "geoip"
    }
  }
}

output {
  elasticsearch {
    hosts => ["http://127.0.0.1:9200"]
    index => "game-analytics-%{+YYYY.MM.dd}"
  }
}
EOF

# Nginx (Reverse Proxy & Security) configurations
# Kibana (5601) is closed to the outside, so port 80 is forwarding to 5601.

# Adding password (username: admin, password: admin123)
htpasswd -b -c /etc/nginx/.htpasswd admin admin123

cat <<EOF > /etc/nginx/sites-available/default
server {
    listen 80;
    server_name _;

    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        proxy_pass http://127.0.0.1:5601;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Nginx config test ve reload
nginx -t
systemctl reload nginx

# Starting and enabling Services
systemctl daemon-reload
systemctl enable elasticsearch kibana logstash nginx
systemctl start elasticsearch kibana logstash nginx

echo ">>> Installation complete!"