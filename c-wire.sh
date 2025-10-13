#!/bin/bash

# Constants (unchangeable values)
readonly RESULT_FILE=resultat.csv          # The output file where results will be saved
readonly C_WIRE_EXE=c-wire_exe             # The name of the program to run
readonly TEST_DIRECTORY="tests"            # The folder where test results will be saved
readonly TMP_DIRECTORY="tmp"  
readonly LAST_DIRECTORY="last_result"              




# Write text in red
echo_red() {
    printf "\e[31m%s\e[0m\n" "$1"
}

# Write text in green
echo_green() {
    printf "\e[32m%s\e[0m\n" "$1"
}


# Create the "tests" folder if it doesn't exist.
if [ ! -d "$TEST_DIRECTORY" ]; then
    mkdir "$TEST_DIRECTORY"
    echo_green "Directory '$TEST_DIRECTORY' created."
    echo " "
fi

# Check if the "tmp" directory exists
if [ -d "$TMP_DIRECTORY" ]; then
    # If the directory exists, empty it
    rm -rf $TMP_DIRECTORY/*
else
    # If the directory doesn't exist, create it
    mkdir $TMP_DIRECTORY
    echo_green "Directory '$TMP_DIRECTORY' created."
    echo " "
fi


# Check if the "last_result" directory exists
if [ -d "$LAST_DIRECTORY" ]; then
    # If the directory exists, move its content to TEST_DIRECTORY
    mkdir -p "$TEST_DIRECTORY"  # Ensure TEST_DIRECTORY exists
    mv "$LAST_DIRECTORY"/* "$TEST_DIRECTORY"/ 2>/dev/null
    
    # Confirm LAST_DIRECTORY is now empty
   
else
    # If the directory doesn't exist, create it
    mkdir "$LAST_DIRECTORY"
    echo_green "Directory '$LAST_DIRECTORY' created."
    echo " "
fi



timer() {
  local timer_name=$1
  local action=$2

  # Check if the timer name and action are provided
  if [[ -z "$timer_name" || -z "$action" ]]; then
    echo "Usage: timer <timer_name> <start|echo>"
    return 1
  fi

  # Variable to store the start time
  local start_time_var="TIMER_${timer_name}"

  # Function to get the current time in nanoseconds (compatible with macOS/Linux)
  get_time_ns() {
    if command -v gdate &> /dev/null; then
      # Use GNU date if available (Linux/with Homebrew on macOS)
      gdate +%s%N
    elif [[ "$(uname)" == "Darwin" ]]; then
      # For macOS without GNU date
      local seconds=$(date +%s)
      local nanoseconds=$(date +%N 2>/dev/null || echo 0) # macOS sometimes returns an error for %N
      echo "$((seconds * 1000000000 + nanoseconds))"
    else
      # For Linux with date +%s%N
      date +%s%N
    fi
  }

  case $action in
    start)
      # Save the current time in nanoseconds
      eval "${start_time_var}=$(get_time_ns)"
      ;;
    echo)
      # Retrieve the stored start time
      local start_time
      eval "start_time=\${${start_time_var}}"
      if [[ -z "$start_time" ]]; then
        echo "Timer '$timer_name' has not been started. Use 'timer $timer_name start' first."
        return 1
      fi

      # Calculate the elapsed time
      local current_time=$(get_time_ns)
      local elapsed=$((current_time - start_time))

      # Convert elapsed time to seconds and milliseconds
      local seconds=$((elapsed / 1000000000))  # seconds
      local milliseconds=$(( (elapsed % 1000000000) / 1000000 ))  # milliseconds

      # Print the formatted result
      printf "%s : %d.%03d s\n" "$timer_name" "$seconds" "$milliseconds"
      ;;
    *)
      echo "Invalid action: $action. Use 'start' or 'echo'."
      return 1
      ;;
  esac
}


correct_entire() {

    # start of filter timer
    timer Check_the_existence_of_the_ID_"$2"_power_station start

    

    local fichier="$1"
    local motif="$2"

    # check if the ID power_sation exist
    if grep -q "^${motif};" "$fichier"; then
        timer Check_the_existence_of_the_ID_"$2"_power_station echo
        echo_green "YES"
        echo " "
        
    else
        # doesn't exist
        timer Check_the_existence_of_the_ID_"$2"_power_station echo
        echo_red "No central with ID: '$motif'"
        timer Total_duration echo
        exit 1
    fi


}





# Function to run a task with filters
process_file() {
    local expression="$1"
    local columns="$2"
    local source_file="$3"
    
    # Define the directory path for Code_C
    CODE_DIR="Code_C"

    # Check if the file "c-wire_exe" exists in the "Code_C" directory
    if [ ! -f "$CODE_DIR/$C_WIRE_EXE" ]; then
        echo "$C_WIRE_EXE does not exist, compiling..."
        make -C "$CODE_DIR" 
    fi

    # Check again if "c-wire_exe" exists after compilation attempt
    if [ ! -f "$CODE_DIR/$C_WIRE_EXE" ]; then
        echo "Error: Compilation failed. Please check your source files and Makefile."

        # Start the total time timer
        timer Total_duration echo

        exit 1
    fi


    # start of filter timer
    timer Total_filtering_time_large_file start

    # 1 - cut the first line of the file    
    # 2 - cut and retrieve the correct line based on the user's command
    # 3 - replace all the '-' per '0' to make it easier to caculate afterwards
    # 4 - retrieve the correct columns
    tail -n+2 "$source_file" \
        | awk -F';' -v num="$num" "$expression" \
        | tr '-' '0' \
        | cut -d ';' -f "$columns" > $TMP_DIRECTORY/file_filter.csv


    # Show the filter time
    timer Total_filtering_time_large_file echo
    echo " "
    

    # start of program c timer
    timer Total_duration_of_the_programme_c start

    # send the correct file to the C program and write the result of the C program to `$RESULT_FILE`
    cat  $TMP_DIRECTORY/file_filter.csv | ./Code_C/${C_WIRE_EXE} >> "$RESULT_FILE"

    RESULTAT_CODE=$?

    # Show the program c time.
    timer Total_duration_of_the_programme_c echo
    echo " "


    ## do this command if you want to save time because we don't need to make an intermediate file 
    ###################################
    #  tail -n+2 "$source_file" \
    #     | awk -F';' -v num="$num" "$expression" \
    #     | tr '-' '0' \
    #     | cut -d ';' -f "$columns" \
    #     | ./Code_C/${C_WIRE_EXE} >> "$RESULT_FILE"


}



# Function to show help 
function_help() {
   
    timer Total_duration start 

    echo "--------------------------------------"
    echo_green "--   C-WIRE Command line HELP       --"
    echo "--------------------------------------"
    echo " "
    echo "Syntax mandatory"
    echo ": $0  input/SOURCE_FILE_csv  'hva'|'hvb'|'lv'  'comp'|'all'|'indiv' "
    echo " "
    echo "Here are the parameters for the script in order:"
    echo "1. Path to the input CSV file with data"
    echo "2. Type of station to process: 'hva', 'hvb', or 'lv'"
    echo "3. Type of consumer to process: comp (companies), indiv (individuals), all (everyone)"
    echo "   just 'comp' are accepted for 'hva' and 'hvb'"
    echo "4. (Optional) Filter by specific cenral ID (integer)"
    echo "5. (Optional) '-h' : Shows this help"
    
    echo " "
    echo "You can use 'minmax' for lv all to show only the 10 LV stations with the highest and lowest consumption."
    echo " "
    echo "Example usage:"
    echo "./c-wire.sh input/SOURCE_FILE.dat hvb comp"
    echo "./c-wire.sh input/SOURCE_FILE.dat hva comp 4"
    echo "./c-wire.sh input/SOURCE_FILE.dat lv indiv 4"
    echo "./c-wire.sh input/SOURCE_FILE.dat lv all minmax 8"
    echo "./c-wire.sh -h" 
    echo " "

    timer Total_duration echo 
    exit 1
    
}


# Check if user asks for help with -h or --help
if [ "$1" == "-h" ] || [ "$2" == "-h" ] || [ "$3" == "-h" ] || [ "$4" == "-h" ] || [ "$5" == "-h" ] || [ "$1" == "--help" ] || [ "$2" == "--help" ] || [ "$3" == "--help" ] || [ "$4" == "--help" ] || [ "$5" == "--help" ]; then
    function_help
    exit
fi



function_too_many_arguments() {

    # Check if $4 is "minmax"
    if [ "$4" == "minmax" ]; then
        if [ "$#" -gt 5 ]; then  # More than 5 arguments in total
            echo_red "Too many parameters"
            function_help
            return 1
        fi
    else
        # Check if $4 isn't "minmax"
        if [ "$#" -gt 4 ]; then  # More than 4 arguments in total
            echo_red "Error: Too many parameters."
            function_help
            return 1
        fi
    fi

    # Check if there are fewer than 4 parameters
    if [ "$#" -lt 3 ]; then
        echo_red "Error: Not enough parameters !!"
        function_help
        return 1
    fi
}


# count how many there are arguments. Display error message if there are too many
function_too_many_arguments "$@"


check_csv_lines() {
  local file=$1

  # Check if the file exists
  if [ ! -f "$file" ]; then
    echo "The file $file does not exist."
    return 1
  fi

  # Check if the file contains at least 3 lines
  if [ $(wc -l < "$file") -ge 3 ]; then
    return 0  # Return 0 if the file contains at least 3 lines
  else
    echo_red "No station is in overconsumption."
    rm $file
    # Start the total time timer
    timer Total_duration echo
    exit 1
    # Return 1 if the file contains fewer than 3 lines
  fi
}



# Start the total time timer
timer Total_duration start


# Check if the source file exists
if [ -f "$1" ]; then

    # Source file exists, assign it to the variable
    source_file="$1"
    
    # Check if the second parameter is one of the valid options (hvb, hva, lv)
    case "$2" in
        "hvb")
            # Handle the 'hvb' case
            echo "Secondary condition verified: hvb"
            
            # Check if the third parameter is 'comp'
            if [[ "$3" == "comp" ]]; then

                echo "Third condition verified: comp"
                echo " "

                # Create the result file with column headers for "HV-B" station
                echo "Station HV-B : Capacity : Consumption (company)" > $RESULT_FILE

                # Check if the fourth parameter is a valid integer or empty
                if [[ "$4" =~ ^[0-9]+$ || -z "$4" ]]; then
                    num="$4"
                    

                    # If no optional parameter is provided
                    if [[ -z "$4" ]]; then
                        
                        # Call the function for processing the file with specific column indices
                        process_file '($2 != "-" && $3 == "-")' "2,7,8" "$source_file"
                       
                        # sort with capacity and rename the file
                        sort -t':' -k2 -n "$RESULT_FILE" > "$LAST_DIRECTORY/hvb_comp.csv"
                
                        echo "File 'hvb_comp.csv' is created"
                    
                    else
                        correct_entire $1 $4
                        # Call the function with the specified integer in the filter
                        process_file '($2 != "-" && $3 == "-" && $1 ~ "^" num)' "2,7,8" "$source_file"
                        # sort with capacity and rename the file
                        sort -t':' -k2 -n "$RESULT_FILE" > "$LAST_DIRECTORY/hvb_comp_$4.csv"
                        echo "File 'hvb_comp_$4.csv' is created"
                    fi
                else
                    # Invalid fourth parameter case
                    echo_red "The fourth parameter is not a valid integer"
                    function_help
                fi
            else
                # Invalid third parameter case
                echo_red "The third parameter must be 'comp'"
               function_help
            fi
            ;;


        "hva")
            # Handle the 'hva' case: High Voltage A station
            echo "Secondary condition verified: hva"

            # Check if the third parameter is 'comp' (company mode)
            if [[ "$3" == "comp" ]]; then

                echo "Third condition verified: comp"
                echo " "

                # Add headers for the result file for HV-A processing
                echo "Station HV-A : Capacity : Consumption (company)" > $RESULT_FILE

                # Validate the fourth parameter (integer or empty)
                if [[ "$4" =~ ^[0-9]+$ || -z "$4" ]]; then
                    num="$4"

                    # If no optional parameter is provided
                    if [[ -z "$4" ]]; then
                        
                        process_file '($2 != "-" && $3 != "-" && $7 != "-") || ($2 == "-" && $3 != "-" && $5 != "-")' "3,7,8" "$source_file"
                        
                        sort -t':' -k2 -n "$RESULT_FILE" > "$LAST_DIRECTORY/hva_comp.csv"
                       
                        echo "File 'hva_comp.csv' is created"
                    
                    else
                        correct_entire $1 $4
                        # Process the file with additional filtering based on integer parameter
                        process_file '($2 != "-" && $3 != "-" && $7 != "-" && $1 ~ "^" num) || ($2 == "-" && $3 != "-" && $5 != "-" && $1 ~ "^" num)' "3,7,8" "$source_file"

                        sort -t':' -k2 -n "$RESULT_FILE" > "$LAST_DIRECTORY/hva_comp_$4.csv"  
                        echo "File 'hva_comp_$4.csv' is created"
                    fi
                else
                    # Invalid fourth parameter case
                    echo_red "The fourth parameter is not a valid integer"
                   function_help
                fi
            else
                # Invalid third parameter case
                echo_red "The third parameter must be 'comp'"
               function_help
            fi
            ;;

        "lv")
            # Handle the 'lv' case (Low Voltage processing)
            echo "Secondary condition verified: lv"
            
            # Check the third parameter: 'comp', 'indiv', 'all', or 'minmax'
            if [ "$3" == "comp" ]; then

                # Case: 'comp' - Process company-related data for LV
                echo "Third condition verified: comp"
                echo " "

                
                echo "Station LV : Capacity : Consumption (company)" > $RESULT_FILE
                
                # Check if the fourth parameter is an integer or empty
                if [[ "$4" =~ ^[0-9]+$ || -z "$4" ]]; then
                    if [[ -z "$4" ]]; then
                    
                        # Process file with specific conditions for 'comp'
                        process_file '($2 == "-" && $3 != "-" && $4 != "-" && $5 == "-") || ($2 == "-" && $3 == "-" && $4 != "-" && $5 != "-")' "4,7,8" "$source_file"
                        # Rename the result file
                       
                        sort -t':' -k2 -n "$RESULT_FILE" > "$LAST_DIRECTORY/lv_comp.csv"  
                        
                        echo "File 'lv_comp.csv' is created"
                    else
                       
                        num="$4"
                        correct_entire $1 $4
                        process_file "(\$2 == \"-\" && \$3 != \"-\" && \$4 != \"-\" && \$5 == \"-\" && \$1 ~ \"^$num\") || (\$2 == \"-\" && \$3 == \"-\" && \$4 != \"-\" && \$5 != \"-\" && \$1 ~ \"^$num\")" "4,7,8" "$source_file"
                       
                        sort -t':' -k2 -n "$RESULT_FILE" > "$LAST_DIRECTORY/lv_comp_$4.csv"  
                        echo "File 'lv_comp_$4.csv' is created"
                    fi
                else
                    # Invalid fourth parameter (not an integer)
                    echo_red "The fourth parameter is not a valid integer"
                   function_help
                fi
            
            elif [ "$3" == "indiv" ]; then

                # Case: 'indiv' - Process individual-related data for LV
                echo "Third condition verified: indiv"
                echo " "
                
                echo "Station LV : Capacity : Consumption (individual)" > $RESULT_FILE
                
                
                # Check if the fourth parameter is an integer or empty
                if [[ "$4" =~ ^[0-9]+$ || -z "$4" ]]; then
                    if [[ -z "$4" ]]; then
                        
                        # Process file with specific conditions for 'indiv'
                        process_file '($2 == "-" && $3 != "-" && $4 != "-" && $5 == "-") || ($2 == "-" && $3 == "-" && $4 != "-" && $5 == "-" && $6 != "-")' "4,7,8" "$source_file"
        
                        sort -t':' -k2 -n "$RESULT_FILE" > "$LAST_DIRECTORY/lv_indiv.csv" 
                       
                        echo "File lv_indiv.csv is created"

                    else
                        # Fourth parameter is an integer
                        num="$4"
                        correct_entire $1 $4
                        # Process file with specific conditions for 'indiv'
                        process_file "(\$2 == \"-\" && \$3 != \"-\" && \$4 != \"-\" && \$5 == \"-\" && \$1 ~ \"^$num\") || (\$2 == \"-\" && \$3 == \"-\" && \$4 != \"-\" && \$6 != \"-\" && \$1 ~ \"^$num\")" "4,7,8" "$source_file"
                      
                        # Sort the result and directly overwrite the original file
                        sort -t':' -k2 -n "$RESULT_FILE" > "$LAST_DIRECTORY/lv_indiv_$4.csv"
                        
                        echo "File 'lv_indiv_$4.csv' is created"
                    fi
                else
                    # Invalid fourth parameter
                    echo_red "The fourth parameter is not a valid integer"
                    function_help
                fi
            
            elif [ "$3" == "all" ]; then

                # Case: 'all' - Process all data for LV
                echo "Third condition verified: all"
                echo " "
            
                echo "Station LV : Capacity : Consumption (all)" > $RESULT_FILE

                # Handle 'minmax' option for extreme nodes
                if [ "$4" == "minmax" ]; then
                    echo "Option 'minmax' detected"
                    if [[ "$5" =~ ^[0-9]+$ || -z "$5" ]]; then
                    # Check if the fifth parameter is empty or provided
                        if [[ -z "$5" ]]; then
                           
                            process_file '($2 == "-" && $3 != "-" && $4 != "-" && $5 == "-") || ($2 == "-" && $3 == "-" && $4 != "-" && ($5 != "-" || $6 != "-"))' "4,7,8" "$source_file"
                                            
                            # start of filter_for_minmax timer
                            timer Filter_minmax start

                            # Extract extreme values for capacity and consumption
                            echo "Min and Max 'capacity-load' extreme nodes" > $LAST_DIRECTORY/lv_all_minmax.csv
                            echo "Station LV : Capacity : Consumption (all)" >> $LAST_DIRECTORY/lv_all_minmax.csv


                            # 1 - create a fourth line with the difference beetween column 3 and 2 and keep juste the positif value     
                            # 2 - sorting in relation to the fourth column
                            # 3 - keeps only the first 3 columns
                            # 4 - keeps the 10 last and first line  
                            # 5 - awk for delete doublon      
                            awk -F':' 'NR > 1 { diff = $3 - $2; if (diff > 0) print $1 ":" $2 ":" $3 ":" diff }' "$RESULT_FILE" | \
                            sort -t':' -k4,4nr | \
                            cut -d ':' -f 1,2,3 | \
                            ( head -n 10; tail -n 10 ) | \
                            awk '!seen[$0]++' >> "$LAST_DIRECTORY/lv_all_minmax.csv"

                            # check if the files isn't empty
                            check_csv_lines $LAST_DIRECTORY/lv_all_minmax.csv

                            # renome the final file
                            mv "$RESULT_FILE" "$TMP_DIRECTORY/$RESULT_FILE"
                            
                           
                            # start of filter_for_minmax timer
                            timer Filter_minmax echo
                            echo "File 'lv_all_minmax.csv' is created"
                            echo " "
                           
                        else
                            # Fifth parameter is an integer
                            num="$5"
                            correct_entire $1 $5
                            process_file "(\$2 == \"-\" && \$3 != \"-\" && \$4 != \"-\" && \$5 == \"-\" && \$1 ~ \"^$num\") || (\$2 == \"-\" && \$3 == \"-\" && \$4 != \"-\" && (\$5 != \"-\" || \$6 != \"-\") && \$1 ~ \"^$num\")" "4,7,8" "$source_file"
                            
                            # start of filter_for_minmax timer
                            timer Filter_minmax start


                            # Extract extreme values with the integer condition
                            echo "Min and Max 'capacity-load' extreme nodes" > $LAST_DIRECTORY/lv_all_minmax_$5.csv
                            echo "Station LV : Capacity : Consumption (all)" >> $LAST_DIRECTORY/lv_all_minmax_$5.csv

                            # 1 - create a fourth line with the difference beetween column 3 and 2 and keep juste the positif value     
                            # 2 - sorting in relation to the fourth column
                            # 3 - keeps only the first 3 columns
                            # 4 - keeps the 10 last and first line  
                            # 5 - awk for delete doublon 
                            awk -F':' 'NR > 1 { diff = $3 - $2; if (diff > 0) print $1 ":" $2 ":" $3 ":" diff }' "$RESULT_FILE" | \
                            sort -t':' -k4,4nr | \
                            cut -d ':' -f 1,2,3 | \
                            ( head -n 10; tail -n 10 ) | \
                            awk '!seen[$0]++' >> "$LAST_DIRECTORY/lv_all_minmax_$5.csv"

                            # check if the files isn't empty
                            check_csv_lines $LAST_DIRECTORY/lv_all_minmax_$5.csv

                             # renome the final file
                            mv "$RESULT_FILE" "$TMP_DIRECTORY/$RESULT_FILE"

                        
                            # start of filter_for_minmax timer
                            timer Filter_minmax echo
                            echo "File 'lv_all_minmax_$5.csv' is created"
                            echo " "

                        fi
                    else
                        # Invalid fourth parameter
                        echo_red "The fourth parameter is not a valid positive integer"
                        function_help
                    fi

                elif [[ "$4" =~ ^[0-9]+$ || (-z "$4" && "$4" != "minmax") ]]; then
                    # Case: 'all' - No 'minmax' option
                    echo "Station LV : Capacity : Consumption (all)" > $RESULT_FILE
                    
                    if [[ -z "$4" ]]; then
                        
                        process_file '($2 == "-" && $3 != "-" && $4 != "-" && $5 == "-") || ($2 == "-" && $3 == "-" && $4 != "-" && ($5 != "-" || $6 != "-"))' "4,7,8" "$source_file"
                        
                        sort -t':' -k2 -n "$RESULT_FILE" > "$LAST_DIRECTORY/lv_all.csv"
                        echo "File 'lv_all.csv' is created"
                        
                    else
                        # Fourth parameter is an integer
                        num="$4"
                        correct_entire $1 $4
                        process_file "(\$2 == \"-\" && \$3 != \"-\" && \$4 != \"-\" && \$5 == \"-\" && \$1 ~ \"^$num\") || (\$2 == \"-\" && \$3 == \"-\" && \$4 != \"-\" && (\$5 != \"-\" || \$6 != \"-\") && \$1 ~ \"^$num\")" "4,7,8" "$source_file"
                        sort -t':' -k2 -n "$RESULT_FILE" > "$LAST_DIRECTORY/lv_all_$4.csv"
                      
                        echo "File 'lv_all_$4.csv' is created"
                    fi
                else
                    # Invalid fourth parameter case
                    echo_red "The fourth parameter is not a valid integer"
                    function_help
                fi
            else
                # Invalid third parameter case
                echo_red "The third parameter must be 'comp', 'indiv', 'all' or 'minmax'"
               function_help
            fi
        ;;

        *)
            # If the second parameter is not recognized
            echo_red "Main condition not recognized: $2"
            function_help
        ;;
    esac
else
    # If the source file is not found
    echo_red "File not found: $1"
    function_help
fi




# Timer function to measure total processing time
timer Total_duration echo
echo " "

if [ "$RESULTAT_CODE" != 0 ]; then 
    echo_red "Bad data"
else 
    echo_green "SUCCESS"
fi
echo " "

