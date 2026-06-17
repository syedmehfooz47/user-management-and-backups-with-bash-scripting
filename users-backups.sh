#!/bin/bash


set -euo pipefail

log_file=logs/operations.log
backup_dir=backups
mkdir -p logs
mkdir -p backups

log_info(){
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" | tee -a "$log_file"
}

log_warn(){
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] $1" | tee -a "$log_file"
}

log_error(){
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" | tee -a "$log_file"
}

user_exists(){
    id "$1" &>/dev/null
}
group_exists(){
    getent group "$1" &>/dev/null
}

user_create(){
    read -p "Enter username:" username
    if user_exists "$username"; then
        echo "User $username already exists"
        log_warn "user_create: $username exists"
        return
    else
        read -p "Need Directory? (y/n)" need_dir
        if [[ "$need_dir" == "y" ]]; then
            sudo useradd -m "$username"
            log_info "user_create: $username created with home directory"
        else
            sudo useradd "$username"
            log_info "user_create: $username created without home directory"
        fi
    fi
}

user_delete(){
    read -p "Enter username to delete:" username
    if ! user_exists "$username"; then
        echo "User $username not found"
        log_warn "user_delete: $username not found"
        return
    else
        if ! sudo userdel -r "$username"; then
            echo "userdel returned an issue"
            log_warn "user_delete: userdel returned an issue for $username"
        fi
        log_info "user_delete: $username deleted"
    fi
}

add_in_group(){
    read -p "Enter username:" username
    read -p "Enter group name:" group
    if ! user_exists "$username"; then
        echo "User $username not found"
        log_warn "add_in_group: $username not found"
        return
    else
        if ! group_exists "$group"; then
            echo "Group $group not found"
            log_warn "add_in_group: $group not found"
            return
        else
            sudo usermod -aG "$group" "$username"
            log_info "add_in_group: $username added to $group"
        fi
    fi
}

remove_from_group(){
    read -p "Enter username:" username
    read -p "Enter group name:" group
    if ! user_exists "$username"; then
        echo "User $username not found"
        log_warn "remove_from_group: $username not found"
        return
    else
        if ! group_exists "$group"; then
            echo "Group $group not found"
            log_warn "remove_from_group: $group not found"
            return
        else
            sudo gpasswd -d "$username" "$group"
            log_info "remove_from_group: $username removed from $group"
        fi
    fi
}

view_users(){
    echo "List of users:"
    cut -d: -f1 /etc/passwd
    log_info "view_users: listed users"
}

view_groups(){
    echo "List of groups:"
    cut -d: -f1 /etc/group
    log_info "view_groups: listed groups"
}

view_system_info(){
    echo "System Information:"
    echo "Hostname: $(hostname)"
    echo "Uptime: $(uptime -p)"
    echo "Memory Usage: $(free -h | awk '/Mem:/ {print $3 "/" $2}')"
    echo "Disk Usage: $(df -h / | awk 'NR==2 {print $3 "/" $2}')"
    log_info "view_system_info: displayed system info"

}

backup(){
    read -p "Enter the directory to backup: " source_dir
    if [ ! -d "$source_dir" ]; then
        echo "Directory $source_dir not found"
        log_warn "backup: $source_dir not found"
        return
    fi
    # use a filename-safe timestamp (no spaces or colons)
    timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
    backup_file="$backup_dir/backup_$timestamp.tar.gz"
    tar -czf "$backup_file" -C "$(dirname "$source_dir")" "$(basename "$source_dir")"
    log_info "backup: $source_dir backed up to $backup_file"
}

cleanup_backups(){
    echo "Cleaning up old backups..."
    find "$backup_dir" -type f -name "*.tar.gz" -mtime +7 -exec rm {} \;
    log_info "cleanup_backups: old backups cleaned up"
}




while true; do
  echo
  echo "================User Management and Backup Script================"
  echo
  echo "By Mehfooz"
  echo
  echo "Please choose an option:"
  echo "1) Create User"
  echo "2) Delete User"
  echo "3) Add User to Group"
  echo "4) Remove User from Group"
  echo "5) View Users"
  echo "6) View Groups"
  echo "7) View System Information"
  echo "8) Backup Directory"
  echo "9) Cleanup Old Backups"
  echo "10) Exit"
  echo
  read -p "Choose an option [1-10]: " choice
  case "$choice" in
    1) user_create ;;
    2) user_delete ;;
    3) add_in_group ;;
    4) remove_from_group ;;
    5) view_users ;;
    6) view_groups ;;
    7) view_system_info ;;
    8) backup ;;
    9) cleanup_backups ;;
    10) echo "Exiting..."; exit 0 ;;
    *) echo "Invalid option. Please choose a number between 1 and 10." ;;
  esac
done