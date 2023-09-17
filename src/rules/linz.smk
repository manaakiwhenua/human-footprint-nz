ROADS_SHAS = {
    'layer-50329': {
        2012: '0e4fe8d9445ab053f296793464d9a9fc3b399b74', # 2012-01-25
        2013: '56dc72e5339e8bfc639c81373a51029a56ec8779', # 2013-01-16
        2014: 'f33043dba8a490491dde5112d00f2a7a862ac100', # 2013-12-13
        2015: 'a38b826b0efef04fa71fd3b574652db2058b4d34', # 2015-03-10
        2016: '58caca4fcae8329a836440eca7017c5301a7c97b', # 2016-01-05
        2017: '96fadc4c95b78df209e04304baffe2d8ac34b47e', # 2017-02-09
        2018: 'a56c6d391117dca4f04a903844497551faf8a2ef', # 2018-02-02
        2019: 'a87a5bbc00153b96fefc2be2306fe3241750d4d2', # 2018-12-12
        2020: 'ea5ba00a947ca217b75f805ae94d3668f5976f57', # 2020-02-16
        2021: '1f3863ea2a953d7568e25d4adf5d893b0869aaa4', # 2021-02-19
        2022: '7463ed5fff871d662599dbbfc44ca3d1fa8477bf', # 2021-12-21
        2023: 'bc89f9f31f43e2f0bb51647153b1905a7ba8da12', # 2022-09-22 # TODO more recent updates?
    }, # NZ Road Centrelines (Topo, 1:50k)
    'layer-50100': {
        2012: 'ed11dcf7385d1a666bba092513f4b2c890ea8041', # 2012-11-24
        2013: 'ac2abca38f125a9eb66bf9a0ccec42e07fe919e9', # 2013-10-04
        2015: '038e4ce31eaf7431867dd30fc135b7d3cae13e76', # 2015-08-21
        2018: '61aa4de74472b9fca5b81907f2b2b23e0268f322', # 2018-02-02
        2019: 'd752a29e69e4e706f3273008562ed9ca35b6b82e', # 2019-04-14
        2020: 'aa06489cfe9860e7c49ef77b509c5b409b6e4c01', # 2020-09-21
        2021: 'ebf4f0f78de6b9cbb1e5f61fa1d9dabb0d6f2923', # 2020-09-23
    } # NZ Chatham Island Road Centrelines (Topo, 1:50k)
}

RAIL_SHAS = {
    'layer-50319': {
        2012: '7f1bd7ea8d473b7149fc2a94a9d1c2044a07b250', # 2012-01-25
        2013: '942c83f499de745e1ff4bf9b25586bccd32d6970', # 2013-01-16
        2014: 'a5bc97f4b119c485f26aa52cca24e97bb50ada7d', # 2013-12-13
        2015: '5d5efa21d11ea01ab109aca1188b99ed93a89b2d', # 2015-03-10
        2016: 'ac4ceab5bdb66cd8d7c8962c38560ef94d04dcfb', # 2016-01-05
        2017: 'dae6754015dc913cecd631b660c1fc635127b2db', # 2017-02-13
        2018: '90206b571844f6500e697b91aecbc5ee4d0a6641', # 2018-05-08
        2019: '403f16ebeb4a5bf5948389d113d3c3cee0cd7028', # 2018-12-12
        2020: '44821f5f99345d208c55bb0ce2d7a2fdd26f0112', # 2020-02-16
        2021: '48eaad62d886c4fdf009f4ce2b3acde3c49153dc', # 2021-02-19
        2021: '4d98ce495eb534ac52ae5705776a8c1351135ea5', # 2021-12-20
        2022: '4d98ce495eb534ac52ae5705776a8c1351135ea5', # 2021-12-20
        2023: '8b52eae6c1a9a4ef97ad56cd8703206da6085b2a', # 2022-09-23 # TODO more recent updates?
    }
} # NZ Railway Centrelines (Topo, 1:50k)

TUNNEL_SHAS = {
    'layer-50366': {
        2012: 'b86a8d2819115fa8af04302908138203a26aea46', # 2012-01-25
        2013: '58285f1e7ab4da3907cf2c12a6c7b42a8b757b09', # 2012-01-16
        2014: 'e7042aee42fdc11f65f2130eb5563204da2305ce', # 2013-12-13
        2015: '9b3f0e4ba2e5376f85866d6e14f3268a279101a7', # 2015-03-10
        2016: 'c100804e147bb1dd349eb245d2b7804bf25ed291', # 2016-01-05
        2017: '2db753ce420ba433d2fc5a771e40271eb73778c4', # 2017-02-13
        2018: '5061cb1452216d1f64ae2afd06c513c7f482fe10', # 2018-02-02
        2019: 'de615c656c7326ef0a9ec16e8987b639a00662b0', # 2018-12-12
        2020: '2d1edafb3437f4c2547322d0159357e70f3723a0', # 2020-02-16
        2021: '0c66a29cdf886857c69f1e9c9bfa499697506973', # 2021-02-19
        2022: '8c45322489582a8453649a5ab8013c3f54379193', # 2021-12-21
        2023: '99396074c180e8f1b6e0abbc3df25098245f9d4c', # 2022-09-22 # TODO more recent updates?
    }
}

