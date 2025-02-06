#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 raw_emails.txt"
    exit 1
fi

raw_file="$1"
extracted_file="extracted_emails.txt"
final_output_file="final_emails.txt"

# Extract email addresses from the raw file
grep -E -o "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}" "$raw_file" | sort -u > "$extracted_file"

# If a previous extraction exists, compare with the new extraction
if [ -f "$final_output_file" ]; then
    # Find emails in the new extraction but not in the final output
    missing_in_final=$(comm -23 <(sort "$extracted_file") <(sort "$final_output_file"))

    # Find emails in the final output but not in the new extraction
    missing_in_extracted=$(comm -13 <(sort "$extracted_file") <(sort "$final_output_file"))

    if [ -z "$missing_in_final" ] && [ -z "$missing_in_extracted" ]; then
        echo "Comparison completed: No discrepancies found."
    else
        echo "Discrepancies found between the new extraction and the final email list:"

        if [ -n "$missing_in_final" ]; then
            echo -e "\nEmails present in the new extraction but missing in the final list:"
            echo "$missing_in_final"
        fi

        if [ -n "$missing_in_extracted" ]; then
            echo -e "\nEmails present in the final list but missing in the new extraction:"
            echo "$missing_in_extracted"
        fi
    fi
else
    echo "No previous final email list found. Creating a new one."
fi

# Save the new extraction as the final output
cp "$extracted_file" "$final_output_file"

# Display the number of emails in the final output
final_count=$(wc -l < "$final_output_file")
echo -e "\nNumber of emails in the final list: $final_count"