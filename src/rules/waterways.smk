COASTLINE = OUTD / 'data/downloads/coastlines/coastlines.gpkg'
COASTLINE_3851 = OUTD / 'data/downloads/coastlines/coastlines.3851.gpkg'
COASTLINE_RASTER = OUTD / 'data/downloads/coastlines/coastlines.tif'

LAKES = OUTD / 'data/downloads/lakes/lakes.gpkg'
LAKES_3851 = OUTD / 'data/downloads/lakes/lakes.3851.gpkg'
LAKES_EXTERIOR = OUTD / 'data/downloads/lakes/lakes-exterior-rings.gpkg'
LAKES_EXTERIOR_RASTER = OUTD / 'data/downloads/lakes/lakes-exterior-rings.tif'

RIVERS_REC = OUTD / 'data/downloads/rivers-rec2/rivers-rec2.gpkg'
PREEXISTING_RIVER_DATA = 'static/NZRiverMaps_data_2023-09-07.csv'
RIVERS_REC_FILTERED = OUTD / 'data/downloads/rivers-rec2/rivers-rec2.attributes.filtered.gpkg'
RIVERS_REC_FILTERED_3851 = OUTD / 'data/downloads/rivers-rec2/rivers-rec2.attributes.filtered.3851.gpkg'
RIVERS_RASTER = OUTD / 'data/downloads/rivers-rec2/rivers-rec2.attributes.filtered.tif'
RIVERS_RASTER_NO_LAKES = OUTD / 'data/downloads/rivers-rec2/rivers-rec2.attributes.filtered.no_lakes.tif'

NAVIGABLE_WATER_EDGES = OUTD / 'data/downloads/navigable-water/navigable-water.tif'
VNL_BUFFER = OUTD / 'data/downloads/navigable-water/vnl-buffer-{year}.tif'
NAVIGABLE_WATER_WITHIN = OUTD / 'data/downloads/navigable-water/navigable-water-within-distance-{year}.tif'
NAVIGABLE_WATER_COST_DISTANCE = OUTD / 'data/downloads/navigable-water/navigable-water-cost-distance-{year}.tif'
NAVIGABLE_WATER_EUCLIDEAN_DISTANCE = OUTD / 'data/downloads/navigable-water/navigable-water-cost-euclidean-distance-{year}.tif'

NAVIGABLE_WATER_FOOTPRINT = OUTD / 'data/footprints/navigable-water/navigable-water-{year}.tif'


rule checkout_coastlines:
    output: COASTLINE
    conda: '../envs/gdal.yml'
    log: LOGD / "checkout_coastlines.log"
    params:
        layer='layer-105085',
        workingcopy=lambda wildcards: f'data/clones/coastlines',
    shell: '''
        rm -rf {output} && rm -rf {params.workingcopy}
        kart clone --workingcopy-location {output} --progress kart@data.koordinates.com:land-information-new-zealand/{params.layer} {params.workingcopy}
    '''

rule reproject_coastlines:
    input: COASTLINE
    output: COASTLINE_3851
    conda: '../envs/gdal.yml'
    log: LOGD / "reproject_coastlines.log"
    shell: '''
        ogr2ogr -t_srs EPSG:3851 {output} {input}
    '''

rule rasterise_coastlines:
    input: COASTLINE_3851
    output: COASTLINE_RASTER
    conda: '../envs/gdal.yml'
    log: LOGD / "rasterise_coastlines.log"
    params:
        extent=config['extent']
    shell: '''
        mkdir -p $(dirname {output})
        gdal_rasterize -at -b -burn 1 -of GTiff -ot Byte -init 0 \
            -tr 100 100 -te {params.extent} \
            {input} {output}
        gdal_edit.py -stats -a_srs EPSG:3851 {output}
    '''
    
use rule checkout_coastlines as checkout_lakes with:
    output: LAKES
    log: LOGD / "checkout_lakes.log"
    params:
        layer='layer-50212', # NZ Lake Polygons (Topo, 1:500k)
        workingcopy=lambda wildcards: f'data/clones/lakes',

use rule reproject_coastlines as reproject_lakes with:
    input: LAKES
    output: LAKES_3851
    log: LOGD / "reproject_lakes.log"

rule lakes_exterior_ring:
    input: LAKES_3851
    output: LAKES_EXTERIOR
    conda: '../envs/gdal.yml'
    log: LOGD / "lakes_exterior_ring.log"
    params:
        layer_name='nz_lake_polygons_topo_1500k'
    shell: '''
        ogr2ogr {output} {input} -dialect sqlite -f "GPKG" -sql "SELECT ST_ExteriorRing(geometry) AS geometry FROM {params.layer_name}"
    '''

use rule rasterise_coastlines as rasterise_lakes with:
    input: LAKES_EXTERIOR
    output: LAKES_EXTERIOR_RASTER
    log: LOGD / "rasterise_lakes.log"

