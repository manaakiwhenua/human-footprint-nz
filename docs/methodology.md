We generated the annual records of the Global Human Footprint for 2012 and 2018. These years are selected because two of the component layers (cropland and pasture) are determined by one source of data [[1]](#1) that is produced on a six-year cycle. With the exception of the built environment in 2012 (for which we use data for 2010), and navigable waterways (which we assume are static and use the latest available data), all other sources of data are also available for these years.

The Snakemake workflow management system is used to create a reproducible and scalable data analysis [[X]](#X). This entails a description of all required software, and ultimate sources of input data, that is required to reproduce these results. The workflow is intended to be transferrable to other machines, and adapted if desired.

All data is first reprojected and clipped to a common grid, and resampled to the same resolution (100 m²). The projection used is the New Zealand Continental Shelf Lambert Conformal 2000 (EPSG:3851), which applies to both mainland New Zealand and offshore islands including the Chatham Islands.

## Human pressure Variables

Like [[2]](#2) we followed the approach of [[3]](#3), but did so at a higher spatial resolution, using national sources of data specific to New Zealand where this was feasible to support the higher spatial resolution.

### Built environments

We used data produced by the Global Human Settlement Layer (GHSL), specifically the GHS-BUILT-S R2023A [[4]](#4). This is a geospatial representation of the built-up surface, expressed as the number of square metres per pixel, both residential and non-residential surfaces, dervied from Sentinel-2 and Landsat. The 2018 year is published at 10 m resolution and is actually downsampled (using a weighted summation).

This is readily converted into a footprint score using the equation:

$$
F = \begin{cases} 10 & \text{if $x > 2000$} \\
4 & \text{if $x > 0$} \\
0 & \text{otherwise} \end{cases}
$$

Noting that a fully built-up pixel would have a value of 10,000 (100 m²), and that therefore 2,000 represents a point where 20% of a pixel is built-up.

### Population density

### Night-time lights

### Croplands

### Pasture

### Roads

### Railways

### Navigable waterways

## References
<a id="1">[1]</a>
https://doi.org/10.26060/W5B4-WK93

<a id="2">[2]</a>
Mu, H., Li, X., Wen, Y. et al. A global record of annual terrestrial Human Footprint dataset from 2000 to 2018. Sci Data 9, 176 (2022). https://doi.org/10.1038/s41597-022-01284-8

<a id="3">[3]</a>
Venter, O., Sanderson, E., Magrach, A. et al. Global terrestrial Human Footprint maps for 1993 and 2009. Sci Data 3, 160067 (2016). https://doi.org/10.1038/sdata.2016.67

<a id="4">[4]</a>
Pesaresi M., Politis P. (2023):
GHS-BUILT-S R2023A - GHS built-up surface grid, derived from Sentinel2 composite and Landsat, multitemporal (1975-2030)European Commission, Joint Research Centre (JRC)
PID: http://data.europa.eu/89h/9f06f36f-4b11-47ec-abb0-4f8b7b1d72ea, doi:10.2905/9F06F36F-4B11-47EC-ABB0-4F8B7B1D72EA

<a id="X">[X]</a>
Mölder, F., Jablonski, K.P., Letcher, B., Hall, M.B., Tomkins-Tinch, C.H., Sochat, V., Forster, J., Lee, S., Twardziok, S.O., Kanitz, A., Wilm, A., Holtgrewe, M., Rahmann, S., Nahnsen, S., Köster, J., 2021. Sustainable data analysis with Snakemake. F1000Res 10, 33.