# Human Footprint NZ

Implementation of https://www.nature.com/articles/s41597-022-01284-8 for New Zealand

## Human pressure variables implementation status

- [x] Built environments
- [x] Population denisty
- [x] Nighttime lights
- [x] Crop land
- [x] Pasture land
- [x] Roads
- [x] Railways
- [x] Navigable waterways

![Human Footprint Index for 2018](<HFI-2018.png>)

![Components of the Human Footprint Index for 2018](<9-square.png>)


## Visual workflow summary

![Generated with: `set -o allexport && source secrets.env && set +o allexport && snakemake --snakefile ./src/Snakefile --profile profiles/default -f all --rulegraph | dot -Tpng > rulegraph.png`](<rulegraph.png>)

## Reproduction

### Secrets

Create a file, `secrets.env` or similar, and fill it with the following secrets of the form:

```env
LINZ_KEY=abc...
LRIS_KEY=xyz...
```

Then use this file to set environment variables immediately before running the `snakemake` command:

```bash
set -o allexport && source secrets.env && set +o allexport && snakemake --snakefile ./src/Snakefile --profile ./profiles/default all
```

These keys are API keys for Koordinates-platform Web Feature Service APIs; they are necessary to download dependent data from Koordinates ([LRIS](lris.scinfo.org.nz/) and the [LINZ Data Service](data.linz.govt.nz/)).

### Technnical Dependencies

1. The workflow depends on [Conda](https://docs.conda.io/en/latest/) (ideally with [Mamba](https://mamba.readthedocs.io/en/latest/))

    - [SnakeMake](https://snakemake.readthedocs.io/en/stable/); install via `mamba install -c conda-forge -c bioconda snakemake`.
    - Beyond that, SnakeMake itself will manage Conda environments for running commands.

1. The workflow depends on [Kart](https://github.com/koordinates/kart); follow the official installation instructions.

    - The instructions currently lack information about adding a public key to be able to clone Kart repositories. Go to https://id.koordinates.com/ssh-keys/ and click "Add Public Key" to add one. If you don't have an SSH key, work through [Github documentation](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account) until you do, as the idea is identical, except that you will add your public key to Koordinates rather than to Github.

1. The workflow depends on [git-lfs](https://git-lfs.com/), due to dependence on static rivers data that cannot be downloaded programmatically.

1. The workflow depends on [Docker](https://www.docker.com/) (for access to [GRASS GIS](https://grass.osgeo.org/)).

1. The workflow depends on [Singularity](https://docs.sylabs.io/guides/3.0/user-guide/installation.html).

_This workflow has only been run on Linux._

### Pre-existing river data

Data for median flow (and wetted width at median flow) for all NZ rivers (REC) were manually downloaded from https://shiny.niwa.co.nz/nzrivermaps/ on 2023-09-07. It does not appear possible to download these data programmatically, as the web interface relies on a session token. Note that these data only exist for the North, South, and Stewart Islands.

![Image of download parameters](<static/Screenshot from 2023-09-07 14-47-23.png>)

## Contact

- Oliva Burge (project leader)
- Richard Law (technical implementation)