LINZ_YEARS = list(map(str, range(2012, 2024)))

def get_kart_roads_sha(year: int, layer: str) -> str:
    return ROADS_SHAS[layer][get_nearest(ROADS_SHAS[layer], year)]

def get_kart_rail_sha(year: int, layer: str) -> str:
    return RAIL_SHAS[layer][get_nearest(RAIL_SHAS[layer], year)]

def get_kart_tunnel_sha(year: int, layer: str) -> str:
    return TUNNEL_SHAS[layer][get_nearest(TUNNEL_SHAS[layer], year)]

MAINLAND_ROADS = OUTD / "data/downloads/roads/mainland/{year}/roads-mainland-{year}.gpkg"
CHATHAMS_ROADS = OUTD / "data/downloads/roads/chathams/{year}/roads-chathams-{year}.gpkg"
ROADS = OUTD / "data/downloads/roads/{year}/roads-{year}.shp" # SHP due to WhiteBox tools limitation https://www.whiteboxgeo.com/manual/wbt_book/supported_formats.html#vector-formats
ROADS_RASTER = OUTD / "data/downloads/roads/{year}/roads-{year}.tif"
ROADS_RASTER_DISTANCE = OUTD / "data/downloads/roads/{year}/roads-{year}-euclidean_distance.tif"
ROADS_FOOTPRINT = OUTD / "data/footprints/roads/roads-{year}.tif"

RAIL = OUTD / "data/downloads/rail/{year}/rail-{year}.shp" # SHP due to WhiteBox tools limitation https://www.whiteboxgeo.com/manual/wbt_book/supported_formats.html#vector-formats
RAIL_NO_TUNNELS = OUTD / "data/downloads/rail/{year}/rail_no_tunnels-{year}.shp"
RAIL_RASTER = OUTD / "data/downloads/rail/{year}/rail-{year}.tif"
RAIL_RASTER_DISTANCE = OUTD / "data/downloads/rail/{year}/rail-{year}-euclidean_distance.tif"
RAIL_FOOTPRINT = OUTD / "data/footprints/rail/rail-{year}.tif"

TUNNELS = "data/downloads/tunnel/{year}/tunnel-{year}.gpkg"

rule checkout_roads_mainland:
    output: MAINLAND_ROADS
    wildcard_constraints:
        year='\d{4}'
    conda: '../envs/gdal.yml'
    log: LOGD / "checkout_roads_mainland_{year}.log"
    params:
        layer='layer-50329',
        workingcopy=lambda wildcards: f'data/clones/roads/mainland/{wildcards.year}',
        kart_hash=lambda wildcards: get_kart_roads_sha(int(wildcards.year), 'layer-50329')
    shell: '''
        rm -rf {output}
        rm -rf {params.workingcopy}
        kart clone --workingcopy-location {output} --progress kart@data.koordinates.com:land-information-new-zealand/{params.layer} {params.workingcopy}
        pushd {params.workingcopy}
            kart checkout {params.kart_hash}
        popd
        '''

use rule checkout_roads_mainland as checkout_roads_chathams with:
    output: CHATHAMS_ROADS
    wildcard_constraints:
        year='\d{4}'
    log: LOGD / "checkout_roads_chathams_{year}.log"
    params:
        layer='layer-50100',
        workingcopy=lambda wildcards: f'data/clones/roads/chathams/{wildcards.year}',
        kart_hash=lambda wildcards: get_kart_roads_sha(int(wildcards.year), 'layer-50100')

rule merge_roads:
    input: MAINLAND_ROADS, CHATHAMS_ROADS
    output: ROADS
    log: LOGD / "merge_roads_{year}.log"
    conda: '../envs/gdal.yml'
    params:
        nln='roads'
    shell: '''
        mkdir -p $(dirname {output})
        ogrmerge.py -o {output} {input} -f "ESRI Shapefile" -single -nln {params.nln} -overwrite_ds -t_srs EPSG:3851 -progress
        ogrinfo {output} -sql "CREATE SPATIAL INDEX ON $(basename -s .shp {output})"
        ogrinfo $(dirname {output})/$(basename -s .shp {output}).dbf -sql "RESIZE $(basename -s .shp {output})"
        '''

