#!/usr/bin/env python3
"""
Nginx Proxy Manager API Automation Script

This script automates the creation of proxy hosts in Nginx Proxy Manager through its API.
It creates proxy configurations for multiple services running in Docker containers.
"""

import argparse
import json
import os
import requests
import sys
from urllib.parse import urljoin

# Default configuration
DEFAULT_CONFIG = {
    "npm_url": "http://localhost:81",
    "domain": "fatunicorns.club",
    "services": [
        {
            "name": "plex",
            "forward_scheme": "http",
            "forward_host": "plex",
            "forward_port": 32400,
            "websocket": True,
            "cache_assets": True,
            "block_exploits": True,
            "allow_websocket_upgrade": True,
            "ssl_forced": True
        },
        {
            "name": "sonarr",
            "forward_scheme": "http",
            "forward_host": "sonarr",
            "forward_port": 8989,
            "websocket": False,
            "cache_assets": False,
            "block_exploits": True,
            "allow_websocket_upgrade": False,
            "ssl_forced": True
        },
        {
            "name": "radarr",
            "forward_scheme": "http",
            "forward_host": "radarr",
            "forward_port": 7878,
            "websocket": False,
            "cache_assets": False,
            "block_exploits": True,
            "allow_websocket_upgrade": False,
            "ssl_forced": True
        },
        {
            "name": "sabnzbd",
            "forward_scheme": "http",
            "forward_host": "sabnzbd",
            "forward_port": 8080,
            "websocket": False,
            "cache_assets": False,
            "block_exploits": True,
            "allow_websocket_upgrade": False,
            "ssl_forced": True
        },
        {
            "name": "prowlarr",
            "forward_scheme": "http",
            "forward_host": "prowlarr",
            "forward_port": 9696,
            "websocket": False,
            "cache_assets": False,
            "block_exploits": True,
            "allow_websocket_upgrade": False,
            "ssl_forced": True
        },
        {
            "name": "frigate",
            "forward_scheme": "http",
            "forward_host": "frigate",
            "forward_port": 5000,
            "websocket": True,
            "cache_assets": False,
            "block_exploits": True,
            "allow_websocket_upgrade": True,
            "ssl_forced": True
        },
        {
            "name": "portainer",
            "forward_scheme": "http",
            "forward_host": "portainer",
            "forward_port": 9000,
            "websocket": True,
            "cache_assets": False,
            "block_exploits": True,
            "allow_websocket_upgrade": True,
            "ssl_forced": True
        }
    ]
}

