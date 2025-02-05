import pandas as pd
import os

# Define paths
csv_file = "/group/ctbrowngrp2/amhorst/2025-pig-v-human/results/roary/try_out/lamylo.txt"  # Update with your actual CSV file
source_folder = "/group/ctbrowngrp2/scratch/annie/2024-pigparadigm/results/MAGs/genomes"  # Update with the actual folder path
destination_folder = "/group/ctbrowngrp2/amhorst/2025-pig-v-human/results/roary/try_out/genomes"  # Update with where you want symlinks

# Read the CSV
df = pd.read_csv(csv_file)

# Ensure destination folder exists
os.makedirs(destination_folder, exist_ok=True)

# Create symlinks
for genome in df["user_genome"]:
    source_path = os.path.join(source_folder, genome + ".fasta")
    symlink_path = os.path.join(destination_folder, genome + ".fasta")

    if os.path.exists(source_path):
        os.symlink(source_path, symlink_path)
    else:
        print(f"Warning: {source_path} does not exist.")

print("Symlinks created.")
