#!/bin/bash
# Doxygen input filter for SQL files
# Converts SQL-style comments (--!) to C++-style comments (//!)

sed 's/^--!/\/\/!/g' "$1"
