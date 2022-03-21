#!/bin/sh

pkgfile="GoogleChrome.pkg"
logfile="/Library/Logs/GoogleChromeInstallScript.log"
url='https://dl.google.com/chrome/mac/stable/gcem/GoogleChrome.pkg'

/bin/echo "--" >> ${logfile}
/bin/echo "`date`: Downloading latest version." >> ${logfile}
/usr/bin/curl -s -o /tmp/${pkgfile} ${url}
/bin/echo "`date`: Installing..." >> ${logfile}
cd /tmp
/usr/sbin/installer -pkg GoogleChrome.pkg -target /
/bin/sleep 5
/bin/echo "`date`: Deleting package installer." >> ${logfile}
/bin/rm /tmp/"${pkgfile}"

exit 0