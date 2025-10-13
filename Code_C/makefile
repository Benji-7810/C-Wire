# Compiler settings
CC = gcc                        # Compiler used
CFLAGS = -Wall -lm              # Compilation flags: show all warnings and link math library
TARGET = c-wire_exe             # Name of the final executable
SRC = main.c avl.c              # Source files to compile
MEMORY = -fsanitize=address -g  # Memory sanitizer for debugging and debug symbols


# Default target: clean and compile the source files
all: exe

# Compile the source files into an executable 
exe:
	@$(CC) $(MEMORY) $(CFLAGS) $(SRC) -o $(TARGET)  # Suppress command display with '@'
	@chmod +x $(TARGET)  # Add execution rights to the generated executable 
	@echo "\e[32mCompilation completed successfully. Executable generated: $(TARGET)\e[0m"
	

# Clean up temporary files and the executable
clean:
	@rm -f $(TARGET)  # Remove the executable file
	@echo "Deleted executable: $(TARGET)"

# Mark targets as phony to prevent conflicts with file names
.PHONY: all clean exe
