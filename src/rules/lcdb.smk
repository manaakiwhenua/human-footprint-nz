LCDB_YEARS = list(map(str, [2018,2012,2008,2001,1996]))
CROPLAND = "data/downloads/cropland/{year}/cropland-{year}.gpkg"
PASTURE = "data/downloads/pasture/{year}/pasture-{year}.gpkg"

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
        where=lambda wildcards: f"\"Class_{wildcards.year}\" IN (30, 33)"
    shell:
        '''
        mkdir -p $(dirname /tmp/mainland/{output}) && ogr2ogr --config GDAL_HTTP_UNSAFESSL YES -f GPKG -t_srs EPSG:2193 /tmp/mainland/{output} WFS:\"{params.host}/services;key={params.key}/wfs/{params.mainland_layer}\" {params.mainland_layer} -nln {params.nln} -nlt {params.nlt} -nlt PROMOTE_TO_MULTI -overwrite -lco GEOMETRY_NAME={params.geom_var} -skipfailures -where "{params.where}" -unsetFid && \
        mkdir -p $(dirname /tmp/chathams/{output}) && ogr2ogr --config GDAL_HTTP_UNSAFESSL YES -f GPKG -t_srs EPSG:3793 /tmp/chathams/{output} WFS:\"{params.host}/services;key={params.key}/wfs/{params.chathams_layer}\" {params.chathams_layer} -nln {params.nln} -nlt {params.nlt} -nlt PROMOTE_TO_MULTI -overwrite -lco GEOMETRY_NAME={params.geom_var} -skipfailures -where "{params.where}" -unsetFid && \
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