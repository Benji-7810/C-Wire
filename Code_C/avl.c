#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <string.h>
#include "avl.h"

// Function to create a new node in the AVL tree
avl_tree* create_node(int value) {
    avl_tree* node = malloc(sizeof(avl_tree));
    if (node == NULL) {
        exit(1);
    }
    node->right_child = NULL; // Right subtree
    node->left_child = NULL;  // Left subtree
    node->value = value;      // Node's value
    node->balance = 0;        // Balance factor
    node->stock = 0;          // Stock value
    node->consumption = 0;    // Consumption value
    return node;
}

// Function to calculate the maximum of two integers
int maximum(int a, int b) {
    return (a > b) ? a : b;
}

// Function to calculate the minimum of two integers
int minimum(int a, int b) {
    return (a < b) ? a : b;
}

// Function to calculate the minimum of three integers
int minimum_of_three(int a, int b, int c) {
    return minimum(minimum(a, b), c);
}

// Function to calculate the maximum of three integers
int maximum_of_three(int a, int b, int c) {
    return maximum(maximum(a, b), c);
}

// Left rotation to balance the AVL tree
avl_tree* left_rotation(avl_tree* node) {
    if (node == NULL) {
        exit(1);
    }

    int balance_node = 0;
    int balance_pivot = 0;

    avl_tree* pivot = node->right_child; // Right child as pivot
    node->right_child = pivot->left_child; // Reorganize pointers
    pivot->left_child = node;

    // Update balance factors
    balance_node = node->balance;
    balance_pivot = pivot->balance;

    node->balance = balance_node - maximum(balance_pivot, 0) - 1;
    pivot->balance = minimum_of_three(balance_node - 2, (balance_node + balance_pivot - 2), balance_pivot - 1);

    return pivot;
}

// Right rotation to balance the AVL tree
avl_tree* right_rotation(avl_tree* node) {
    if (node == NULL) {
        exit(1); // Cannot rotate a NULL node
    }

    int balance_node = 0;
    int balance_pivot = 0;

    avl_tree* pivot = node->left_child;     // Left child as pivot
    node->left_child = pivot->right_child; // Reorganize pointers
    pivot->right_child = node;             // Make node the right child

    // Update balance factors
    balance_node = node->balance;
    balance_pivot = pivot->balance;

    node->balance = balance_node - minimum(balance_pivot, 0) + 1;
    pivot->balance = maximum_of_three(balance_node + 2, (balance_node + balance_pivot + 2), balance_pivot + 1);

    return pivot; // Pivot becomes the new root
}

// Double left rotation for AVL balancing
avl_tree* double_left_rotation(avl_tree* node) {
    if (node == NULL || node->right_child == NULL) {
        exit(1);
    }
    node->right_child = right_rotation(node->right_child); // Right rotation on the right child
    return left_rotation(node);                            // Left rotation on the current node
}

// Double right rotation for AVL balancing
avl_tree* double_right_rotation(avl_tree* node) {
    if (node == NULL || node->left_child == NULL) {
        exit(1);
    }
    node->left_child = left_rotation(node->left_child);  // Left rotation on the left child
    return right_rotation(node);                         // Right rotation on the current node
}

// Function to balance the AVL tree
avl_tree* balance_avl_tree(avl_tree* node) {
    if (node == NULL) {
        return NULL;
    }
    if (node->balance >= 2) {
        if (node->right_child != NULL && node->right_child->balance >= 0) {
            return left_rotation(node);
        } else if (node->right_child != NULL) {
            return double_left_rotation(node);
        }
    } else if (node->balance <= -2) {
        if (node->left_child != NULL && node->left_child->balance <= 0) {
            return right_rotation(node);
        } else if (node->left_child != NULL) {
            return double_right_rotation(node);
        }
    }

    return node; // No balancing needed
}

// Function to insert a value into the AVL tree
avl_tree* insert_avl(avl_tree* node, int value, int* height_change) {

    if (node == NULL) {
        *height_change = 1;
        return create_node(value); // Create a new node if the tree is empty
    }

    // research the value
    if (value < node->value) {
        node->left_child = insert_avl(node->left_child, value, height_change);
        *height_change = -*height_change;
    }

    // research the value
    else if (value > node->value) {
        node->right_child = insert_avl(node->right_child, value, height_change);
    } 

    else {
        *height_change = 0;
        return node; // Duplicate values are not allowed in AVL trees
    }

    if (*height_change != 0) {
        node->balance = node->balance + *height_change;
        node = balance_avl_tree(node); // Balance the tree
        if (node->balance == 0) {
            *height_change = 0;
        } else {
            *height_change = 1;
        }
    }

    return node;
}

// Function to find a node in the AVL tree by value
avl_tree* find_node(avl_tree* node, int value) {

    //value not found
    if (node == NULL) {
        return NULL;
    }
    
    // value found
    if (node->value == value) {
        return node;

    // research the value
    } else if (value < node->value) {
        return find_node(node->left_child, value);

    // research the value
    } else {
        return find_node(node->right_child, value);
    }
}

// Function to print stock and consumption values in order
void print_stock(avl_tree* node) {
    if (node == NULL) {
        return;
    }
    print_stock(node->left_child);
    printf("%ld: %ld: %ld\n", node->value, node->stock, node->consumption);
    print_stock(node->right_child);
}

// Function to delete all nodes in the AVL tree
void delete_tree(avl_tree* node) {
    if (node == NULL) {
        return;
    }
    // Recursively delete left and right subtrees
    delete_tree(node->left_child);
    delete_tree(node->right_child);

    // Free the current node
    free(node);
}