rule checkout_rail:
    output: RAIL
    wildcard_constraints:
        year='\d{4}'
    wildcard_constraints:
        year=f'({"|".join(LINZ_YEARS)})'
    conda: '../envs/gdal.yml'
    log: LOGD / "checkout_rail_{year}.log"
    params:
        layer='layer-50319',
        workingcopy=lambda wildcards: f'data/clones/rail/{wildcards.year}',
        kart_hash=lambda wildcards: get_kart_rail_sha(int(wildcards.year), 'layer-50319')
    shell: '''
        rm -rf $(dirname {output})/$(basename -s .shp {output}).gpkg
        rm -rf {params.workingcopy}
        kart clone --workingcopy-location $(dirname {output})/$(basename -s .shp {output}).gpkg --progress kart@data.koordinates.com:land-information-new-zealand/{params.layer} {params.workingcopy}
        pushd {params.workingcopy}
            kart checkout {params.kart_hash}
        popd
        ogr2ogr -t_srs EPSG:3851 {output} $(dirname {output})/$(basename -s .shp {output}).gpkg
    '''

rule erase_tunnels_rail:
    input: 
        feature=RAIL,
        overlay=TUNNELS
    output: RAIL_NO_TUNNELS
    conda: '../envs/qgis.yml'
    log: f"{LOGS_DIR}/erase_tunnels_rail_{{year}}.log"
    params:
        grid_size=0.01
    shell: '''
        mkdir -p $(dirname {output})
        mkdir -p /tmp/{output}
        qgis_process run native:difference -- INPUT={input.feature} OVERLAY={input.overlay} OUTPUT=/tmp/{output} GRID_SIZE={params.grid_size}
        qgis_process run native:difference -- INPUT=/tmp/{output} OVERLAY={input.overlay} OUTPUT=/tmp/{output} GRID_SIZE={params.grid_size}
        qgis_process run native:difference -- INPUT=/tmp/{output} OVERLAY={input.overlay} OUTPUT={output} GRID_SIZE={params.grid_size}
    '''


use rule checkout_rail as checkout_tunnels with:
    output: TUNNELS
    log: f"{LOGS_DIR}/checkout_tunnels_{{year}}.log"
    params:
        layer='layer-50366',
        workingcopy=lambda wildcards: f'data/clones/tunnel/{wildcards.year}',
        kart_hash=lambda wildcards: get_kart_tunnel_sha(int(wildcards.year), 'layer-50366')

rule roads_rasterisation:
    input: ROADS,
    output: ROADS_RASTER
    log: LOGD / "roads_rasterisation_{year}.log"
    conda: '../envs/gdal.yml'
    params:
        extent=config['extent']
    shell: '''
        mkdir -p $(dirname {output})
        gdal_rasterize -b -burn 1 -of GTiff -ot Byte -init 0 \
            -tr 100 100 -te {params.extent} \
            {input} {output}
        gdal_edit.py -stats -a_srs EPSG:3851 {output}
    '''

use rule roads_rasterisation as rail_rasterisation with:
    input: RAIL_NO_TUNNELS
    output: RAIL_RASTER
    log:LOGD / "rail_rasterisation_{year}.log"

rule roads_euclidean_distance:
    input: ROADS_RASTER
    output: ROADS_RASTER_DISTANCE
    log: LOGD / "roads_euclidean_distance_{year}.log"
    conda: '../envs/whitebox.yml'
    shell: '''
        mkdir -p $(dirname {output})
        whitebox_tools -r=EuclideanDistance -v -wd="$(dirname {input})" -i=$(basename {input}) -o={output}
    '''

use rule roads_euclidean_distance as rail_euclidean_distance with:
    input: RAIL_RASTER
    output: RAIL_RASTER_DISTANCE
    log: LOGD / "/rail_euclidean_distance_{year}.log"

rule roads_footprint:
    input: ROADS_RASTER_DISTANCE
    output: ROADS_FOOTPRINT
    log: LOGD / "/roads_footprint_{year}.log"
    conda: '../envs/gdal.yml'
    params:
        creation_options=" ".join(f'--co {k}={v}' for k, v in config['compression_co']['zstd_pred3'].items()),
        calc='(A<=500)*8+((A>500)&(A<15000))*(3.75*exp(-1.0*((A/1000.0)-1.0))+0.25)+(A>=15000)*0'
    shell: '''
        mkdir -p $(dirname {output})
        gdal_calc.py --outfile={output} --calc="{params.calc}" -A {input} \
            --type Float32 --overwrite {params.creation_options}
        gdal_edit.py -stats {output}
    '''

use rule roads_footprint as rail_footprint with:
    input: RAIL_RASTER_DISTANCE
    output: RHEADAIL_FOOTPRINT
    log: LOGD / "/rail_footprint_{year}.log"
    params:
        creation_options=" ".join(f'--co {k}={v}' for k, v in config['compression_co']['zstd_pred3'].items()),
        calc='(A<=500)*8+(A>500)*0'
