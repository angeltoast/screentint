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

function Main {  # All steps are called from here
	echo "Tint range 1000 (dark red) to 10000 (Bright blue)"
	
	read -p "Enter a number between 1000 and 10000: " choice
	
	sct $choice
	read -p "Screen tint set to $choice . Press any key to exit"
	
}

function menu_dialog {  # Display a simple menu from $menu_dialog_variable and return selection as $Result
                        # $1 and $2 are dialog box size;
                        # $3 is optional: can be the text for --cancel-label
  if [ "$3" ]; then
    cancel="$3"
  else
    cancel="Cancel"
  fi
  # Prepare array for display
  declare -a ItemList=()                                      # Array will hold entire list
  Items=0
  for Item in $menu_dialog_variable; do                       # Read items from the variable
    Items=$((Items+1))                                        # and copy each one to the array
    ItemList[${Items}]="${Item}"                              # First element is tag
    Items=$((Items+1))
    ItemList[${Items}]="${Item}"                              # Second element is required
  done
  # Display the list for user-selection
  dialog --backtitle "$Backtitle" --title " $title " \
    --no-tags --ok-label "$Ok" --cancel-label "$cancel" --menu "$Message" \
      "$1" "$2" ${Items} "${ItemList[@]}" 2>output.file
  retval=$?
  Result=$(cat output.file)
}

Main

