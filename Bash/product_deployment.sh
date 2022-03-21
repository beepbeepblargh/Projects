#!/bin/bash

if serverinfo -q --configured
then
  if test $# -eq 1
  then
      if test "$1" == "help"
      then
          echo "Parameters can be"
          echo "TP: Threat Prevention"
          echo "WC: Web Control"
          echo "help : To see this help"
          exit 0
      fi
      if test "$1" == "TP"
      then
  	    echo "<array>" >> /tmp/ProductDeploy.xml
  	    echo "<string>installer_choice_5</string>" >> /tmp/ProductDeploy.xml
  	    echo "</array>" >> /tmp/ProductDeploy.xml
  	    echo "Only TP will be installed."
      elif test "$1" == "WC"
      then
          echo "<array>" >> /tmp/ProductDeploy.xml
  	    echo "<string>installer_choice_3</string>" >> /tmp/ProductDeploy.xml
  	    echo "</array>" >> /tmp/ProductDeploy.xml
  	    echo "Only WC will be installed."
  	 else
  	    echo "Parameters can be"
          echo "TP: Threat Prevention"
          echo "WC: Web Control"
          echo "help : To see this help"
          exit 1
  	 fi
  elif test $# -eq 2
  then
      if  [[ ( "$1" == "TP" &&  "$2" == "WC" ) || ( "$1" == "WC" && "$2" == "TP" ) ]]
      then
  	    echo "<array>" >> /tmp/ProductDeploy.xml
  	    echo "</array>" >> /tmp/ProductDeploy.xml
  	    echo "Only TP and WC  will be installed."
      elif [[ ( "$1" == "FW" &&  "$2" == "WC" ) || ( "$1" == "WC" && "$2" == "FW" ) ]]
    	then
    	    echo "<array>" >> /tmp/ProductDeploy.xml
    	    echo "<string>installer_choice_3</string>" >> /tmp/ProductDeploy.xml
    	    echo "</array>" >> /tmp/ProductDeploy.xml
    	    echo "Only WC  will be installed."

        elif [[ ( "$1" == "TP" &&  "$2" == "FW" ) || ( "$1" == "FW" && "$2" == "TP" ) ]]
        then
            echo "<array>" >> /tmp/ProductDeploy.xml
    	    echo "<string>installer_choice_5</string>" >> /tmp/ProductDeploy.xml
    	    echo "</array>" >> /tmp/ProductDeploy.xml
    	    echo "Only TP will be installed."
  	  else
  	    echo "Parameters can be"
          echo "TP: Threat Prevention"
          echo "WC: Web Control"
          echo "help : To see this help"
          exit 1
  	fi
  elif test $# -eq 3
  then
      if  [[ ( "$1" == "TP" &&  "$2" == "FW" && "$3" == "WC" ) || ( "$1" == "FW" &&  "$2" == "TP" && "$3" == "WC" )  || ( "$1" == "TP" &&  "$2" == "WC" && "$3" == "FW" ) || ( "$1" == "FW" &&  "$2" == "WC" && "$3" == "TP" ) || ( "$1" == "WC" &&  "$2" == "TP" && "$3" == "FW" ) || ( "$1" == "WC" &&  "$2" == "FW" && "$3" == "TP" ) ]]
      then
          echo "<array>" >> /tmp/ProductDeploy.xml
  	    echo "</array>" >> /tmp/ProductDeploy.xml
          echo "Only TP and WC will be installed."
      else
  	   echo "Parameters can be"
         echo "TP: Threat Prevention"
         echo "WC: Web Control"
         echo "help : To see this help"
         exit 1
      fi
  else
      echo "Invalid parameters:"
      echo "Parameters can be"
      echo "TP: Threat Prevention"
      echo "WC: Web Control"
      exit 1
  fi
