import sourmash
from pathlib import Path
from sourmash.nodegraph import Nodegraph
import pandas as pd
import random

# Parameters
ksize = 31
n_iterations = 100

# Load the sig file paths once
sig_files = sorted(Path("/group/ctbrowngrp2/amhorst/2025-pigparadigm/results/sketches/MAG_sketch").glob("*.sig"))

# Prepare a list to store results for all iterations
all_results = []

for iteration in range(n_iterations):
    print(f"Iteration {iteration + 1}/{n_iterations}")
    
    # Shuffle sample order for this iteration
    shuffled_files = sig_files.copy()
    random.shuffle(shuffled_files)
    
    # Reset Nodegraph for each iteration
    all_hashes = Nodegraph(ksize, 1_000_000, 4)
    
    cumulative_kmers = 0
    for position, sig_file in enumerate(shuffled_files, start=1):
        # Load signature exactly as before
        sig = sourmash.load_one_signature(str(sig_file), ksize=ksize, select_moltype='DNA')
        
        prev_total = all_hashes.n_occupied()
        all_hashes.update(sig.minhash)
        new_total = all_hashes.n_occupied()
        new_kmers = new_total - prev_total
        
        # Append a row with iteration, sample, position in this iteration, new kmers, cumulative total
        all_results.append({
            "iteration": iteration,
            "position": position,
            "sample": sig_file.name,
            "new_kmers": new_kmers,
            "cumulative_kmers": new_total
        })

# Convert to pandas DataFrame
df = pd.DataFrame(all_results)

# Save to CSV
df.to_csv("../../results/MAGs/250925_new_kmers_mags.k31.100perm.csv", index=False)
