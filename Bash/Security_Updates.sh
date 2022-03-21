#!/usr/bin/env bash

sudo softwareupdate -l
sudo softwareupdate -i -a -R

echo "Updates are now complete. Computer May Restart."
