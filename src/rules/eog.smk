# https://eogdata.mines.edu/products/vnl/

VNL = 'data/downloads/vnl/{year}/VNL_v21_npp_2012_global_vcmslcfg_c202205302300.median_masked.tif'
VNL_FOOTPRINT = 'data/footprints/vnl/{year}/vnl-footprint-{year}.tif'

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
# NB output is scaled 0-255 (Byte) over New Zealand to make computation of deciles computationally easier for the Human Footprint index, 
# and therefore is not actually in units of nW/cm^2/sr, but the intermediate data is retained if needed.
# Since Human Footpring mapping is using VNL data for the computation of deciles, this conversion does not result in lost information. 
rule download_project_clip_vnl:
    output: VNL
    params:
        url=lambda wildcards: VNL_URLS[int(wildcards.year)]
    conda: '../envs/gdal.yml'
    wildcard_constraints:
        year=f'({"|".join(VNL_YEARS)})'
    shell:
        '''
        mkdir -p $(dirname {output}) && \
        curl -o - {params.url} | gunzip > {output}.4326.tif && \
        gdal_edit.py -stats {output}.4326.tif && \
        gdalwarp -t_srs EPSG:3851 -t_coord_epoch {wildcards.year}.0 \
        -r near -tr 100 100 -te 1722483.9 5228058.61 4624385.49 8692574.54 \
        -co COMPRESS=ZSTD -co PREDICTOR=3 \
        -co TILED=YES -co BLOCKXSIZE=512 -co BLOCKYSIZE=512 \
        -co NUM_THREADS=ALL_CPUS -overwrite \
        -multi -wo NUM_THREADS=ALL_CPUS \
        {output}.4326.tif {output}.unscaled.tif \
        && gdal_edit.py -stats {output}.unscaled.tif \
        && gdal_translate -ot Byte -scale {output}.unscaled.tif {output} \
        && gdal_edit.py -stats {output} \
        '''

# NB perform "gdalinfo -hist {output}" to verify that the output is in 10 approximately equal bins (excluding 0).
# The result won't have exactly bins: values stradling the edge aren't distributed evenly between boundary values,
# Yet, for 2020, each class 1-10 has between 131,825 to 131,859 pixels, and the remaining 1,004,044,827 pixels are 0.
rule footprint_vnl:
    input: VNL
    output: VNL_FOOTPRINT
    wildcard_constraints:
        year=f'({"|".join(VNL_YEARS)})'
    log: f"{LOGS_DIR}/footprint_vnl_{{year}}.log"
    threads: 5
    params:
        logLevel='DEBUG'
    conda: '../envs/rasterio.yml'
    script: '../scripts/decile.py'
