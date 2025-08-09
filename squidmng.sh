#!/bin/bash

# Squid HTTP Proxy Manager v1.0
# Professional script for managing HTTP proxy server on Ubuntu

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Configuration variables
SQUID_CONFIG="/etc/squid/squid.conf"
SQUID_PASSWD="/etc/squid/passwd"
CONFIG_DIR="squidConfigs"
SQUID_SERVICE="squid"
SELECTED_IP=""
SELECTED_PORT=""

# Create config directory if not exists
if [[ ! -d "$CONFIG_DIR" ]]; then
    mkdir -p "$CONFIG_DIR" 2>/dev/null || {
        echo -e "${RED}Failed to create config directory: $CONFIG_DIR${NC}"
        echo -e "${RED}Please check if you have the necessary permissions to create directories.${NC}"
        exit 1
    }
fi

# Function to print colored output
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to print fancy header
print_header() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}${BOLD}                        SQUID HTTP PROXY MANAGER v1.0                       ${NC}${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Function to print section header
print_section_header() {
    local title=$1
    local title_length=${#title}
    local padding=$((77 - title_length))
    
    echo -e "${BLUE}┌──────────────────────────────────────────────────────────────────────────────┐${NC}"
    printf  "${BLUE}│${WHITE}${BOLD} %s${NC}${BLUE}%*s│${NC}\n" "$title" $padding ""
    echo -e "${BLUE}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo
}

# Function to print info box
print_info_box() {
    local message=$1
    local color=${2:-$CYAN}
    local msg_length=${#message}
    local padding=$((77 - msg_length))
    
    echo -e "${color}┌─ INFO ───────────────────────────────────────────────────────────────────────┐${NC}"
    printf  "${color}│ %s%*s│${NC}\n" "$message" $padding ""
    echo -e "${color}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo
}

# Function to print success message
print_success() {
    local message=$1
    echo -e "${GREEN}✓${NC} ${GREEN}$message${NC}"
}

# Function to print error message
print_error() {
    local message=$1
    echo -e "${RED}✗${NC} ${RED}$message${NC}"
}

# Function to print warning message
print_warning() {
    local message=$1
    echo -e "${YELLOW}⚠${NC} ${YELLOW}$message${NC}"
}

# Function to read multiline input with paste support
read_multiline_input() {
    local prompt=$1
    local items=()
    local line_count=0
    
    print_color $YELLOW "$prompt"
    echo -e "${GRAY}Enter data (Enter 1 user per line, press Enter twice to finish):${NC}"
    
    local empty_count=0
    local seen_lines=()
    
    while true; do
        read -r line
        
        if [[ -z "$line" ]]; then
            ((empty_count++))
            if [[ $empty_count -ge 2 ]]; then
                break
            fi
        else
            empty_count=0
            if [[ -n "$line" ]]; then
                # Trim whitespace
                line=$(echo "$line" | xargs)
                
                # Check for duplicates
                local is_duplicate=false
                for seen_line in "${seen_lines[@]}"; do
                    if [[ "$seen_line" == "$line" ]]; then
                        is_duplicate=true
                        break
                    fi
                done
                
                if [[ "$is_duplicate" == false ]]; then
                    items+=("$line")
                    seen_lines+=("$line")
                    ((line_count++))
                    # Print feedback to stderr so it doesn't get captured in return value
                    echo -e "  ✓ [$line_count] $line" >&2
                else
                    echo -e "  ⚠ Duplicate skipped: $line" >&2
                fi
            fi
        fi
    done
    
    # Return only the pure data - output to stdout
    for item in "${items[@]}"; do
        echo "$item"
    done
}

# Function to get network interfaces with IPs
get_network_interfaces() {
    print_section_header "Network Interface Selection"

    
    local interfaces=()
    local ips=()
    local counter=1
    
    # Header with fixed width
    echo -e "${CYAN}┌─ Available Network Interfaces ───────────────────────────────────────────────┐${NC}"
    printf "${CYAN}│${NC} ${WHITE}No.${NC} ${WHITE}Interface Name       ${WHITE}IP Address${NC}%*s${CYAN}│${NC}\n" 42 ""

    # Loop through network interfaces and IPs
    while IFS= read -r line; do
        interface=$(echo "$line" | awk '{print $1}')
        ip=$(echo "$line" | awk '{print $2}')
        if [[ "$interface" != "lo" && "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            interfaces+=("$interface")
            ips+=("$ip")

            # Format interface name and IP with fixed width
            local interface_padded=$(printf "%-20s" "$interface")
            local content_length=$((3 + 2 + 20 + 1 + ${#ip}))  # " XX. interface_name IP"
            local padding=$((78 - content_length))
            
            printf "${CYAN}│${NC} %2d. %s ${GREEN}%s${NC}%*s${CYAN}│${NC}\n" \
                $counter "$interface_padded" "$ip" $padding ""
            ((counter++))
        fi
    done < <(ip -4 addr show | grep -oP '^\d+: \K\w+|inet \K[^/]+' | paste - -)
    # Footer with fixed width
    echo -e "${CYAN}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo
    
    if [[ ${#interfaces[@]} -eq 0 ]]; then
        print_error "No network interfaces found!"
        return 1
    fi
    
    while true; do
        read -p "$(echo -e "${YELLOW}❯${NC} Select interface number: ")" choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#interfaces[@]} ]]; then
            SELECTED_IP="${ips[$((choice-1))]}"
            print_success "Selected: ${interfaces[$((choice-1))]} - $SELECTED_IP"
            break
        else
            print_error "Invalid selection. Please try again."
        fi
    done
    return 0
}

# Function to display system information with Squid status
show_system_info() {
    # Collect system information
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}' | cut -d. -f1)
    memory_info=$(free -h | grep '^Mem:')
    memory_used=$(echo $memory_info | awk '{print $3}')
    memory_total=$(echo $memory_info | awk '{print $2}')
    disk_usage=$(df -h / | awk 'NR==2 {print $5}')
    uptime_info=$(uptime -p | sed 's/up //')
    
    # Add variables to collect Squid information
    squid_status="Unknown"
    auto_start_status="Unknown"
    listen_address="Unknown"
    listen_port="Unknown"
    active_connections="0"

    # Check Squid service status
    if systemctl is-active --quiet squid 2>/dev/null; then
        squid_status="Running"
    elif systemctl is-failed --quiet squid 2>/dev/null; then
        squid_status="Failed"
    else
        squid_status="Stopped"
    fi

    # Check auto-start status
    if systemctl is-enabled --quiet squid 2>/dev/null; then
        auto_start_status="Enabled"
    else
        auto_start_status="Disabled"
    fi

    # Get listen address and port from config file or netstat
    if [ -f /etc/squid/squid.conf ]; then
        http_port_line=$(grep -E "^[[:space:]]*http_port" /etc/squid/squid.conf | head -1)
        if [ -n "$http_port_line" ]; then
            # Extract IP address and port
            listen_port=$(echo "$http_port_line" | awk '{print $2}' | cut -d: -f2)
            if [[ "$http_port_line" =~ [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+ ]]; then
                listen_address=$(echo "$http_port_line" | awk '{print $2}' | cut -d: -f1)
            else
                listen_address="0.0.0.0"
                listen_port=$(echo "$http_port_line" | awk '{print $2}')
            fi
        else
            listen_address="Not configured"
            listen_port="Not configured"
        fi
    else
        # Fallback: check from netstat
        listen_port=$(netstat -tlnp 2>/dev/null | grep squid | head -1 | awk '{print $4}' | cut -d: -f2)
        if [ -z "$listen_port" ]; then
            listen_address="Not found"
            listen_port="Not found"
        else
            listen_address="0.0.0.0"
        fi
    fi

    # Count active connections
    active_connections="0"
    
    # Get current port from config if SELECTED_PORT is not set
    if [[ -z "$SELECTED_PORT" ]]; then
        if [ -f "$SQUID_CONFIG" ]; then
            SELECTED_PORT=$(grep -E "^[[:space:]]*http_port" "$SQUID_CONFIG" | head -1 | awk '{print $2}' | grep -oE '[0-9]+$')
        fi
    fi
    
    if [[ -n "$SELECTED_PORT" ]]; then
        if command -v ss >/dev/null 2>&1; then
            conn_count=$(ss -tn 2>/dev/null | grep ":$SELECTED_PORT" | wc -l)
            active_connections="$conn_count"
        elif command -v netstat >/dev/null 2>&1; then
            conn_count=$(netstat -tn 2>/dev/null | grep ":$SELECTED_PORT" | wc -l)
            active_connections="$conn_count"
        fi
    fi

    # Function to print formatted line with exact width control
    print_info_line() {
        local label="$1"
        local value="$2"
        local color="$3"
        
        # Calculate exact content length
        local label_len=${#label}
        local value_len=${#value}
        local content_len=$((label_len + value_len + 3)) # ": " adds 2, space adds 1
        
        # Total box width is 79 characters (including borders)
        # Content area is 78 characters
        local padding=$((78 - content_len))
        
        # Ensure padding is not negative
        if [ $padding -lt 0 ]; then
            padding=0
        fi
        
        printf "${CYAN}│${NC} %s: ${color}%s${NC}%*s${CYAN}│${NC}\n" "$label" "$value" $padding ""
    }

    # Header
    echo -e "${CYAN}┌─ System Information ─────────────────────────────────────────────────────────┐${NC}"

    # System Information
    print_info_line "CPU Usage" "${cpu_usage}%" "${GREEN}"
    
    # Memory formatting
    memory_display="${memory_used} / ${memory_total}"
    if [[ ${#memory_display} -gt 25 ]]; then
        memory_display="${memory_used}/${memory_total}"
    fi
    print_info_line "Memory" "$memory_display" "${GREEN}"
    
    print_info_line "Disk Usage" "$disk_usage" "${GREEN}"
    print_info_line "Uptime" "$uptime_info" "${GREEN}"

    # Separator
    echo -e "${CYAN}├──────────────────────────────────────────────────────────────────────────────┤${NC}"

    # Squid Information
    squid_color="${GREEN}"
    if [ "$squid_status" != "Running" ]; then
        squid_color="${RED}"
    fi
    print_info_line "Squid Status" "$squid_status" "$squid_color"

    autostart_color="${GREEN}"
    if [ "$auto_start_status" != "Enabled" ]; then
        autostart_color="${YELLOW}"
    fi
    print_info_line "Auto-start Status" "$auto_start_status" "$autostart_color"

    print_info_line "Listen Address" "$listen_address"    "${GREEN}"
    print_info_line "Listen Port" "$listen_port"    "${YELLOW}"
    print_info_line "Active Connections" "$active_connections" "${GREEN}"

    # Footer
    echo -e "${CYAN}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
}

# Function to check service status
check_service_status() {
    print_header
    print_section_header "Service Status & System Monitoring"
       
    # Call the function
    show_system_info
    echo
    
    # Recent logs - Fixed width with rounded corners
    echo -e "${CYAN}┌─ Recent Service Logs ────────────────────────────────────────────────────────┐${NC}"
    
    # Log header
    local log_header="Last 5 logs from the last hour:"
    local log_header_length=$((${#log_header} + 1))
    local log_header_padding=$((78 - log_header_length))
    printf "${CYAN}│${NC} ${GRAY}%s${NC}%*s${CYAN}│${NC}\n" "$log_header" $log_header_padding ""
    
    # Display logs
    if systemctl is-active --quiet $SQUID_SERVICE 2>/dev/null; then
        if journalctl -u $SQUID_SERVICE --no-pager -n 5 --since "1 hour ago" 2>/dev/null | grep -q "."; then
            journalctl -u $SQUID_SERVICE --no-pager -n 5 --since "1 hour ago" 2>/dev/null | while read -r line; do
                # Truncate long log lines to fit in box
                if [[ ${#line} -gt 73 ]]; then
                    line="${line:0:70}..."
                fi
                local line_length=$((${#line} + 1))
                local line_padding=$((78 - line_length))
                printf "${CYAN}│${NC} ${GRAY}%s${NC}%*s${CYAN}│${NC}\n" "$line" $line_padding ""
            done
        else
            local no_logs="No recent logs found"
            local no_logs_length=$((${#no_logs} + 1))
            local no_logs_padding=$((78 - no_logs_length))
            printf "${CYAN}│${NC} ${GRAY}%s${NC}%*s${CYAN}│${NC}\n" "$no_logs" $no_logs_padding ""
        fi
    else
        local log_warning="Squid service is not running. No logs available."
        local log_warning_length=$((${#log_warning} + 1))
        local log_warning_padding=$((78 - log_warning_length))
        printf "${CYAN}│${NC} ${YELLOW}%s${NC}%*s${CYAN}│${NC}\n" "$log_warning" $log_warning_padding ""
    fi
    
    echo -e "${CYAN}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo

    # Control options with box formatting
    echo -e "${YELLOW}┌─ Control Options ────────────────────────────────────────────────────────────┐${NC}"

    local control_items=(
        "1. Restart Service"
        "2. Stop Service"           
        "3. Change Port"
        "4. Test Internet Bandwidth (beta)"
        "5. Full Service Logs"
        "6. Back to Main Menu"
    )

    for item in "${control_items[@]}"; do
        local item_length=$((${#item} + 1))  # +1 for leading space
        local item_padding=$((78 - item_length))
        printf "${YELLOW}│${NC} ${CYAN}%s${NC}%*s${YELLOW}│${NC}\n" "$item" $item_padding ""
    done

    echo -e "${YELLOW}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo
    
    while true; do
        read -p "$(echo -e "${YELLOW}❯${NC} Select option [1-6]: ")" choice
        
        case $choice in
            1)
                print_color $YELLOW "Restarting Squid service..."
                if systemctl restart $SQUID_SERVICE; then
                    print_success "Service restarted successfully!"
                else
                    print_error "Failed to restart service!"
                fi
                sleep 2
                check_service_status
                return
                ;;
            2)
                print_color $YELLOW "Stopping Squid service..."
                if systemctl stop $SQUID_SERVICE; then
                    print_success "Service stopped successfully!"
                else
                    print_error "Failed to stop service!"
                fi
                sleep 2
                check_service_status
                return
                ;;  
            3)
                change_port
                check_service_status
                return
                ;;
            4)
                test_bandwidth
                check_service_status
                return
                ;;
            5)
                print_section_header "Full Service Logs"
                journalctl -u $SQUID_SERVICE --no-pager -n 50
                echo
                read -p "Press Enter to continue..."
                check_service_status
                return
                ;;
            6)
                break
                ;;
            *)
                print_error "Invalid option!"
                ;;
        esac
    done
}

# Function to change port
change_port() {
    print_header
    print_section_header "Change Squid Port"
    
    # Check if Squid is installed
    if [ ! -f "$SQUID_CONFIG" ]; then
        print_error "Squid is not installed or configured!"
        print_warning "Please install Squid first."
        echo
        read -p "Press Enter to continue..."
        return
    fi
    
    # Get current port
    local current_port=""
    if [ -f "$SQUID_CONFIG" ]; then
        current_port=$(grep -E "^[[:space:]]*http_port" "$SQUID_CONFIG" | head -1 | awk '{print $2}' | grep -oE '[0-9]+$')
    fi
    
    if [ -z "$current_port" ]; then
        current_port="Not configured"
    fi
    
    echo -e "${CYAN}┌─ Current Configuration ──────────────────────────────────────────────────────┐${NC}"
    printf "${CYAN}${NC} Current Port: ${YELLOW}%s${NC}%*s${CYAN}${NC}\n" "$current_port" 60 ""
    echo -e "${CYAN}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo
    
    # Get new port
    while true; do
        read -p "$(echo -e "${YELLOW}❯${NC} Enter new port (1-65535): ")" new_port
        
        if [[ "$new_port" =~ ^[0-9]+$ ]] && [[ $new_port -ge 1 ]] && [[ $new_port -le 65535 ]]; then
            # Check if port is already in use
            if netstat -tuln 2>/dev/null | grep -q ":$new_port "; then
                print_error "Port $new_port is already in use!"
                read -p "$(echo -e "${YELLOW}❯${NC} Do you want to continue anyway? (Y/N): ")" continue_anyway
                if [[ ! "$continue_anyway" =~ ^[Yy]$ ]]; then
                    continue
                fi
            fi
            break
        else
            print_error "Invalid port number. Please enter a number between 1-65535."
        fi
    done
    
    echo
    print_warning "This will restart the Squid service."
    read -p "$(echo -e "${YELLOW}❯${NC} Continue? (Y/N): ")" confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_warning "Operation cancelled."
        read -p "Press Enter to continue..."
        return
    fi
    
    echo
    print_color $YELLOW "Changing port to $new_port..."
    
    # Backup current config
    cp "$SQUID_CONFIG" "${SQUID_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Get current IP address from config
    local current_ip=""
    if [ -f "$SQUID_CONFIG" ]; then
        http_port_line=$(grep -E "^[[:space:]]*http_port" "$SQUID_CONFIG" | head -1)
        if [[ "$http_port_line" =~ [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+ ]]; then
            current_ip=$(echo "$http_port_line" | awk '{print $2}' | cut -d: -f1)
        else
            current_ip="0.0.0.0"
        fi
    fi
    
    if [ -z "$current_ip" ]; then
        current_ip="0.0.0.0"
    fi
    
    # Update config file
    if [[ "$current_ip" == "0.0.0.0" ]]; then
        sed -i "s/^[[:space:]]*http_port.*/http_port $new_port/" "$SQUID_CONFIG"
    else
        sed -i "s/^[[:space:]]*http_port.*/http_port $current_ip:$new_port/" "$SQUID_CONFIG"
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Configuration updated successfully!"
        
        # Restart service
        print_color $YELLOW "Restarting Squid service..."
        if systemctl restart $SQUID_SERVICE; then
            sleep 2
            if systemctl is-active --quiet $SQUID_SERVICE; then
                print_success "Service restarted successfully!"
                print_success "New port: $new_port"
            else
                print_error "Service failed to start with new port!"
                print_warning "Restoring previous configuration..."
                cp "${SQUID_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)" "$SQUID_CONFIG"
                systemctl restart $SQUID_SERVICE
            fi
        else
            print_error "Failed to restart service!"
            print_warning "Restoring previous configuration..."
            cp "${SQUID_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)" "$SQUID_CONFIG"
        fi
    else
        print_error "Failed to update configuration!"
    fi
    
    echo
    read -p "Press Enter to continue..."
}

# Function to test bandwidth
test_bandwidth() {
    clear
    print_header
    print_section_header "Internet Bandwidth Test"
    
    # Multiple test servers for better accuracy
    local test_servers=(
        "http://speedtest.ftp.otenet.gr/files/test1Mb.db"
        "http://speedtest.ftp.otenet.gr/files/test10Mb.db"
        "http://ipv4.download.thinkbroadband.com/10MB.zip"
        "http://speedtest.tele2.net/1MB.zip"
        "http://speedtest-sgp1.digitalocean.com/10mb.test"
        "http://speedtest-nyc1.digitalocean.com/10mb.test"
        "http://speedtest-sfo1.digitalocean.com/10mb.test"
    )
    
    # Function to format speed
    format_speed() {
        local speed=$1
        if (( $(echo "$speed >= 1000" | bc -l 2>/dev/null || echo "0") )); then
            echo "$(echo "scale=2; $speed / 1000" | bc -l 2>/dev/null || echo "0") Gbps"
        else
            echo "$(echo "scale=2; $speed" | bc -l 2>/dev/null || echo "0") Mbps"
        fi
    }
    
    # Function to test single server
    test_single_server() {
        local server_url=$1
        local server_name=$(echo "$server_url" | sed 's|.*//||' | sed 's|/.*||')
        
        print_color $CYAN "Testing with: $server_name"
        
        # Test download speed
        local speed_result=$(curl -s -w "%{speed_download}" -o /dev/null --connect-timeout 10 --max-time 30 "$server_url" 2>/dev/null)
        
        if [[ "$speed_result" =~ ^[0-9]+\.?[0-9]*$ ]] && (( $(echo "$speed_result > 0" | bc -l 2>/dev/null || echo "0") )); then
            local speed_mbps=$(echo "scale=2; $speed_result / 1024 / 1024 * 8" | bc -l 2>/dev/null || echo "0")
            print_success "Speed: $(format_speed $speed_mbps)"
            echo "$speed_mbps"
        else
            print_error "Failed to test with $server_name"
            echo "0"
        fi
    }
    
    # Test direct connection
    print_color $YELLOW "Testing direct internet connection..."
    print_color $YELLOW "This may take a while... Please wait..."
    echo
    
    local speeds=()
    local valid_tests=0
    
    for server in "${test_servers[@]}"; do
        local speed=$(test_single_server "$server")
        if (( $(echo "$speed > 0" | bc -l 2>/dev/null || echo "0") )); then
            speeds+=("$speed")
            ((valid_tests++))
        fi
        echo
    done
    
    if [[ $valid_tests -eq 0 ]]; then
        print_error "All speed tests failed!"
        print_warning "Please check your internet connection."
        echo
        read -p "Press Enter to continue..."
        return
    fi
    
    # Calculate average speed
    local total_speed=0
    for speed in "${speeds[@]}"; do
        total_speed=$(echo "$total_speed + $speed" | bc -l 2>/dev/null || echo "0")
    done
    local avg_speed=$(echo "scale=2; $total_speed / $valid_tests" | bc -l 2>/dev/null || echo "0")
    
    # Display results
    echo -e "${CYAN}┌─ Direct Connection Test Results ─────────────────────────────────────────────┐${NC}"
    printf "${CYAN}${NC} Valid Tests:     ${GREEN}%d${NC}%*s${CYAN}${NC}\n" $valid_tests 60 ""
    printf "${CYAN}${NC} Average Speed:   ${GREEN}%s${NC}%*s${CYAN}${NC}\n" "$(format_speed $avg_speed)" 60 ""
    echo -e "${CYAN}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
    
    # Ask if user wants to test proxies
    echo
    read -p "$(echo -e "${YELLOW}❯${NC} Do you want to test proxy speeds? (Y/N): ")" test_proxies
    
    if [[ "$test_proxies" =~ ^[Yy]$ ]]; then
        test_proxy_speeds "$avg_speed"
    fi
    
    echo
    read -p "Press Enter to continue..."
}

# Function to test proxy speeds
test_proxy_speeds() {
    local direct_speed=$1
    
    print_section_header "Proxy Speed Test"
    
    # Show format example
    echo -e "${YELLOW}Format: ${WHITE}IP:PORT:USERNAME:PASSWORD${NC}"
    echo -e "${GRAY}Example:${NC}"
    echo -e "  ${CYAN}100.150.200.250:3128:user1:pass123${NC}"
    echo -e "${GRAY}Enter one proxy per line, Press Enter twice to finish.${NC}"
    echo
    
    # Read proxy list using multiline input
    local proxies_input
    exec 3>&1 4>&2
    proxies_input=$(read_multiline_input "Enter proxy list:" 2>&4)
    exec 3>&- 4>&-
    
    if [[ -z "$proxies_input" ]]; then
        print_error "No proxies provided!"
        return
    fi
    
    # Parse proxies
    local proxies=()
    while IFS= read -r proxy_line; do
        if [[ -n "$proxy_line" ]]; then
            proxy_line=$(echo "$proxy_line" | xargs)
            local colon_count=$(echo "$proxy_line" | tr -cd ':' | wc -c)
            if [[ $colon_count -eq 3 ]]; then
                IFS=':' read -r ip port user pass <<< "$proxy_line"
                if [[ -n "$ip" && -n "$port" && -n "$user" && -n "$pass" ]]; then
                    if [[ "$port" =~ ^[0-9]+$ ]] && [[ $port -ge 1 ]] && [[ $port -le 65535 ]]; then
                        # Check for duplicates
                        local is_duplicate=false
                        for existing_proxy in "${proxies[@]}"; do
                            if [[ "$existing_proxy" == "$proxy_line" ]]; then
                                is_duplicate=true
                                break
                            fi
                        done
                        
                        if [[ "$is_duplicate" == false ]]; then
                            proxies+=("$proxy_line")
                        fi
                    fi
                fi
            fi
        fi
    done <<< "$proxies_input"
    
    if [[ ${#proxies[@]} -eq 0 ]]; then
        print_error "No valid proxies provided!"
        return
    fi
    
    echo
    print_color $CYAN "Testing ${#proxies[@]} proxies..."
    echo
    
    # Test servers for proxy testing (smaller files for faster testing)
    local proxy_test_servers=(
        "http://speedtest.ftp.otenet.gr/files/test1Mb.db"
        "http://ipv4.download.thinkbroadband.com/1MB.zip"
    )
    
    # Function to format speed
    format_speed() {
        local speed=$1
        if (( $(echo "$speed >= 1000" | bc -l 2>/dev/null || echo "0") )); then
            echo "$(echo "scale=2; $speed / 1000" | bc -l 2>/dev/null || echo "0") Gbps"
        else
            echo "$(echo "scale=2; $speed" | bc -l 2>/dev/null || echo "0") Mbps"
        fi
    }
    
    # Function to test single proxy
    test_single_proxy() {
        local proxy=$1
        local proxy_num=$2
        local total_proxies=$3
        
        IFS=':' read -r ip port user pass <<< "$proxy"
        local curl_proxy="http://$user:$pass@$ip:$port"
        local display_proxy="${ip}:${port}@${user}"
        
        if [[ ${#display_proxy} -gt 25 ]]; then
            display_proxy="${display_proxy:0:22}..."
        fi
        
        local progress_indicator=$(printf "[%2d/%2d]" $proxy_num $total_proxies)
        
        # Test proxy connectivity first
        if ! timeout 10 curl -s --proxy "$curl_proxy" --connect-timeout 5 -I http://httpbin.org/ip >/dev/null 2>&1; then
            printf "${CYAN}${NC} %s %-25s ${RED}✗ CONNECTION FAILED${NC}%*s${CYAN}${NC}\n" \
                "$progress_indicator" "$display_proxy" 30 ""
            return
        fi
        
        # Test speed with multiple servers
        local total_speed=0
        local valid_tests=0
        
        for server in "${proxy_test_servers[@]}"; do
            local speed_result=$(timeout 15 curl -s -w "%{speed_download}" -o /dev/null --proxy "$curl_proxy" --connect-timeout 8 --max-time 20 "$server" 2>/dev/null)
            
            if [[ "$speed_result" =~ ^[0-9]+\.?[0-9]*$ ]] && (( $(echo "$speed_result > 0" | bc -l 2>/dev/null || echo "0") )); then
                local speed_mbps=$(echo "scale=2; $speed_result / 1024 / 1024 * 8" | bc -l 2>/dev/null || echo "0")
                total_speed=$(echo "$total_speed + $speed_mbps" | bc -l 2>/dev/null || echo "0")
                ((valid_tests++))
            fi
        done
        
        if [[ $valid_tests -gt 0 ]]; then
            local avg_speed=$(echo "scale=2; $total_speed / $valid_tests" | bc -l 2>/dev/null || echo "0")
            local speed_percentage=$(echo "scale=1; $avg_speed * 100 / $direct_speed" | bc -l 2>/dev/null || echo "0")
            
            # Color code based on performance
            local speed_color=$GREEN
            if (( $(echo "$speed_percentage < 50" | bc -l 2>/dev/null || echo "0") )); then
                speed_color=$RED
            elif (( $(echo "$speed_percentage < 80" | bc -l 2>/dev/null || echo "0") )); then
                speed_color=$YELLOW
            fi
            
            printf "${CYAN}${NC} %s %-25s ${speed_color}%s${NC} (${speed_color}%.1f%%${NC})%*s${CYAN}${NC}\n" \
                "$progress_indicator" "$display_proxy" "$(format_speed $avg_speed)" "$speed_percentage" 15 ""
        else
            printf "${CYAN}${NC} %s %-25s ${RED}✗ SPEED TEST FAILED${NC}%*s${CYAN}${NC}\n" \
                "$progress_indicator" "$display_proxy" 20 ""
        fi
    }
    
    # Display results header
    echo -e "${CYAN}┌─ Proxy Speed Test Results ───────────────────────────────────────────────────┐${NC}"
    printf "${CYAN}${NC} Direct Speed: ${GREEN}%s${NC}%*s${CYAN}${NC}\n" "$(format_speed $direct_speed)" 60 ""
    echo -e "${CYAN}├──────────────────────────────────────────────────────────────────────────────┤${NC}"
    
    # Test each proxy
    for i in "${!proxies[@]}"; do
        test_single_proxy "${proxies[i]}" $((i+1)) ${#proxies[@]}
    done
    
    echo -e "${CYAN}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
    
    # Legend
    echo
    echo -e "${GRAY}Explanation:${NC}"
    echo -e "  ${GREEN}Green${NC}: 80-100% of direct speed"
    echo -e "  ${YELLOW}Yellow${NC}: 50-79% of direct speed"
    echo -e "  ${RED}Red${NC}: Below 50% of direct speed"
}

# Function to install Squid
install_squid() {
    print_header
    print_section_header "Install Squid HTTP Proxy Server"    
    
    # Check if already installed
    if systemctl is-active --quiet $SQUID_SERVICE 2>/dev/null; then
        print_warning "Squid is already installed and running."
        echo -e "${YELLOW}You can reinstall it, but this will stop the current service.${NC}"
        read -p "$(echo -e "${YELLOW}❯${NC} Do you want to reinstall? (Y/N): ")" reinstall
        if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
            return
        fi
        systemctl stop $SQUID_SERVICE 2>/dev/null
        print_color $YELLOW "Stopping existing Squid service..."
    fi
    
    # Get network interface
    if ! get_network_interfaces; then
        read -p "Press Enter to continue..."
        return
    fi
    
    # Get port
    echo
    while true; do
        read -p "$(echo -e "${YELLOW}❯${NC} Enter HTTP proxy port (default: 3128): ")" port
        port=${port:-3128}
        if [[ "$port" =~ ^[0-9]+$ ]] && [[ $port -ge 1 ]] && [[ $port -le 65535 ]]; then
            if ! netstat -tuln 2>/dev/null | grep -q ":$port "; then
                SELECTED_PORT="$port"
                break
            else
                print_error "Port $port is already in use. Please choose another port."
                
            fi
        else
            print_error "Invalid port number. Please enter a number between 1-65535."
        fi
    done
    
    echo
    print_info_box "Installing Squid HTTP Proxy Server. Please wait..."
    
    # Update package list
    echo -e "${GRAY}Updating package list...${NC}"
    apt update -qq
    
    # Install Squid and apache2-utils (for htpasswd)
    echo -e "${GRAY}Installing squid and apache2-utils...${NC}"
    if ! apt install -y squid apache2-utils >/dev/null 2>&1; then
        print_error "Failed to install Squid!"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Create Squid configuration
    echo -e "${GRAY}Creating configuration...${NC}"
    
    # Backup original config
    cp "$SQUID_CONFIG" "${SQUID_CONFIG}.original" 2>/dev/null
    
    cat > "$SQUID_CONFIG" << EOF
# Squid HTTP Proxy Configuration

# Port configuration
http_port $SELECTED_IP:$SELECTED_PORT

# Access control lists
acl localnet src 10.0.0.0/8
acl localnet src 172.16.0.0/12
acl localnet src 192.168.0.0/16
acl localnet src fc00::/7
acl localnet src fe80::/10

# SSL ports
acl SSL_ports port 443
acl Safe_ports port 80
acl Safe_ports port 21
acl Safe_ports port 443
acl Safe_ports port 70
acl Safe_ports port 210
acl Safe_ports port 1025-65535
acl Safe_ports port 280
acl Safe_ports port 488
acl Safe_ports port 591
acl Safe_ports port 777
acl CONNECT method CONNECT

# Authentication
auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
auth_param basic children 5
auth_param basic realm Squid Proxy Server
auth_param basic credentialsttl 2 hours
acl authenticated proxy_auth REQUIRED

# Access rules
http_access deny !Safe_ports
http_access deny CONNECT !SSL_ports
http_access allow localhost manager
http_access deny manager
http_access allow authenticated
http_access allow localnet
http_access allow localhost
http_access deny all

# Logging
access_log /var/log/squid/access.log squid
cache_log /var/log/squid/cache.log

# Cache configuration
cache_dir ufs /var/spool/squid 100 16 256

# DNS configuration
dns_nameservers 8.8.8.8 1.1.1.1

# Performance tuning
maximum_object_size 1024 MB
maximum_object_size_in_memory 512 KB

# Forwarded headers
forwarded_for delete
via off

# Error page customization
error_directory /usr/share/squid/errors/English

# Refresh patterns
refresh_pattern ^ftp:		1440	20%	10080
refresh_pattern ^gopher:	1440	0%	1440
refresh_pattern -i (/cgi-bin/|\?) 0	0%	0
refresh_pattern .		0	20%	4320

# Memory cache size
cache_mem 256 MB

# Coredump directory
coredump_dir /var/spool/squid
EOF
    
    # Create password file
    touch "$SQUID_PASSWD"
    chown proxy:proxy "$SQUID_PASSWD"
    chmod 640 "$SQUID_PASSWD"
    
    # Initialize cache directories
    echo -e "${GRAY}Initializing cache directories...${NC}"
    squid -z >/dev/null 2>&1
    
    # Enable and start service
    echo -e "${GRAY}Starting service...${NC}"
    systemctl enable $SQUID_SERVICE >/dev/null 2>&1
    systemctl restart $SQUID_SERVICE
    
    # Check status
    sleep 3
    echo
    if systemctl is-active --quiet $SQUID_SERVICE; then
        print_success "Squid installed and started successfully!"
        print_success "Listening on: $SELECTED_IP:$SELECTED_PORT"
        print_success "Service status: Active"
        print_warning "Note: No users created yet. Please add users to start using the proxy."
    else
        print_error "Failed to start Squid service!"
        print_warning "Checking logs..."
        journalctl -u $SQUID_SERVICE --no-pager -n 10
    fi
    
    echo
    read -p "Press Enter to continue..."
}

# Function to show users
show_users() {
    print_header
    print_section_header "HTTP Proxy Users"

    local users=()
    if [[ -f "$SQUID_PASSWD" ]]; then
        while IFS=':' read -r username encrypted_password; do
            if [[ -n "$username" ]]; then
                users+=("$username")
            fi
        done < "$SQUID_PASSWD"
    fi

    if [[ ${#users[@]} -eq 0 ]]; then
        # Empty state with proper box formatting
        echo -e "${CYAN}┌─ Users List (0 users) ───────────────────────────────────────────────────────┐${NC}"
        local warning_msg="No HTTP proxy users found."
        local warning_length=$((${#warning_msg} + 1))
        local warning_padding=$((78 - warning_length))
        printf "${CYAN}│${NC} ${YELLOW}%s${NC}%*s${CYAN}│${NC}\n" "$warning_msg" $warning_padding ""
        echo -e "${CYAN}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
    else
        # Header with user count
        local header_title="Users List (${#users[@]} users)"
        local header_length=${#header_title}
        local header_padding=$((77 - header_length))

        printf "${CYAN}┌ %s" "$header_title"
        for ((i=0; i<$header_padding; i++)); do printf "─"; done
        printf "┐${NC}\n"

        # Display users with proper formatting
        for i in "${!users[@]}"; do
            local user_number=$(printf "%3d." $((i+1)))
            local user_display="$user_number ${users[i]}"
            local user_length=$((${#user_display} + 1))  # +1 for leading space
            local user_padding=$((78 - user_length))

            printf "${CYAN}│${NC} %s%*s${CYAN}│${NC}\n" "$user_display" $user_padding ""
        done

        echo -e "${CYAN}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
    fi

    echo
    read -p "Press Enter to continue..."
}

# Function to create config file for user
create_user_config() {
    local username=$1
    local password=$2
    
    # Ensure config directory exists
    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir -p "$CONFIG_DIR"
        if [[ $? -ne 0 ]]; then
            print_error "Failed to create config directory: $CONFIG_DIR"
            return 1
        fi
    fi
    
    if [[ -z "$SELECTED_IP" || -z "$SELECTED_PORT" ]]; then
        # Try to get from existing config
        if [[ -f "$SQUID_CONFIG" ]]; then
            http_port_line=$(grep -E "^[[:space:]]*http_port" "$SQUID_CONFIG" | head -1)
            if [ -n "$http_port_line" ]; then
                if [[ "$http_port_line" =~ [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+ ]]; then
                    SELECTED_IP=$(echo "$http_port_line" | awk '{print $2}' | cut -d: -f1)
                    SELECTED_PORT=$(echo "$http_port_line" | awk '{print $2}' | cut -d: -f2)
                else
                    SELECTED_IP="0.0.0.0"
                    SELECTED_PORT=$(echo "$http_port_line" | awk '{print $2}')
                fi
            fi
        fi
    fi
    
    if [[ -z "$SELECTED_IP" || -z "$SELECTED_PORT" ]]; then
        print_error "Server IP and port not configured. Please install Squid first."
        return 1
    fi
    
    # Create config content for HTTP proxy clients
    cat > "$CONFIG_DIR/$username.txt" << EOF
# HTTP Proxy Configuration for $username
# Use these settings in your HTTP proxy client

Proxy Type: HTTP
Server: $SELECTED_IP
Port: $SELECTED_PORT
Username: $username
Password: $password

# Example curl command:
curl --proxy http://$username:$password@$SELECTED_IP:$SELECTED_PORT http://httpbin.org/ip

# Browser proxy settings:
# HTTP Proxy: $SELECTED_IP:$SELECTED_PORT
# Username: $username
# Password: $password
EOF
    
    if [[ $? -eq 0 ]]; then
        return 0
    else
        print_error "Failed to create config file for user: $username"
        return 1
    fi
}

# Function to add multiple users
add_multi_users() {
    print_header
    print_section_header "Add Multiple Users"

    # Check if Squid is installed
    if [ ! -f "$SQUID_CONFIG" ]; then
        print_error "Squid is not installed or configured!"
        print_warning "Please install Squid first."
        echo
        read -p "Press Enter to continue..."
        return
    fi

    echo -e "${GRAY}Enter data (Enter 1 user per line, press Enter twice to finish):${NC}"
    # Read usernames using multiline input
    local usernames_input
    usernames_input=$(read_multiline_input "Enter usernames (one per line):")
    if [[ -z "$usernames_input" ]]; then
        print_error "No usernames provided!"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Parse usernames - SILENT VALIDATION (NO ERROR MESSAGES)
    local usernames=()
    local line_num=0
    while IFS= read -r username; do
        ((line_num++))
        # Skip empty lines
        [[ -z "$username" ]] && continue
        
        # Trim whitespace
        username=$(echo "$username" | xargs)
        
        if [[ -n "$username" ]]; then
            if [[ "$username" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                # Check if user already exists in passwd file
                if [[ -f "$SQUID_PASSWD" ]] && grep -q "^$username:" "$SQUID_PASSWD"; then
                    print_error "User '$username' already exists! Skipping..."
                else
                    usernames+=("$username")
                fi
            fi
        fi
    done <<< "$usernames_input"
    
    if [[ ${#usernames[@]} -eq 0 ]]; then
        print_error "No valid usernames provided!"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo
    print_info_box "Creating ${#usernames[@]} users..."
    echo
    
    # Create users and set passwords
    local created_users=()
    for username in "${usernames[@]}"; do
        echo -e "${CYAN}Setting up user: ${WHITE}$username${NC}"
        
        while true; do
            read -s -p "$(echo -e "${YELLOW}❯${NC} Set password for '$username': ")" password
            echo
            if [[ ${#password} -ge 4 ]]; then
                read -s -p "$(echo -e "${YELLOW}❯${NC} Confirm password for '$username': ")" password2
                echo
                if [[ "$password" == "$password2" ]]; then
                    # Add user to htpasswd file
                    if htpasswd -b "$SQUID_PASSWD" "$username" "$password" >/dev/null 2>&1; then
                        if create_user_config "$username" "$password"; then
                            created_users+=("$username")
                            print_success "User '$username' created successfully!"
                        else
                            print_warning "User '$username' created but config file failed!"
                            created_users+=("$username")
                        fi
                    else
                        print_error "Failed to create user '$username'!"
                    fi
                    break
                else
                    print_error "Passwords don't match for '$username'!"
                fi
            else
                print_error "Password for '$username' must be at least 4 characters long!"
            fi
        done
        echo
    done
    
    # Reload Squid to apply changes
    if [[ ${#created_users[@]} -gt 0 ]]; then
        print_color $YELLOW "Reloading Squid configuration..."
        systemctl reload $SQUID_SERVICE >/dev/null 2>&1
    fi
    
    echo
    print_success "Successfully created ${#created_users[@]} users!"
    print_success "Config files created in: $CONFIG_DIR/"
    
    echo
    read -p "Press Enter to continue..."
}

# Function to delete users
delete_users() {
    print_header
    print_section_header "Delete Users"
    
    local users=()
    if [[ -f "$SQUID_PASSWD" ]]; then
        while IFS=':' read -r username encrypted_password; do
            if [[ -n "$username" ]]; then
                users+=("$username")
            fi
        done < "$SQUID_PASSWD"
    fi
    
    if [[ ${#users[@]} -eq 0 ]]; then
        print_warning "No HTTP proxy users found to delete."
        read -p "Press Enter to continue..."
        return
    fi

    echo
    echo -e "${CYAN}┌─ Available Users to Delete ──────────────────────────────────────────────────┐${NC}"
    for i in "${!users[@]}"; do
        local user_number=$(printf "%3d." $((i+1)))
        local user_display="$user_number ${users[i]}"
        local user_length=$((${#user_display} + 1))  # +1 for leading space
        local user_padding=$((78 - user_length))
        
        printf "${CYAN}│${NC} %s%*s${CYAN}│${NC}\n" "$user_display" $user_padding ""
    done
    echo -e "${CYAN}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo
        
    print_info_box "Enter user numbers to delete (space-separated, e.g., '1 3 5'):"
    read -p "$(echo -e "${YELLOW}❯${NC} Selection: ")" selections
    
    if [[ -z "$selections" ]]; then
        print_warning "No selection made."
        read -p "Press Enter to continue..."
        return
    fi
    
    local to_delete=()
    for selection in $selections; do
        if [[ "$selection" =~ ^[0-9]+$ ]] && [[ $selection -ge 1 ]] && [[ $selection -le ${#users[@]} ]]; then
            to_delete+=("${users[$((selection-1))]}")
        else
            print_error "Invalid selection: $selection"
        fi
    done
    
    if [[ ${#to_delete[@]} -eq 0 ]]; then
        print_error "No valid users selected!"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo
    print_warning "Users to be deleted:"
    for user in "${to_delete[@]}"; do
        echo -e "  ${RED}•${NC} $user"
    done
    
    echo
    read -p "$(echo -e "${RED}❯${NC} Are you sure you want to delete these users? (Y/N): ")" confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_warning "Operation cancelled."
        read -p "Press Enter to continue..."
        return
    fi
    
    echo
    print_color $YELLOW "Deleting users..."
    
    # Delete users
    local deleted_count=0
    for user in "${to_delete[@]}"; do
        if htpasswd -D "$SQUID_PASSWD" "$user" >/dev/null 2>&1; then
            # Remove config file
            rm -f "$CONFIG_DIR/$user.txt"
            print_success "Deleted user: $user"
            ((deleted_count++))
        else
            print_error "Failed to delete user: $user"
        fi
    done
    
    # Reload Squid to apply changes
    if [[ $deleted_count -gt 0 ]]; then
        print_color $YELLOW "Reloading Squid configuration..."
        systemctl reload $SQUID_SERVICE >/dev/null 2>&1
    fi
    
    echo
    print_success "Successfully deleted $deleted_count users!"
    
    echo
    read -p "Press Enter to continue..."
}

# Function to test proxies
test_proxies() {
    clear
    print_header
    print_section_header "Test HTTP Proxies"
    
    # Show format example clearly
    echo -e "${YELLOW}Format: ${WHITE}IP:PORT:USERNAME:PASSWORD${NC}"
    echo -e "${GRAY}Example:${NC}"
    echo -e "  ${CYAN}100.150.200.250:3128:user1:pass123${NC}"
    echo -e "  ${CYAN}192.168.1.100:8080:alice:secret456${NC}"
    echo -e "${GRAY}Enter one proxy per line, Press Enter twice to finish.${NC}"
    echo
    
    # Read proxy list using multiline input
    local proxies_input
    # Redirect stderr to display feedback, capture only stdout (pure data)
    exec 3>&1 4>&2
    proxies_input=$(read_multiline_input "Enter proxy list:" 2>&4)
    exec 3>&- 4>&-
    
    if [[ -z "$proxies_input" ]]; then
        print_error "No proxies provided!"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo
    
    # Parse proxies with silent validation (no error messages)
    local proxies=()
    local line_num=0
    local valid_count=0
    local invalid_count=0
    
    # Process each line from input
    while IFS= read -r proxy_line; do
        ((line_num++))
        
        # Skip empty lines
        if [[ -z "$proxy_line" ]]; then
            continue
        fi
        
        # Trim whitespace
        proxy_line=$(echo "$proxy_line" | xargs)
        
        # Skip if still empty after trim
        if [[ -z "$proxy_line" ]]; then
            continue
        fi
        
        # Simple validation: count colons and check basic format
        local colon_count=$(echo "$proxy_line" | tr -cd ':' | wc -c)
        
        if [[ $colon_count -eq 3 ]]; then
            # Split and validate components
            IFS=':' read -r ip port user pass <<< "$proxy_line"
            
            # Check if all components exist and port is numeric
            if [[ -n "$ip" && -n "$port" && -n "$user" && -n "$pass" ]]; then
                if [[ "$port" =~ ^[0-9]+$ ]] && [[ $port -ge 1 ]] && [[ $port -le 65535 ]]; then
                    # Check for duplicates in proxies array
                    local is_duplicate=false
                    for existing_proxy in "${proxies[@]}"; do
                        if [[ "$existing_proxy" == "$proxy_line" ]]; then
                            is_duplicate=true
                            break
                        fi
                    done
                    
                    if [[ "$is_duplicate" == false ]]; then
                        proxies+=("$proxy_line")
                        ((valid_count++))
                        print_color $GREEN "  ✓ Valid: $proxy_line"
                    fi
                else
                    ((invalid_count++))
                fi
            else
                ((invalid_count++))
            fi
        else
            ((invalid_count++))
        fi
        
    done <<< "$proxies_input"
    
    # Show summary instead of detailed errors
    if [[ $invalid_count -gt 0 ]]; then
        print_warning "Skipped $invalid_count invalid proxy entries"
    fi
    
    if [[ ${#proxies[@]} -eq 0 ]]; then
        print_error "No valid proxies provided!"
        if [[ $invalid_count -gt 0 ]]; then
            echo -e "${GRAY}Check proxy format: IP:PORT:USERNAME:PASSWORD${NC}"
        fi
        read -p "Press Enter to continue..."
        return
    fi
    
    echo
    print_color $CYAN "Testing ${#proxies[@]} proxies..."
    print_color $CYAN "Please wait..."   
    echo
    
    local success_count=0
    local total_count=${#proxies[@]}
    
    # Proxy test results with proper box formatting
    echo -e "${CYAN}┌─ Proxy Test Results ─────────────────────────────────────────────────────────┐${NC}"

    for i in "${!proxies[@]}"; do
        local proxy="${proxies[i]}"
        
        # Parse proxy components
        IFS=':' read -r ip port user pass <<< "$proxy"
        
        local curl_proxy="http://$user:$pass@$ip:$port"
        
        # Test with timeout
        local display_proxy="${ip}:${port}@${user}"
        if [[ ${#display_proxy} -gt 30 ]]; then
            display_proxy="${display_proxy:0:27}..."
        fi
        
        # Create progress indicator
        local progress_indicator=$(printf "[%2d/%2d]" $((i+1)) $total_count)
        
        # Test proxy first
        if timeout 10 curl -s --proxy "$curl_proxy" --connect-timeout 5 -I http://httpbin.org/ip >/dev/null 2>&1; then
            local result_text="${GREEN}✓ SUCCESS${NC}"
            ((success_count++))
        else
            local result_text="${RED}✗ FAILED${NC}"
        fi
        
        # Calculate padding based on actual text length (không tính mã màu)
        local progress_len=${#progress_indicator}
        local proxy_len=${#display_proxy}
        # Độ dài thực tế của result_text không tính mã màu
        local result_len=8  # "✓ SUCCESS" hoặc "✗ FAILED" đều 8 ký tự
        
        # Total content: " " + progress + " " + proxy + " " + result + " "
        local total_content_len=$((1 + progress_len + 1 + proxy_len + 1 + result_len + 1))
        local padding=$((78 - total_content_len))
        
        # Print the formatted line
        printf "${CYAN}${NC} %s %-30s %b%*s${CYAN}${NC}\n" \
            "$progress_indicator" "$display_proxy" "$result_text" $padding ""
        
    done

    echo -e "${CYAN}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
    
    local success_rate=0
    if [[ $total_count -gt 0 ]]; then
        success_rate=$((success_count * 100 / total_count))
    fi
    
    echo
    echo -e "${CYAN}┌─ Test Summary ───────────────────────────────────────────────────────────────┐${NC}"

    # Total Proxies
    local total_text="Total Proxies: $total_count"
    local total_length=$((${#total_text} + 1))
    local total_padding=$((78 - total_length))
    printf "${CYAN}${NC} Total Proxies:   ${WHITE}%s${NC}%*s${CYAN}${NC}\n" "$total_count" $total_padding ""

    # Successful
    local success_text="Successful: $success_count"
    local success_length=$((${#success_text} + 1))
    local success_padding=$((78 - success_length))
    printf "${CYAN}${NC} Successful:      ${GREEN}%s${NC}%*s${CYAN}${NC}\n" "$success_count" $success_padding ""

    # Failed
    local failed_count=$((total_count - success_count))
    local failed_text="Failed: $failed_count"
    local failed_length=$((${#failed_text} + 1))
    local failed_padding=$((78 - failed_length))
    printf "${CYAN}${NC} Failed:          ${RED}%s${NC}%*s${CYAN}${NC}\n" "$failed_count" $failed_padding ""

    # Success Rate
    local rate_text="Success Rate: ${success_rate}%"
    local rate_length=$((${#rate_text} + 1))
    local rate_padding=$((78 - rate_length))
    printf "${CYAN}${NC} Success Rate:    ${YELLOW}%s%%${NC}%*s${CYAN}${NC}\n" "$success_rate" $rate_padding ""

    echo -e "${CYAN}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
    
    echo
    read -p "Press Enter to continue..."
}

# Function to uninstall Squid
uninstall_squid() {
    print_header
    print_section_header "Uninstall Squid"
    
    echo -e "${RED}┌─ WARNING ────────────────────────────────────────────────────────────────────┐${NC}"

    # First warning line
    local warning1="This will completely remove Squid and all configurations!"
    local warning1_length=$((${#warning1} + 1))
    local warning1_padding=$((78 - warning1_length))
    printf "${RED}│${NC} %s%*s${RED}│${NC}\n" "$warning1" $warning1_padding ""

    # Second warning line
    local warning2="All proxy users and config files will be affected."
    local warning2_length=$((${#warning2} + 1))
    local warning2_padding=$((78 - warning2_length))
    printf "${RED}│${NC} %s%*s${RED}│${NC}\n" "$warning2" $warning2_padding ""

    echo -e "${RED}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
    
    echo
    read -p "$(echo -e "${RED}❯${NC} Are you sure you want to uninstall Squid? (Y/N): ")" confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_warning "Operation cancelled."
        read -p "Press Enter to continue..."
        return
    fi
    
    echo
    print_color $YELLOW "Uninstalling Squid..."
    
    # Stop and disable service
    echo -e "${GRAY}Stopping service...${NC}"
    systemctl stop $SQUID_SERVICE 2>/dev/null
    systemctl disable $SQUID_SERVICE 2>/dev/null
    
    # Remove package
    echo -e "${GRAY}Removing package...${NC}"
    apt remove --purge -y squid >/dev/null 2>&1
    
    # Remove configuration files
    echo -e "${GRAY}Removing configuration files...${NC}"
    rm -f "$SQUID_CONFIG"
    rm -f "$SQUID_PASSWD"
    rm -rf /var/log/squid
    rm -rf /var/spool/squid
    
    # Ask about user configs
    if [[ -d "$CONFIG_DIR" ]] && [[ $(ls -A "$CONFIG_DIR" 2>/dev/null) ]]; then
        echo
        read -p "$(echo -e "${YELLOW}❯${NC} Do you want to remove all user config files in '$CONFIG_DIR'? (Y/N): ")" remove_configs
        if [[ "$remove_configs" =~ ^[Yy]$ ]]; then
            rm -rf "$CONFIG_DIR"
            print_success "User config files removed"
        fi
    fi
    
    echo
    print_success "Squid has been completely uninstalled!"
    
    echo
    read -p "Press Enter to continue..."
}

# Main menu function
show_main_menu() {
    print_header
    print_section_header "Main Menu"
    
    # Menu box with rounded corners
    echo -e "${YELLOW}┌─ Menu Options ───────────────────────────────────────────────────────────────┐${NC}"
    
    # Menu items with proper padding
    local menu_items=(
        "1. Install Squid HTTP Proxy"
        "2. Show Users"
        "3. Add Users"
        "4. Delete Users"
        "5. Test Proxies"
        "6. Check Status & Monitoring"
        "7. Uninstall Squid"
        "8. Exit"
    )
    
    for item in "${menu_items[@]}"; do
        local item_length=$((${#item} + 1))  # +1 for leading space
        local item_padding=$((78 - item_length))
        printf "${YELLOW}│${NC} ${CYAN}%s${NC}%*s${YELLOW}│${NC}\n" "$item" $item_padding ""
    done
    
    echo -e "${YELLOW}└──────────────────────────────────────────────────────────────────────────────┘${NC}"
    echo
}

# Main program loop
main() {
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        print_warning "Please run: sudo $0"
        exit 1
    fi
    
    # Check for required commands
    local required_commands=("curl" "netstat" "systemctl" "htpasswd")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            if [[ "$cmd" == "htpasswd" ]]; then
                print_error "Required command '$cmd' not found!"
                print_warning "Please install apache2-utils package: apt install apache2-utils"
            else
                print_error "Required command '$cmd' not found!"
                print_warning "Please install the required packages."
            fi
            exit 1
        fi
    done
    
    while true; do
        show_main_menu
        read -p "$(echo -e "${YELLOW}❯${NC} Select option [1-8]: ")" choice
        
        case $choice in
            1) install_squid ;;
            2) show_users ;;
            3) add_multi_users ;;
            4) delete_users ;;
            5) test_proxies ;;
            6) check_service_status ;;
            7) uninstall_squid ;;
            8) 
                # Clear screen and show thank you message
                clear
                print_header
                print_section_header "Thank you for using Squid HTTP Proxy Manager!"
                echo
                exit 0
                ;;
            *) 
                print_error "Invalid option! Please select 1-8."
                sleep 1
                ;;
        esac
    done
}

# Run main function
main "$@"