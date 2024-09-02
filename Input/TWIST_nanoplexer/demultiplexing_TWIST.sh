#!/bin/bash

# Function to get user input and set up directories
setup_directories() {
    input_dir="Input"
    if [ ! -d "$input_dir" ]; then
        read -p "'Input' directory not found. Enter the path to the Input directory: " input_dir
    fi

    fastq_pass_dir="${input_dir}/fastq_pass"
    if [ ! -d "$fastq_pass_dir" ]; then
        echo "Error: fastq_pass directory not found in ${input_dir}"
        exit 1
    fi

    sample_file="${input_dir}/sample_names.csv"
    if [ ! -f "$sample_file" ]; then
        echo "Error: sample_names.csv not found in ${input_dir}"
        exit 1
    fi

    barcodes_dir="${input_dir}/barcodes"
    if [ ! -d "$barcodes_dir" ]; then
        echo "Error: barcodes directory not found in ${input_dir}"
        exit 1
    fi

    csv_file="${barcodes_dir}/barcodes.csv"
    if [ ! -f "$csv_file" ]; then
        echo "Error: barcodes.csv not found in ${barcodes_dir}"
        exit 1
    fi

    nanoplexer_input_dir="${input_dir}/nanoplexer_input"
    if [ ! -d "$nanoplexer_input_dir" ]; then
        mkdir -p "$nanoplexer_input_dir"
    fi

    output_dir="nanoplexer_output"
    if [ ! -d "$output_dir" ]; then
        mkdir -p "$output_dir"
    fi
}

# Function to process CSV and create FASTA file
process_csv() {
    input_file="$csv_file"
    output_file="${nanoplexer_input_dir}/barcodes.fa"

    # Clear the output file if it exists
    > "$output_file"

    # Process the CSV file
    awk -F ';' -v sample_file="$sample_file" '
    BEGIN {
        while (getline < sample_file) {
            split($0, fields, ",")
            samples[fields[2]] = fields[1]  # Well_ID as key, Sample_Name as value
        }
        close(sample_file)
    }
    NR == 1 {
        for (i=1; i<=NF; i++) {
            if ($i ~ /Well_ID/) well_id_col = i
            if ($i ~ /Index_reversed/) index_rev_col = i
            if ($i ~ /Index_forward/) index_fwd_col = i
        }
        if (well_id_col == "" || index_rev_col == "" || index_fwd_col == "") {
            print "Error: Missing required columns in CSV file" > "/dev/stderr"
            print "Found columns: " $0 > "/dev/stderr"
            exit 1
        }
    }
    NR > 1 {
        if ($well_id_col in samples) {
            print ">" $well_id_col > "'$output_file'"
            print $index_fwd_col > "'$output_file'"
            print ">" $well_id_col "_rev" > "'$output_file'"
            print $index_rev_col > "'$output_file'"
        }
    }
    ' "$input_file"

    # Check if any barcodes were found
    if [ ! -s "$output_file" ]; then
        echo "No barcodes found for the specified samples in the input file."
        rm "$output_file"
        exit 1
    fi

    echo "barcodes.fa file has been created successfully in the ${nanoplexer_input_dir} directory."
}

# Function to create dual barcode file with sample names and barcode headers
create_dual_barcode_file() {
    input_file="${nanoplexer_input_dir}/barcodes.fa"
    output_file="${nanoplexer_input_dir}/dual_barcode_TWIST.txt"

    # Clear the output file if it exists
    > "$output_file"

    # Process the FASTA file and create dual barcode file with sample names and barcode headers
    awk -v sample_file="$sample_file" '
    BEGIN {
        FS = "," # Set field separator for sample file
        while (getline < sample_file) {
            samples[$2] = $1 # $2 is Well_ID, $1 is sample name
        }
        close(sample_file)
    }
    /^>/ {
        header = substr($0, 2)  # Remove the ">" from the header
        if (header ~ /_rev$/) {
            rev_header = header
            well_id = substr(header, 1, length(header) - 4)  # Remove "_rev"
            if (fwd_header != "") {
                sample_name = samples[well_id]
                if (sample_name != "") {
                    print sample_name "\t" fwd_header "\t" rev_header > "'$output_file'"
                }
                fwd_header = ""
            }
        } else {
            fwd_header = header
        }
    }
    ' "$input_file"

    echo "dual_barcode_TWIST.txt file has been created successfully in the ${nanoplexer_input_dir} directory."
}

# Updated function to handle both .fastq.gz and .fastq files
concatenate_fastq_files() {
    output_file="${input_dir}/allsamples.fastq"
    
    echo "Processing FASTQ files..."
    
    # Check for both .fastq.gz and .fastq files
    gz_files=("${fastq_pass_dir}"/*.fastq.gz)
    fastq_files=("${fastq_pass_dir}"/*.fastq)
    gz_count=${#gz_files[@]}
    fastq_count=${#fastq_files[@]}
    
    # Remove output file if it exists
    rm -f "$output_file"
    
    if [ "$gz_count" -gt 0 ] || [ "$fastq_count" -gt 0 ]; then
        if [ "$gz_count" -gt 0 ]; then
            echo "Found $gz_count .fastq.gz files. Processing..."
            for file in "${gz_files[@]}"; do
                gunzip -c "$file" >> "$output_file" 2>/dev/null
                if [ $? -ne 0 ]; then
                    echo "Error processing file: $file"
                fi
            done
        fi
        
        if [ "$fastq_count" -gt 0 ]; then
            echo "Found $fastq_count .fastq files. Processing..."
            for file in "${fastq_files[@]}"; do
                cat "$file" >> "$output_file" 2>/dev/null
                if [ $? -ne 0 ]; then
                    echo "Error processing file: $file"
                fi
            done
        fi
    else
        echo "Error: No .fastq.gz or .fastq files found in ${fastq_pass_dir}"
        exit 1
    fi
    
    if [ -s "$output_file" ]; then
        echo "All FASTQ files have been processed and concatenated into $output_file"
    else
        echo "Error: Failed to concatenate FASTQ files or no FASTQ files found."
        rm -f "$output_file"
        exit 1
    fi
}

# Function to run nanoplexer for demultiplexing with error handling
run_nanoplexer() {
    input_file="${input_dir}/allsamples.fastq"
    barcode_file="${nanoplexer_input_dir}/barcodes.fa"
    dual_barcode_file="${nanoplexer_input_dir}/dual_barcode_TWIST.txt"

    # Check if input files exist
    if [ ! -f "$input_file" ] || [ ! -f "$barcode_file" ] || [ ! -f "$dual_barcode_file" ]; then
        echo "Error: One or more required input files not found."
        exit 1
    fi

    echo "Running nanoplexer for demultiplexing..."
    if command -v nanoplexer &> /dev/null; then
        nanoplexer -b "$barcode_file" -d "$dual_barcode_file" -p "$output_dir" "$input_file"
        if [ $? -eq 0 ]; then
            echo "Nanoplexer demultiplexing completed successfully. Output is in the $output_dir directory."
        else
            echo "Error: Nanoplexer demultiplexing failed."
            exit 1
        fi
    else
        echo "Error: nanoplexer command not found. Please ensure it's installed and in your PATH."
        exit 1
    fi
}

# Main script
setup_directories
process_csv
create_dual_barcode_file
concatenate_fastq_files
run_nanoplexer

# Clean up
echo "Cleaning up temporary files..."
rm -f "${input_dir}/allsamples.fastq"
echo "Cleanup complete."

echo "Script execution finished."
