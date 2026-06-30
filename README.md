## HOW TO UNENROLL CHROMEBOOK ON KERNVER 7

> [!NOTE]
> WHAT YOU WILL NEED: A USB with at least 8 GB of Storage, MrChromebox script, SuzyQable to Disable Write Protection, and an unenrolled Chromebook

> [!WARNING]
> I AM NOT RESPONSIBLE FOR ANY TROUBLE YOU GET IN USING THIS REPOSITORY




### Step 1: Clean Enrollment Files
```bash
# Stop management services
stop metricsd 2>/dev/null
stop update-engine 2>/dev/null

# Remove enrollment files
rm -rf /mnt/stateful_partition/unencrypted/preserve/enterprise/
rm -rf /mnt/stateful_partition/unencrypted/preserve/attestation/
rm -f /mnt/stateful_partition/unencrypted/cache/vpd/flush.log

# Clear device ID
rm -f /mnt/stateful_partition/unencrypted/preserve/device_id
```

***

### Step 2: Run Spooflock Script
```bash
# Create the file
cat > /tmp/spooflock.sh << 'EOF'
#!/bin/bash

# Generate fake identifiers
NEW_SERIAL=\$(cat /dev/urandom | tr -dc 'A-Z0-9' | fold -w 10 | head -n 1)
NEW_MAC=(printf '02:%02x:%02x:%02x:%02x:%02x'((RANDOM%256)) ((RANDOM%256))((RANDOM%256)) ((RANDOM%256))((RANDOM%256)))

echo "Setting fake serial: \$NEW_SERIAL"

# Modify machine ID
echo "\(NEW_SERIAL-\)(date +%s)" | md5sum | cut -d' ' -f1 > /etc/machine-id
cp /etc/machine-id /var/lib/dbus/machine-id

# Change hostname
hostnamectl set-hostname "chromebook-\$NEW_SERIAL"

# Block Google management servers
cat >> /etc/hosts << 'HOSTS'
127.0.0.1 ://google.com
127.0.0.1 ://google.com
127.0.0.1 ://google.com
127.0.0.1 ://googleapis.com
127.0.0.1 ://googleapis.com
HOSTS

echo "Done. Reboot to apply."
EOF

# Make it executable and run
chmod +x /tmp/spooflock.sh
sudo bash /tmp/spooflock.sh
```

***

### Step 3: Flash Firmware
```bash
# Download MrChromebox's script
cd /tmp
curl -LO https://mrchromebox.tech
sudo bash firmware-util.sh
```

***

### Step 4: Final Reboot
```bash
reboot
```
