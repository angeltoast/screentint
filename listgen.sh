#!/bin/bash

# Developed by Elizabeth Mills
# Revision date: 11th April 2021

# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at
# your option) any later version. For a copy, write to:
#                 The Free Software Foundation, Inc.
#                  51 Franklin Street, Fifth Floor
#                    Boston, MA 02110-1301 USA

# This program is distributed in the hope that it will be useful, but
#      WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#            General Public License for more details.

# Functions return the text of the selected item as global variable
# $Result and the selected item number as global variable $Response.
# Window width and height are adjusted according to content
# See listgen.manual for guidance on the use of these functions

# Initialise global variables
declare -a Options  # Array
Response=""         # Output (menu item number)
Result=""           # Output (menu item text)
Width=$(tput cols)  # Screen width
Ok="Ok"             # Default button text
Exit="Exit"         # Default button text
Instructions="Use arrow keys to move. Enter to select"

# read -p "DEBUG listgen $LINENO"   # Basic debugging

# --------------------   ------------------------
# Function        Line	 Usage
# --------------------   ------------------------
# Echo			       53 	 echo
# Heading          58    Print a heading
# first_item       70    Prints first item of a menu
# subsequent_item  98    Prints successive menu items
# PrintRev        104    Reverses text colour
# Buttons         113    Prints a row of buttons. 3 arguments: Type; Button string; Message string
# get_char        162    Capture key press
# ActiveMenu      172    Controls the highlighting of menu items. 1 argument = Type (Menu, Yes/No)
# listgen1        307    Generates a simple menu of one-word items
# listgen2        362    Generates a menu of multi-word items
# listgenx        425    Generates a numbered list of one-word items in columns
# SelectPage      522    Used by listgenx to manage page handling
# PrintPage       569    Used by listgenx to display selected page
# --------------------   ------------------------

Echo() { # Prints text or an empty row then advances row counter
  echo "$1"
  cursor_row=$((cursor_row+1))        # Advance line counter
}

