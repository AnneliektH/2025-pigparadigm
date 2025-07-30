import pandas as pd
import numpy as np
from sklearn.manifold import MDS
import matplotlib.pyplot as plt
import seaborn as sns

# Load the pairwise data
df = pd.read_csv("../../results/pairwise/3217_pairwise.csv")

# Get all unique sample names
samples = pd.unique(df[['query_name', 'match_name']].values.ravel())

# Pivot to square matrix (1 - jaccard)
pivot_df = df.pivot(index='query_name', columns='match_name', values='jaccard')

# Reindex to ensure full square matrix with all samples
pivot_df = pivot_df.reindex(index=samples, columns=samples)

# Fill missing with 1 (max dissimilarity)
pivot_df = pivot_df.fillna(1)

# Make it symmetric
sym_df = pivot_df.combine(pivot_df.T, func=lambda a, b: (a + b) / 2)

# Create dissimilarity matrix (1 - jaccard)
distance_matrix = 1 - sym_df.values

# Run NMDS
mds = MDS(n_components=2, dissimilarity='precomputed', metric=False, random_state=42)
nmds_coords = mds.fit_transform(distance_matrix)

# Create NMDS DataFrame
nmds_df = pd.DataFrame(nmds_coords, columns=["NMDS1", "NMDS2"], index=sym_df.index)

# Load metadata
meta = pd.read_csv("../../results/pairwise/3217_meta.csv")  # or sep="\t"
nmds_df = nmds_df.reset_index().rename(columns={"index": "label"})
nmds_merged = pd.merge(nmds_df, meta, on="label")

# Plot
plt.figure(figsize=(8,6))
sns.scatterplot(data=nmds_merged, x="NMDS1", y="NMDS2", hue="category")
plt.grid(True)
plt.tight_layout()
plt.savefig('../../results/pairwise/3217_nmds.pdf')
