# set the name of the report alongside the path ".\ relative path"
$ReportName = ".\Office365LicenseReport.csv"

# Set the String ID of the license ("SPE_E3" = Microsoft 365 E3)
$StringID = "INTUNE_A_D"

# get all office Users
$UsersDetails = Get-MsolUser -All | Where-Object {($_.Licenses).AccountSkuId -match $StringID}

# set export array
$ExportArray = @()

# loop through each office 365 user with the specified String ID
Foreach ($UserDetail in $UsersDetails) {

    # set the office 365 user's UserPrincipalName
    $UserUpn = $UserDetail.UserPrincipalName.ToString()

    # add values to array
    $ExportArray += [PSCustomObject][Ordered]@{

        # get the office 365 user's display name
        "Display Name"                   = $UserDetail.DisplayName

        # get the office 365 user's userprincipalname
        "UserPrincipalName"              = $UserUpn

        # get the office 365 user's first Name
        "First Name"                     = $UserDetail.FirstName

        # get the office 365 user's last Name
        "Last Name"                      = $UserDetail.LastName

        # get the office 365 user's creation date
        "When Created"                   = $UserDetail.WhenCreated

        # get the office 365 user's mobile number
        "Mobile Number"                  = $UserDetail.MobilePhone

        # get the office 365 user's department
        "Department"                     = $UserDetail.Department

        # get the office 365 user's city
        "City"                           = $UserDetail.City

        # get the office 365 user's usage location
        "Usage Location"                 = $UserDetail.UsageLocation

        # get the office 365 user's mfa status
        "MFA Status"                     = $UserDetail.StrongAuthenticationRequirements.state

        # get the office 365 user's last password change timestamp
        "Last Password Change Timestamp" = $UserDetail.LastPasswordChangeTimestamp

        # get the office 365 user's block sign-in status
        "Block Sign-In Status"           = $UserDetail.BlockCredential

    }
}

# echo the exported array
Write-Output $ExportArray

# export to csv file
$ExportArray | Export-Csv -Path $ReportName -Delimiter "," -NoTypeInformation