rule download_rec25:
    output: RIVERS_REC
    conda: '../envs/gdal.yml'
    log: LOGD / "download_rec25.log"
    params:
        url="https://services3.arcgis.com/fp1tibNcN9mbExhG/arcgis/rest/services/REC2_Layers/FeatureServer/0/query?where=objectid%3Dobjectid&objectIds=&time=&geometry=&geometryType=esriGeometryPolyline&inSR=&spatialRel=esriSpatialRelIntersects&resultType=none&distance=0.0&units=esriSRUnit_Meter&relationParam=&returnGeodetic=false&outFields=*&returnGeometry=true&featureEncoding=esriDefault&multipatchOption=xyFootprint&maxAllowableOffset=&geometryPrecision=&outSR=&defaultSR=&datumTransformation=&applyVCSProjection=false&returnIdsOnly=false&returnUniqueIdsOnly=false&returnCountOnly=false&returnExtentOnly=false&returnQueryGeometry=false&returnDistinctValues=false&cacheHint=false&orderByFields=&groupByFieldsForStatistics=&outStatistics=&having=&resultOffset=&resultRecordCount=&returnZ=false&returnM=false&returnExceededLimitFeatures=true&quantizationParameters=&sqlFormat=none&f=json&token="
    shell: '''
        rm -f {output}
        ogr2ogr -f GPKG {output} "{params.url}" -gt 10000
    '''

rule rec_join_and_filter:
    input: RIVERS_REC
    output: RIVERS_REC_FILTERED
    conda: '../envs/geopandas.yml'
    params:
        rec_attributes=PREEXISTING_RIVER_DATA
    log: LOGD / "rec_join_and_filter.log"
    script: '../scripts/rec-join.py'

use rule reproject_coastlines as reproject_rec with:
    input: RIVERS_REC_FILTERED
    output: RIVERS_REC_FILTERED_3851

rule rasterise_rivers:
    input: RIVERS_REC_FILTERED_3851
    output: RIVERS_RASTER
    conda: '../envs/gdal.yml'
    log: LOGD / "rasterise_rivers.log"
    params:
        extent=config['extent']
    shell: '''
        mkdir -p $(dirname {output})
        gdal_rasterize -at -b -burn 1 -of GTiff -ot Byte -init 0 \
            -tr 100 100 -te {params.extent} \
            {input} {output}
        gdal_edit.py -stats -a_srs EPSG:3851 {output}
    '''

rule remove_rivers_in_lakes:
    input:
        rivers=RIVERS_RASTER,
        lakes=LAKES_3851
    output: RIVERS_RASTER_NO_LAKES
    conda: '../envs/gdal.yml'
    log: LOGD / "remove_rivers_in_lakes.log"
    params:
        tmp=TMPD,
        extent=config['extent'],
        creation_options=" ".join(f'--co {k}={v}' for k, v in config['compression_co']['zstd_pred2'].items())
    shell: '''
        mkdir -p $(dirname {params.tmp}/{input.lakes})
        gdal_rasterize -at -b -burn 1 -of GTIFF -ot Byte -init 0 \
            -tr 100 100 -te {params.extent} \
            {input.lakes} {params.tmp}/{input.lakes}.tif
        mkdir -p $(dirname {output})
        gdal_calc.py --outfile={output} --hideNoData -A {params.tmp}/{input.lakes}.tif -B {input.rivers} \
            --calc="(A==1)*0+logical_and(A==0,B==1)*B+logical_and(A==1,B==1)*0" \
            --NoDataValue=0 --type=Byte --overwrite {params.creation_options}
        gdal_edit.py -stats -a_srs EPSG:3851 {output}
    '''

rule merge_navigable_water:
    input: RIVERS_RASTER_NO_LAKES, LAKES_EXTERIOR_RASTER, COASTLINE_RASTER
    output: NAVIGABLE_WATER_EDGES
    conda: '../envs/gdal.yml'
    log: LOGD / "merge_navigable_water.log"
    params:
        creation_options=" ".join(f'--co {k}={v}' for k, v in config['compression_co']['lzw_pred2'].items())
    shell: '''
        mkdir -p $(dirname {output})
        gdal_calc.py --outfile={output} -A {input[0]} -B {input[1]} -C {input[2]} \
            --calc="maximum(maximum(A,B),C)" \
            --hideNoData --NoDataValue=0 --type=Int32 --overwrite {params.creation_options}
        gdal_edit.py -stats -a_srs EPSG:3851 {output}
    '''

rule night_light_buffer:
    input: VNL
    output: VNL_BUFFER
    wildcard_constraints:
        year='\d{4}'
    conda: '../envs/whitebox.yml'
    log: LOGD / "night_light_buffer-{year}.log"
    wildcard_constraints:
        year=f'({"|".join(VNL_YEARS)})'
    params:
        distance=4000, # 4,000 metres (units of the CRS, i.e. EPSG:3851)
    shell: '''
        rm -rf {output}
        whitebox_tools -r=BufferRaster -v --wd="$(dirname {input})" --input=$(basename {input}) -o={output} --size={params.distance}
        gdal_edit.py -stats -a_srs EPSG:3851 {output}
    '''

