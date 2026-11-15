#!/bin/bash
# Stops the daemon, gives the fans back to macOS and removes the installed files.
${SUDO:-sudo} sh -c "
launchctl bootout system/com.local.fancurve 2>/dev/null
/usr/local/bin/smc -k F0Md -w 00; /usr/local/bin/smc -k F1Md -w 00; /usr/local/bin/smc -k Ftst -w 00
rm -f /Library/LaunchDaemons/com.local.fancurve.plist /usr/local/bin/fancurve /usr/local/bin/fans-mode /usr/local/bin/fans /usr/local/bin/smc /usr/local/etc/fans-mode /etc/sudoers.d/fancurve
"