Heading() { # Always use this function to clear the screen
  clear
  # Prepare local variables
  local Length
  local Limit
  local Text
  local stpt
  
  Text="$Backtitle"                   # Backtitle global variable set by caller
  
  if [ ${#Text} -ge $Width ]; then    # If Backtitle too long for window
    Limit=$((Width-2))                # Set Limit to 2 characters lt Width
    Text="${Text:0:$Limit}"           # Limit text
  fi
  Length=$(echo $Text | wc -c)        # Count characters
  stpt=$(( (Width - Length) / 2 ))    # Horizontal startpoint
  tput cup 0 $stpt                    # Move cursor to startpoint on top row
  tput bold                           # Prepare to print backtitle
  printf "%-s\\n" "$Backtitle"        # Display backtitle
  tput sgr0                            # Make sure colour inversion is reset
 # printf "%$(tput cols)s\n"|tr ' ' '-' # Draw a line across width of terminal
  cursor_row=3                         # Save cursor row after heading
  first_button_start=40               # Column
}

first_item() {   # Aligned text according to screen size
  # Receives two arguments: $1 Text to print; $2 Length of $1
  # Prepare local variables
  local Length
  local Limit
  local Text
  
  Text="$1"                         # Text passed from caller
  if [ ${#Text} -ge $Width ]; then
    Limit=$((Width-2))              # Set Limit to 2 characters < Width
    Text="${Text:0:$Limit}"         # Limit text
  fi
  
  if [ $2 ]; then   # If a 2nd argument is passed (length of $1)
    if [ $2 -ge $Width ]; then  # Check to see if it exceeds console width
      Length=$((Width-2))       # If it does, shorten it to fit
    else  
      Length=$2                 # If not too long, set length variable to
    fi                          # the value passed as $2
  else                          # If $2 is not passed
    Length=$MaxLen              # Set length to maximum length of list items
  fi
  stpt=$(( (Width - Length) / 2 ))    # Horizontal startpoint
  tput cup $cursor_row $stpt          # Move cursor to startpoint
  printf "%-s\\v" "$Text"             # Print the item
  cursor_row=$((cursor_row+1))        # Advance line counter
}

subsequent_item() {                   # Subsequent item(s) in an aligned list
  tput cup $cursor_row $stpt          # Move cursor to startpoint
  printf "%-s\\n" "$1"                # Print with a following newline
  cursor_row=$((cursor_row+1))        # Advance line counter
}

PrintRev() {  # Receives numeric argument of item number and reverses colour
  tput rev                           # Reverse colour
  ItemLen=${#ListgenArray[${1}]}     # Get length
  Spaces=$((MaxLen-ItemLen))         # Calculate spaces needed to pad it out
  Padding="$(printf '%*s' "$Spaces")"     # Pad with spaces to make length
  printf "%-s" "${ListgenArray[${1}]}$Padding" # Reprint item at this position
  tput sgr0 	                                 # Reset colour
}

Buttons() {
  # Receives 3 arguments: 1) Type (Menu, Yes/No); 2) Button string; 3) Message string
  # Button string should contain one or two words: eg: 'Ok' or 'Ok Exit'
  # (this may be extended to three options after further testing)
  Echo
  # Use only local variables
  button_row=$cursor_row                    # Save row position of buttons
  button_count=$(echo $2 | wc -w)           # One or two buttons
  if [ $button_count -eq 0 ]; then          # Exit in case of error
    echo "listgen-sgi line $LINENO - No buttons specified" > listgen.log
    return 1
  fi
  Button1="$(echo $2 | cut -d' ' -f1)"      # Text for 1st button
  Len=$(echo $Button1 | wc -c)              # Count characters 
  Button1Len=$((Len+2))                     # Add for braces
  ButtonString="[ $Button1 ]"               # 1st button string
  if [ $button_count -gt 1 ]; then          # If second button
    Button2="$(echo $2 | cut -d' ' -f2)"      # Text for 2nd button
    Len=$(echo $Button2 | wc -c)              # Count characters 
    Button2Len=$((Len+3))                     # Add for braces and spaces
    ButtonString="[ $Button1 ] [ $Button2 ]"  # 2nd button string
  else                                      # Otherwise set variables to null
    Button2=""
    Button2Len=0
  fi
  ButtonStringLen=${#ButtonString}
  button_start=$(((Width-Button1Len-Button2Len)/2))
  tput cup $button_row $button_start          # Reposition cursor
  printf "%-s\\n" "$ButtonString"              # Print buttons
  case $3 in
  "") Message=""
    ;;
  *) cursor_row=$((cursor_row+1))             # Advance cursor row after buttons
    Echo
    lov=${#3}                                 # Length of message
    if [ ${lov} -lt ${Width} ]; then
      message_start=$(( (Width - lov) / 2 ))
    else
      message_start=1
    fi
    tput cup $cursor_row $message_start       # Reposition cursor
    Echo "$3"                                 # Print message
  esac
  ActiveMenu "$1"
  Echo
  
}

get_char() {
    SAVEDSTTY=`stty -g`
    stty -echo
    stty -icanon
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    # KeyPress="$(head -c1)"
    stty icanon
    stty echo
    stty $SAVEDSTTY
}

ActiveMenu() {  # Receives 2 arguments: 1) Type (Menu, Yes/No); 2) Caller (listgen1 or listgen2)
  tput civis &                                # Hide cursor
  local Counter=0
  selected_button=1
  if [ $1 = "Yes/No" ]; then                  # Prevent vertical cursor movement
    cursor_bottom=0                           # Initialise at unrealistic limits
    cursor_top=100
    cursor_row=$first_button_start            # Prepare to move cursor to first button
    tput cup $cursor_row $stpt                # Move cursor to selected position
  else                                        # ie: Not Yes/No
    cursor_row=$cursor_top                    # Prepare to move cursor to top
    tput cup $cursor_row $stpt                # Move cursor to selected position
    PrintRev "$Counter"                       # Print top item in reverse colour
  fi
  while :
  do
    if [ $selected_button -eq 1 ]; then                   # Left button
      tput cup $button_row $button_start                  # Move cursor to button position
      tput rev                                            # Reverse colour
      printf "%-${Button1Len}s" "[ ${Button1} ]"          # Highlight first button
      tput sgr0                                           # Restore colour settings
    else                                                  # Right button
      tput cup $button_row $((button_start+Button1Len+2)) # Move cursor to second button position
      tput rev                                            # Reverse colour
      printf "%-${Button2Len}s" "[ ${Button2} ]"          # Highlight second button
      tput sgr0                                           # Restore colour settings
    fi

    KeyPress=$(get_char)                    # Capture key press
    case "${KeyPress}" in
      "") # Ok/Return pressed
        if [ $1 = "Yes/No" ]; then
          Response=$selected_button
          case $Response in
          1) Result="${Button1}"
          ;;
          2) Result="${Button2}"
          esac
        else  # ie: menu
          if [ $selected_button -eq 1 ]; then
            Response=$((Counter+1))
            if [ $CalledBy = "listgen2" ]; then
              Compare=1
              for i in $PrimaryFile
              do
                if [ $Compare -eq $Response ]; then
                  Result="$i"
                  break
                fi
                Compare=$((Compare+1))
              done
            else
              Result="${ListgenArray[${Counter}]}"
            fi
          else
            Response=0
            Result="${Button2}"
          fi
        fi
        tput cnorm
      return $Response
      ;;
      A) # Up arrow:
        if [ $cursor_row -gt $cursor_top ]; then            # Not already at top
          tput cup $cursor_row $stpt                        # Reposition cursor
          printf "%-s\\n" "${ListgenArray[${Counter}]}$Padding" # Reprint item at this position
          cursor_row=$((cursor_row-1))                      # Next row up
          tput cup $cursor_row $stpt                        # move cursor to selected row
          Counter=$((Counter-1))                            # Decrease counter for next list item
          PrintRev $Counter                                 # Print current item in reverse colour
        fi
      ;;
      B) # Down arrow
        if [ $cursor_row -lt $cursor_bottom ]; then         # Not already at bottom
          tput cup $cursor_row $stpt                        # Reposition cursor
          printf "%-s\\n" "${ListgenArray[${Counter}]}$Padding" # Reprint item at this position
          cursor_row=$((cursor_row+1))                      # Next row down
          tput cup $cursor_row $stpt                        # move cursor to selected row
          Counter=$((Counter+1))                            # Increase counter for next list item
          PrintRev $Counter                                 # Print current item in reverse colour
        fi
      ;;
      C) # Right arrow
        if [ $selected_button -eq 1 ]; then
          tput cup $button_row $button_start                # Move cursor to first button position
          printf "%-${ButtonStringLen}s" "${ButtonString} " # Unhighlight all buttons
          tput cup $button_row $((button_start+Button1Len+2)) # Move cursor to second button position
          tput rev                                          # Reverse colour
          printf "%-${Button2Len}s" "[ ${Button2} ]"        # Highlight second button
          tput sgr0                                         # Reset
          tput cup $cursor_row $stpt                        # return cursor to menu row
          selected_button=2                                 # Set button variable
        else  # Selected button is 2
          tput cup $button_row $button_start                # Move cursor to first button position
          printf "%-${ButtonStringLen}s" "${ButtonString} " # Unhighlight all buttons
          tput cup $button_row $button_start                # Move cursor to first button position
          tput rev                                          # Reverse colour
          printf "%-${Button1Len}s" "[ ${Button1} ]"        # Highlight first button
          tput sgr0                                         # Reset
          tput cup $cursor_row $stpt                        # return cursor to menu row
          selected_button=1
        fi
      ;;
      D) # Left arrow
        if [ $selected_button -eq 2 ]; then
          tput cup $button_row $button_start                # Move cursor to first button position
          printf "%-${ButtonStringLen}s" "${ButtonString} " # Unhighlight all buttons
          tput cup $button_row $button_start                # Move cursor to first button position
          tput rev                                          # Reverse colour
          printf "%-${Button1Len}s" "[ ${Button1} ]"        # Highlight first button
          tput sgr0                                         # Reset
          tput cup $cursor_row $stpt                        # return cursor to menu row
          selected_button=1
        else  # Selected button is 1
          tput cup $button_row $button_start                # Move cursor to first button position
          printf "%-${ButtonStringLen}s" "${ButtonString} " # Unhighlight all buttons
          tput cup $button_row $((button_start+Button1Len+2)) # Move cursor to second button position
          tput rev                                          # Reverse colour
          printf "%-${Button2Len}s" "[ ${Button2} ]"        # Highlight second button
          tput sgr0                                         # Reset
          tput cup $cursor_row $stpt                        # return cursor to menu row
          selected_button=2                                 # Set button variable
        fi
      ;;
      9)  # Tab?
          echo "$KeyPress is TAB"
          echo
          exit
      ;;
      *) tput cup $cursor_row $stpt                         # Reposition cursor
      continue
    esac
  done
}

