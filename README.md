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

_This workflow has only been run on Linux._

## Contact

- Oliva Burge (project leader)
- Richard Law (technical implementation)