rule naviagable_water_within_distance:
    input:
        navigable_water=NAVIGABLE_WATER_EDGES,
        vnl_buffer=VNL_BUFFER
    output: NAVIGABLE_WATER_WITHIN
    conda: '../envs/gdal.yml'
    log: LOGD / "naviagable_water_within_distance-{year}.log"
    wildcard_constraints:
        year=f'({"|".join(VNL_YEARS)})'
    params:
        creation_options=" ".join(f'--co {k}={v}' for k, v in config['compression_co']['lzw_pred2'].items())
    shell: '''
        rm -rf {output}
        gdal_calc.py -A {input.navigable_water} -B {input.vnl_buffer} --outfile={output} --calc="logical_and(A==1,B==1)*1" \
            --NoDataValue=0 --type=Int32 --overwrite {params.creation_options}
        gdal_edit.py -stats -a_srs EPSG:3851 {output}
    '''

rule navigable_water_cost_distance_grass:
    input:
        source=NAVIGABLE_WATER_WITHIN,
        cost=NAVIGABLE_WATER_EDGES
    output: NAVIGABLE_WATER_COST_DISTANCE
    shadow: "shallow"
    container: "docker://osgeo/grass-gis:releasebranch_8_3-alpine"
    log: LOGD / "cost_distance_grass-{year}.log"
    params:
        tmp=TMPD,
        grassdata="grassdata/navigable_water",
        mapset="PERMANENT",
        grass_exe="grass grassdata/navigable_water/PERMANENT/ --exec",
        extent=config['extent'],
        max_cost=800, # 800 * 100m = 80,000m = 80km
        creation_options_grass="createopt=\"" + ",".join(f'{k}={v}' for k, v in config['compression_co']['zstd_pred3'].items()) + "\"",
        creation_options=" ".join(f'-co {k}={v}' for k, v in config['compression_co']['zstd_pred3'].items())
    shell: '''
        rm -rf {params.grassdata}
        rm -f {log}
        rm -f {output}
        rm -f {params.tmp}/$(basename {output})
        (
            grass -c {input.cost} -e {params.grassdata} && \
            {params.grass_exe} r.in.gdal -e -k --verbose --overwrite input="{input.cost}" output="$(basename -s .tif {input.cost})" memory=2048 && \
            {params.grass_exe} r.in.gdal -k --verbose --overwrite input="{input.source}" output="$(basename -s .tif {input.source})" memory=2048 && \
            {params.grass_exe} r.cost -k -n input=$(basename -s .tif {input.cost}) start_raster=$(basename -s .tif {input.source}) output=$(basename -s .tif {output}) max_cost={params.max_cost} memory=14000 && \
            {params.grass_exe} r.out.gdal -f -c input=$(basename -s .tif {output}) {params.creation_options_grass} type=Float32 output={params.tmp}/$(basename {output})
        ) 2>&1 | tee {log}
        gdalwarp -tr 100 100 -te {params.extent} -overwrite {params.creation_options} \
            {params.tmp}/$(basename {output}) {output}
        gdal_edit.py -stats {output}
    '''


rule navigable_water_euclidean_distance:
    input:
        cost_distance=NAVIGABLE_WATER_COST_DISTANCE,
        source=NAVIGABLE_WATER_WITHIN
    output: NAVIGABLE_WATER_EUCLIDEAN_DISTANCE
    log: LOGD / "navigable_water_euclidean_distance-{year}.log"
    conda: '../envs/gdal.yml'
    params:
        tmp=TMPD,
        creation_options_a=" ".join(f'--co {k}={v}' for k, v in config['compression_co']['lzw_pred2'].items()),
        creation_options_b=" ".join(f'-co {k}={v}' for k, v in config['compression_co']['lzw_pred2'].items())
    shell: '''
        mkdir -p $(dirname {output})
        gdal_calc.py --outfile={params.tmp}/$(basename {output}) -A {input.cost_distance} -B {input.source} --calc="where(isnan(A+B),0,1)" --hideNoData --NoDataValue=0 \
            --type=Byte --overwrite {params.creation_options_a}
        gdal_proximity.py {params.tmp}/$(basename {output}) {output} -of GTiff -ot Float32 -maxdist 15000 -use_input_nodata NO -distunits GEO {params.creation_options_b} -co BIGTIFF=YES
    '''

rule navigable_water_footprint:
    input: NAVIGABLE_WATER_EUCLIDEAN_DISTANCE,
    output: NAVIGABLE_WATER_FOOTPRINT
    log: LOGD / "roads_footprint_{year}.log"
    conda: '../envs/gdal.yml'
    params:
        calc='((A>=0)&(A<15000))*(4*exp(-1.0*(A/1000.0)))+(A>=15000)*0',
        creation_options=" ".join(f'--co {k}={v}' for k, v in config['compression_co']['zstd_pred3'].items())
    shell: '''
        mkdir -p $(dirname {output})
        gdal_calc.py --outfile={output} --calc="{params.calc}" -A {input} \
            --type Float32 --overwrite {params.creation_options}
        gdal_edit.py -stats {output}
    '''