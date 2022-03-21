﻿New-LocalUser -Name "test01" -Password ( ConvertTo-SecureString -AsPlainText -Force 'test') -PasswordNeverExpires -fullname Test1 -Description Helpdesk -AccountNeverExpires -UserMayNotChangePassword| Add-LocalGroupMember -Group administrators
New-LocalUser -Name "test02" -Password ( ConvertTo-SecureString -AsPlainText -Force 'test') -PasswordNeverExpires -fullname Test2 -Description Test -AccountNeverExpires -UserMayNotChangePassword| Add-LocalGroupMember -Group users
#Written by Chris Ng