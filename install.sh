#!/bin/bash
# Builds the smc tool, installs the daemon and the fans command, and starts the daemon.
# Needs the Xcode Command Line Tools. Run it as your user; it asks for sudo.
set -e
cd "$(dirname "$0")"
SMC_COMMIT=master
tmp=$(mktemp -d)
for f in smc.c smc.h; do
    curl -sfL -o "$tmp/$f" "https://raw.githubusercontent.com/hholtmann/smcFanControl/$SMC_COMMIT/smc-command/$f"
done
cc -O2 -DCMD_TOOL_BUILD -w -o "$tmp/smc" "$tmp/smc.c" -framework IOKit -framework CoreFoundation
me=$(id -un)
${SUDO:-sudo} sh -c "
set -e
mkdir -p /usr/local/bin /usr/local/etc
install -o root -g wheel -m 755 '$tmp/smc' /usr/local/bin/smc
install -o root -g wheel -m 755 fancurve.sh /usr/local/bin/fancurve
install -o root -g wheel -m 755 fans-mode /usr/local/bin/fans-mode
install -o root -g wheel -m 755 fans /usr/local/bin/fans
install -o root -g wheel -m 644 com.local.fancurve.plist /Library/LaunchDaemons/com.local.fancurve.plist
[ -e /usr/local/etc/fans-mode ] || echo curve > /usr/local/etc/fans-mode
printf '%s ALL=(root) NOPASSWD: /usr/local/bin/fans-mode\n' '$me' > /etc/sudoers.d/fancurve
chmod 440 /etc/sudoers.d/fancurve
visudo -cf /etc/sudoers.d/fancurve
launchctl bootout system/com.local.fancurve 2>/dev/null || true
launchctl bootstrap system /Library/LaunchDaemons/com.local.fancurve.plist
"
rm -rf "$tmp"
echo "installed; try: fans status"
