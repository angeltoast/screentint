#!/bin/bash

# A script to change the colour of the screen display
# To run in a terminal under any version of GNU Linux
# Developed by Elizabeth Mills
# 11th April 2021

# Save this script in your home directory
# Don't forget to make it executable (chmod +x screentint.sh)
# Run:   ./screentint.sh

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful, but
#      WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#            General Public License for more details.

# A copy of the GNU General Public License is available from the Feliz2
#        page at http://sourceforge.net/projects/feliz2/files
#        or https://github.com/angeltoast/feliz2, or write to:
#                 The Free Software Foundation, Inc.
#                  51 Franklin Street, Fifth Floor
#                    Boston, MA 02110-1301 USA

source listgen.sh # For generating menus and lists

Backtitle="Set Screen Colour Temperature"

function Main {  # All steps are called from here
  while :
  do
    listgen1 "1500 2500 3500 4500 5500 6500 7500 8500" "Tint range 1500 (warm - red) to 8500 (cool - blue)" "Set Finish"
    if [ $Result = "Finish" ]; then
      clear
      exit
    else
      sct "$Result"
    fi
  done
}

Main
