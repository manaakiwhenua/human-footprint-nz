# https://eogdata.mines.edu/products/vnl/

VNL = 'data/downloads/vnl/{year}/VNL_v21_npp_2012_global_vcmslcfg_c202205302300.median_masked.tif'
VNL_FOOTPRINT = 'data/downloads/vnl/{year}/vnl-footprint-{year}.tif'

VNL_URLS = {
    2022: 'https://eogdata.mines.edu/nighttime_light/annual/v22/2022/VNL_v22_npp-j01_2022_global_vcmslcfg_c202303062300.median_masked.dat.tif.gz',
    2021: 'https://eogdata.mines.edu/nighttime_light/annual/v21/2021/VNL_v21_npp_2021_global_vcmslcfg_c202205302300.median_masked.dat.tif.gz',
    2020: 'https://eogdata.mines.edu/nighttime_light/annual/v21/2020/VNL_v21_npp_2020_global_vcmslcfg_c202205302300.median_masked.dat.tif.gz',
    2019: 'https://eogdata.mines.edu/nighttime_light/annual/v21/2019/VNL_v21_npp_2019_global_vcmslcfg_c202205302300.median_masked.dat.tif.gz',
    2018: 'https://eogdata.mines.edu/nighttime_light/annual/v21/2018/VNL_v21_npp_2018_global_vcmslcfg_c202205302300.median_masked.dat.tif.gz',
    2017: 'https://eogdata.mines.edu/nighttime_light/annual/v21/2017/VNL_v21_npp_2017_global_vcmslcfg_c202205302300.median_masked.dat.tif.gz',
    2016: 'https://eogdata.mines.edu/nighttime_light/annual/v21/2016/VNL_v21_npp_2016_global_vcmslcfg_c202205302300.median_masked.dat.tif.gz',
    2015: 'https://eogdata.mines.edu/nighttime_light/annual/v21/2015/VNL_v21_npp_2015_global_vcmslcfg_c202205302300.median_masked.dat.tif.gz',
    2014: 'https://eogdata.mines.edu/nighttime_light/annual/v21/2014/VNL_v21_npp_2014_global_vcmslcfg_c202205302300.median_masked.dat.tif.gz',
    2013: 'https://eogdata.mines.edu/nighttime_light/annual/v21/2013/VNL_v21_npp_2013_global_vcmcfg_c202205302300.median_masked.dat.tif.gz',
    2012: 'https://eogdata.mines.edu/nighttime_light/annual/v21/2012/VNL_v21_npp_201204-201212_global_vcmcfg_c202205302300.median_masked.dat.tif.gz',
}

VNL_YEARS = list(map(str, VNL_URLS.keys()))

# Median monthly radiance, nW/cm^2/sr
rule download_project_clip_vnl:
    output: VNL
    params:
        url=lambda wildcards: VNL_URLS[int(wildcards.year)]
    conda: '../envs/gdal.yml'
    shell:
        '''
        mkdir -p $(dirname {output}) && \
        curl -o - {params.url} | gunzip > {output}.4326.tif && \
        gdalwarp -t_srs EPSG:3851 \
        -r near -tr 100 100 -te 1722483.9 5228058.61 4624385.49 8692574.54 \
        -co COMPRESS=ZSTD -co PREDICTOR=2 \
        -co TILED=YES -co BLOCKXSIZE=512 -co BLOCKYSIZE=512 \
        -co NUM_THREADS=ALL_CPUS -overwrite \
        -multi -wo NUM_THREADS=ALL_CPUS \
        {output}.4326.tif {output} \
        && gdal_edit.py -stats {output}
        '''

# TODO work out a method of classifying as ten equal quantiles (excluding 0 or nan in the computation of quantile)
# NB quantile can be efficiently computed by loading the array, flattening, excluding nan and 0, and sorting
#   The issue I'm having is computing the mask in numpy to apply the correct integer value...
#       Python kills the process before it will compute the array
# Probably what needs to be done is to
# a) calculate the quantile thresholds as described
# b) loop and update over windows of 512x512
# rule footprint_vnl:
#     input: VNL
#     output: VNL_FOOTPRINT
#     conda: '../envs/gdal.yml'
#     run:
#         '''
#         import numpy as np
#         import rasterio as rio
#         ds = rio.open(input[0])
#         data = ds.read()
#         ''''
