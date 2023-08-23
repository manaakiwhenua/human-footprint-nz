WORLDPOP_YEARS = list(map(str, range(2000, 2021)))

WORLDPOP = 'data/downloads/worldpop/nzl_ppp_{year}.tif'
WORLDPOP_NZ = 'data/downloads/worldpop/nzl_ppp_{year}.3851.tif'
WORLDPOP_FOOTPRINT_NZ = 'data/footprints/population-density/nzl_ppp_{year}.3851.tif'

def worldpop_endpoint(year: int):
    # https://hub.worldpop.org/geodata/listing?id=76
    # return f'https://data.worldpop.org/GIS/Population_Density/Global_2000_2020_1km/{year}/NZL/nzl_pd_{year}_1km.tif'
    return f'https://data.worldpop.org/GIS/Population/Global_2000_2020/{year}/NZL/nzl_ppp_{year}.tif'

# Data is people per pixel, but pixels are not equal area
rule download_worldpop:
    output: WORLDPOP
    wildcard_constraints:
        year=f'({"|".join(WORLDPOP_YEARS)})'
    conda: '../envs/gdal.yml'
    log: f"{LOGS_DIR}/download_worldpop{{year}}.log"
    params:
        url=lambda wildcards: worldpop_endpoint(int(wildcards.year))
    shell:
        '''
        mkdir -p $(dirname /tmp/{output}) && \
        gdal_translate {params.url} {output} \
        -co COMPRESS=ZSTD -co PREDICTOR=2 \
        -co TILED=YES -co BLOCKXSIZE=512 -co BLOCKYSIZE=512 \
        -co NUM_THREADS=ALL_CPUS
        '''

# Unit is people per pixel, i.e. people per 100m2
# This does a weighted sum, to return data to a projection that actually uses metres
rule reproject_worldpop:
    input: WORLDPOP
    output: WORLDPOP_NZ
    wildcard_constraints:
        year=f'({"|".join(WORLDPOP_YEARS)})'
    conda: '../envs/gdal.yml'
    log: f"{LOGS_DIR}/reproject_worldpop{{year}}.log"
    shell:
        '''
        gdalwarp -t_srs EPSG:3851 -r sum \
        -tr 100 100 \
        -co COMPRESS=ZSTD -co PREDICTOR=2 \
        -co TILED=YES -co BLOCKXSIZE=512 -co BLOCKYSIZE=512 \
        -co NUM_THREADS=ALL_CPUS -overwrite \
        {input} {output} \
        && gdal_edit.py -stats {output}
        '''

# Original footprint formula used 1km2, and max value was 1000 people per pixel, i.e. 1000 people per km2
# To convert this to 100m2, this is 1/100 of 1km2, so 1/100*1000 = 10; therefore the max value is 10 people per 100m2
# 10 | where people per pixel (ppp) is greater than or equal to 10
# 3.333 * log(people/km2 + 1) | where ppp is greater than 0 and less than 10
# 0 | otherwise
rule footprint_worldpop:
    input: WORLDPOP_NZ
    output: WORLDPOP_FOOTPRINT_NZ
    conda: '../envs/gdal.yml'
    log: f"{LOGS_DIR}/footprint_worldpop{{year}}.log"
    shell:
        '''
        mkdir -p $(dirname {output}) && \
        gdal_calc.py --outfile={output} --calc="0*(A==0)+10*(A>=10)+3.333*log(A*100+1)" -A {input} \
        --creation-option COMPRESS=ZSTD --creation-option PREDICTOR=2 \
        --creation-option TILED=YES --creation-option BLOCKXSIZE=512 --creation-option BLOCKYSIZE=512 \
        --creation-option NUM_THREADS=ALL_CPUS --overwrite \
        && gdal_edit.py -stats {output}
        '''