### Secrets

Create a file, `secrets.env` or similar, and fill it with secrets of the form:

```env
LINZ_KEY=abc...
LRIS_KEY=xyz...
```

Then use this file to set environment variables immediately before running the Snakemake CLI:

`set -o allexport && source secrets.env && set +o allexport && snakemake ...`