We generated the annual records of the Global Human Footprint for 2012 and 2018. These years are selected because two of the component layers (cropland and pasture) are determined by one source of data [[1]](#1) that is produced on a six-year cycle. Except for the built environment in 2012 (for which we use data for 2010), and navigable waterways (which we assume are static and use the latest available data), all other sources of data are also available for these years.

All data is first reprojected and clipped to a common grid, and resampled to the same resolution (100 m²). The projection used is the New Zealand Continental Shelf Lambert Conformal 2000 (EPSG:3851), which applies to both mainland New Zealand and offshore islands including the Chatham Islands.

## Human pressure Variables

Like [[2]](#2) we followed the approach of [[3]](#3), but did so at a higher spatial resolution, using national sources of data specific to New Zealand where this was feasible to support the higher spatial resolution.

### Built environments

We used data produced by the Global Human Settlement Layer (GHSL), specifically the GHS-BUILT-S R2023A [[4]](#4). This is a geospatial representation of the built-up surface, expressed as the number of square metres per pixel, both residential and non-residential surfaces, dervied from Sentinel-2 and Landsat. The 2018 year is published at 10 m resolution and is actually downsampled (using a weighted summation).

This is readily converted into a footprint score using the rule:

$$
F = \begin{cases} 10 & \text{if $x > 2000$} \\
4 & \text{if $0 < x \le 2000$} \\
0 & \text{otherwise} \end{cases}
$$

Noting that a fully built-up pixel would have a value of 10,000 (100 m²), and that therefore 2,000 represents a point where 20% of a pixel is built-up.

### Population density

We used the global population density data provided by WorldPop, which produces population estimates from building footprints, on a 1 km² grid [[5]](#5). WorldPop is focussed on low- and middle-income countries where official sources of population density data do not typically exist. We could have used Statistics New Zealand's geographic data, but there are two relevant complications. One is that the statistical standard for geographic areas was recently changed, removing the smallest geographic unit in the statistical geographic hierarchy, the meshblock, when publishing census information. [[6]](#6). Instead, two new levels (statistical areas 1 and 2) were introduced, which are composed of contiguous clusters of one or more meshblocks. Meshblocks themselves are not ideal units with which to compute population density, as they include both habited and inhabited (or even inhabitable) parts, particularly at the margins of settlements. The unavailability of meshblocks for most recent population data compounds this problem, and introduces a temporal consistency issue. Statistics New Zealand has a protype "population grid" (at 1 km², 500 m², and 250 m²) which normalises the geographic unit and would be ideal to use, but this is only published with data from the 2018 census. WorldPop data was therefore used for consistency, and also because it is available with annual population density estimates.

WorldPop data does appear to have spurious population estimates in unexpected places, including in territorial waters. A coastline mask is applied to the downloaded data to remove these data, but others may remain, for example within national parks.

WorldPop data is given in units of people per pixel; nominally pixels are 100 m² but the data does not actually use an equal-area projection, so a conversion is first made using a weighted sum algorithm to EPSG:3851.

The value (people per 100 m²) is converted to a footprint score using the equation:

$$
F = \begin{cases} 10 & \text{if $x \ge 10$} \\
3.333\cdot\log_{10}(x+1) & \text{if $0 < x < 10$} \\
0 & \text{otherwise} \end{cases}
$$

### Night-time lights

Annual composite night-time light data are obtained from the Earth Observation Group (EOG) at the Colorodo School of Mines, Annual VIIRS Nighttime lights (VNL) V2 [[7]](#7). Annual composition includes the removal of temporal lights (e.g. fires) and background values, and is ultimately derived from night-time data from the Visible Infrared Imaging Radiometer Suite (VIIRS) Day/Night Band (DNB) [[8]](#8).

The units are median monthly radiance, in units of nW cm¯² sr¯¹. The data is clipped to the same New Zealand geogrpaphical area as the other component layers, and then scaled to a 0-255 range to facilitate the computation of deciles for the Human Footprint index. The boundaries of ten equal deciles are determined ignoring values of 0, and the decile (1 to 10), or 0, is directly used as the footprint score.

### Croplands (including forestry)

We used the land cover information from the Landcover Database version 5.0 for the identification of croplands in 2012 and 2018 [[9]](#9) [[10]](#10). Specifically, classes 30 (short-rotation cropland), 33 (orchards, vineyards or other perennial crops), 64 (forest - harvested), and 71 (exotic forest). We decided to include exotic forest and harvested forests (typically bare ground from the harvesting of exotic forest) under the standard human footprint definition of "cropland" for the purpose of human footprint mapping in New Zealand. This is because exotic forests are a major class of land cover and represent a significant human alteration of the natural landscape.

The data is downloaded as a vector, rasterised as a binary raster at 10 m² resolution, and then downsampled to 100 m² with a summation algorithm to obtain a 0–100 value for measuring partial pixel cover at this scale (a value of 20 indicates that 20% of the pixel is covered in cropland or forestry). These values are converted to a footprint score using the equation:

$$
F = \frac{x}{100}\cdot4
$$

### Pasture

Pasture data is obtained similarly to croplands. Classes 2 (urban parkland/open space), 40 (high producing exotic grassland), 41 (low producing grassland), and 44 (depleted grassland) are all included in this definition.

The cover values are obtained in the same fashion as cropland and are converted to a footprint score using the rule:

$$
F = \begin{cases} 7 & \text{if $x > 20$} \\
4 & \text{if $0 < x \le 20$} \\
0 & \text{otherwise} \end{cases}
$$

### Roads

We obtained road centreline data from Land Information New Zealand's topographic data (1:50,000 scale) [[11]](#11) [[12]](#12). All data in this series has a stated planimetric accuracy of ±22 m, although does not record whether a road is public or private. Tunnels are erased from the set of roads, using a 1m tolerance, using a process that does not affect surface roads that are situated above tunnels. Roads are rasterised to the same grid with a 100 m² resolution using GDAL (_not_ using the "all touched" rasterisation strategy).

Simple Euclidean distance from these roads is calculated in raster space, in metres. This proximity information is then converted to a footprint score using the equation:


$$
F = \begin{cases} 8 & \text{if $x \le 500$} \\
3.75\cdot\exp(-1\cdot(\frac{x}{1000}-1))+0.25 & \text{if $500 < x < 15000$} \\
0 & \text{otherwise} \end{cases}
$$

A temporal component to roads (and tunnels) was captured through the use novel use of Kart, a distributed version-control software for geospatial data (built on git) [[13]](#13). This software allowed us to represent the topographic roads data at specific points in time (from 2012 to the present) in order to capture the state of the road network as it developed over time (e.g. excluding the most recently completed highways).

### Railways

Railway centrelines are obtained in the same fashion as roads [[14]](#14), including accounting for tunnels, and using Kart for the representation of temporality (although this is much less relevant). Euclidean distance from railway lines is calculated and converted to a footprint score using the rule:

$$
F = \begin{cases} 8 & \text{if $x \le 500$} \\
0 & \text{otherwise} \end{cases}
$$

### Navigable waterways

For the purposes of human footprint mapping, navigable waterways are defined as waterways where the depth is greater than 2 m, as well as all coastlines and major lakes.

Major lakes are taken from those lakes present in Land Information New Zealand's 1:500,000 scale topographic mapping [[15]](#15). The exterior ring of the lake is obtained (the lake is represented as a line rather than a polygon) and then rasterised.

The coastline is taken as the mean high water at 1:50,000 scale [[16]](#16). This is rasterised. 

Rivers are obtained from River Environment Classification (REC2) New Zealand [[17]](#17). However, these do not have depth information. Depth is estimated on the basis of estimated discharge rates for REC2 rivers availabe at NZ River Maps [[18]](#18), and converted using the following equations from [[19]](#19), which assumes a second order parabola as the shape of a river channel:

$$
\text{velocity} = 4\cdot\frac{\text{discharge} \text{[m}^{3}\text{s}^{-1}\text{]}^{0.6}}{\text{width[m]}}
$$

$$
\text{cross-sectional area} = \frac{\text{discharge}}{\text{velocity}}
$$

$$
\text{depth[m]} = 1.5\cdot\frac{\text{cross-sectional area}}{\text{width}}
$$

Where certain parameters are already given by NZ River Maps data:
 - Discharge: median flow (cumecs): the predicted median of mean daily flow time-series over all time.
 - Width: width at median flow (m): wetted width across the river channel at median flow.

Rivers are filtered; only reaches with depths greater than 2 m are retained as "navigable waterways".

Rivers are represented in REC2 continously _through_ lakes; these parts are erased in the raster representation of rivers using the lakes dataset, such that when the rasterised representations of rivers, lakes and coastlines are combined, there is a raster representation only of the edges of lakes, as well as all coastlines, and navigable rivers.

Using VIIRS night-time lights (VNL) data previously described, any navigable water within 4 km (Euclidean) of a lit pixel (of any brightness) is identified as a "source" area for the subequent distance allocation algorithm.

We identified any navigable waterway pixel within 80 km of a "source" pixel _along the network of navigable waterways_, progressing from "source" pixels. Traversal beyond navigable waterways (i.e. over land, or across a lake or inland sea) is not considered possible in this model.

Once identified, all accessible parts of the navigable waterway network are used as source areas for a Euclidean distance allocation (in metres) and converted to a footprint score using the rule:

$$
F = \begin{cases} 0 & \text{if $x \ge 15000$} \\
4\cdot\exp(-1\cdot x) & \text{otherwise} \end{cases}
$$

### Final human footprint index

All eight components are combined additvely. The New Zealand coastline (1:50,000 scale) is re-used in this final step in order to firmly set no-data values for marine spaces. Outside of marine areas, the minimum value is 0. This results in a raster layer where all terrestrial spaces have a minimum value of 0 (wilderness) up to a hypothetical maximum of 61. The datatype is 32-bit floating-point, rather than an integer, because some components use logarithmic or exponential functions and the values are not rounded.

## Reproducibility

The Snakemake workflow management system is used to create a reproducible and scalable data analysis [[20]](#20). This entails a description of all required software, and ultimate sources of input data, that is required to reproduce these results. The workflow is intended to be transferrable to other machines, and adapted if desired. The source code developed to implement this dataset is available on Github [[21]](#21).


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

<a id="5">[5]</a>
Lloyd, C., Sorichetta, A. & Tatem, A. High resolution global gridded data for use in population studies. Sci Data 4, 170001 (2017). https://doi.org/10.1038/sdata.2017.1

<a id="6">[6]</a>
Stats NZ (2022). Statistical standard for geographic areas 2023. Retrieved from https://www.stats.govt.nz

<a id="7">[7]</a>
Elvidge, C.D, Zhizhin, M., Ghosh T., Hsu FC, Taneja J. Annual time series of global VIIRS nighttime lights derived from monthly averages:2012 to 2019. Remote Sensing 2021, 13(5), p.922, doi:10.3390/rs13050922

<a id="8">[8]</a>
Cao, C., X. Shao, X. Xiong, S. Blonski, Q. Liu, S. Uprety, X. Shao, Y. Bai, F. Weng, Suomi NPP VIIRS sensor data record verification, validation, and long-term performance monitoring, Journal of Geophysical Research: Atmospheres, DOI: 10.1002/2013JD020418, 2013.

<a id="9">[9]</a>
doi:10.26060/W5B4-WK93

<a id="10">[10]</a>
doi:10.26060/ETRS-VH40

<a id="11">[11]</a>
https://data.linz.govt.nz/layer/50329-nz-road-centrelines-topo-150k/

<a id="12">[12]</a>
https://data.linz.govt.nz/layer/50100-nz-chatham-island-road-centrelines-topo-150k/

<a id="13">[13]</a>
Kart contributors (2023). Kart geospatial data version-control software. https://kartproject.org 

<a id="14">[14]</a>
https://data.linz.govt.nz/layer/50319-nz-railway-centrelines-topo-150k/

<a id="15">[15]</a>
https://data.linz.govt.nz/layer/50212-nz-lake-polygons-topo-1500k/

<a id="16">[16]</a>
https://data.linz.govt.nz/layer/105085-nz-coastline-mean-high-water/

<a id="17">[17]</a>
https://data-niwa.opendata.arcgis.com/maps/NIWA::river-environment-classification-rec2-new-zealand/about

<a id="18">[18]</a>
Whitehead, A.L. & Booker, D.J. (2020). NZ River Maps: An interactive online tool for mapping predicted freshwater variables across New Zealand. NIWA, Christchurch. https://shiny.niwa.co.nz/nzrivermaps/

<a id="19">[19]</a>
Williams, B. A., Venter, O., Allan, J. R., Atkinson, S. C., Rehbein, J. A., Ward, M., ... & Watson, J. E. (2020). Change in terrestrial human footprint drives continued loss of intact ecosystems. One Earth, 3(3), 371-382.

<a id="20">[20]</a>
Mölder, F., Jablonski, K.P., Letcher, B., Hall, M.B., Tomkins-Tinch, C.H., Sochat, V., Forster, J., Lee, S., Twardziok, S.O., Kanitz, A., Wilm, A., Holtgrewe, M., Rahmann, S., Nahnsen, S., Köster, J., 2021. Sustainable data analysis with Snakemake. F1000Res 10, 33.

<a id="21">[21]</a>
https://github.com/manaakiwhenua/human-footprint-nz