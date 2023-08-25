"""
Convert a numerical raster into a 1-10 scale, on the basis of ten equal quantiles.
0 and NaN are excluded from the quantile calculation, and retained in the output.
"""

from concurrent.futures import ThreadPoolExecutor
import copy
import logging
import numpy as np
from pathlib import Path
import subprocess
import threading

import rasterio as rio

smk = snakemake # type: ignore

logging.basicConfig(
    filename=Path(str(smk.log)),
    level=smk.params.get('logLevel', logging.INFO),
    format='%(asctime)s.%(msecs)03d %(levelname)s %(module)s - %(funcName)s: %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

def trim_zeros(filt: np.ndarray, trim='fb') -> np.ndarray:
    '''
    The numpy implementation of trim_zeros is extremely unoptimised; this is an alternative.
    '''
    a = np.asanyarray(filt, dtype=bool)
    if a.ndim != 1:
        raise ValueError('trim_zeros requires an array of exactly one dimension')

    trim_upper = trim.upper()
    len_a = len(a)
    i = j = None
    
    if 'F' in trim_upper:
        i = a.argmax()
        if not a[i]:  # i.e. all elements of `filt` evaluate to `False`
            return filt[len_a:]

    if 'B' in trim_upper:
        j = len_a - a[::-1].argmax()
        if not j:  # i.e. all elements of `filt` evaluate to `False`
            return filt[len_a:]

    return filt[i:j]

def calculate_deciles(data: np.ndarray) -> np.ndarray:
    return np.percentile(
        trim_zeros(np.sort(data.flatten(), axis=0, kind='stable'), trim='f'),
        np.arange(10, 100, 10)
    )

def main(workers=smk.threads):

    with rio.open(smk.input[0]) as ds:
        deciles : np.narray = calculate_deciles(ds.read(1, masked=False))
    deciles = np.insert(deciles, 0, 0)
    logging.info(deciles)

    logging.info(f"Opening {smk.input[0]} for reading")
    with rio.open(smk.input[0]) as src:
        # Create a destination dataset based on source params. The
        # destination will be tiled, and we'll process the tiles
        # concurrently.
        profile = copy.copy(src.profile)
        profile.update(dtype=np.uint8, compress='lzw')
        logging.info(profile)
        logging.info(f"Opening {smk.output[0]} for writing")
        with rio.open(smk.output[0], "w", **profile) as dst:
            windows = [window for ij, window in dst.block_windows(1)]
            logging.debug(f"{len(windows)} windows to process")
            # We cannot write to the same file from multiple threads
            # without causing race conditions. To safely read/write
            # from multiple threads, we use a lock to protect the
            # DatasetReader/Writer
            read_lock = threading.Lock()
            write_lock = threading.Lock()

            def process(window):
                with read_lock:
                    src_array = src.read(1, window=window)

                try:
                    with write_lock:
                        dst.write(
                            np.digitize(src_array, deciles, right=True).astype(np.uint8), window=window, indexes=1
                        )
                except Exception as e:
                    raise e
            
            # We map the process() function over the list of windows
            with ThreadPoolExecutor(max_workers=workers) as executor:
                executor.map(process, windows)
    
    subprocess.run(["gdal_edit.py", "-stats", str(smk.output[0])])


main()