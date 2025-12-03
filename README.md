# Projet C-Wire

This project makes it possible to analyse stations (power stations, HV-A stations, HV-B stations, LV substations) to determine whether they are in a situation of energy overproduction or underproduction, as well as to assess what proportion of their energy is consumed by the customers.

------------------------
# ###########################
#      How to use it        #
# ###########################


1. -**firt import your data source file in input folder then run c-wire.sh**
2. -**add execution rights if necessary : chmod +x c-wire.sh**

## Utilization example:

1. `./c-wire.sh input/SOURCE_FILE.dat hvb comp`
2. `./c-wire.sh input/SOURCE_FILE.dat lv indiv 4`
3. `./c-wire.sh input/SOURCE_FILE.dat lv all minmax 8`

### Explanation
Here are the parameters for the script in order:
1. Path to the input CSV file with data.
2. Type of station to process: `hva`, `hvb`, or `lv`.
3. Type of consumer to process: `comp` (companies), `indiv` (individuals), `all` (everyone).
   Just `comp` is accepted for `hva` and `hvb`.
4. (Optional) Filter by specific central ID (integer).
5. (Optional) `-h`: Shows this help.

### For more explanation and example:
- Write `./c-wire.sh -h` or `./c-wire.sh --help`.

# How does the program work:
All the project is controlled by the shell script **c-wire.sh**, which uses bash commands and the **c-wire_exe**.

### Details
1. Parameters verification by the shell.
2. Filter data in function of the parameters.
3. Send filtered data to executable.
4. Build an AVL tree to compute results.
5. Redirect results to a result file in folder `tests`.

- Temporary files during execution are stored in the directory `tmp`.
- Result files are stored in the folder `last_result`.
- The previous results are stored in the folder `tests`.
- If input file has bad data, there will be an error message. No output result file will be generated.
- If no station is in overconsumption, then no output result file will be generated.
  Example command about overconsumption: `./c-wire.sh input/source_file.dat lv minmax`.

# Source file organization:
- `c-wire.sh`                ---> Main program.
- `/Code_c/main.c`           ---> Source code for building AVL and computing the consumption and capacity.
- `/Code_c/avl.c`            ---> All functions used by `main.c`.


### Directories
- `tmp/`              ---> Is a folder for temporary files. This folder is cleaned before new execution.
- `test/`             ---> Is a folder containing last result files of previous execution.
- `last_result/`      ---> Is a folder that displays the current result file.
- `input/`            ---> Is the directory intended to contain the source files.

## Special command
- `make clean` to delete exe and clean temporary files.