listgen1() { # Simple listing alternative to the bash 'select' function
  # Arguments:
  # 1) Primary file (string of single-word references)
  # 2) May be a translated message or empty
  # 3) Translated button text eg: 'Ok Exit' or just 'Ok'
  # Read listgen.manual for full details
  case $2 in
    "") Message=""
    ;;
    *) Message="$2"
  esac
  Heading
  Padding=" "
  MaxLen=2
  while :
  do
    local Counter=0
    MenuList=$1
    # Find length of longest item to create padding for use in reverse colour
    for i in $MenuList
    do
      Counter=$((Counter+1))
      if [ $Counter -eq 1 ]; then
        MaxLen=${#i}              # Save length
      else
        ItemLen=${#i}
        if [ $ItemLen -gt $MaxLen ]; then
          MaxLen=$ItemLen
        fi
      fi
    done
    # Now run through the file again to print each item
    Counter=0
    for i in $MenuList
    do
      if [ $Counter -eq 0 ]; then
        cursor_top=$cursor_row
        first_item "$i"
      else
        subsequent_item "$i"
      fi
      ListgenArray[$Counter]=$i   # Save to array for menu actions
      Counter=$((Counter+1))
    done
    CalledBy="listgen1"
    cursor_bottom=$((cursor_row-1))
    case $3 in
    "") read -p "No buttons passed"
    ;;
    *) Buttons "Menu" "$3" "$Message"
    esac
    break
  done
}

