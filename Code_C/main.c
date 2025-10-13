#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <time.h>
#include "avl.h"

// Return value
#define SUCCESS 0
#define ERROR_INPUT 1
#define ERROR_MEMORY 2

// Function to print an error message and return the program
int error(int code, avl_tree *root, int count_line) {
    if (code == ERROR_INPUT) {
        // Display an error message with line number in the terminal
        fprintf(stderr, "Error: Invalid input. Only long integers are accepted. Check line %d in the file 'file_filter.csv' located in the tmp directory\n", count_line);

        // Display the error message in the file 
        printf("Error: Invalid input. Only long integers are accepted. Check line %d in the file 'file_filter.csv' located in the tmp directory\n", count_line);

    } else if (code == ERROR_MEMORY) {
        // Display an error message with line number in the terminal
        fprintf(stderr, "Error: Memory allocation failed.Check line %d in the file 'file_filter.csv' located in the tmp directory\n", count_line);

        // Display the error message in the file
        printf("Error: Memory allocation failed. Check line %d in the file 'file_filter.csv' located in the tmp directory\n", count_line);
    }

    if (root != NULL) { // Free memory if the tree is not empty
        delete_tree(root);
    }

    return code; // Stop the program and return the error code
}

// Function to check if the input is a valid integer
int validate_input(char *input, avl_tree *root, int count_line) {
    if (input == NULL || *input == '\0') { // If input is empty
        return error(ERROR_INPUT, root, count_line);
    }

    // Check each character in the input
    int i = 0;
    if (input[0] == '-' || input[0] == '+') { // First character can be a sign
        i++;
    }

    for (; input[i] != '\0' && input[i] != '\n'; i++) {
        if (!isdigit(input[i])) { // If any character is not a number
            return error(ERROR_INPUT, root, count_line);
        }
    }

    return SUCCESS; // Return SUCCESS if input is valid
}

int main() {

    avl_tree *tree = NULL; // Root of the AVL tree
    int height_change = 0; // Variable to track if the height changed
    char line[256];        // Buffer to read lines from input
    char *token;           // Pointer to split strings
    long int value, stock, consumption;
    int count_line = 0;
    
    // Read input line by line
    while (fgets(line, sizeof(line), stdin)) {
        count_line++;

        if (line[0] == '\0') { // Alternatively, handle an empty line
            error(ERROR_INPUT, tree, count_line);
            return ERROR_INPUT; // Stop if empty line is found
        }

        // Get and check the first value (value)
        token = strtok(line, ";");
        if (validate_input(token, tree, count_line) != SUCCESS) {
            return ERROR_INPUT; // Return if input validation fails
        }
        value = atol(token); // Convert the string to a long integer

        // Get and check the second value (stock)
        token = strtok(NULL, ";");
        if (validate_input(token, tree, count_line) != SUCCESS) {
            return ERROR_INPUT; // Return if input validation fails
        }
        stock = atol(token);

        // Get and check the third value (consumption)
        token = strtok(NULL, ";");
        if (validate_input(token, tree, count_line) != SUCCESS) {
            return ERROR_INPUT; // Return if input validation fails
        }
        consumption = atol(token);

        // Check if the value already exists in the tree
        avl_tree *node = find_node(tree, value);

        if (node != NULL) {
            // If the value exists, update its stock and consumption
            node->stock += stock;
            node->consumption += consumption;
        } else {
            // If the value does not exist, insert it into the tree
            tree = insert_avl(tree, value, &height_change);
            if (tree == NULL) { // If memory allocation fails
                error(ERROR_MEMORY, tree, count_line);
                return ERROR_MEMORY;
            }
            // After insertion, find the new node and initialize its stock and consumption
            node = find_node(tree, value);
            if (node != NULL) {
                node->stock = stock;
                node->consumption = consumption;
            }
        }
    }

    // Print the stock and consumption values in the tree
    print_stock(tree);
    fprintf(stderr, "All is good in the program C. Processing...\n");

    // Free all the memory used by the tree
    delete_tree(tree);
    tree = NULL; // Set root to NULL to avoid errors

    return SUCCESS; // Exit the program successfully
}
