#!/bin/bash

# A script to find and kick unauthorized users connected to your account.
# Usage: sudo kick_competitor [TTY]

CALLER_USER="$SUDO_USER"

# Determine the TTY of the user who ran the sudo command
# If SUDO_USER is set, we can usually find their TTY, but `tty` run under sudo often returns the same TTY.
CURRENT_TTY=$(tty | sed 's|/dev/||')

if [ -z "$1" ]; then
    echo "Active sessions connected to your server ($CALLER_USER):"
    echo "--------------------------------------------------------"
    printf "%-10s %-20s %-20s %s\n" "TTY" "IP ADDRESS" "LOGIN TIME" "STATUS"
    
    # List sessions for the current user and format correctly
    who | grep "^$CALLER_USER " | while read -r u t m d tm ip_raw; do
        # Format the time
        login_time="$m $d $tm"
        # Extract IP from parenthesis
        ip=$(echo "$ip_raw" | tr -d '()')
        
        status=""
        if [ "$t" == "$CURRENT_TTY" ]; then
            status="<-- YOU ARE HERE"
        fi
        
        printf "%-10s %-20s %-20s %s\n" "$t" "$ip" "$login_time" "$status"
    done
    
    echo "--------------------------------------------------------"
    echo "To kick a specific session, run: sudo kick_competitor <TTY>"
    echo "Example: sudo kick_competitor pts/1"
    exit 0
fi

TARGET_TTY="$1"

if [ "$CURRENT_TTY" == "$TARGET_TTY" ]; then
    echo "Error: You cannot kill your own active session ($CURRENT_TTY)."
    exit 1
fi

# Verify the TTY belongs to the caller user
TTY_USER=$(who | grep " $TARGET_TTY " | awk '{print $1}')

if [ "$TTY_USER" != "$CALLER_USER" ]; then
    if [ -z "$TTY_USER" ]; then
        echo "Error: Session '$TARGET_TTY' not found."
    else
        echo "Error: You can only kill sessions connected to your own user ($CALLER_USER)."
        echo "You cannot interfere with other teams' servers."
    fi
    exit 1
fi

echo "Terminating session on $TARGET_TTY..."

# Kill all processes attached to that specific TTY
pkill -9 -t "$TARGET_TTY" 2>/dev/null

echo "Session on $TARGET_TTY has been successfully terminated."