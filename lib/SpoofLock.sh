#!/bin/bash
# spooflock.sh - Chromebook Identity Spoofer
# Run as root in Developer Mode

# Backup original values
mkdir -p /mnt/stateful_partition/spoof_backup
date > /mnt/stateful_partition/spoof_backup/backup_timestamp

# Generate random identifiers
NEW_SERIAL=$(cat /dev/urandom | tr -dc 'A-Z0-9' | fold -w 10 | head -n 1)
NEW_UUID=$(cat /proc/sys/kernel/random/uuid)
NEW_MAC=$(printf '02:%02x:%02x:%02x:%02x:%02x' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))

echo "=== Spooflock Identity Changer ==="
echo "New Serial: $NEW_SERIAL"
echo "New UUID: $NEW_UUID"
echo "New MAC: $NEW_MAC"

# Modify VPD (Vital Product Data) - requires write protection disabled
if [ -f /usr/sbin/vpd ]; then
    # Backup VPD
    /usr/sbin/vpd -i RO_VPD -l > /mnt/stateful_partition/spoof_backup/ro_vpd_backup.txt
    /usr/sbin/vpd -i RW_VPD -l > /mnt/stateful_partition/spoof_backup/rw_vpd_backup.txt
    
    # Set new serial (if writable)
    /usr/sbin/vpd -i RW_VPD -s "serial_number=$NEW_SERIAL" 2>/dev/null || echo "Note: VPD may be read-only"
fi

# Spoof MAC address (requires compatible wireless driver)
# This is temporary until reboot
ifconfig wlan0 down 2>/dev/null
ifconfig wlan0 hw ether $NEW_MAC 2>/dev/null
ifconfig wlan0 up 2>/dev/null

# Modify machine-id
echo $NEW_UUID | tr -d '-' > /etc/machine-id
cp /etc/machine-id /var/lib/dbus/machine-id

# Chrome OS specific - modify stateful partition identifiers
if [ -d /mnt/stateful_partition ]; then
    # Generate new device-specific identifiers
    echo "$NEW_SERIAL-$(date +%s)" > /mnt/stateful_partition/spoof_backup/device_identity
    
    # Clear various tracking files
    rm -f /mnt/stateful_partition/unencrypted/cache/vpd/flush.log 2>/dev/null
    rm -rf /mnt/stateful_partition/unencrypted/preserve/attestation 2>/dev/null
fi

# Modify hostname
hostnamectl set-hostname "chromebook-$NEW_SERIAL"

# Block management endpoints (basic)
cat >> /etc/hosts << 'EOF'
127.0.0.1 m.google.com
127.0.0.1 clients3.google.com
127.0.0.1 clients4.google.com
127.0.0.1 dl.google.com
127.0.0.1 update.googleapis.com
127.0.0.1 safebrowsing.googleapis.com
EOF

echo "=== Spoofing Complete ==="
echo "Reboot recommended to apply all changes"
echo "Run 'reboot' to restart"
