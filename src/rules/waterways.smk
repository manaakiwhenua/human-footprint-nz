COASTLINE = 'data/downloads/coastlines/{year}/coastlines-{year}.gpkg'

LAKES = 'data/downloads/lakes/{year}/lakes-{year}.gpkg'
LAKES_LINES = 'data/downloads/lakes/{year}/lakes-lines-{year}.gpkg'

rule checkout_coastlines:
    output: COASTLINE
    # wildcard_constraints:
    #     year=f'({"|".join(LINZ_YEARS)})'
    conda: '../envs/gdal.yml'
    log: f"{LOGS_DIR}/checkout_coastlines_{{year}}.log"
    params:
        layer='layer-105085',
        workingcopy=lambda wildcards: f'data/clones/coastlines/{wildcards.year}',
        # kart_hash=lambda wildcards: get_kart_rail_sha(int(wildcards.year), 'layer-50319')
    shell:
        '''
        rm -rf $(dirname {output})/$(basename -s .shp {output}).gpkg && rm -rf {params.workingcopy} \
        && kart clone --workingcopy-location $(dirname {output})/$(basename -s .shp {output}).gpkg --progress kart@data.koordinates.com:land-information-new-zealand/{params.layer} {params.workingcopy}
        '''

# rule checkout_lakes:
#     output: LAKES

# TODO convert polygon lakes to lines:
# ogr2ogr output.gpkg input.gpkg -dialect sqlite -f "GPKG" -sql "SELECT ST_ExteriorRing(geometry) as geometry from input"