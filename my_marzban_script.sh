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
sudo apt update && sudo apt install -y curl socat wget sed

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
sudo bash -c "$(curl -sL https://raw.githubusercontent.com/erfjab/ESSL/master/essl.sh)" @ --install
# SSL issue can take time, added sudo
sudo essl "$EMAIL" "$DOMAIN" marzban

echo "🎨 Setting up Custom Template..."
sudo mkdir -p /var/lib/marzban/templates/subscription/
sudo wget -N -P /var/lib/marzban/templates/subscription/ https://raw.githubusercontent.com/samimifar/marzban-template/master/src/en/index.html

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
