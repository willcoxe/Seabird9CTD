# Seabird9CTD

1. Parse Seabird 9 .cnv files into DataFrame
2. Bin this dataframe with depth of choice (values averaged to +/- 0.5 * bin depth)
3. Make quick TS Diagram to get an idea of the dataset

NOTE: this code does not utilize any of the julia optimizations. However it works and is fairly fast. 
