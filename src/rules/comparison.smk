MU_DATA = {
    '2000': 'https://figshare.com/ndownloader/files/30716462',
    '2001': 'https://figshare.com/ndownloader/files/30716564',
    '2002': 'https://figshare.com/ndownloader/files/30716567',
    '2003': 'https://figshare.com/ndownloader/files/30716570',
    '2004': 'https://figshare.com/ndownloader/files/30716573',
    '2005': 'https://figshare.com/ndownloader/files/30716525',
    '2006': 'https://figshare.com/ndownloader/files/30716528',
    '2007': 'https://figshare.com/ndownloader/files/30716531',
    '2008': 'https://figshare.com/ndownloader/files/30716534',
    '2009': 'https://figshare.com/ndownloader/files/30716126',
    '2010': 'https://figshare.com/ndownloader/files/30716537',
    '2011': 'https://figshare.com/ndownloader/files/30716540',
    '2012': 'https://figshare.com/ndownloader/files/30716543',
    '2013': 'https://figshare.com/ndownloader/files/30716546',
    '2014': 'https://figshare.com/ndownloader/files/30716549',
    '2015': 'https://figshare.com/ndownloader/files/30716552',
    '2016': 'https://figshare.com/ndownloader/files/30716555',
    '2017': 'https://figshare.com/ndownloader/files/30716558',
    '2018': 'https://figshare.com/ndownloader/files/30716561',
    '2019': 'https://figshare.com/ndownloader/files/40978571',
    '2020': 'https://figshare.com/ndownloader/files/40978574',
}

GLOBAL_HFP = OUTD / 'data/downloads/hfp/{year}/hfp{year}.tif'
GLOBAL_HFP_DIFF = OUTD / 'data/footprints/diffs/{year}/hfp{year}-diff.tif'


# Download data for year
# Warp/clip/resample to matching 3851 grid
rule download_project_clip_global_hfp:
    output: GLOBAL_HFP
    wildcard_constraints:
        year='\d{4}'
    params:
        url=lambda wildcards: MU_DATA[wildcards.year],
        extent=config['extent'],
        creation_options=" ".join(f'-co {k}={v}' for k, v in config['compression_co']['zstd_pred3'].items())
    conda: '../envs/gdal.yml'
    log: LOGD / "download_project_clip_global_hfp_{year}.log"
    shell: '''
        mkdir -p $(dirname {output})
        curl -L -o - {params.url} | gunzip > {output}.ESRI54009.tif
        gdal_edit.py -stats {output}.ESRI54009.tif
        gdalwarp -t_srs EPSG:3851 -t_coord_epoch {wildcards.year}.0 \
            -r near -tr 100 100 -te {params.extent} -overwrite {params.creation_options}\
            -multi -wo NUM_THREADS=ALL_CPUS \
            {output}.ESRI54009.tif {output}
        gdal_edit.py -stats {output}
    '''

# Calculate a diff and write it out, noting it should be a signed float
rule calculate_diff:
    input:
        _global=GLOBAL_HFP,
        nz=FOOTPRINT
    output: GLOBAL_HFP_DIFF
    conda: '../envs/gdal.yml'
    log: LOGD / "calculate_diff_{year}.log"
    params:
        creation_options=" ".join(f'--co {k}={v}' for k, v in config['compression_co']['zstd_pred3'].items())
    shell: '''
        mkdir -p $(dirname {output})
        gdal_calc.py -A {input._global} -B {input.nz} --calc=A-B \
            --outfile {output} --overwrite {params.creation_options}
        gdal_edit.py -stats {output}
    '''