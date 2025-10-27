#!/usr/bin/env python3

"""
Reads an input TSV (argv[1]) using pandas, extracts the 'ident' 
column, and writes a new 2-column TSV (argv[2]) with a 
constructed file path and the original identifier.
"""

import sys
import pandas as pd

def main():
    # --- 1. Check for input AND output file arguments ---
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <input_file.tsv> <output_file.tsv>", file=sys.stderr)
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]
    
    # --- 2. Define the path components ---
    path_prefix = "/home/ctbrown/scratch3/2025-other-pig-bins/UPGG/"
    path_suffix = ".fa.gz"

    try:
        # --- 3. Read the input file using pandas ---
        # pd.read_csv works for TSVs by setting the delimiter
        df = pd.read_csv(input_file, delimiter=',')

        # --- 4. Check if 'ident' column exists ---
        if 'ident' not in df.columns:
            print(f"Error: Column 'ident' not found in {input_file}.", file=sys.stderr)
            print(f"Found columns: {list(df.columns)}", file=sys.stderr)
            sys.exit(1)
            
        # Drop rows where 'ident' might be missing (NaN)
        df.dropna(subset=['ident'], inplace=True)

        # --- 5. Create the new columns ---
        
        # We'll build a new DataFrame for the output
        output_df = pd.DataFrame()

        # Vectorized string operations are fast.
        # Ensure 'ident' is treated as a string, just in case.
        ident_col = df['ident'].astype(str)
        
        output_df['filepath'] = path_prefix + ident_col + path_suffix
        output_df['identifier'] = ident_col

        # --- 6. Write the output file ---
        output_df.to_csv(
            output_file,
            sep='\t',        # Set delimiter to tab
            index=False,     # Do not write the DataFrame index
            header=False     # Do not write the column names ('filepath', 'identifier')
        )
        
        print(f"Success! Output written to {output_file}", file=sys.stderr)

    except pd.errors.EmptyDataError:
        print(f"Error: Input file {input_file} is empty.", file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print(f"Error: Input file not found at {input_file}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()