else
  if test $# -eq 1
  then
      if test "$1" == "help"
      then
          echo "Parameters can be"
          echo "TP: Threat Prevention"
          echo "FW: FireWall"
          echo "WC: Web Control"
          echo "help : To see this help"
          exit 0
      fi
      if test "$1" == "TP"
      then
  	    echo "<array>" >> /tmp/ProductDeploy.xml
  	    echo "<string>installer_choice_4</string>" >> /tmp/ProductDeploy.xml
  	    echo "<string>installer_choice_5</string>" >> /tmp/ProductDeploy.xml
  	    echo "</array>" >> /tmp/ProductDeploy.xml
  	    echo "Only TP will be installed."
  	elif test "$1" == "FW"
  	then
  	    echo "<array>" >> /tmp/ProductDeploy.xml
  	    echo "<string>installer_choice_3</string>" >> /tmp/ProductDeploy.xml
  	    echo "<string>installer_choice_5</string>" >> /tmp/ProductDeploy.xml
  	    echo "</array>" >> /tmp/ProductDeploy.xml
  	    echo "Only FW will be installed."
      elif test "$1" == "WC"
      then
          echo "<array>" >> /tmp/ProductDeploy.xml
  	    echo "<string>installer_choice_3</string>" >> /tmp/ProductDeploy.xml
  	    echo "<string>installer_choice_4</string>" >> /tmp/ProductDeploy.xml
  	    echo "</array>" >> /tmp/ProductDeploy.xml
  	    echo "Only WC will be installed."
  	 else
  	    echo "Parameters can be"
          echo "TP: Threat Prevention"
          echo "FW: FireWall"
          echo "WC: Web Control"
          echo "help : To see this help"
          exit 1
  	 fi
  elif test $# -eq 2
  then
      if  [[ ( "$1" == "TP" &&  "$2" == "FW" ) || ( "$1" == "FW" && "$2" == "TP" ) ]]
      then
  	    echo "<array>" >> /tmp/ProductDeploy.xml
  	    echo "<string>installer_choice_5</string>" >> /tmp/ProductDeploy.xml
  	    echo "</array>" >> /tmp/ProductDeploy.xml
  	    echo "Only TP and FW  will be installed."

  	elif [[ ( "$1" == "FW" &&  "$2" == "WC" ) || ( "$1" == "WC" && "$2" == "FW" ) ]]
  	then
  	    echo "<array>" >> /tmp/ProductDeploy.xml
  	    echo "<string>installer_choice_3</string>" >> /tmp/ProductDeploy.xml
  	    echo "</array>" >> /tmp/ProductDeploy.xml
  	    echo "Only FW and WC  will be installed."

      elif [[ ( "$1" == "TP" &&  "$2" == "WC" ) || ( "$1" == "WC" &&  "$2" == "TP" ) ]]
      then
          echo "<array>" >> /tmp/ProductDeploy.xml
  	    echo "<string>installer_choice_4</string>" >> /tmp/ProductDeploy.xml
  	    echo "</array>" >> /tmp/ProductDeploy.xml
  	    echo "Only TP and WC will be installed."
  	else
  	    echo "Parameters can be"
          echo "TP: Threat Prevention"
          echo "FW: FireWall"
          echo "WC: Web Control"
          echo "help : To see this help"
          exit 1
  	fi
  elif test $# -eq 3
  then
      if  [[ ( "$1" == "TP" &&  "$2" == "FW" && "$3" == "WC" ) || ( "$1" == "FW" &&  "$2" == "TP" && "$3" == "WC" )  || ( "$1" == "TP" &&  "$2" == "WC" && "$3" == "FW" ) || ( "$1" == "FW" &&  "$2" == "WC" && "$3" == "TP" ) || ( "$1" == "WC" &&  "$2" == "TP" && "$3" == "FW" ) || ( "$1" == "WC" &&  "$2" == "FW" && "$3" == "TP" ) ]]
      then
          echo "<array>" >> /tmp/ProductDeploy.xml
  	    echo "</array>" >> /tmp/ProductDeploy.xml
          echo "All FM's will be installed."
      else
  	   echo "Parameters can be"
         echo "TP: Threat Prevention"
         echo "FW: FireWall"
         echo "WC: Web Control"
         echo "help : To see this help"
         exit 1
      fi
  else
      echo "Invalid parameters:"
      echo "Parameters can be"
      echo "TP: Threat Prevention"
      echo "FW: FireWall"
      echo "WC: Web Control"
      exit 1
  fi
fi

hdiutil attach McAfee-*

installer -pkg /Volumes/McAfee-*/McAfee-*.pkg -target / -applyChoiceChangesXML /tmp/ProductDeploy.xml

hdiutil detach /Volumes/McAfee-*

rm /tmp/ProductDeploy.xml
