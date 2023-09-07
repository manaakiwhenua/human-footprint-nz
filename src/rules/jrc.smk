# https://ghsl.jrc.ec.europa.eu/download.php?ds=bu
# https://ghsl.jrc.ec.europa.eu/ghs_buS2023.php
# NB The spatial raster dataset depicts the distribution of built-up surfaces, expressed as number of square metres.
# Includes both residential and non-residential
# 2018 (10m) data is observed from the Sentinel-2 image data

JEODPP_TILES = {
    'R14_C33',
    'R14_C34',
    'R15_C32',
    'R15_C33',
    'R15_C4'
}

JEODPP_YEARS = list(map(str, [2020, 2018, 2015, 2010, 2005, 2000, 1995, 1990, 1985, 1980, 1975]))
JEODPP_RESOLUTION = {k: v for k, v in zip(JEODPP_YEARS, map(lambda year: 100 if int(year) != 2018 else 10, JEODPP_YEARS))} # 2018 data is only available at 10m resolution, others have 100m as best available resolution


GHS = 'data/downloads/ghs_built_s/{year}/GHS_BUILT_S_E{year}_GLOBE_R2023A_54009_V1_0.tif'
GHS_FOOTPRINT = 'data/footprints/built-environment/GHS_BUILT_S_E{year}_GLOBE_R2023A_54009_V1_0.tif'

def get_jeodpp_url(year: int) -> list[str]:
    res : int = JEODPP_RESOLUTION[str(year)]
    # Mollweide projection
    return list(map(
        lambda tile: f'https://jeodpp.jrc.ec.europa.eu/ftp/jrc-opendata/GHSL/GHS_BUILT_S_GLOBE_R2023A/GHS_BUILT_S_E{year}_GLOBE_R2023A_54009_{res}/V1-0/tiles/GHS_BUILT_S_E{year}_GLOBE_R2023A_54009_{res}_V1_0_{tile}.zip',
        JEODPP_TILES
    ))

JEODPP_URLS = {k: v for k, v in zip(JEODPP_YEARS, map(get_jeodpp_url, JEODPP_YEARS))}

rule download_unzip_merge_jeodpp:
    output: GHS
    params:
        urls=lambda wildcards: JEODPP_URLS[wildcards.year],
        res=lambda wildcards: JEODPP_RESOLUTION[wildcards.year]
    conda: '../envs/gdal.yml'
    log: f"{LOGS_DIR}/download_unzip_merge_jeodpp_{{year}}.log"
    shell:
        '''
        rm -r $(dirname {output}) && mkdir $(dirname {output}) && \
        for link in {params.urls}; do
            echo "downloading $link" && curl -o $(dirname {output})/${{link##*/}} $link && \
            echo "unzipping $(dirname {output})/${{link##*/}}" && unzip -o $(dirname {output})/${{link##*/}} -d $(dirname {output}) && \
            rm $(dirname {output})/${{link##*/}}
        done; \
        echo "warping" && \
        gdalwarp -t_srs EPSG:3851 -t_coord_epoch {wildcards.year}.0 \
        -tr {params.res} {params.res} -r near -te 1722483.9 5228058.61 4624385.49 8692574.54 \
        -ot UInt16 \
        -co COMPRESS=ZSTD -co PREDICTOR=2 \
        -co TILED=YES -co BLOCKXSIZE=512 -co BLOCKYSIZE=512 \
        -co NUM_THREADS=ALL_CPUS -overwrite \
        -multi -wo NUM_THREADS=ALL_CPUS \
        $(dirname {output})/*.tif {output} \
        && gdal_edit.py -stats {output}
        '''

# Incudes conditional block to resample data to 100m^2 if necessary (i.e., for 2018)
rule footprint_built:
    input: GHS
    output: GHS_FOOTPRINT
    conda: '../envs/gdal.yml'
    log: f"{LOGS_DIR}/footprint_built_{{year}}.log"
    params:
        res=lambda wildcards: JEODPP_RESOLUTION[wildcards.year]
    shell:
        '''
        mkdir -p $(dirname {output}) && \
        if [ {params.res} -ne 100 ]; then
            gdalwarp -tr 100 100 -r sum -ot UInt16 \
            -te 1722483.9 5228058.61 4624385.49 8692574.54 \
            -co COMPRESS=ZSTD -co PREDICTOR=2 \
            -co TILED=YES -co BLOCKXSIZE=512 -co BLOCKYSIZE=512 \
            -co NUM_THREADS=ALL_CPUS -overwrite \
            -multi -wo NUM_THREADS=ALL_CPUS \
            {input} {input}.100.tif
        else
            cp {input} {input}.100.tif
        fi
        gdal_calc.py --outfile={output} -A {input}.100.tif --calc="4*((A>0)&(A<=2000))+10*(A>2000)" \
        --co COMPRESS=ZSTD --co PREDICTOR=2 \
        --co TILED=YES --co BLOCKXSIZE=512 --co BLOCKYSIZE=512 \
        --co NUM_THREADS=ALL_CPUS --overwrite \
        && gdal_edit.py -stats -a_srs EPSG:3851 {output} \
        && rm {input}.100.tif
        '''