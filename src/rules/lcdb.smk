LCDB_YEARS = list(map(str, [2018,2012,2008,2001,1996]))
CROPLAND = "data/downloads/cropland/{year}/cropland-{year}.gpkg"
PASTURE = "data/downloads/pasture/{year}/pasture-{year}.gpkg"

CROPLAND_PERCENT = "data/downloads/cropland/{year}/cropland-percent-{year}.tif"
PASTURE_PERCENT = "data/downloads/pasture/{year}/pasture-percent-{year}.tif"

CROPLAND_FOOTPRINT = "data/footprints/cropland/cropland-{year}.tif"
PASTURE_FOOTPRINT = "data/footprints/pasture/pasture-{year}.tif"

# NB that "Exotic Forest" and "Forest - Harvested" (LCDB) are included in our definition of "cropland"
rule download_cropland:
    output: CROPLAND
    wildcard_constraints:
        year=f'({"|".join(LCDB_YEARS)})'
    threads: 2
    conda: '../envs/gdal.yml'
    log: f"{LOGS_DIR}/download_cropland_{{year}}.log"
    params:
        host="https://lris.scinfo.org.nz",
        key=lambda wc: os.environ.get('LRIS_KEY'),
        mainland_layer="layer-104400", # LCDB v5.0 - Land Cover Database version 5.0, Mainland, New Zealand
        chathams_layer="layer-104442", # LCDB v5.0 - Land Cover Database version 5.0, Chatham Islands
        nln="cropland",
        nlt="multipolygon",
        geom_var="geom",
        where=lambda wildcards: f"\"Class_{wildcards.year}\" IN (30, 33, 64, 71)"
    shell:
        '''
        mkdir -p $(dirname /tmp/mainland/{output}) && ogr2ogr --config GDAL_HTTP_UNSAFESSL YES -f GPKG -t_srs EPSG:2193 -t_coord_epoch {wildcards.year}.0 /tmp/mainland/{output} WFS:\"{params.host}/services;key={params.key}/wfs/{params.mainland_layer}\" {params.mainland_layer} -nln {params.nln} -nlt {params.nlt} -nlt PROMOTE_TO_MULTI -overwrite -lco GEOMETRY_NAME={params.geom_var} -skipfailures -where "{params.where}" -unsetFid && \
        mkdir -p $(dirname /tmp/chathams/{output}) && ogr2ogr --config GDAL_HTTP_UNSAFESSL YES -f GPKG -t_srs EPSG:3793 -t_coord_epoch {wildcards.year}.0 /tmp/chathams/{output} WFS:\"{params.host}/services;key={params.key}/wfs/{params.chathams_layer}\" {params.chathams_layer} -nln {params.nln} -nlt {params.nlt} -nlt PROMOTE_TO_MULTI -overwrite -lco GEOMETRY_NAME={params.geom_var} -skipfailures -where "{params.where}" -unsetFid && \
        mkdir -p $(dirname {output}) && ogrmerge.py -o {output} /tmp/mainland/{output} /tmp/chathams/{output} -f GPKG -single -nln {params.nln} -overwrite_ds -t_srs EPSG:3851 -progress   
        '''

use rule download_cropland as download_pasture with:
    output: PASTURE
    log: f"{LOGS_DIR}/download_pasture_{{year}}.log"
    params:
        host="https://lris.scinfo.org.nz",
        key=lambda wc: os.environ.get('LRIS_KEY'),
        mainland_layer="layer-104400", # LCDB v5.0 - Land Cover Database version 5.0, Mainland, New Zealand
        chathams_layer="layer-104442", # LCDB v5.0 - Land Cover Database version 5.0, Chatham Islands
        nln="pasture",
        nlt="multipolygon",
        geom_var="geom",
        where=lambda wildcards: f"\"Class_{wildcards.year}\" IN (2, 40, 41, 44)"

# Rasterise crops as a 10m^2 raster, present = 1, absent = 0
# Resample back to 100m^2 raster, summation, to get a 0-100 value for measuring partial cover at this scale
rule burn_cropland:
    input: CROPLAND
    output: CROPLAND_PERCENT
    wildcard_constraints:
        year=f'({"|".join(LCDB_YEARS)})'
    conda: '../envs/gdal.yml'
    log: f"{LOGS_DIR}/burn_cropland_{{year}}.log"
    shell:
        '''
        mkdir -p $(dirname /tmp/lcdb/{output}) && \
        gdal_rasterize -b -burn 4 -of GTiff -ot Byte \
        -a_nodata 0 -init 0 \
        -tr 20 20 -te 1722483.9 5228058.61 4624385.49 8692574.54 \
        {input} /tmp/lcdb/{output} \
        && gdalwarp -r sum -tr 100 100 -te 1722483.9 5228058.61 4624385.49 8692574.54 \
        -co COMPRESS=ZSTD -co PREDICTOR=2 \
        -co TILED=YES -co BLOCKXSIZE=512 -co BLOCKYSIZE=512 \
        -co NUM_THREADS=ALL_CPUS -overwrite \
        -multi -wo NUM_THREADS=ALL_CPUS \
        -dstnodata 0 \
        -overwrite /tmp/lcdb/{output} {output} \
        && gdal_edit.py -stats -unsetnodata -a_srs EPSG:3851 {output}
        '''

use rule burn_cropland as burn_pasture with:
    input: PASTURE
    output: PASTURE_PERCENT
    log: f"{LOGS_DIR}/burn_pasture_{{year}}.log"


rule footprint_cropland:
    input: CROPLAND_PERCENT
    output: CROPLAND_FOOTPRINT
    wildcard_constraints:
        year=f'({"|".join(LCDB_YEARS)})'
    conda: '../envs/gdal.yml'
    log: f"{LOGS_DIR}/footprint_cropland_{{year}}.log"
    shell:
        '''
        mkdir -p $(dirname {output}) && \
        gdal_calc.py --outfile={output} -A {input} --calc="0*(A==0)+4*((A>0)&(A<=20))+7*(A>20)" \
        --co COMPRESS=ZSTD --co PREDICTOR=2 \
        --co TILED=YES --co BLOCKXSIZE=512 --co BLOCKYSIZE=512 \
        --co NUM_THREADS=ALL_CPUS --overwrite \
        && gdal_edit.py -stats -a_srs EPSG:3851 {output}
        '''

rule footprint_pasture:
    input: PASTURE_PERCENT
    output: PASTURE_FOOTPRINT
    wildcard_constraints:
        year=f'({"|".join(LCDB_YEARS)})'
    conda: '../envs/gdal.yml'
    log: f"{LOGS_DIR}/footprint_pasture_{{year}}.log"
    shell:
        '''
        mkdir -p $(dirname {output}) && \
        gdal_calc.py --outfile={output} -A {input} --calc="A/100.0*4" \
        --co COMPRESS=ZSTD --co PREDICTOR=2 \
        --co TILED=YES --co BLOCKXSIZE=512 --co BLOCKYSIZE=512 \
        --co NUM_THREADS=ALL_CPUS --overwrite \
        && gdal_edit.py -stats -a_srs EPSG:3851 {output}
        '''