listgen2() { # Advanced menuing function with extended descriptions
  # Arguments:
  # 1) Primary file (string of single-word references)
  # 2) May be a translated message or empty
  # 3) Translated button text eg: 'Ok Exit' or just 'Ok'
  # 4) Secondary file (the name {only} of the array containing long descriptions)
  # Read listgen.manual for full details
  case $2 in
  "") Message=""
  ;;
  *) Message="$2"
  Heading
  esac
  Padding=" "
  MaxLen=2
  Boundary=$((T_COLS-2))
  while :
  do
    Result=""
    PrimaryFile="$1"
    name=$4[@]
    LongDescription=("${!name}")
    # First find length of longest item to create padding for use in reverse colour
    Max=$(echo $PrimaryFile | wc -w)
    for (( i=0; i < $Max; ++i ))
    do
      # ----------------
      if [ ${#LongDescription[${i}]} -ge $Boundary ]; then
        UnTrimmed="${LongDescription[${i}]}"
        Trimmed="${UnTrimmed:0:$Boundary}"
        LongDescription[${i}]="$Trimmed"
      fi
      # ---------------
      if [ $i -eq 0 ]; then
        MaxLen=${#LongDescription[${i}]}
      else
        ItemLen=${#LongDescription[${i}]}
        if [ $ItemLen -gt $MaxLen ]; then
          MaxLen=$ItemLen
        fi
      fi
    done
    # Now run through the file again to print each item
    for (( i=0; i < $Max; ++i ))
    do
      if [ $i -eq 0 ]; then
        cursor_top=$cursor_row
        ListgenArray[$i]="${LongDescription[${i}]}"   # Save to array for menu actions
        first_item "${LongDescription[${i}]}"
      else
        ListgenArray[$i]="${LongDescription[${i}]}"   # Save to array for menu actions
        subsequent_item "${LongDescription[${i}]}"
      fi
    done
    CalledBy="listgen2"
    cursor_bottom=$((cursor_row-1))
    if [ "$3" ]; then
      Buttons "Menu" "$3" "$_Instructions"
    fi
    return 0
  done
}

listgenx() { # The calling function creates temp.file before calling listgenx
             # The input.file must be one record per line
             # Calling function can send an optional 'Headline' string as $1
             # to appear at the top of the screen, and an optional 'Message' as $2
             # to appear at the bottom of the screen. $3, $4 and $5 are paging advice
  # Prepare input file
  grep -v '^$' temp.file > input.file         # Remove any blank lines
  rm temp.file                                # Remove the temp file

  tput cnorm              # Ensure cursor is visible
  if [ "$1" ]; then
    Headline="$1"
  else
    Headline=""
  fi
  if [ "$2" ]; then
    Message="$2"
  else
    Message="Please enter the number of your selection: " # ... In language files
  fi
  if [ "$3" ]; then
    Advise="$3"
  else
    Advise="or ' ' to go back" # ... In language files
  fi
  if [ "$4" ]; then
    Previous="$4"
  else
    Previous="Enter '<' for previous page"
  fi
  if [ "$5" ]; then
    Next="$5"
  else
    Next="Enter '>' for next page"
  fi

  total_items=$(cat input.file | wc -l)
  LastItem="$(tail -n 1 input.file)"
  Heading
  # Establish terminal size
  terminal_width=$(tput cols)             # Start with full terminal width
  display_width=$((terminal_width-4))     # Allow for two characters margin each side
  terminal_centre=$((terminal_width/2))   # Page centre used to calculate start point
  terminal_height=$(tput lines)           # Full height of terminal
  top_row=4                               # Leave space for heading
  cursor_row=$top_row                     # Start cursor at top row
  bottom_row=$((terminal_height-4))       # Leave space for footer
  items_in_column=$((bottom_row-top_row)) # Number of items in each column
  # Prepare an array of columns
  declare -a Columns                      # Prepare an array to hold all prepared columns
  declare -a ColumnWidths                 # And one for their widths

  WidthOfColumns=2                        # Initialise for loop
  local Counter=0
  RecordNumber=0                          # Initialise record-counting variable
  while [ $RecordNumber -le $total_items  ] # ....... Outer loop for entire file #####
  do
    TestLen=0                             # Set length-testing variable for column
    Column=""                             # Start column string variable
    for (( line=1; line <= $items_in_column; ++line )) # ......... Column loop #####
    do
      RecordNumber=$((RecordNumber+1))
      item=$(head -n $RecordNumber input.file | tail -1)  # Read item from file
      ItemLen=${#item}                            # Measure length
      ItemLen=$((ItemLen+3))                      # Add column spacing
      if [ $ItemLen -gt $TestLen ]; then
        TestLen=$ItemLen                          # Save greatest length
      fi
      Column="$Column $item"                      # Save this record in string
      if [ $RecordNumber -gt $total_items ]; then # If last record
        break
      fi
    done # .... End of column loop ####
    NumberOfColumns=$((NumberOfColumns+1))        # Increment columns counter
    Columns[${NumberOfColumns}]="${Column}"       # Save this column to the array
    ColumnWidths[${NumberOfColumns}]=$TestLen     # Save the width of this column
    Column=""                                     # Empty the string for next column
  done # ........ End of file loop #####
  rm input.file

  # Now build all pages, before proceeding to page-handling in SelectPage()
  declare -a Pages        # Each element of this array will hold a list of the columns forming the page
  declare -a PageWidths   # Each element of this array will hold total width of columns forming the page
  Page=""                 # This variable will hold a list of column numbers for the selected page
  PageNumber=1            # Page selector
  PageWidth=4             # Start width accumulator with margins
  ColumnWidth=0
  LastPage=0
  while :
  do
    for (( column=1; column <= $NumberOfColumns; ++column )) # Build a page
    do
      if [ $((PageWidth+ColumnWidth+4)) -ge $display_width ]; then
                                              # If adding another column would exceed
        PageWidths[${PageNumber}]=$PageWidth  # page width ... save this page's width
        PageWidth=4                           # and reset variable for next page
        Pages[${PageNumber}]="${Page}"        # Copy the list of columns to Pages array
        PageNumber=$((PageNumber+1))          # Then set next page, advance page counter, and
        Page=""                               # empty string for next list of columns
      fi

      ColumnWidth=0
      # Loop through each $Columns[@] to test the length of each string
      for item in ${Columns[${column}]}
      do
        ItemLen=${#item}
        if [ $ItemLen -gt $ColumnWidth ]; then
          ColumnWidth=$((ItemLen+3))           # Longest item plus spaces between columns
        fi
      done
      if [ $((PageWidth+ColumnWidth+1)) -lt $terminal_width ]; then # Page is not full
        PageWidth=$((PageWidth+ColumnWidth+1)) # Add column width to page width accumulator
        Page="$Page $column"                   # and append the column number to this page
      fi
      if [ $column -eq $NumberOfColumns ]; then # Last column
        LastPage=$PageNumber
        PageWidths[${PageNumber}]=$PageWidth
        Pages[${PageNumber}]="${Page}"          # Copy the list of columns to Pages array
        break 2
      fi
    done
  done

  PageNumber=1    # Start at first page
  SelectPage      # Switch between pages
}

SelectPage() {
  while :
  do
    # Display appropriate page according to user input
    case $PageNumber in
    1) if [ $LastPage -gt 1 ]; then   # On page 1, with more than 1 page in total
        Instructions="$Next - $Advise"
      else
        Instructions="$Advise"
      fi
      InstrLen=${#Instructions}
      PrintPage
      case $? in                       # Return will be 0, 1, or 2
      1) PageNumber=$PageNumber        # < (left arrow) = illegal call to previous page
      ;;
      2) if [ $LastPage -gt 1 ]; then  # On page 1, with more than 1 page in total
          PageNumber=$((PageNumber+1)) # > (right arrow) = next page
        else
          PageNumber=$PageNumber       # > (right arrow) = illegal call to next page
        fi
      ;;
      *) break                        # 0 : an item was selected or 'Exit' entered
      esac
    ;;
    $LastPage) Instructions="$Previous - $Advise"
      InstrLen=${#Instructions}
      PrintPage
      case $? in                      # Return will be 0, 1, or 2
      1) PageNumber=$((PageNumber-1)) # < (left arrow) = previous page
      ;;
      2) PageNumber=$PageNumber        # > (right arrow) = illegal call to next page
      ;;
      *) break                        # 0 : an item was selected or 'Exit' entered
      esac
    ;;
    *) Instructions="$Previous - $Advise - $Next"
      InstrLen=${#Instructions}
      PrintPage
      case $? in                          # Return will be 0, 1, or 2
      1) if [ $PageNumber -gt 1 ]; then   # Not on page 1
          PageNumber=$((PageNumber-1))    # < (left arrow) = previous page
        else
          PageNumber=$PageNumber          # < (left arrow) = illegal call to previous page
        fi
      ;;
      2) if [ $PageNumber -lt $LastPage ]; then   # Not on last page
        PageNumber=$((PageNumber+1))      # > (right arrow) = next page
      else
        PageNumber=$PageNumber            # > (right arrow) = illegal call to next page
      fi
      ;;
      *) break                            # 0 : an item was selected or '' entered
      esac
    esac
  done
}

