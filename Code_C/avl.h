#ifndef AVL_H
#define AVL_H

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <string.h>

// AVL tree structure
typedef struct avl_tree {
    struct avl_tree* right_child; // Pointer to the right child
    struct avl_tree* left_child;  // Pointer to the left child
    unsigned long int value;               // Node value
    unsigned int balance;                  // Balance factor
    unsigned long int stock;               // Stock value
    unsigned long int consumption;         // Consumption value
} avl_tree;


// Function to create a new node in the AVL tree
avl_tree* create_node(int value);

// Function to calculate the maximum of two integers
int maximum(int a, int b);

// Function to calculate the minimum of two integers
int minimum(int a, int b);

// Function to calculate the minimum of three integers
int minimum_of_three(int a, int b, int c);

// Function to calculate the maximum of three integers
int maximum_of_three(int a, int b, int c);

// Left rotation to balance the AVL tree
avl_tree* left_rotation(avl_tree* node);

// Right rotation to balance the AVL tree
avl_tree* right_rotation(avl_tree* node);

// Double left rotation for AVL balancing
avl_tree* double_left_rotation(avl_tree* node);

// Double right rotation for AVL balancing
avl_tree* double_right_rotation(avl_tree* node);

// Function to balance the AVL tree
avl_tree* balance_avl_tree(avl_tree* node);

// Function to insert a value into the AVL tree
avl_tree* insert_avl(avl_tree* node, int value, int* height_change);

// Function to find a node in the AVL tree by value
avl_tree* find_node(avl_tree* node, int value);

// Function to print stock and consumption values in order
void print_stock(avl_tree* node);

// Function to delete all nodes in the AVL tree
void delete_tree(avl_tree* node);

#endif // AVL_H
