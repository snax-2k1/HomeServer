#!/bin/bash
# Multi-Compose Management Script for HomeServer

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Available compose files
COMPOSE_FILES=(
    "docker-compose.yaml:Main HTPC Services"
    "docker-compose-traefik.yaml:Traefik with VLAN setup"
    "soulmask-compose.yaml:SoulMask Game Server"
)

show_status() {
    echo -e "${BLUE}=== Docker Compose Status ===${NC}"
    for file_info in "${COMPOSE_FILES[@]}"; do
        IFS=':' read -r file desc <<< "$file_info"
        if [ -f "$file" ]; then
            echo -e "${YELLOW}$desc ($file):${NC}"
            if docker-compose -f "$file" ps --services --filter "status=running" | grep -q .; then
                echo -e "${GREEN}  ✓ Running${NC}"
                docker-compose -f "$file" ps --format "table {{.Name}}\t{{.Status}}"
            else
                echo -e "${RED}  ✗ Stopped${NC}"
            fi
            echo ""
        fi
    done
}

start_service() {
    local file=$1
    local desc=$2
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}File not found: $file${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Starting $desc...${NC}"
    docker-compose -f "$file" up -d
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $desc started successfully${NC}"
    else
        echo -e "${RED}✗ Failed to start $desc${NC}"
    fi
}

stop_service() {
    local file=$1
    local desc=$2
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}File not found: $file${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Stopping $desc...${NC}"
    docker-compose -f "$file" down
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $desc stopped successfully${NC}"
    else
        echo -e "${RED}✗ Failed to stop $desc${NC}"
    fi
}

restart_service() {
    local file=$1
    local desc=$2
    
    stop_service "$file" "$desc"
    sleep 2
    start_service "$file" "$desc"
}

show_logs() {
    local file=$1
    local service=$2
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}File not found: $file${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Showing logs for $service in $file...${NC}"
    if [ -n "$service" ]; then
        docker-compose -f "$file" logs -f "$service"
    else
        docker-compose -f "$file" logs -f
    fi
}

# Main menu
case "$1" in
    "status"|"")
        show_status
        ;;
    "start")
        if [ -z "$2" ]; then
            echo "Usage: $0 start <compose-file>"
            echo "Available files:"
            for file_info in "${COMPOSE_FILES[@]}"; do
                IFS=':' read -r file desc <<< "$file_info"
                echo "  $file - $desc"
            done
            exit 1
        fi
        
        # Find description for file
        for file_info in "${COMPOSE_FILES[@]}"; do
            IFS=':' read -r file desc <<< "$file_info"
            if [ "$file" = "$2" ]; then
                start_service "$file" "$desc"
                exit 0
            fi
        done
        echo -e "${RED}Unknown compose file: $2${NC}"
        ;;
    "stop")
        if [ -z "$2" ]; then
            echo "Usage: $0 stop <compose-file>"
            exit 1
        fi
        
        # Find description for file
        for file_info in "${COMPOSE_FILES[@]}"; do
            IFS=':' read -r file desc <<< "$file_info"
            if [ "$file" = "$2" ]; then
                stop_service "$file" "$desc"
                exit 0
            fi
        done
        echo -e "${RED}Unknown compose file: $2${NC}"
        ;;
    "restart")
        if [ -z "$2" ]; then
            echo "Usage: $0 restart <compose-file>"
            exit 1
        fi
        
        # Find description for file
        for file_info in "${COMPOSE_FILES[@]}"; do
            IFS=':' read -r file desc <<< "$file_info"
            if [ "$file" = "$2" ]; then
                restart_service "$file" "$desc"
                exit 0
            fi
        done
        echo -e "${RED}Unknown compose file: $2${NC}"
        ;;
    "logs")
        if [ -z "$2" ]; then
            echo "Usage: $0 logs <compose-file> [service-name]"
            exit 1
        fi
        show_logs "$2" "$3"
        ;;
    "start-all")
        echo -e "${YELLOW}Starting all services...${NC}"
        for file_info in "${COMPOSE_FILES[@]}"; do
            IFS=':' read -r file desc <<< "$file_info"
            if [ -f "$file" ]; then
                start_service "$file" "$desc"
            fi
        done
        ;;
    "stop-all")
        echo -e "${YELLOW}Stopping all services...${NC}"
        for file_info in "${COMPOSE_FILES[@]}"; do
            IFS=':' read -r file desc <<< "$file_info"
            if [ -f "$file" ]; then
                stop_service "$file" "$desc"
            fi
        done
        ;;
    *)
        echo -e "${GREEN}HomeServer Multi-Compose Manager${NC}"
        echo "================================="
        echo "Usage: $0 [command] [options]"
        echo ""
        echo "Commands:"
        echo "  status                    Show status of all services (default)"
        echo "  start <compose-file>      Start services from specific file"
        echo "  stop <compose-file>       Stop services from specific file"
        echo "  restart <compose-file>    Restart services from specific file"
        echo "  logs <compose-file> [svc] Show logs from specific file/service"
        echo "  start-all                 Start all available compose files"
        echo "  stop-all                  Stop all available compose files"
        echo ""
        echo "Available compose files:"
        for file_info in "${COMPOSE_FILES[@]}"; do
            IFS=':' read -r file desc <<< "$file_info"
            echo "  $file - $desc"
        done
        echo ""
        echo "Examples:"
        echo "  $0 status"
        echo "  $0 start soulmask-compose.yaml"
        echo "  $0 logs docker-compose.yaml plex"
        echo "  $0 stop-all"
        ;;
esac
