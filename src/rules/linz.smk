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
        2018: '89079bb19736b01c21ad06a8eb0b6a4cf81bf29c', # 2018-02-02
        2019: '403f16ebeb4a5bf5948389d113d3c3cee0cd7028', # 2018-12-12
        2020: '44821f5f99345d208c55bb0ce2d7a2fdd26f0112', # 2020-02-16
        2021: '48eaad62d886c4fdf009f4ce2b3acde3c49153dc', # 2021-02-19
        2021: '4d98ce495eb534ac52ae5705776a8c1351135ea5', # 2021-12-20
        2022: '4d98ce495eb534ac52ae5705776a8c1351135ea5', # 2021-12-20
        2023: '8b52eae6c1a9a4ef97ad56cd8703206da6085b2a', # 2022-09-23 # TODO more recent updates?
    }
} # NZ Railway Centrelines (Topo, 1:50k)


LINZ_YEARS = list(map(str, range(2012, 2024)))

def get_kart_roads_sha(year: int, layer: str) -> str:
    available_years = ROADS_SHAS[layer].keys()
    year = max(min(available_years), year) # Clamp to lower end
    try:
        return ROADS_SHAS[layer][year]
    except KeyError:
        return get_kart_roads_sha(year-1, layer) # Try previous year

# TODO DRY
def get_kart_rail_sha(year: int, layer: str) -> str:
    available_years = RAIL_SHAS[layer].keys()
    year = max(min(available_years), year) # Clamp to lower end
    try:
        return RAIL_SHAS[layer][year]
    except KeyError:
        return get_kart_rail_sha(year-1, layer) # Try previous year

MAINLAND_ROADS = "data/downloads/roads/mainland/{year}/roads-mainland-{year}.gpkg"
CHATHAMS_ROADS = "data/downloads/roads/chathams/{year}/roads-chathams-{year}.gpkg"
ROADS = "data/downloads/roads/{year}/roads-{year}.gpkg"
ROADS_RASTER = "data/downloads/roads/{year}/roads-{year}.tif"

RAIL = "data/downloads/rail/{year}/rail-{year}.gpkg"
RAIL_RASTER = "data/downloads/rail/{year}/rail-{year}.tif"

rule checkout_roads_mainland:
    output: MAINLAND_ROADS
    wildcard_constraints:
        year=f'({"|".join(LINZ_YEARS)})'
    conda: '../envs/gdal.yml'
    log: f"{LOGS_DIR}/checkout_roads_mainland_{{year}}.log"
    params:
        layer='layer-50329',
        workingcopy=lambda wildcards: f'data/clones/roads/mainland/{wildcards.year}',
        kart_hash=lambda wildcards: get_kart_roads_sha(int(wildcards.year), 'layer-50329')
    shell:
        '''
        rm -rf {output} && rm -rf {params.layer} \
        && kart clone --workingcopy-location {output} --progress kart@data.koordinates.com:land-information-new-zealand/{params.layer} {params.workingcopy} \
        && cd {params.workingcopy} && kart checkout {params.kart_hash} && cd -
        '''

use rule checkout_roads_mainland as checkout_roads_chathams with:
    output: CHATHAMS_ROADS
    log: f"{LOGS_DIR}/checkout_roads_chathams_{{year}}.log"
    params:
        layer='layer-50100',
        workingcopy=lambda wildcards: f'data/clones/roads/chathams/{wildcards.year}',
        kart_hash=lambda wildcards: get_kart_roads_sha(int(wildcards.year), 'layer-50100')

rule merge_roads:
    input: MAINLAND_ROADS, CHATHAMS_ROADS
    output: ROADS
    log: f"{LOGS_DIR}/merge_roads_{{year}}.log"
    conda: '../envs/gdal.yml'
    params:
        nln='roads'
    shell:
        '''
        mkdir -p $(dirname {output}) && \
        ogrmerge.py -o {output} {input} -f GPKG -single -nln {params.nln} -overwrite_ds \
        -t_srs EPSG:3851 -progress   
        '''

use rule checkout_roads_mainland as checkout_rail_mainland with:
    output: RAIL
    log: f"{LOGS_DIR}/checkout_rail_mainland{{year}}.log"
    params:
        layer='layer-50319',
        workingcopy=lambda wildcards: f'data/clones/rail/mainland/{wildcards.year}',
        kart_hash=lambda wildcards: get_kart_rail_sha(int(wildcards.year), 'layer-50319')

rule roads_rasterisation:
    input: ROADS
    output: ROADS_RASTER
    log: f"{LOGS_DIR}/roads_rasterisation_{{year}}.log"
    conda: '../whitebox.yml'
    shell:
        '''
        mkdir -p $(dirname {output}) && \
        whitebox_tools --help
        '''

use rule roads_rasterisation as rail_rasterisation with:
    input: RAIL
    output: RAIL_RASTER
    log: f"{LOGS_DIR}/rail_rasterisation_{{year}}.log"