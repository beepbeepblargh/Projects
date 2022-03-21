#!/bin/sh
#Written by Chris Ng
hdiutil attach ~/Desktop/Install/CS_Test_Mac_agent.dmg

sudo installer -pkg /Volumes/LDMSClient/ldmsagent.pkg -target / -verbose

hdiutil detach /Volumes/LDMSClient