PrintPage() {
  Heading
  if [ "$Headline" ]; then
    first_item "${Headline}" "${#Headline}"
  fi
  ThisPage="${Pages[${PageNumber}]}"            # String of column numbers for this page
  PageWidth=${PageWidths[${PageNumber}]}        # Full width of this page
  column_start=$(( terminal_centre - (PageWidth/2) -3 ))
  cursor_row=$top_row                           # Start at top row
  local Counter
  while :
  do
    local Counter=1
    for column in ${ThisPage}                   # Outer loop iterates through columns for $ThisPage
    do                                          # getting the column numbers
      ColumnWidth=${ColumnWidths[${column}]}
      if [ -z "$ColumnWidth" ]; then
        continue
      fi
      for item in ${Columns[${column}]}         # Inner loop iterates through contents of columns
      do
        tput cup $cursor_row $column_start      # Move cursor to print point
        printf "%-s\n" "${Counter}) $item"
        if [ $item = $LastItem ]; then
          break
        fi
        cursor_row=$((cursor_row+1))
        Counter=$((Counter+1))
      done
      column_start=$((column_start+ColumnWidth+2))  # Start next column
      cursor_row=$top_row                           # ... at top row
    done

    InstrLen=$((InstrLen/2))
    tput cup $((terminal_height-2)) $((terminal_centre-InstrLen)) # Position cursor at bottom of screen
    Echo "${Instructions}"
    tput cup $((bottom_row+1)) 0                    # Then back to row below bottom row
    TPread "${Message}: "
    case $Response in
    '') Result=""
      return 0                                    # Quit without selecting anything
    ;;
    "<") return 1                                   # Previous page, if valid
    ;;
    ">") return 2                                   # Next page, if valid
    ;;
    *[!0-9]*) Heading
      if [ "$Headline" ]; then
        first_item "${Headline}"
      fi
      ThisPage="${Pages[${PageNumber}]}"            # String of column numbers for this page
      PageWidth=${PageWidths[${PageNumber}]}        # Full width of this page
      column_start=$(( terminal_centre - (PageWidth/2) -3 ))
      cursor_row=$top_row                           # Start at top row
      continue
    ;;
    *) Counter=0                            # Find the numbered item in the columns of this page
      for column in ${ThisPage}             # Outer loop iterates through $ThisPage
      do
        for item in ${Columns[${column}]}   # Inner loop iterates through $Columns[@] for this page
        do
          Counter=$((Counter+1))
          if [ $Counter -eq $Response ]; then
            Result=$item
            return 0
          fi
        done
      done
    esac
  done
}
