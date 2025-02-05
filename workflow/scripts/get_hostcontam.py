# imports
import pandas as pd
import glob
import os.path
import argparse

# function to get sums
def process_files(input_path):
    all_gather_results = glob.glob(os.path.join(input_path, "*.csv"))

    pig_dict = {}
    human_dict = {}

    for file in all_gather_results:
        df = pd.read_csv(file)
        # Sum f_unique_weighted for 'human' (hg38-entire)
        human_dict[file] = df.loc[df['name'] == 'hg38-entire', 'f_unique_weighted'].sum()
        # Sum f_unique_weighted for everything else (pig)
        pig_dict[file] = df.loc[df['name'] != 'hg38-entire', 'f_unique_weighted'].sum()

    return pig_dict, human_dict

def save_results(pig_dict, human_dict, output_file):
    # Extract base filenames for each file
    filenames = [os.path.basename(file) for file in pig_dict.keys()]

    # Combine both dictionaries into a single DataFrame
    combined_df = pd.DataFrame({
        "File": filenames,
        "f_unique_weighted_pig": [pig_dict.get(file, 0) for file in pig_dict.keys()],
        "f_unique_weighted_human": [human_dict.get(file, 0) for file in pig_dict.keys()]
    })
    combined_df.to_csv(output_file, index=False)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process CSV files in a directory.")
    parser.add_argument("input_path", help="Path to the input directory")
    parser.add_argument("output_file", help="Path to the output directory")
    args = parser.parse_args()

    pig_dict, human_dict = process_files(args.input_path)
    save_results(pig_dict, human_dict, args.output_file)