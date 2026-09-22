#!/bin/bash

# Clear screen
clear

# Show Banner
echo "------------------------------------------------------------"
echo -e "\e[1;36m"
echo "      ██╗   ██╗███╗   ██╗██╗     "
echo "      ╚██╗ ██╔╝████╗  ██║██║     "
echo "       ╚████╔╝ ██╔██╗ ██║██║     "
echo "        ╚██╔╝  ██║╚██╗██║██║     "
echo "         ██║   ██║ ╚████║███████╗"
echo "         ╚═╝   ╚═╝  ╚═══╝╚══════╝"
echo -e "\e[0m"
echo "           Marzban One Line Setup"
echo "------------------------------------------------------------"

# Necessary Package Check
echo "📦 Checking necessary packages..."
sudo apt update && sudo apt install -y curl socat wget sed certbot

# Inputs
read -p "Enter Domain Name (e.g., mar.example.com): " DOMAIN
read -p "Enter Email for SSL: " EMAIL
read -p "Enter Telegram Bot Token: " BOT_TOKEN
read -p "Enter Telegram Admin ID: " ADMIN_ID
read -p "Enter Subscription Title: " SUB_TITLE
read -p "Create Admin Username: " ADMIN_USER
read -s -p "Create Admin Password: " ADMIN_PASS
echo -e "\n--------------------------------------------------"

echo "🚀 Installing Marzban..."
# Marzban installation (using timeout as per your original script)
sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install

echo "🔐 Generating SSL Certificates..."
CERT_DIR="/var/lib/marzban/certs/$DOMAIN"
LE_CERT_DIR="/etc/letsencrypt/live/$DOMAIN"
RENEW_HOOK="/etc/letsencrypt/renewal-hooks/deploy/marzban-$DOMAIN.sh"

echo "🔥 Opening TCP port 80 for Let's Encrypt validation..."
if command -v ufw >/dev/null 2>&1; then
    sudo ufw allow 80/tcp
elif command -v firewall-cmd >/dev/null 2>&1 && sudo systemctl is-active --quiet firewalld; then
    sudo firewall-cmd --permanent --add-service=http
    sudo firewall-cmd --reload
else
    echo "No active UFW or firewalld detected; no local firewall rule was needed."
fi

echo "⚠️  If this is a cloud VPS, also allow inbound TCP port 80 in its provider firewall/security group."

# The domain A/AAAA record must point to this server.
sudo certbot certonly \
    --standalone \
    --non-interactive \
    --agree-tos \
    --email "$EMAIL" \
    -d "$DOMAIN"

sudo mkdir -p "$CERT_DIR"
sudo install -m 644 "$LE_CERT_DIR/fullchain.pem" "$CERT_DIR/fullchain.pem"
sudo install -m 600 "$LE_CERT_DIR/privkey.pem" "$CERT_DIR/privkey.pem"

# Keep the copies used by Marzban updated after every Certbot renewal.
sudo mkdir -p /etc/letsencrypt/renewal-hooks/deploy
sudo tee "$RENEW_HOOK" > /dev/null <<EOF
#!/bin/bash
set -e

install -m 644 "$LE_CERT_DIR/fullchain.pem" "$CERT_DIR/fullchain.pem"
install -m 600 "$LE_CERT_DIR/privkey.pem" "$CERT_DIR/privkey.pem"

if command -v marzban >/dev/null 2>&1; then
    marzban restart
fi
EOF
sudo chmod 700 "$RENEW_HOOK"

echo "🎨 Setting up Custom Template..."
sudo mkdir -p /var/lib/marzban/templates/subscription/
sudo wget -N -P /var/lib/marzban/templates/subscription/ https://raw.githubusercontent.com/yannaing86tt/template/main/subscription/index.html

ENV_FILE="/opt/marzban/.env"

update_env() {
    local key=$1
    local value=$2
    if sudo grep -iqE "^#?\s*$key\s*=" "$ENV_FILE"; then
        sudo sed -i "s|^#*\s*$key\s*=.*|$key = \"$value\"|gI" "$ENV_FILE"
    else
        echo "$key = \"$value\"" | sudo tee -a "$ENV_FILE" > /dev/null
    fi
}

echo "📝 Updating .env configuration..."
update_env "UVICORN_HOST" "0.0.0.0"
update_env "UVICORN_PORT" "8000"
update_env "UVICORN_SSL_CERTFILE" "/var/lib/marzban/certs/$DOMAIN/fullchain.pem"
update_env "UVICORN_SSL_KEYFILE" "/var/lib/marzban/certs/$DOMAIN/privkey.pem"
update_env "TELEGRAM_API_TOKEN" "$BOT_TOKEN"
update_env "TELEGRAM_ADMIN_ID" "$ADMIN_ID"
update_env "SUB_PROFILE_TITLE" "$SUB_TITLE"
update_env "XRAY_SUBSCRIPTION_URL_PREFIX" "https://$DOMAIN:8000"
update_env "CUSTOM_TEMPLATES_DIRECTORY" "/var/lib/marzban/templates/"
update_env "SUBSCRIPTION_PAGE_TEMPLATE" "subscription/index.html"

# Remove any old typo entries
sudo sed -i "/^UNICORN_SSL_/d" "$ENV_FILE"

echo "🔄 Restarting Marzban to apply changes..."
marzban restart

# Wait for Marzban to wake up before creating admin
sleep 5

echo "👤 Creating Admin User..."
marzban cli admin create --username "$ADMIN_USER" --password "$ADMIN_PASS" --sudo || echo "Admin setup skipped."

echo "--------------------------------------------------"
echo -e "\e[1;32m✅ Setup အောင်မြင်စွာ ပြီးဆုံးပါပြီ!\e[0m"
echo "🌐 Dashboard: https://$DOMAIN:8000/dashboard"
echo "👤 Username: $ADMIN_USER"
echo "--------------------------------------------------"