class NginxProxyManagerAPI:
    def __init__(self, base_url, email, password):
        self.base_url = base_url
        self.email = email
        self.password = password
        self.token = None
        self.session = requests.Session()
    
    def login(self):
        """Authenticate with the Nginx Proxy Manager API and get token"""
        login_url = urljoin(self.base_url, "/api/tokens")
        payload = {
            "identity": self.email,
            "secret": self.password
        }
        
        try:
            response = self.session.post(login_url, json=payload)
            response.raise_for_status()
            
            data = response.json()
            self.token = data.get("token")
            
            if not self.token:
                print("Failed to get authentication token.")
                return False
                
            # Set auth header for all future requests
            self.session.headers.update({"Authorization": f"Bearer {self.token}"})
            print("Successfully authenticated with NPM")
            return True
            
        except requests.exceptions.RequestException as e:
            print(f"Login failed: {e}")
            return False
    
    def get_proxy_hosts(self):
        """Get all existing proxy hosts"""
        if not self.token:
            print("Not authenticated. Call login() first.")
            return []
            
        proxy_url = urljoin(self.base_url, "/api/nginx/proxy-hosts")
        
        try:
            response = self.session.get(proxy_url)
            response.raise_for_status()
            
            return response.json()
            
        except requests.exceptions.RequestException as e:
            print(f"Failed to get proxy hosts: {e}")
            return []
    
    def create_proxy_host(self, service, domain):
        """Create a proxy host configuration for a service"""
        if not self.token:
            print("Not authenticated. Call login() first.")
            return None
            
        proxy_url = urljoin(self.base_url, "/api/nginx/proxy-hosts")
        
        domain_name = f"{service['name']}.{domain}"
        
        # Build the proxy host configuration
        payload = {
            "domain_names": [domain_name],
            "forward_scheme": service["forward_scheme"],
            "forward_host": service["forward_host"],
            "forward_port": service["forward_port"],
            "access_list_id": 0,
            "certificate_id": 0,
            "meta": {
                "letsencrypt_agree": True,
                "dns_challenge": False
            },
            "advanced_config": "",
            "locations": [],
            "block_exploits": service.get("block_exploits", False),
            "caching_enabled": service.get("cache_assets", False),
            "allow_websocket_upgrade": service.get("allow_websocket_upgrade", False),
            "http2_support": True,
            "hsts_enabled": True,
            "hsts_subdomains": False,
            "ssl_forced": service.get("ssl_forced", False)
        }
        
        try:
            print(f"Creating proxy host for {domain_name}...")
            response = self.session.post(proxy_url, json=payload)
            response.raise_for_status()
            
            return response.json()
            
        except requests.exceptions.RequestException as e:
            print(f"Failed to create proxy host for {domain_name}: {e}")
            if hasattr(e.response, 'text'):
                print(f"Response: {e.response.text}")
            return None
            
    def update_proxy_host(self, host_id, service, domain):
        """Update an existing proxy host configuration"""
        if not self.token:
            print("Not authenticated. Call login() first.")
            return None
            
        proxy_url = urljoin(self.base_url, f"/api/nginx/proxy-hosts/{host_id}")
        
        domain_name = f"{service['name']}.{domain}"
        
        # Build the proxy host configuration
        payload = {
            "domain_names": [domain_name],
            "forward_scheme": service["forward_scheme"],
            "forward_host": service["forward_host"],
            "forward_port": service["forward_port"],
            "access_list_id": 0,
            "certificate_id": 0,
            "meta": {
                "letsencrypt_agree": True,
                "dns_challenge": False
            },
            "advanced_config": "",
            "locations": [],
            "block_exploits": service.get("block_exploits", False),
            "caching_enabled": service.get("cache_assets", False),
            "allow_websocket_upgrade": service.get("allow_websocket_upgrade", False),
            "http2_support": True,
            "hsts_enabled": True,
            "hsts_subdomains": False,
            "ssl_forced": service.get("ssl_forced", False)
        }
        
        try:
            print(f"Updating proxy host for {domain_name}...")
            response = self.session.put(proxy_url, json=payload)
            response.raise_for_status()
            
            return response.json()
            
        except requests.exceptions.RequestException as e:
            print(f"Failed to update proxy host for {domain_name}: {e}")
            if hasattr(e.response, 'text'):
                print(f"Response: {e.response.text}")
            return None

def main():
    parser = argparse.ArgumentParser(description="Automate Nginx Proxy Manager configurations")
    parser.add_argument("--url", help="Nginx Proxy Manager URL (default: http://localhost:81)", default="http://localhost:81")
    parser.add_argument("--email", help="NPM admin email", required=True)
    parser.add_argument("--password", help="NPM admin password", required=True)
    parser.add_argument("--domain", help="Base domain (default: fatunicorns.club)", default="fatunicorns.club")
    parser.add_argument("--force-update", help="Force update existing proxy hosts", action="store_true")
    
    args = parser.parse_args()
    
    # Initialize the API client
    api = NginxProxyManagerAPI(args.url, args.email, args.password)
    
    # Login to the API
    if not api.login():
        sys.exit(1)
    
    # Get existing proxy hosts
    existing_hosts = api.get_proxy_hosts()
    existing_domains = {}
    
    for host in existing_hosts:
        for domain in host.get("domain_names", []):
            existing_domains[domain] = host.get("id")
    
    # Create or update proxy hosts for each service
    for service in DEFAULT_CONFIG["services"]:
        domain_name = f"{service['name']}.{args.domain}"
        
        if domain_name in existing_domains and not args.force_update:
            print(f"Proxy host for {domain_name} already exists (ID: {existing_domains[domain_name]}). Skipping...")
            continue
        
        if domain_name in existing_domains:
            # Update existing proxy host
            result = api.update_proxy_host(existing_domains[domain_name], service, args.domain)
            if result:
                print(f"Successfully updated proxy host for {domain_name}")
        else:
            # Create new proxy host
            result = api.create_proxy_host(service, args.domain)
            if result:
                print(f"Successfully created proxy host for {domain_name}")
    
    print("All proxy hosts have been processed.")

if __name__ == "__main__":
    main()
