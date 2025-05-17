#!/bin/bash
# Nginx Proxy Manager API Automation with cURL
# This script automates the creation of proxy hosts in Nginx Proxy Manager using cURL

# Configuration
NPM_URL="http://localhost:81"
DOMAIN="fatunicorns.club"
NPM_EMAIL="admin@example.com"
NPM_PASSWORD="your_password_here"

# Color output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to get auth token
get_auth_token() {
    echo -e "${YELLOW}Authenticating with Nginx Proxy Manager...${NC}"
    
    AUTH_RESPONSE=$(curl -s -X POST "${NPM_URL}/api/tokens" \
        -H "Content-Type: application/json" \
        -d "{\"identity\":\"${NPM_EMAIL}\",\"secret\":\"${NPM_PASSWORD}\"}")
    
    # Check if authentication was successful
    if echo "$AUTH_RESPONSE" | grep -q "token"; then
        TOKEN=$(echo "$AUTH_RESPONSE" | grep -o '"token":"[^"]*' | cut -d'"' -f4)
        echo -e "${GREEN}Authentication successful${NC}"
        return 0
    else
        echo -e "${RED}Authentication failed. Response: $AUTH_RESPONSE${NC}"
        return 1
    fi
}

# Function to create a proxy host
create_proxy_host() {
    local name=$1
    local forward_scheme=$2
    local forward_host=$3
    local forward_port=$4
    local websocket=$5
    local cache_assets=$6
    local block_exploits=$7
    
    local domain_name="${name}.${DOMAIN}"
    
    echo -e "${YELLOW}Creating proxy host for ${domain_name}...${NC}"
    
    # First check if this proxy host already exists
    EXISTING=$(curl -s -X GET "${NPM_URL}/api/nginx/proxy-hosts" \
        -H "Authorization: Bearer ${TOKEN}")
    
    if echo "$EXISTING" | grep -q "\"domain_names\":\[\"${domain_name}\"\]"; then
        echo -e "${YELLOW}Proxy host for ${domain_name} already exists. Skipping...${NC}"
        return 0
    fi
    
    # Prepare JSON data for creating proxy host
    JSON_DATA=$(cat <<EOF
{
    "domain_names": ["${domain_name}"],
    "forward_scheme": "${forward_scheme}",
    "forward_host": "${forward_host}",
    "forward_port": ${forward_port},
    "access_list_id": 0,
    "certificate_id": 0,
    "meta": {
        "letsencrypt_agree": true,
        "dns_challenge": false
    },
    "advanced_config": "",
    "locations": [],
    "block_exploits": ${block_exploits},
    "caching_enabled": ${cache_assets},
    "allow_websocket_upgrade": ${websocket},
    "http2_support": true,
    "hsts_enabled": true,
    "hsts_subdomains": false,
    "ssl_forced": true
}
EOF
)
    
    # Create the proxy host
    RESPONSE=$(curl -s -X POST "${NPM_URL}/api/nginx/proxy-hosts" \
        -H "Authorization: Bearer ${TOKEN}" \
        -H "Content-Type: application/json" \
        -d "$JSON_DATA")
    
    if echo "$RESPONSE" | grep -q "\"created_on\""; then
        echo -e "${GREEN}Successfully created proxy host for ${domain_name}${NC}"
    else
        echo -e "${RED}Failed to create proxy host for ${domain_name}. Response: ${RESPONSE}${NC}"
    fi
}

# Main script execution

# Get authentication token
get_auth_token
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to authenticate with Nginx Proxy Manager. Exiting...${NC}"
    exit 1
fi

# Create proxy hosts for each service
echo -e "${YELLOW}Creating proxy hosts for all services...${NC}"

# Plex
create_proxy_host "plex" "http" "plex" 32400 true true true

# Sonarr
create_proxy_host "sonarr" "http" "sonarr" 8989 false false true

# Radarr
create_proxy_host "radarr" "http" "radarr" 7878 false false true

# SABnzbd
create_proxy_host "sabnzbd" "http" "sabnzbd" 8080 false false true

# Prowlarr
create_proxy_host "prowlarr" "http" "prowlarr" 9696 false false true

# Frigate
create_proxy_host "frigate" "http" "frigate" 5000 true false true

# Portainer
create_proxy_host "portainer" "http" "portainer" 9000 true false true

echo -e "${GREEN}All proxy hosts have been processed.${NC}"
