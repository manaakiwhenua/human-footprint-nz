# https://eogdata.mines.edu/products/vnl/

VNL = OUTD / 'data/downloads/vnl/{year}/VNL_v21_npp_2012_global_vcmslcfg_c202205302300.median_masked.tif'
VNL_FOOTPRINT = OUTD / 'data/footprints/vnl/{year}/vnl-footprint-{year}.tif'

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

DECILE_BASELINE_YEAR = 2012

VNL_YEARS = list(map(str, VNL_URLS.keys()))

# Median monthly radiance, nW/cm^2/sr
# NB output is scaled to 0-65535 (UInt16) over New Zealand to make computation of deciles computationally easier for the Human Footprint index,
# and therefore is not actually in units of nW/cm^2/sr, but the original (clipped, floating point) data is retained if needed.
# Since the Human Footprint index converts VNL data into deciles, this conversion does not result in lost information,
rule download_project_clip_vnl:
    output: VNL
    wildcard_constraints:
        year='\d{4}'
    params:
        url=lambda wildcards: VNL_URLS[get_nearest(VNL_URLS, wildcards.year)],
        extent=config['extent'],
        creation_options=" ".join(f'-co {k}={v}' for k, v in config['compression_co']['zstd_pred3'].items()),
        scale_max=1000 # nW/cm^2/sr
    conda: '../envs/gdal.yml'
    log: LOGD / "download_project_clip_vnl_{year}.log"
    shell: '''
        mkdir -p $(dirname {output})
        curl -o - {params.url} | gunzip > {output}.4326.tif
        gdal_edit.py -stats {output}.4326.tif
        gdalwarp -t_srs EPSG:3851 -t_coord_epoch {wildcards.year}.0 \
            -r near -tr 100 100 -te {params.extent} -overwrite {params.creation_options}\
            -multi -wo NUM_THREADS=ALL_CPUS \
            {output}.4326.tif {output}.unscaled.tif
        gdal_edit.py -stats {output}.unscaled.tif
        gdal_translate -ot Uint16 -scale 0 {params.scale_max} 0 65535 {output}.unscaled.tif {output}
        gdal_edit.py -stats {output}
    '''

rule footprint_vnl:
    input:
        night_light=VNL,
        baseline=expand(VNL, year=[DECILE_BASELINE_YEAR])
    output: VNL_FOOTPRINT
    log: LOGD / "footprint_vnl_{year}.log"
    threads: 5
    params:
        logLevel='INFO'
    conda: '../envs/rasterio.yml'
    script: '../scripts/decile.py'
