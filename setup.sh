#!/bin/bash
set -e

# Initialize .env if not exists
if [ ! -f .env ]; then
    cp .env.example .env
    CERT_PASSWORD=$(openssl rand -base64 16)
    sed -i "s/CERT_PASSWORD=.*/CERT_PASSWORD=$CERT_PASSWORD/" .env
fi

source .env

BASE_DN="o=$ORG"
ADMIN_DN="cn=$ADMIN_CN,$BASE_DN"
SERVER_HOSTNAME=$(hostname)

echo "Creating volumes..."
docker volume create edir-data
docker volume create idconsole-data

echo ""
echo "Starting eDirectory..."
echo "IMPORTANT: During setup prompts:"
echo "  - Press ENTER to accept all defaults"
echo "  - Choose a strong admin password when prompted"
echo "  - At the end: Press Ctrl+P then Ctrl+Q to detach"
echo ""
docker run -it --name edir \
    --stop-timeout 180 \
    --restart always \
    --memory="700M" \
    --cpuset-cpus="1" \
    --pids-limit="300" \
    -v edir-data:/config \
    --network=host \
    $EDIR_IMAGE new

echo ""
echo "DEBUG: Verifying eDirectory installation..."
docker exec edir ls -la /config/eDirectory/inst/data/data/ 2>&1 || echo "DEBUG: Installation may have failed"

echo ""
echo "Preparing Identity Console volume..."
VOLUME_PATH=/var/lib/docker/volumes/idconsole-data/_data
sudo mkdir -p $VOLUME_PATH/{data,var/log}

echo "Copying CA certificate..."
sudo docker cp edir:/config/eDirectory/inst/data/data/SSCert.pem $VOLUME_PATH/data/

echo "Generating server certificates..."
CERT_DIR=/tmp/idconsole-certs
mkdir -p $CERT_DIR
openssl genrsa -out $CERT_DIR/server.key 2048
openssl req -new -x509 -key $CERT_DIR/server.key \
    -out $CERT_DIR/server.crt -days 3650 \
    -subj "/CN=$SERVER_HOSTNAME/O=$ORG"
openssl pkcs12 -export -out $CERT_DIR/keys.pfx \
    -inkey $CERT_DIR/server.key -in $CERT_DIR/server.crt \
    -passout pass:$CERT_PASSWORD

sudo cp $CERT_DIR/keys.pfx $VOLUME_PATH/data/
sudo chmod 644 $VOLUME_PATH/data/keys.pfx
rm -rf $CERT_DIR

echo "Creating Identity Console configuration..."
sudo tee $VOLUME_PATH/data/edirapi.conf > /dev/null <<EOF
listen = ":9000"
pfxpassword = "$CERT_PASSWORD"
ospmode = "false"
bcert = "/etc/opt/novell/eDirAPI/cert/"
EOF

sudo chown -R 35753:35753 $VOLUME_PATH

echo "Starting Identity Console..."
docker run -d --name idconsole \
    --stop-timeout 180 \
    --restart always \
    --memory="1024M" \
    --cpuset-cpus="1" \
    --pids-limit="500" \
    -v idconsole-data:/config \
    --network=host \
    -e ACCEPT_EULA=Y \
    $IDCONSOLE_IMAGE

echo "Setup complete!"
echo ""
echo "IMPORTANT: Edit .env and set ADMIN_PASSWORD to match the password you entered during setup"
echo ""
echo "Access Identity Console at: https://$(hostname -I | awk '{print $1}'):9000/identityconsole/"
echo "Login: $ADMIN_DN"
