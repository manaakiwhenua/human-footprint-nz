WORLDPOP_YEARS = list(map(str, range(2000, 2021)))

WORLDPOP = OUTD / 'data/downloads/worldpop/nzl_ppp_{year}.tif'
WORLDPOP_NZ = OUTD / 'data/downloads/worldpop/nzl_ppp_{year}.3851.tif'
WORLDPOP_NZ_LANDMASKED = OUTD / 'data/downloads/worldpop/nzl_ppp_{year}.3851.landmasked.tif'
WORLDPOP_FOOTPRINT_NZ = OUTD / 'data/footprints/population-density/nzl_ppp_{year}.3851.tif'

def worldpop_endpoint(year: int):
    # https://hub.worldpop.org/geodata/listing?id=76
    # return f'https://data.worldpop.org/GIS/Population_Density/Global_2000_2020_1km/{year}/NZL/nzl_pd_{year}_1km.tif'
    year = get_nearest(WORLDPOP_YEARS, year)
    return f'https://data.worldpop.org/GIS/Population/Global_2000_2020/{year}/NZL/nzl_ppp_{year}.tif'

# Data is people per pixel, but pixels are not equal area,
# so population density cannot immediately be inferred from this
rule download_worldpop:
    output: WORLDPOP
    wildcard_constraints:
        year='\d{4}'
    conda: '../envs/gdal.yml'
    log: LOGD / "download_worldpop_{year}.log"
    params:
        url=lambda wildcards: worldpop_endpoint(int(wildcards.year)),
        creation_options=" ".join(f'-co {k}={v}' for k, v in config['compression_co']['zstd_pred3'].items())
    shell: '''
        mkdir -p $(dirname /tmp/{output})
        gdal_translate {params.url} {output} {params.creation_options}
    '''

# Unit is people per pixel, i.e. people per 100m2
# This performs a weighted sum, to return data to a projection that actually uses metres
# (This is also a slight downsample)
rule reproject_worldpop:
    input: WORLDPOP
    output: WORLDPOP_NZ
    conda: '../envs/gdal.yml'
    log: LOGD / "reproject_worldpop_{year}.log"
    params:
        extent=config['extent'],
        creation_options=" ".join(f'-co {k}={v}' for k, v in config['compression_co']['zstd_pred3'].items())
    shell: '''
        gdalwarp -t_srs EPSG:3851 -t_coord_epoch {wildcards.year}.0 \
            -r sum -tr 100 100 -te {params.extent} \
            -overwrite {params.creation_options} \
            {input} {output}
        gdal_edit.py -stats {output}
        '''

# Includes a mask with the NZ coastline,
#   as there are some spurious population densities on coastal waters
rule mask_worldpop:
    input:
        population=WORLDPOP_NZ,
        coastline=NZ_COAST_RASTER
    output: WORLDPOP_NZ_LANDMASKED
    conda: '../envs/gdal.yml'
    log: LOGD / "mask_worldpop_{year}.log"
    params:
        creation_options=" ".join(f'--co {k}={v}' for k, v in config['compression_co']['zstd_pred3'].items())
    shell: '''
        mkdir -p $(dirname {output})
        gdal_calc.py --outfile={output} \
            --calc="(B==0)*0+isnan(A)*0+(A<0)*0+logical_and(B==1,A>0)*A" \
            -A {input.population} -B {input.coastline} --hideNoData --NoDataValue=none \
            --type=Float32 --overwrite {params.creation_options}
        gdal_edit.py -stats {output}
    '''

# Original footprint formula used 1km2, and max value was 1000 people per pixel, i.e. 1000 people per km2
# To convert this to 100m2, this is 1/100 of 1km2, so 1/100*1000 = 10; therefore the max value is 10 people per 100m2
#   10 | where people per pixel (ppp) is greater than or equal to 10
#   3.333 * log(people/km2 + 1) | where ppp is greater than 0 and less than 10
#   0 | otherwise
rule footprint_worldpop:
    input: WORLDPOP_NZ_LANDMASKED
    output: WORLDPOP_FOOTPRINT_NZ
    conda: '../envs/gdal.yml'
    log: LOGD / "footprint_worldpop_{year}.log"
    params:
        creation_options=" ".join(f'--co {k}={v}' for k, v in config['compression_co']['zstd_pred3'].items())
    shell: '''
        mkdir -p $(dirname {output})
        gdal_calc.py --outfile={output} \
            --calc="0*(A==0)+0*(A>=3.3e38)+10*(A>=10)+((A<10)&(A>0))*(3.333*log10(A*100+1))" \
            -A {input} --hideNoData --type=Float32 --overwrite {params.creation_options}
        gdal_edit.py -stats {output}
    '''