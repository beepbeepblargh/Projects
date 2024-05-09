#!/bin/bash

# New Starter script for creating LDAP account and Google account for both employees and contractors
# Updated Dec 2022

# TODO:
# ✅ Improve readability/style
# ✅ Make the location list easier to maintain
# ✅ Unify handling the location-based stuff
# ┝ 🔲 Cleanup the Country mail groups, so no-one would be in both Country and City (which is a member of Country already)
# └ ✅ Make Toronto mail group
# ✅ Integrate adduser.sh
# ┝ 🔲 Move the *.ldif files to the same directory where this script will live
# └ 🔲 Unify style
# ✅ Integrate newcontractors.sh
# ✅ Offer adding to extra mail groups besides the defaults
# ✅ Verify dept & manager
# ✅ Don't ask about BW SF/Zoom/Gong for Falcon commercial users
# ✅ Ask about SMM
# ✅ Set BenefitFocus profile attribute for US starters
# ✅ Set signature by GAM
# ✅❓ Set calendar timezone, weekstart etc. by GAM
# ✅ Set Falcon aliases & Falcon Users OU by GAM, if applicable
# ✅ Send the initial passwords to New Hire Onboarding
# ✅ Invite to 1Password
# ✅ Add default entries to 1Pw vault (like Google, LDAP, O365, Okta)
# 🔲 Create O365 account – see REST API (via curl) or https://learn.microsoft.com/en-us/cli/azure/?view=azure-cli-latest
# └ 🔲 Auto-add pw to 1Pw
#
# BONUS:
# ✅ Add dry-run mode
#

shopt -s expand_aliases
# Define this as alias rather than variable (like before) to make it behave when space is not one of the IFS characters
alias gam='python3.7 /home/sysadmin/gam/gambw/gam.py'
if [[ $1 =~ ^(-n|--dry-run) ]]; then
  readonly DEBUG="-n" # Used drop-in by ldappadd below; also used in if-tests
  alias gam_write='echo gam' # Dry-run GAM for the create/update actions
  alias op_write='echo op' # Dry-run 1Password for the provision/create actions
  alias mail='tee; echo mail' # Dry-run inform other teams - done this way to not lose the piped content
  alias curl='echo curl' # Dry-run Zoom/Gong user creation
else
  alias gam_write='gam'
  alias op_write='op'
fi

# Dept list from https://brandwatch.atlassian.net/wiki/spaces/ITI/pages/3165585753/ADE+-+Enrol+-+Workstation+AdminUser+-+New+Starter#:~:text=Valid%20User%20Departments
# Remove the empty lines when copy-pasting from there
# TODO: curl this from someplace?
department_list=$(cat <<'ENDOFLIST'
Brand: Brand Management
Brand: Creative
Brand: Content
Brand: Customer & Community
Brand: PR & Comms
Brand: Website
CX: Customer Education
CX: Strategy
CX: Customer Support
CX: Agency
CX: Management
CX: Brand Enterprise
CX: Brand Commercial
Engineering: Applications
Engineering: Management
Engineering: Systems / SRE
Marketing & Design
Marketing: Field Marketing
Marketing: Product Marketing
Marketing: Customer Marketing
Marketing: Demand Gen
Marketing: Content Marketing
Marketing: Marketing Operations
Operations: Transformation Office
Operations: Corporate
Operations: Finance
Operations: Incubator
Operations: Business Systems & IT
Operations: Legal
Operations: Executive Management
Operations: Facilities & Procurement
Operations: Employee Success
Operations: Recruitment
Operations: Strategy
PS: Onboarding & PM
PS: Commercial Customer Support
PS: PS Management
PS: Technical Services
PS: Strategy & Insights
Product: Applications
Product: Design
Product: Management
Sales: Demand Gen
Sales: Commercial New Business
Sales: Revenue Operations
Sales: Commercial Account Management
Sales: Enterprise Account Management
Sales: Commercial Lead Gen
Sales: Partners
Sales: Management
Sales: Solutions Consultants
Sales: Enterprise New Business
Sales: Enterprise Lead Gen
Sales: Solution Strategy
ENDOFLIST
)

# Define the locations + some associated data, in as easily editable / human-readable / bulletproof way as possible.
#
# Entries in the "city" and "country" column are expected to also have an identically-named Google group (EMEA is a known/handled exception).
# Remote users are added to the "Country" mail group, others to the "City" group.
# "city" is also used for the location in email signature (if "Remote", falls back to Country).
# Both "country" and "city" are mentioned in the emails to other teams.
# For city-states, "country" can be the same as "city" – it won't get duplicated in the end result.
# "timezone" is for Google Calendar timezone (use "n/a" if a "Remote" location spans several timezones).
# "region" is for Google Schema, to determine which VPN server this user should use ("europe" or "us"). Not really needed anymore.
#
# Columns MUST be separated by at least two spaces, or at least 1 tab.
#
# country   city            timezone             schema_region
location_list=$(cat <<'ENDOFLIST'
Australia   Remote          n/a                  europe
Germany     Berlin          Europe/Berlin        europe
USA         Boston          America/New_York     us
UK          Brighton        Europe/London        europe
Hungary     Budapest        Europe/Budapest      europe
Bulgaria    Remote          Europe/Sofia         europe
Canada      Remote          n/a                  us
India       Chennai         Asia/Kolkata         europe
Denmark     Copenhagen      Europe/Copenhagen    europe
Denmark     Remote          Europe/Copenhagen    europe
France      Remote          Europe/Paris         europe
Germany     Frankfurt       Europe/Berlin        europe
Germany     Remote          Europe/Berlin        europe
Hungary     Remote          Europe/Budapest      europe
India       Remote          Asia/Kolkata         europe
UK          London          Europe/London        europe
Australia   Melbourne       Australia/Melbourne  europe
USA         New York        America/New_York     us
France      Paris           Europe/Paris         europe
USA         San Francisco   America/Los_Angeles  us
Singapore   Singapore       Asia/Singapore       europe
Bulgaria    Sofia           Europe/Sofia         europe
Germany     Stuttgart       Europe/Berlin        europe
Australia   Sydney          Australia/Sydney     europe
Canada      Toronto         America/Toronto      us
UK          Remote          Europe/London        europe
USA         Remote          n/a                  us
EMEA        Remote          n/a                  europe
APAC        Remote          n/a                  europe
ENDOFLIST
)

# Regex for separating the columns
col_sep='[[:blank:]]*(\t+|  +)[[:blank:]]*'

function continue_anyway {
  # Usage:
  # continue_anyway "Optional message to show before the 'Continue anyway?' prompt" && {
  #   do-something
  # } || {
  #   exit 123
  # }
  echo -e "$1\nContinue anyway? (y/N)"
  local carry_on # Keep this variable inside this function
  read carry_on
  carry_on="${carry_on:=no}" # if not chosen, set to default
  if [[ ${carry_on,,} =~ ^y ]]; then
    return 0 # Continue as if successful
  else
    return 1 # Continue as if failed
  fi
}

# Check if script is running on chungus
if [[ "$(hostname)" != "chungus.service0.btn1.bwcom.net" && ! $DEBUG ]]; then
  echo -e "\n\nScript needs to be run from chungus \n\n \$ ssh -A sysadmin@chungus.service0.btn1.bwcom.net '/home/sysadmin/sysadmin/IT/New_Starters/newstarter.sh' \n\n"
  exit 1
else
  echo -e "\nRunning on chungus, continue\n"
fi

# Test access to mg1006 (needed for LDAP account creation)
ssh -q -o "BatchMode=yes" root@mg1006 "echo -e 'mg1006 is reachable, continue\n'" || {
  echo "Connection to mg1006 failed - is your ~/.ssh/config (on your own machine) set up properly, and your SSH key added to the right places?"
  echo "See the 'Prerequisites' section at https://brandwatch.atlassian.net/wiki/spaces/ITI/pages/3183673600"
  continue_anyway || exit 2
}

# Requires v2 of 1Pw CLI
if [[ $(op --version | cut -d '.' -f 1) -ne 2 ]]; then
  echo -e "\n1Password CLI version 2 expected but not found, so 1Pw automation bits won't work.\n"
fi

echo -e "\nDefault responses for the prompts below are shown in uppercase. Empty response means you want the default.\n"

# Make the regex [a-z] not match accented characters
LC_COLLATE=C
# Let's define it early, it's needed in several places later
OIFS=$IFS

