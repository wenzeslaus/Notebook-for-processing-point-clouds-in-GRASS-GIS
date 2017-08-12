# Processing lidar and UAV point clouds in GRASS GIS

Notebooks for FOSS4G Boston 2017 workshop called
*Processing lidar and UAV point clouds in GRASS GIS*
available at:

https://grasswiki.osgeo.org/wiki/Processing_lidar_and_UAV_point_clouds_in_GRASS_GIS_(workshop_at_FOSS4G_Boston_2017)#Optimizations.2C_troubleshooting_and_limitations

## Conversion

Get the latest version:

    wget "https://grasswiki.osgeo.org/wiki/Processing_lidar_and_UAV_point_clouds_in_GRASS_GIS_(workshop_at_FOSS4G_Boston_2017)#Optimizations.2C_troubleshooting_and_limitations"

Remove non-ASCII characters (not important at this point):

    iconv -c -f utf-8 -t ascii workshop.html > workshop_ascii.html
    mv workshop_ascii.html workshop.html

Manually remove header and footer and replace all

    <pre>some code...

with

    <pre><code>
    some code...

Conversion tool from https://github.com/wenzeslaus/gdoc2py:

    ./gdoc2nb.py --gisdbase /grassdata/ --location nc_spm --mapset PER workshop.html notebooks/workshop_python.ipynb

## Simple test

    jupyter notebook notebooks

## Test the image from source


Build it to have it locally:

```
docker build -t grass-point-cloud-workshop .
```

Run it to test it:

```
docker run -it --rm -p 8888:8888 grass-point-cloud-workshop
```
