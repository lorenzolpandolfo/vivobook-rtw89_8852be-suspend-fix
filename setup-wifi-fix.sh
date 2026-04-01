#!/bin/bash

sudo tee /usr/lib/systemd/system-sleep/fix-wifi.sh > /dev/null << 'EOF'
#!/bin/bash

case $1 in
  pre)
    modprobe -r rtw89_8852be
    ;;
  post)
    modprobe rtw89_8852be
    ;;
esac
EOF

sudo chmod +x /usr/lib/systemd/system-sleep/fix-wifi.sh
echo "fix-wifi.sh created successfully! You may suspend the system to test it."
