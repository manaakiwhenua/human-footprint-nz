import logging
from pathlib import Path

import pandas as pd
import geopandas as gpd

smk = snakemake # type: ignore

logging.basicConfig(
    filename=Path(str(smk.log)),
    level=smk.params.get('logLevel', logging.INFO),
    format='%(asctime)s.%(msecs)03d %(levelname)s %(module)s - %(funcName)s: %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

def main():
    # Open attribute data
    df = pd.read_csv(smk.params['rec_attributes'], index_col='nzsegment')

    # Calculate depth of each segment, assuming second order parabola as shape
    # Ignore Equation 2 https://www.nature.com/articles/sdata201667 (sream width) as we already have it
    df['velocity'] = 4 * (df['Median flow'] ** 0.6) / df['Width at median flow'] # Equation 3 https://www.nature.com/articles/sdata201667
    df['cross-sectional-area'] = df['Median flow'] / df['velocity'] # Equation 4 https://www.nature.com/articles/sdata201667
    df['depth'] = 1.5 * df['cross-sectional-area'] / df['Width at median flow'] # Equation 5 https://www.nature.com/articles/sdata201667
       
    # Filter on depth condition (traversibility)
    df = df[df['depth']>2]

    # Open geodata
    gdf = gpd.read_file(str(smk.input[0]))

    # Inner join on segmentid
    deep_gdf = gdf.join(df, on='nzsegment', how='inner', validate='1:1')

    # Write output
    deep_gdf.to_file(str(smk.output[0]))

main()