# Get the user's information
echo "Are we setting up an account for an employee or a contractor? (E/c)"
read usertype
usertype="${usertype:=employee}" # if not chosen, set to default
echo "Enter the user's Brandwatch username (with or without '@brandwatch.com')"
read theuser
theuser=${theuser%@brandwatch.com} # Strip the domain if it's there
until [[ $theuser && ${#theuser} -le 64 && ${theuser,,} =~ ^[a-z0-9._-]+$ ]]; do
  # NB: [a-z] matches also accented letters unless LC_COLLATE=C
  [[ ! $theuser ]] && echo "The username cannot be left empty!" # Catch accidentally pressing enter twice
  [[ ${#theuser} -gt 64 ]] && echo "The username cannot be longer than 64 characters."
  [[ ${theuser,,} =~ [^a-z0-9._-] ]] && echo "The username contains invalid characters." # Anything outside a-z, 0-9 range plus literally ._-
  echo "Try again"
  read theuser
  theuser=${theuser%@brandwatch.com} # Strip the domain if it's there
done
theuser=${theuser,,} # To all-lowercase
if [[ ! ${theuser,,} =~ ^.+\..+$ ]]; then
  # We might have exceptions to the rule, so let's check for this here, instead of together with the strict requirements above
  continue_anyway "The username doesn't follow the naming standard 'firstname.lastname'." || exit 3
fi
[[ $DEBUG ]] && echo "Username: $theuser"
IFS='.' read -r _fname _sname <<< "$theuser"
if [[ ${#theuser} -gt 20 ]]; then
  continue_anyway "The username '$theuser' is longer than 20 characters (the limit for the Cision GBA Utility)." || exit 3
fi
echo "Enter user's first name (default suggestion: ${_fname^})"
read firstname
firstname="${firstname:=${_fname^}}" # if not chosen, set to default
echo "Enter user's surname (default suggestion: ${_sname^})"
read surname
surname="${surname:=${_sname^}}" # if not chosen, set to default
# Check for accented letters in the name (as LDAP doesn't seem to like those)
if [[ "$firstname" == *[![:ascii:]]* ]]; then
  echo "Edit the plain-ASCII version of first name for LDAP as needed"
  read -e -i "${_fname^}" ascii_firstname
  until [[ $ascii_firstname ]]; do
   echo "This cannot be left empty!"
   read ascii_firstname
  done
else
  ascii_firstname="$firstname"
fi
if [[ "$surname" == *[![:ascii:]]* ]]; then
  echo "Edit the plain-ASCII version of surname for LDAP as needed"
  read -e -i "${_sname^}" ascii_surname
  until [[ $ascii_surname ]]; do
    echo "This cannot be left empty!"
    read ascii_surname
  done
else
  ascii_surname="$surname"
fi
echo "Enter the user's line manager's username (with or without '@brandwatch.com')"
read manager
until [[ $manager ]]; do
  echo "This cannot be left empty!"
  read manager
done
# Check that the manager would exist
echo -n "Verifying manager... " # -n for no newline after this line
until [[ $managerdetails ]]; do
  manager=${manager%@brandwatch.com} # Strip the domain if it's there
  managerdetails=$(gam info user $manager@brandwatch.com 2>/dev/null)
  [[ $managerdetails ]] && break
  echo -e "\rThe chosen manager ($manager) doesn't seem to exist, try again (or press Ctrl-C to give up and exit)." # -r = return carriage and overwrite the line
  read manager
done
echo "OK"
managerfname=$(grep "First Name:" <<< "$managerdetails" | cut -c 13-)
managersname=$(grep "Last Name:" <<< "$managerdetails" | cut -c 12-)
# Let's try to offer the next new starter day (1st and 3rd Tuesday of every month)
IFS=, read dayofmonth month_full month_num year now < <(LC_ALL=C date +%-d,%B,%-m,%Y,%x)
if [[ $dayofmonth -le 10 ]]; then
  # Up until the 10th of a month, suggest current month
  startmonth=$month_full # full name
  startyear=$year
  startday=$(LC_ALL=C ncal -h | awk '/^Tu/ { print $4 }') # Current month; -h to not highlight today (it messes up columns); find Tuesdays and print 3rd of them
  if [[ $month_num -eq 12 && $startday -gt 17 ]]; then
    # Too close to Christmas, probably won't be a new starter day that week
    startmonth=$(date -d "$now 1 month" +%B)
    startyear=$(date -d "$now 1 month" +%Y)
    startday=$(LC_ALL=C ncal -m 1f | awk '/^Tu/ { print $2 }') # '1f' as in 'January, following year'; 1st Tuesday
  fi
else
  # Else suggest next month
  startmonth=$(date -d "$now 1 month" +%B)
  _startmonth=$(date -d "$now 1 month" +%-m) # -m means unpadded month number
  startyear=$(date -d "$now 1 month" +%Y)
  if [[ $month_num -eq 12 ]]; then
    startday=$(LC_ALL=C ncal -m 1f | awk '/^Tu/ { print $2 }') # '1f' as in 'January, following year'; 1st Tuesday
  else
    startday=$(LC_ALL=C ncal -m ${_startmonth} | awk '/^Tu/ { print $2 }') # next month; 1st Tuesday
  fi
fi
case $startday in
  1?) suffix="th" ;; # In order to not get 11st/12nd/13rd
  *1) suffix="st" ;;
  *2) suffix="nd" ;;
  *3) suffix="rd" ;;
  *)  suffix="th" ;;
esac
echo "Enter the new starter's scheduled start date: Month, day year (default suggestion: $startmonth $startday$suffix, $startyear)"
read startdate
startdate="${startdate:=$startmonth $startday$suffix, $startyear}" # if not chosen, set to default
[[ $DEBUG ]] && echo "Start date: $startdate"
echo "What department will this user be in?"
read department
department=${department/ - /: } # Replace (the first instance of) " - " (if present) with ": "
until [[ $(grep -E "^${department}$" <<< "$department_list") ]]; do
  if [[ ! $department ]]; then
    echo "This cannot be left empty!"
  else
    echo "The chosen department ($department) isn't valid, try again (or press Ctrl-C to give up and exit)."
  fi
  read department
done
echo "Department OK"
[[ $DEBUG ]] && echo "Department: $department"
echo "What is the user's location?"
# Reformat the location list above: 0. City, Country / 0. Country Remote
# Turn column separators into single tabs, output columns 2 & 1 (sep. by comma+space), switch "Remote" & country, number the lines (align to 2-digit width)
# Yes, this could all be done by sed, but the expression got quite bewildering. This way it's clearer.
(sed -E "s/$col_sep/\t/g" | awk -F '\t' -v OFS=', ' '{print $2,$1}' | sed -E 's/(Remote), (.+)/\2 \1/' | nl -w 2 -s '. ') <<< "$location_list"
read location
until [[ $(wc --lines <<< "$location_list") -ge $location && $location -ge 1 ]]; do
  if [[ ! $location ]]; then
    echo "This cannot be left empty!"
  else
    echo "Location code not recognised (must be a number between 1 and $(wc --lines <<< "$location_list")), try again (or press Ctrl-C to give up and exit)."
  fi
  read location
done
echo "Which non-default mail groups and delegated mailboxes should this user be added to? (Comma-, space- or newline-separated list of emails or group/mailbox names)"
echo "NB: if a group/mailbox has spaces or commas in the name, then use email here instead (optionally omitting '@brandwatch.com')"
echo "Enter a blank line to finish (i.e. press Enter twice)."
mailgroups=$(sed -E -e 's/(, *|@(brandwatch.com)?,? *)/\n/g' -e '/^$/q') # Replace any "comma/at + space" with newline; stop after emtpy line (to allow multiline paste)
# See https://stackoverflow.com/questions/20913635/how-to-read-multi-line-input-in-a-bash-script
IFS=$'\n'
_mailgroups=() # Empty array
for mailgroup in $mailgroups; do
  mailgroup=$(xargs <<< "$mailgroup") # Trim leading/trailing spaces
  if [[ $mailgroup =~ \  ]]; then
    echo "'$mailgroup' contains spaces - try again with the email instead"
    read mailgroup
    [[ $mailgroup =~ \  ]] && { echo "Still the same - moving on..."; continue; }
  fi
  mailgroup=${mailgroup%@brandwatch.com} # Remove the domain
  _mailgroups+=("$mailgroup") # Add to array
done
mailgroups="${_mailgroups[*]}" # Turn the array into newline-separated list, thanks to the IFS=$'\n'
IFS=$OIFS
[[ $DEBUG ]] && echo -e "Mail groups:\n$mailgroups\n"

if [[ ${usertype,,} =~ ^c ]]; then # Contractor
  usertype="contractor" # To make some if-tests clearer below
  echo "What type of access does this contractor need?"
  echo "1. Mail"
  echo "2. Mail and Drive"
  read accesstype
  until [[ $accesstype -eq 1 || $accesstype -eq 2 ]]; do
    if [[ ! $accesstype ]]; then
      echo "This cannot be left empty!"
    else
      echo "Invalid response ($accesstype), try again"
    fi
    read accesstype
  done
  case $accesstype in
    1) accesstype="mailonly" ;;
    2) accesstype="mailanddrive" ;;
  esac
  echo "Does this contractor need a Zoom account? (y/N)"
  read zoom
  zoom="${zoom:=no}" # if not chosen, set to default
  echo "Does this contractor need Workfront access? (y/N)"
  read workfront
  workfront="${workfront:=no}" # if not chosen, set to default
else # Employee
  usertype="employee" # To make some if-tests clearer below
  echo "$firstname $surname's job title?"
  read jobtitle
  until [[ $jobtitle ]]; do
    echo "This cannot be left empty!"
    read jobtitle
  done
  echo "Will this user be managing someone? (y/N)"
  read directreport
  directreport="${directreport:=no}" # if not chosen, set to default
  echo "Is this new starter part of either the marketing, sales or BDR team? (y/N - BW Salesforce included if 'y')"
  read marketing
  marketing="${marketing:=no}" # if not chosen, set to default
  # TODO: verify what this should be:
  # [[ ${department,,} =~ ^(Brand|Sales): ]] && marketing="yes"
  [[ ${marketing,,} =~ ^y ]] && salesforce="yes" # Marketing implies SF
  # TODO: verify this:
  # [[ ${department,,} =~ ^(Engineering|Product): ]] && engineering="yes"
  [[ ${department,,} =~ ^(Engineering) ]] && engineering="yes"
  echo "Is this new starter a member of Professional Services? (y/N)"
  echo "That is, Technical Analyst/Consultant, Research Analyst/Consultant, Project Mangers, Education/Onboarding/Language Specialists, APAC services"
  read workfront
  workfront="${workfront:=no}" # if not chosen, set to default
  echo "Does this user need the @falcon.io email aliases? (Implies also 'Falcon Users' OU) (y/N)"
  read falcon_alias
  falcon_alias="${falcon_alias:=no}" # if not chosen, set to default
  echo "Does this user need access to the SMM suite? (Access to the ‘Brandwatch Demo Org' environment only.) (y/N)"
  read smm_suite
  smm_suite="${smm_suite:=no}" # if not chosen, set to default
#  echo "Does this user require a Microsoft Office license? (y/N)"
#  read needs_msoffice
#  needs_msoffice="${needs_msoffice:=no}" # if not chosen, set to default
#  echo "Does this user require a Microsoft Intune license? (y/N)"
#  read needs_intune
#  needs_intune="${needs_intune:=no}" # if not chosen, set to default
  echo "Does this user require a Bria account? (y/N)"
  read bria
  bria="${bria:=no}" # if not chosen, set to default
  echo "Which Brighton office VLAN should this user be on? (Leave empty if unsure)"
  read vlan
  vlan="${vlan:=17}" # if not chosen, set to default
fi

echo "If this user needs BCR access, enter the BW analytics client account name as requested by the line manager on the new starter requirements form."
read analyticsclient
analyticsclient="${analyticsclient:=no}" # if not chosen, set to default
if [[ ! $salesforce ]]; then # Ask if not already set above
  echo "Does this new starter need a Salesforce login? (y/N)"
  read salesforce
  salesforce="${salesforce:=no}" # if not chosen, set to default
fi
if [[ ${salesforce,,} =~ ^y ]]; then
  echo "Which Salesforce instance: Falcon (default; implies Okta access), old Brandwatch, or both? (F/bw/both)"
  read sfdc_instance
  sfdc_instance="${sfdc_instance:=Falcon}" # if not chosen, set to default
fi
[[ ${sfdc_instance,,} =~ ^(f|both) ]] && needs_okta="yes" # Falcon Salesforce implies Okta
if [[ ${sfdc_instance,,} == "bw" || ${salesforce,,} =~ ^n ]]; then
  echo "Does this user need Cision Okta access? (y/N)"
  read needs_okta
  needs_okta="${needs_okta:=no}" # if not chosen, set to default
fi
if [[ $usertype == "employee" && ! ${sfdc_instance,,} =~ ^f ]]; then
  # Only for employees, and not for those needing only Falcon Salesforce
  echo "Does this user need a Zoom Pro license? (y/N)"
  echo "WARNING: Please check zoom.us to see if there are any Licensed users available. If there are 0 Licenses available type 'n' for now."
  read zoompro
  zoompro="${zoompro:=no}" # if not chosen, set to default
  echo "Does this user need access to BW Gong? (y/N)"
  read gong
  gong="${gong:=no}" # if not chosen, set to default
fi
if [[ $usertype == "employee" ]]; then
  [[ ${zoompro,,} =~ ^n ]] && zoom="y" # If not Pro then Basic account for employees
  echo "Will the user's computer be prepared by the IT team, or by the user unattended? (I/u)"
  read computer_setup
  computer_setup="${computer_setup:=IT}" # if not chosen, set to default
  if [[ ${computer_setup,,} =~ ^u ]]; then
    computer_password="(not set - unattended setup)"
  else
    # The complexity criteria on macOS won't allow more than 2 consecutive characters (but doesn't seem to check beyond a-z, A-Z & 0-9):
    forbidden_lower="abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz"
    forbidden_upper="ABC|BCD|CDE|DEF|EFG|FGH|GHI|HIJ|IJK|JKL|KLM|LMN|MNO|NOP|OPQ|PQR|QRS|RST|STU|TUV|UVW|VWX|WXY|XYZ"
    forbidden_numbers="012|123|234|345|456|567|678|789"
    forbidden_seq="($forbidden_lower|$forbidden_upper|$forbidden_numbers)"
    # If we have the dictionary file, then suggest a passphrase
    if [[ -s /usr/share/dict/american-english ]]; then
      # /usr/share/dict/words points at this
      dictionary="$(grep -Ev "(.)\1|$forbidden_seq" /usr/share/dict/american-english)" # Filter out double chars and forbidden sequences
      readarray -t namelist < <(grep -P '^[A-Z][a-z]{2,}(?!ed)$' <<< "$dictionary") # Find proper nouns; 3+ chars
      readarray -t verblist < <(grep -E '^[a-z]{3,}ed$' <<< "$dictionary") # Find preterites (well, kind of); 5+ chars
      readarray -t wordlist < <(grep -Ev '([^A-Za-z]|ed$)' <<< "$dictionary") # Filter out accented letters, apostrophes and also preterites
      inspiration=(
        "\nFor inspiration:"
        # Pick at random from the arrays: 3 x Name-verbed-#-word
        "${namelist[$(($RANDOM % ${#namelist[@]}))]}-${verblist[$(($RANDOM % ${#verblist[@]}))]}-$(($RANDOM % 9))-${wordlist[$(($RANDOM % ${#wordlist[@]}))]}"
        "${namelist[$(($RANDOM % ${#namelist[@]}))]}-${verblist[$(($RANDOM % ${#verblist[@]}))]}-$(($RANDOM % 9))-${wordlist[$(($RANDOM % ${#wordlist[@]}))]}"
        "${namelist[$(($RANDOM % ${#namelist[@]}))]}-${verblist[$(($RANDOM % ${#verblist[@]}))]}-$(($RANDOM % 9))-${wordlist[$(($RANDOM % ${#wordlist[@]}))]}"
      )
    fi
    IFS=$'\n' # Can't use temporary IFS before the echo, because array expansion happens before echo is run
    echo -e "Enter the password/passphrase you plan to set for this user's computer account and 1Password vault${inspiration[*]}"
    IFS=$OIFS
    read computer_password
    # Check this against the complexity criteria
    until [[ $pw_length && $pw_digit && $pw_letter && $pw_symbol && $pw_nodouble && $pw_noseq ]]; do
      # At least 10 characters:
      [[ ${#computer_password} -ge 10 ]] && pw_length="true" || { unset pw_length; echo "Too short! (Needs to be at least 10 characters)"; }
      # At least one digit:
      [[ $computer_password =~ [[:digit:]] ]] && pw_digit="true" || { unset pw_digit; echo "Doesn't contain any digits!"; }
      # At least one ASCII letter (NB: [a-z] etc. match also accented letters unless LC_COLLATE=C)
      [[ ${computer_password,,} =~ [a-z] ]] && pw_letter="true" || { unset pw_letter; echo "Doesn't contain any letters!"; }
      # At least one symbol (incl. accented letters):
      [[ ${computer_password,,} =~ [^0-9a-z] ]] && pw_symbol="true" || { unset pw_symbol; echo "Doesn't contain any symbols!"; }
      # No double characters:
      [[ ! $(grep -E '(.)\1' <<< "$computer_password") ]] && pw_nodouble="true" || { unset pw_nodouble; echo "Contains a repeated character!"; }
      # No more than two consecutive characters:
      [[ ! $computer_password =~ $forbidden_seq ]] && pw_noseq="true" || { unset pw_noseq; echo "Contains more than 2 sequencial letters/numbers!"; }
      [[ $pw_length && $pw_digit && $pw_letter && $pw_symbol && $pw_nodouble && $pw_noseq ]] && break
      echo "Try again:"
      read computer_password
    done
    echo "Okay - looks like the password meets the complexity criteria. Well done!"
    vault_password="$computer_password"
  fi
fi
ldap_password=$(pwgen --no-capitalize --ambiguous -1 10)
if [[ ! $ldap_password ]]; then
  echo "Seems that pwgen has gone missing - can't generate passwords."
  until [[ ${#ldap_password} -ge 10 ]]; do
    echo "Enter a 10+ character password to set for LDAP account"
    read ldap_password
  done
  until [[ ${#google_password} -ge 14 ]]; do
    echo "Enter a 14+ character password to set for Google account"
    read google_password
  done
else
  if [[ $usertype == "contractor" || ${computer_setup,,} =~ ^u ]]; then
    # For contractors (who will use their own computer), and employees doing the setup unattended
    google_password=$(pwgen --capitalize --numerals --symbols --ambiguous -1 14) # Actually set as the Google pw
    change_pw="on" # Must be changed at first logon
    random_google_password=$google_password # Used for 1Pw & sent to New Hire Onboarding
    echo -e "\nOkay, user got a random Google password: $google_password"
    echo -e "It'll also be added to their 1Password vault and optionally sent to New Hire Onboarding team.\n"
  else
    google_password="Cherrypie2020!" # Actually set as the Google pw
    change_pw="off" # Doesn't have to be changed at first logon
    random_google_password=$(pwgen --capitalize --numerals --symbols --ambiguous -1 14) # Used for 1Pw & sent to New Hire Onboarding
    echo -e "\nOkay, user got the standard Google password for now: $google_password"
    echo "Once the computer is prepared, remember to reset it to the random password added to the user's 1Password vault."
    echo -e "That random password will optionally also be sent to New Hire Onboarding team.\n"
  fi
fi
echo -e "\nLog in to 1Password with the IT Licenses account password so we can provision the account and add the default entries to the new starter's vault"
[[ $DEBUG ]] || eval $(op signin --account team-brandwatch.1password.com)

echo -e "\n\nAlright, enough with the questions already, let's create some accounts!\n\n"

echo "Creating LDAP account..."

##### Copied and slightly refactored from adduser.sh ######

# GLOBALS
readonly LDAP_SERVER="ldap://mg1006"
readonly LDAP_PW="LTTRhiwA"
readonly LDAP_SECRET="/etc/ldap.secret" # TODO: this is unused
readonly LDAP_BIND_USER="cn=root,dc=base,dc=runtime-collective,dc=com"
readonly SUFFIX="dc=base,dc=runtime-collective,dc=com"
readonly GSUFFIX="ou=Group"
readonly STANDARD_GROUPS=( audio mailaccess employees rcusers runtime users webaccess ovpnusers jira-users )
readonly ENGI_GROUPS=( sshaccess tech )
readonly MAILUSER_GROUPS=( mailaccess jira-users )

#------------------------------------------------
# next_uid will work out the next free uid and gid, and return whichever is greater
# -- this means a user's uid and gid will be the same
function next_uid () {
  # lifted from ldapscripts ldapadduser (which we should probably just use instead?!?)
  let userid=$(( $( ldapsearch -LLL -w ${LDAP_PW} -D "${LDAP_BIND_USER}" -P 3 -H ${LDAP_SERVER} -b "${SUFFIX}" '(&(objectClass=posixAccount)(!(uid=nobody)))' uidNumber | grep "uidNumber: " | sed "s|uidNumber: ||" | uniq | sort -n | tail -n 1 ) +1 ))
  let groupid=$(( $( ldapsearch -LLL -w ${LDAP_PW} -D "${LDAP_BIND_USER}" -P 3 -H ${LDAP_SERVER} -b "${GSUFFIX},${SUFFIX}" '(&(objectClass=posixGroup))' gidNumber | grep "gidNumber: " | sed "s|gidNumber: ||" | uniq | sort -n | tail -n 1) +1 ))
  if [[ $userid -ge $groupid ]]; then
    echo $userid;
  else
    echo $groupid;
  fi
}

#------------------------------------------------
# add_user_ldap adds a user and user's group record to ldap using ldapadd
function add_user_ldap () {
  # Function can take an argument which is a replacement for the default user template ldif
  # Default is currently 'user-template.ldif'
  local user_template_ldif=${1:-"user-template.ldif"} # Fancy way of doing if $1 then use that, else use default value
  local user_ldif=$( mktemp "$theuser.ldif.XXXX" )
  local group_ldif=$( mktemp "$theuser-group.ldif.XXXX" )
  # [[ ! $vlan ]] && vlan="17" # If empty/unset
  # The default is set above now
  cat $user_template_ldif | sed -e "s/USERID/$theuser/; s/DEFAULTID/$nextuid/; s/FIRSTNAME/$ascii_firstname/; s/SURNAME/$ascii_surname/; s/VLAN/$vlan/;" > $user_ldif
  cat group-template.ldif | sed -e "s/GROUPNAME/$theuser/; s/DEFAULTID/$nextuid/;" > $group_ldif
  ldapadd $DEBUG -a -x -D $LDAP_BIND_USER -w $LDAP_PW  -H $LDAP_SERVER -P 3 -f $user_ldif
  ldapadd $DEBUG -a -x -D $LDAP_BIND_USER -w $LDAP_PW  -H $LDAP_SERVER -P 3 -f $group_ldif
  rm $group_ldif
  rm $user_ldif
}

#------------------------------------------------
function add_user_ldap_groups () {
  declare -a grouparray=("${!1}") # Indirect expansion
  local groupadd_ldif=$( mktemp "$theuser-groupadd.ldif.XXXX" )
  for group in "${grouparray[@]}" ; do
    cat groupadd-template.ldif | sed -e "s/GROUPID/$group/; s/USERID/$theuser/;" > $groupadd_ldif
    ldapadd $DEBUG -a -x -D $LDAP_BIND_USER -w $LDAP_PW  -H $LDAP_SERVER -P 3 -f $groupadd_ldif
  done
  rm $groupadd_ldif
}

#------------------------------------------------
function create_standard_user () {
  echo "Creating User: $theuser with UID/GID: $nextuid"
  # add user to ldap
  add_user_ldap
  # add user to standard groups
  add_user_ldap_groups STANDARD_GROUPS[@] # Gets expanded inside the function

  # add user to Engineering groups if needed
  if [[ ${engineering,,} =~ ^y ]]; then
    add_user_ldap_groups ENGI_GROUPS[@] # Gets expanded inside the function
  fi

  # set user password
  if [[ -n $DEBUG ]]; then echo "Not setting password"; return 0; fi
  echo "Setting User's password to: $ldap_password"
  ssh root@mg1006 "(echo $ldap_password; echo $ldap_password) | smbpasswd -as $theuser" || {
    echo "Setting the password failed, check it manually afterwards."
    return 0 # Don't cause the script to exit
  }
}

#------------------------------------------------
function create_mailuser_only () {
  echo "Creating User: $theuser with UID/GID: $nextuid"
  echo "!!NOTE: This user will only have access to email"
  # add user to ldap
  add_user_ldap "external-user-template.ldif"
  # add user to standard groups
  add_user_ldap_groups MAILUSER_GROUPS[@] # Gets expanded inside the function

  # set user password
  if [[ -n $DEBUG ]]; then echo "Not setting password"; return 0; fi
  echo "Setting User's password to: $ldap_password"
  ssh root@mg1006 "(echo $ldap_password; echo $ldap_password) | smbpasswd -as $theuser" || {
    echo "Setting the password failed, check it manually afterwards."
    return 0 # Don't cause the script to exit
  }
}

#------------------------------------------------
# check to see if the username is taken
if getent passwd $theuser >/dev/null; then
  # echo "LDAP user '$theuser' already exists" >&2
  continue_anyway "LDAP user '$theuser' exists already." || exit 10
fi

# check to see if the UID/GID we're about to use is taken
readonly nextuid=$(next_uid)
if getent group $nextuid >/dev/null ; then
  echo "GID $nextuid already in use!" >&2
  exit 11
fi
if getent passwd $nextuid >/dev/null ; then
  echo "UID $nextuid already in use!" >&2
  exit 12
fi

# Setup user
if [[ $accesstype == "mailonly" ]]; then
  create_mailuser_only || {
    continue_anyway "There was an issue with creating the LDAP account for this mail-only user." || exit 13
  }
else
  create_standard_user || {
    continue_anyway "There was an issue with creating the LDAP account for this standard user." || exit 13
  }
fi

###### End of content from adduser.sh #######
echo "Done!"

echo
echo "Creating Google account..."
if [[ $accesstype == "mailanddrive" ]]; then
  OU="Contractors"
  OU_comment=" to give Mail and Drive access"
elif [[ $accesstype == "mailonly" ]]; then
  OU="Mail Only"
  OU_comment=" to give mail access only."
elif [[ ${falcon_alias,,} =~ ^y ]]; then
  # Not contractor, and needs Falcon aliases
  OU="Falcon Users"
else
  OU="Brandwatch Users"
fi
echo "Adding user into '$OU' OU$OU_comment."
gam_write create user $theuser firstname "$firstname" lastname "$surname" password "$google_password" changepassword $change_pw org "/$OU" || {
  echo "Creating the Google account failed."
  exit 5
}
sleep 2
echo "Google account created: $theuser@brandwatch.com."

# Parse the location data
# Number the lines (1 digit width, i.e. no padding; sep. by tab), grep by loc. number, then turn column separators into single tabs, and remove the loc. number
location_data=$( (nl -w 1 -s $'\t' <<< "$location_list") | grep -E "^$location"$'\t' | sed -E -e "s/$col_sep/\t/g" -e "s/^$location\t//")
[[ $DEBUG ]] && echo "Location data: '$location_data'"
# Assign the column data to variables
IFS=$'\t' read -r country city tz region <<< "$location_data"

# Format the locations for use below
if [[ $country == "EMEA" ]]; then
  location="$country $city"
  sig_location="Location"
elif [[ $country == "APAC" ]]; then
  location="$country $city"
  location_mailgroup="$country"
  sig_location="Location"
elif [[ $city == "Remote" ]]; then
  location="$country $city"
  location_mailgroup="$country"
  sig_location="Remote: $country"
else
  if [[ $city == "$country" ]]; then # city-states like Singapore
    location="$city"
  else
    location="$city, $country"
  fi
  location_mailgroup="$city"
  sig_location="$city"
fi

if [[ $DEBUG ]]; then
  echo "Location: $location (country: $country / city: $city)"
  echo "Location for signature: $sig_location"
  echo "Location-specific mail group: $location_mailgroup"
  echo "Timezone: $tz"
fi

if [[ $usertype == "employee" ]]; then
  # Don't do this for contractors

  # Add user to the staff group
  gam_write update group staff add member $theuser@brandwatch.com
  sleep 1

  if [[ ${falcon_alias,,} =~ ^y ]]; then
    gam_write create alias $theuser@falcon.io user $theuser@brandwatch.com
    sleep 1
    gam_write create alias ${theuser}1@falcon.io user $theuser@brandwatch.com
    sleep 1
    gam_write update group falcon-everybody add member $theuser@brandwatch.com
  fi
  sleep 1

  # Add to location-based mail group
  if [[ $location_mailgroup ]]; then
    gam_write update group $location_mailgroup add member $theuser@brandwatch.com
    sleep 1
  else
    echo "Not added to any regional email group."
  fi

  echo
  if [[ $country == "USA" ]]; then
    echo "The user is US-based, so adding BenefitFocus profile attributes."
    gam_write update user $theuser@brandwatch.com Benefit_Focus_Admin.ROLE Member
    sleep 2
  else
    echo "Not a US-based employee, so not adding the BenefitFocus profile attribute."
  fi

#  echo "Creating Azure user account..."
#  curl -X PUT https://management.azure.com/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.ApiManagement/service/{serviceName}/users/{userId}?api-version=2021-08-01  \
#  -d "{
#    \"properties\": {
#      \"firstName\": \"$firstname\",
#      \"lastName\": \"$surname\",
#      \"email\": \"$theuser@brandwatch.com\",
#      \"password\": \"$azure_password\",
#    }
#  }"
#  if [[ ${needs_intune,,} =~ ^y ]]; then
#    ...
#  fi
#  if [[ ${needs_msoffice,,} =~ ^y ]]; then
#    ...
#  fi
fi

# Set calendar timezone
echo
if [[ $tz && ${tz,,} != "n/a" ]]; then
  echo "Setting user's calendar timezone..."
  gam_write calendar $theuser@brandwatch.com modify timezone $tz
  sleep 1
else
  echo "User's location is vague or unspecified, calendar timezone not set."
fi

# Would be nice to set the calendar to begin with Monday, unless in USA etc.
# Unfortunately weekStart can't be set by GAM (yet?), only read.
#echo
#if [[ ! $country =~ ^(USA|Canada|India|Portugal|Singapore)$ ]]; then
#  # This list is not complete
#  gam_write user $theuser@brandwatch.com modify calendar primary weekStart 1
#  sleep 1
#fi

echo
echo "Setting the user's signature..."
# This will be named "My Signature" in user's Gmail
# There are special rules for Germany
# TODO: confirm what the address line should say for remote hires
if [[ $country == "Germany" ]]; then
  case $city in
    Stuttgart) german_sig_footer1="Brandwatch GmbH, Leuschnerstr. 12, D-70174 Stuttgart (Sitz der Gesellschaft)"
              german_sig_footer2a="RG Stuttgart HRB 738170" ;;
    Frankfurt) german_sig_footer1="De-Saint-Exupéry-Straße 10 / Amelia-Mary-Eahrhart-Straße in "
              german_sig_footer2a="60549 Frankfurt" ;;
    Berlin|*)  german_sig_footer1="Brandwatch GmbH, Bergmannstraße 5, 10961, Berlin"
              german_sig_footer2a="HRB nr: 168630" ;;
  esac
  german_sig_footer2b="Geschäftsführer: Julius Dietz"
fi
# The German extra lines will not be added for other locations thanks to the surrounding {RT}...{/RT} tags in the template HTML file
# See https://github.com/GAM-team/GAM/wiki/ExamplesEmailSettings#setting-a-signature
gam_write user $theuser@brandwatch.com signature file "mail-signature-template.html" html replace Name "$firstname $surname" replace Jobtitle "$jobtitle" replace Location "$sig_location" replace Username "$theuser" replace German_footer_1 "$german_sig_footer1" replace German_footer_2a "$german_sig_footer2a" replace German_footer_2b "$german_sig_footer2b"
sleep 1

echo
echo "Adding the user to email groups and/or delegated mailboxes, if any were requested..."
_failed_mailgroups=() # Empty array
for mailgroup in $mailgroups; do
  [[ $DEBUG ]] && echo "Now checking: '$mailgroup'"
  mail_type=$(gam whatis ${mailgroup,,}@brandwatch.com 2>&1 >/dev/null | grep -E -i "$mailgroup@brandwatch.com is a (group|user)( alias)?$" | sed "s/$mailgroup@brandwatch.com is a //i")
  # Output redirection because the type info is sent to stderr, and we don't care about the details sent to stdout. The "i" option for grep/sed = case-insensitive
  [[ $DEBUG ]] && echo "Detected type: $mail_type"
  case $mail_type in
    group*) gam_write update group $mailgroup@brandwatch.com add member $theuser@brandwatch.com ;;
    user*) gam_write user $mailgroup@brandwatch.com delegate to $theuser@brandwatch.com ;;
    *) echo "'$mailgroup' seems to be neither a group nor a shared mailbox, so not doing anything with that."
       _failed_mailgroups+=("$mailgroup") # Add to array
       continue ;;
  esac
  sleep 2
done
failed_mailgroups="$(tr ' ' '\n' <<< "${_failed_mailgroups[@]}")" # Turn the array into newline-separated list
echo "Done"

# Notify the other teams
echo
echo

if [[ ${marketing,,} =~ ^y ]]; then
  echo "We'll email Operations to get BW Salesforce, Marketo and/or Outreach accounts setup"
  echo -e "Hello Business Operations,\n\n Please setup a Brandwatch Salesforce, Marketo and/or Outreach account for $firstname $surname \nEmail: $theuser@brandwatch.com \nLocation: $location \nJob Title: $jobtitle \nDepartment: $department \nStart Date: $startdate \n \nThe new starter's line manager is $managerfname $managersname \nLine manager email: $manager@brandwatch.com \n \n \n Thank you,\n - The IT Team" | mail -aFrom:Brandwatch\ IT\<it@brandwatch.com\> -a Reply-To:it@brandwatch.com -s "New Brandwatch user - $firstname $surname" bizops@brandwatch.com
elif [[ ${sfdc_instance,,} =~ ^b ]]; then
  # "b" for "BW" or "both"
  echo "We'll email Operations to get BW Salesforce setup done"
  echo -e "Hey Business Operations,\n\n Please setup a Brandwatch Salesforce account for $firstname $surname \nEmail: $theuser@brandwatch.com \nLocation: $location \nJob Title: $jobtitle \nDepartment: $department \nStart Date: $startdate \n \nThe new starter's line manager is $managerfname $managersname \nLine manager email: $manager@brandwatch.com \n \n \n Thank you,\n - The IT Team" | mail -aFrom:Brandwatch\ IT\<it@brandwatch.com\> -a Reply-To:it@brandwatch.com -s "New Salesforce user - $firstname $surname" bizops@brandwatch.com
else
  echo "Not a Marketing/Sales/BDR user."
fi

if [[ ${engineering,,} =~ ^y ]]; then
  gam_write update group engineering add member $theuser@brandwatch.com
  echo "We'll email Support to get ZenDesk Light Agent setup done"
  echo -e "Hey Support,\n \n Please setup $firstname $surname as a ZenDesk Light Agent.\n\n Email Address: $theuser@brandwatch.com \n \n \n Thank you,\n - The IT Team" | mail -aFrom:Brandwatch\ IT\<it@brandwatch.com\> -a Reply-To:it@brandwatch.com -s "New Zendesk Light Agent - $firstname $surname" support@brandwatch.com
else
  echo "Not an Engineering user."
fi

if [[ ${smm_suite,,} =~ ^y ]]; then
  echo "We'll email Support to get SMM suite setup done"
  echo -e "Hey Support,\n \n Please provide $firstname $surname access to the 'Brandwatch Demo Org' environment.\n\n Email Address: $theuser@brandwatch.com \n \n \n Thank you,\n - The IT Team" | mail -aFrom:Brandwatch\ IT\<it@brandwatch.com\> -a Reply-To:it@brandwatch.com -s "New SMM Suite 'BW demo org' access - $firstname $surname" support@brandwatch.com
else
  echo "SMM suite access not needed."
fi

if [[ ${bria,,} =~ ^y ]]; then
  echo "We'll email Leo to get Bria set up"
  echo -e "Hey Leo,\n\n Can you setup $firstname $surname a Bria account please?\n\n Email Address: $theuser@brandwatch.com \nLocation: $location \n \n \n Thank you,\n - The IT Team" | mail -aFrom:Brandwatch\ IT\<it@brandwatch.com\> -a Reply-To:it@brandwatch.com -s "New Bria account for $firstname $surname" leo@netfuse.org
else
  echo "Bria not needed."
fi

if [[ ${zoompro,,} =~ ^y ]]; then
  echo ""
  echo "Creating Zoom Pro account"
  echo ""
  curl --request POST \
    --url https://api.zoom.us/v2/users \
    --header 'authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdWQiOm51bGwsImlzcyI6ImdRUFpkazVNVE8yQmVzQ2dQWkV4SkEiLCJleHAiOjc5ODA1NjcwNjAsImlhdCI6MTU3NDQzODIzMX0.elF-YoSFDaK0mMICSmZGjwqeea--ei96--s-Jz5eq78' \
    --header 'content-type: application/json' \
    --data '{"action":"create","user_info":{"email":"'$theuser'@brandwatch.com","type":2,"first_name":"'$firstname'","last_name":"'$surname'"}}'
  echo ""
  echo "Done! A Zoom Pro account has been created!  WARNING: If an error occurs, it is most likely that there are no more available licenses. Please free up some licenses and try again using the Zoom standalone script ZoomV2.sh"
elif [[ ${zoom,,} =~ ^y ]]; then
  # Covers regular users + contractors who need (basic) Zoom account
  echo ""
  echo "Creating Basic Zoom account"
  echo ""
  curl --request POST \
    --url https://api.zoom.us/v2/users \
    --header 'authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdWQiOm51bGwsImlzcyI6ImdRUFpkazVNVE8yQmVzQ2dQWkV4SkEiLCJleHAiOjc5ODA1NjcwNjAsImlhdCI6MTU3NDQzODIzMX0.elF-YoSFDaK0mMICSmZGjwqeea--ei96--s-Jz5eq78' \
    --header 'content-type: application/json' \
    --data '{"action":"create","user_info":{"email":"'$theuser'@brandwatch.com","type":1,"first_name":"'$firstname'","last_name":"'$surname'"}}'
  echo ""
  echo "Done! A Basic Zoom account has been created."
else
  echo "Zoom not needed."
fi

# There's a check above, so this won't be asked for those on only Falcon Salesforce
if [[ ${gong,,} =~ ^y ]]; then
  echo ""
  echo "Adding user to Gong Zoom Group"
  echo ""
  curl --request POST \
  --url https://api.zoom.us/v2/groups/{H4B_FFOCR0qupwUyyhVMgQ}/members \
  --header 'authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdWQiOm51bGwsImlzcyI6ImdRUFpkazVNVE8yQmVzQ2dQWkV4SkEiLCJleHAiOjc5ODA1NjcwNjAsImlhdCI6MTU3NDQzODIzMX0.elF-YoSFDaK0mMICSmZGjwqeea--ei96--s-Jz5eq78' \
  --header 'content-type: application/json' \
  --data '{"members":[{"email":"'$theuser'@brandwatch.com"}]}'
  echo "Done! User has been added into the Gong Zoom Group"
elif [[ ${sfdc_instance,,} =~ ^b ]]; then
  # "b" for "BW" or "both"
  echo "Adding user to the non cloud recording group"
  curl --request POST \
  --url https://api.zoom.us/v2/groups/{va2LQTA9RWKf2d4NrTuhWQ}/members \
  --header 'authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJhdWQiOm51bGwsImlzcyI6ImdRUFpkazVNVE8yQmVzQ2dQWkV4SkEiLCJleHAiOjc5ODA1NjcwNjAsImlhdCI6MTU3NDQzODIzMX0.elF-YoSFDaK0mMICSmZGjwqeea--ei96--s-Jz5eq78' \
  --header 'content-type: application/json' \
  --data '{"members":[{"email":"'$theuser'@brandwatch.com"}]}'
  echo "Done! User has been added into the Regular Non-Cloud Recording Zoom Group"
fi

# Invite the user to 1Password
echo -e "\nInviting the user to 1Password \n"
# This is done above, right after the questions
# eval $(op signin --account team-brandwatch.1password.com)
# The account we use needs to be in the "Provision Managers" group in 1Password
op_write user provision --email "$theuser@brandwatch.com" --name "$firstname $surname" > /dev/null 2>&1 && {
  echo "$firstname $surname invited to 1Password – adding some default items to their vault."
  # The vault's name has the possessive as "apostrophe+s" unless the name ends in "s":
  uservault="$firstname $surname'$([[ $surname =~ .*s$ ]] || echo -n 's') Private Vault"
  if [[ $vault_password ]]; then
    # Won't be set if the user is doing the computer setup on their own
    op_write item create --vault="$uservault" --category=login --title='Computer' username=$theuser password=$computer_password >/dev/null
  fi
  op_write item create --vault="$uservault" --category=login --title='Google' --url https://accounts.google.com/ username=$theuser@brandwatch.com password=$random_google_password >/dev/null
  op_write item create --vault="$uservault" --category=login --title='LDAP (Staff Wi-Fi & OpenVPN)' --url https://chpwd.brandwatch.net username=$theuser password=$ldap_password >/dev/null
  #if [[ ${needs_msoffice,,} =~ ^y ]]; then
    op_write item create --vault="$uservault" --category=login --title='Office 365' --url https://www.office.com/login username=$theuser@brandwatch.com >/dev/null
  #fi
  if [[ ${needs_okta,,} =~ ^y ]]; then
    op_write item create --vault="$uservault" --category=login --title='Cision Okta' --url https://cision.okta.com username=$theuser >/dev/null
  fi
  echo "Creating ticket to review the starter's 1Pw vault."
  echo -e "Hello IT Team,\n \n This notice is to remind you to review and update the items in '$uservault' in 1Password.\n \n Thank you,\n - The IT Team" | mail -aFrom:Brandwatch\ IT\<it@brandwatch.com\> -a Reply-To:it@brandwatch.com -s "Review '$uservault' in 1Password" it@brandwatch.com
  echo -e "Done"
} || {
  onepassword_failed="yes"
  echo "Failed to invite $firstname $surname to 1Password, creating ticket to do it manually."
  echo -e "Hello IT Team,\n \n This notice is to remind you to invite $theuser@brandwatch.com to 1Password.\n \n Thank you,\n - The IT Team" | mail -aFrom:Brandwatch\ IT\<it@brandwatch.com\> -a Reply-To:it@brandwatch.com -s "Invite $theuser@brandwatch.com to 1Password" it@brandwatch.com
  echo -e "Done"
}
echo

if [[ $usertype == "contractor" ]]; then
  if [[ ${workfront,,} =~ ^y ]]; then
    echo "Sending Frances Cragg an email for Workfront access"
    echo -e "Hello Frances. \n \n The accounts for the contractor: $firstname $surname has been setup. \n \nTheir email address is: $theuser@brandwatch.com \n \nDepartment: $department \n \nPlease create a Workfront account for them. \n \n Thank you,\n - The IT Team" | mail -aFrom:Brandwatch\ IT\<it@brandwatch.com\> -a Reply-To:it@brandwatch.com -s "New starter $firstname $surname needs Workfront access" frances@brandwatch.com
  else
    echo "Workfront access not needed."
  fi

  echo

  # Let the People Team know the noobies email address
  echo "Letting the People Team know that we've set the user up"
  echo -e "Hello HR Team. The accounts for the contractor: $firstname $surname have been setup. \n \n Their email address is: $theuser@brandwatch.com. \n \n Start Date: $startdate. \n \n Thank you,\n - The IT Team" | mail -aFrom:Brandwatch\ IT\<it@brandwatch.com\> -a Reply-To:it@brandwatch.com -s "New contractor $firstname $surname has been setup" people-team@brandwatch.com matthew.williams@brandwatch.com

  # Ditto for HM
  echo "Letting the manager know the new starter's Google account has been setup"
  echo -e "Hello $managerfname $managersname, \n \nAccounts for the contractor $firstname $surname have been set up. \n \nTheir email address is: $theuser@brandwatch.com" | mail -aFrom:Brandwatch\ IT\<it@brandwatch.com\> -a Reply-To:it@brandwatch.com -s "Accounts for new starter $firstname $surname are being created" $manager@brandwatch.com

  echo
  echo "Contractor account creation script completed."
else # Employee
  if [[ ${workfront,,} =~ ^y ]]; then
    echo "We'll email Frances Cragg to get Workfront set up"
    echo -e "Hey Frances,\n \n Please setup $firstname $surname a Workfront account.\n\n Job Title: $jobtitle \n \n Email Address: $theuser@brandwatch.com. \n \n Department: $department. \n \n \n Thank you,\n - The IT Team" | mail -aFrom:Brandwatch\ IT\<it@brandwatch.com\> -a Reply-To:it@brandwatch.com -s "New Workfront account - $firstname $surname" frances@brandwatch.com
  else
    echo "Workfront access not needed."
  fi

  # Creating reminder ticket to add user into O365
  echo -e "\nCreating ticket to remind us to add user into O365 \n"
  echo -e "Hello IT Team,\n \n This notice is to remind you to add $theuser@brandwatch.com into Office 365 (portal.office.com) \n \n \n Thank you,\n - The IT Team" | mail -aFrom:Brandwatch\ IT\<it@brandwatch.com\> -a Reply-To:it@brandwatch.com -s "Add $theuser@brandwatch.com to Office 365" it@brandwatch.com
  echo -e "Done"

  echo -e "Sending email to remind us to order and document peripherals order"
  echo -e "Hello IT Team member,\n \n Please order the selected peripheral bundle for $firstname $surname  \n \n Order the equipment noted here https://docs.google.com/spreadsheets/d/1mHTZwThdA8eikC2cw_Qajp6gU2HKEf_11As29tvxt2U/edit#gid=0 \n \n You can confirm which item to order based on the users role via https://docs.google.com/spreadsheets/d/1ZlYPxmMfkVi2hw-9XNCCvqhc4pJPp0eT4G7_EN-b4vE/edit#gid=0
  \n \n Thank you,\n - Us" | mail -aFrom:Brandwatch\ IT\<it@brandwatch.com\> -a Reply-To:it@brandwatch.com -s "Order peripherals bundle for $firstname $surname and link to New Starter ticket" it@brandwatch.com

  ## Add Username to Custom Schema for JIRA SAML authentication
  echo "Adding Username to Google Schema"
  gam_write update user $theuser@brandwatch.com BW_SAML.bwUserName $theuser
  echo "Done"

  ## Add user information into Custom Schema for MDM use
  echo "Setting up MDM information"
  echo "Adding user's full name into BW_SAML.full_name"
  gam_write update user $theuser@brandwatch.com BW_SAML.Full_Name "$firstname $surname"
  echo "Done"
  echo "Adding user's department into  BW_SAML.department"
  gam_write update user $theuser@brandwatch.com organization department "$department" primary
  echo "Done"
  if [[ $region ]]; then
    echo "Adding user's region into Google Schema"
    gam_write update user $theuser@brandwatch.com address type work region "$region" primary
    echo "Done"
  else
    echo "Region for Google Schema unknown, not setting anything."
  fi

  ## Add Custom Schema details based on users JIRA groups in LDAP
  echo "Adding JIRA groups to Google Schema"

  # These are already defined above now
  # readonly LDAP_SERVER="ldap://mg1006"
  # readonly LDAP_PW="LTTRhiwA"
  # readonly LDAP_SECRET="/etc/ldap.secret"
  # readonly LDAP_BIND_USER="cn=root,dc=base,dc=runtime-collective,dc=com"
  # readonly SUFFIX="dc=base,dc=runtime-collective,dc=com"
  # readonly GSUFFIX="ou=Group"
  readonly SCHEMA="BW_SAML.bwUserGroups multivalued"

  function add_group_to_schema () {
   jiraGroups=$(ldapsearch -LLL -w ${LDAP_PW} -D "${LDAP_BIND_USER}" -P 3 -H ${LDAP_SERVER} -b "${GSUFFIX},${SUFFIX}" "(&(objectClass=posixGroup)(icsStatus=BrandwatchTeam)(memberUid=$theuser))" | grep "cn: " | sed "s|cn:||")
   declare -a jiraGroupArray=($jiraGroups)
   for group in "${jiraGroupArray[@]}"; do
     gamCommand="$gamCommand $SCHEMA $group" # Append the groups
   done
   gam_write update user $theuser@brandwatch.com $gamCommand
   echo "Done"
  }
  add_group_to_schema # TODO: reportedly this isn't useful anymore?

  echo "Adding user into Backup and Sync deployment group"
  gam_write update group backupandsyncusers@brandwatch.com add member user $theuser@brandwatch.com
  echo "Done"

  # Summarise script to ticket
  echo -e "\nCreating script report \n"
  echo -e "Hello IT Team,\n \n  This is a script summary: \n \n  Username $theuser \n \n Email: $theuser@brandwatch.com \n \n First Name: $firstname \n \n Surname: $surname \n \n Manager: $managerfname $managersname \n \n Job Title: $jobtitle \n \n Department: $department \n \n Location: $location \n \n Marketing(Salesforce included if Y) (y/n): $marketing \n \n Engineering (y/n): $engineering \n \n Zoom Pro (y/n): $zoompro \n \n Salesforce (Falcon/BW/both/no): $salesforce $sfdc_instance \n \n \n End Of Summary" | mail -aFrom:Brandwatch\ IT\<it@brandwatch.com\> -a Reply-To:it@brandwatch.com -s "Script Summary for $firstname $surname ($theuser@brandwatch.com)" it@brandwatch.com
  echo -e "Done"

  echo "Letting the People Team know that we've set the user up"
  echo -e "Hello HR Team,\n \n New starter $firstname $surname has been setup. \n \nTheir email address is: $theuser@brandwatch.com \nJob Title: $jobtitle \nLocation: $location \nStart Date: $startdate \nLine Manger Name: $managerfname $managersname \nDirect Report: $directreport \n \n \n Thank you,\n - The IT Team" | mail -aFrom:Brandwatch\ IT\<it@brandwatch.com\> -a Reply-To:it@brandwatch.com -s "New starter $firstname $surname has been setup" people-team@brandwatch.com melanie.schwartz@brandwatch.com matthew.williams@brandwatch.com

  echo "Letting the TA Team know that we've set the user up"
  echo -e "Hello TA Team,\n \n New starter $firstname $surname has been setup. \n \nTheir email address is: $theuser@brandwatch.com \nJob Title: $jobtitle \nLocation: $location \nStart Date: $startdate \nLine Manger Name: $managerfname $managersname \nDirect Report: $directreport \n \n \n Thank you,\n - The IT Team" | mail -aFrom:Brandwatch\ IT\<it@brandwatch.com\> -a Reply-To:it@brandwatch.com -s "New starter $firstname $surname has been setup" ta.notifications@brandwatch.com

  echo "Letting Cision know to add user to Calendar Sync"
  echo -e "Hello Cision Office Team,\n \n $firstname $surname has recently joined Brandwatch. Please add them to the Calendar sync with Brandwatch. \n \nTheir email address is: $theuser@brandwatch.com \n \n \n Thank you, \n \n - The IT Team" | mail -aFrom:Brandwatch\ IT\<it@brandwatch.com\> -a Reply-To:it@brandwatch.com -s "Add user to Calendar sync: $theuser@brandwatch.com" office365team@cision.com

  echo "Letting Finance know to add user to Expensify"
  echo -e "Hello Finance Team,\n \n $firstname $surname has recently joined Brandwatch. Please add them to Expensify. \n \n Their email address is: $theuser@brandwatch.com \n \n \n Thank you, \n \n - The IT Team" | mail -aFrom:Brandwatch\ IT\<it@brandwatch.com\> -a Reply-To:it@brandwatch.com -s "Add user to Expensify" staffexpenses@brandwatch.com

  echo "Letting iDesk Support know about the new user for HotDesk+"
  echo -e "Hello iDesk Team,\n \n Please can you add the following users to HotDesk+ please? \n \nNew starter $firstname $surname. \n \n Their email address is: $theuser@brandwatch.com \nDepartment: $department \nJob Title: $jobtitle \nLocation: $location \nStart Date: $startdate \nLine Manger Name: $managerfname $managersname \n \n Thank you,\n - The IT Team" | mail -aFrom:Brandwatch\ IT\<it@brandwatch.com\> -a Reply-To:it@brandwatch.com -s "HotDesk+ Account for New starter $firstname $surname" connect@idesk.life

  echo "Letting the manager know their new starters Google account has been setup"
  echo -e "Hello $managerfname $managersname,\n \nAccounts for new starter $firstname $surname have been created. \n \n Their email address is: $theuser@brandwatch.com \nLocation: $location \nStart Date: $startdate. \n \n Thank you, \n \n - The IT Team" | mail -aFrom:Brandwatch\ IT\<it@brandwatch.com\> -a Reply-To:it@brandwatch.com -s "Accounts for new starter $firstname $surname are being created" $manager@brandwatch.com

  echo "Sending email to the Support team to add the new user to the Brandwatch Platform."
  echo -e "Hello Support Team,\n \nPlease could you create an analytics/platform account for $firstname $surname. \n \n The Brandwatch email is $theuser@brandwatch.com \n \nThe analytics client they should be added to is: \n$analyticsclient \n \nTheir line manager is $managerfname $managersname and their email is $manager@brandwatch.com. Please contact them if any other information is needed. \n \n \n Thank you,\n - The IT Team" | mail -aFrom:Brandwatch\ IT\<it@brandwatch.com\> -a Reply-To:it@brandwatch.com -s "Please create Brandwatch platform account for $firstname $surname" support@brandwatch.com
  echo "Done."

  echo
  echo -e "\n\nStarter script has now been completed.\n\n"

  if [[ ${computer_setup,,} =~ ^i ]] || [[ $failed_mailgroups || $onepassword_failed ]]; then
    echo -e "Notes:\n"
    if [[ $failed_mailgroups ]]; then
      echo "Failed to add $theuser@brandwatch.com into following groups / delegated mailboxes:"
      echo "$failed_mailgroups"
      echo -e "Add them there manually.\n"
    fi
    if [[ ${computer_setup,,} =~ ^i ]]; then
      echo "User's initial Google account password was set to '$google_password'"
      echo "Remember to reset it to this one once the computer setup is done: $random_google_password"
      echo -e "This random password $([[ $onepassword_failed ]] || echo -n "was also added to the user's 1Password vault, and") will optionally be sent to New Hire Onboarding team.\n"
    fi
    if [[ $onepassword_failed ]]; then
      echo "Failed to invite the user to 1Password, so do that manually (there's also a ticket about that):"
      echo "  \$ op user provision --email \"$theuser@brandwatch.com\" --name \"$firstname $surname\""
      echo "Then find their vault and add these entries:"
      if [[ $vault_password ]]; then
        # Won't be set if the user is doing the computer setup on their own
        echo "Computer: $theuser / $computer_password"
      fi
      echo "Google: $theuser@brandwatch.com / $random_google_password / URL: https://accounts.google.com/"
      echo "LDAP (Staff Wi-Fi & OpenVPN): $theuser / $ldap_password / URL: https://chpwd.brandwatch.net"
      #if [[ ${needs_msoffice,,} =~ ^y ]]; then
        echo "Office 365: $theuser@brandwatch.com / TBD / URL: https://www.office.com/login"
      #fi
      if [[ ${needs_okta,,} =~ ^y ]]; then
        echo "Cision Okta: $theuser / TBD / URL: https://cision.okta.com"
      fi
    fi
  fi

  echo "Enter a backup verification code for this user's Google account to send to New Hire Onboarding team (to cancel, leave it empty or press Ctrl-C)"
  if [[ ${computer_setup,,} =~ ^i ]]; then
    echo "NB: make sure you wouldn't use this code yourself later when setting up their computer! Maybe pick the last code from the list?"
  fi
  read google_2fa_code
  if [[ $google_2fa_code ]]; then
    echo "Letting New Hire Onboarding team know the initial passwords of the user"
    echo -e "Hello New Hire Onboarding team,\n \nThe basic accounts for the $location new starter $firstname $surname have been set up. They are starting on $startdate in $managerfname $managersname's team as a$([[ ${jobtitle:0:1} =~ ^[AEIOU] ]] && echo -n 'n') $jobtitle.\n \nTheir initial password for the computer and 1Password vault: $computer_password\n\nTheir email address: $theuser@brandwatch.com\nInitial Google password: $random_google_password\nBackup verification code: $google_2fa_code\n \n Thank you,\n - The IT Team" | mail -aFrom:Brandwatch\ IT\<it@brandwatch.com\> -a Reply-To:it@brandwatch.com -s "Initial password for new starter $firstname $surname" newhireonboarding@brandwatch.com
  fi
fi

