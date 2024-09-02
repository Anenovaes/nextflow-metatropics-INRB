#!/bin/bash

# Store the original directory
original_dir=$(pwd)

# Prompt user for the path to barcode directories
read -p "Enter the path to the directory containing barcode folders (press Enter if it's the current directory): " barcode_path

# If no path is provided, use the current directory
if [ -z "$barcode_path" ]; then
    barcode_path="."
fi

# Change to the specified directory
cd "$barcode_path" || { echo "Error: Unable to change to directory $barcode_path"; exit 1; }

# Create a file to store read counts in the original directory
read_counts_file="$original_dir/read_counts.txt"
echo "Barcode,Read Count" > "$read_counts_file"

# Loop through all directories starting with "barcode"
for dir in barcode*/; do
    # Check if any barcode directories exist
    if [ ! -d "$dir" ]; then
        echo "Error: No barcode directories found in $barcode_path"
        exit 1
    fi

    # Remove trailing slash from directory name
    dir=${dir%/}
    
    # Create the output filename in the original directory
    output_file="$original_dir/${dir}.fastq"
    
    # Concatenate all .fastq files in the directory to the output file in the original directory
    cat "$dir"/*.fastq > "$output_file"
    
    # Count the number of reads (each read in FASTQ starts with @)
    read_count=$(grep -c "^@" "$output_file")
    
    # Append the count to the read counts file
    echo "$dir,$read_count" >> "$read_counts_file"
    
    # Print the count to the console
    echo "Processed $dir: Created ${dir}.fastq with $read_count reads"
done

# Change back to the original directory
cd "$original_dir"

echo "All barcode folders processed. Read counts saved in read_counts.txt"
echo "Summary of read counts:"
cat "read_counts.txt"
