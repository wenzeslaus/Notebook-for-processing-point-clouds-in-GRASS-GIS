# Copyright (C) Vaclav Petras.
# Distributed under the terms of the BSD 2-Clause License.

FROM jupyter/scipy-notebook:7a3e968dd212

MAINTAINER Vaclav Petras <wenzeslaus@gmail.com>

USER root

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Create a Python 2.x environment using conda including
# the ipython kernel # and the kernda utility.
# Add any additional packages to be used in Python 2 notebook should go
# on the second line here after kernda.
# This particular command does not require root, but the ones around
# it do.
RUN conda create --quiet --yes -p $CONDA_DIR/envs/python2 python=2.7 \
        ipython ipykernel kernda matplotlib && \
    conda clean --all -f -y

# Create a global kernelspec in the image and modify it so that it properly activates
# the python2 conda environment.
RUN $CONDA_DIR/envs/python2/bin/python -m ipykernel install && \
$CONDA_DIR/envs/python2/bin/kernda -o -y /usr/local/share/jupyter/kernels/python2/kernel.json

RUN apt-get update && apt-get install -y \
    software-properties-common curl \
    && add-apt-repository ppa:ubuntugis/ubuntugis-unstable \
    && apt-get update \
    && apt-get install -y grass grass-dev grass-doc \
    && apt-get autoremove \
    && apt-get clean

# GRASS GIS g.extension build expects documentation, but grass-doc does not work
RUN touch /usr/lib/grass76/docs/html/grass_logo.png
RUN touch /usr/lib/grass76/docs/html/grassdocs.css

# libLAS probably reports wrong location of libgeotiff
RUN ln -s /usr/lib/x86_64-linux-gnu/libgeotiff.so /usr/lib/

USER $NB_USER

WORKDIR /home/$NB_USER

RUN mkdir -p /home/$NB_USER/grassdata

RUN curl -SL http://fatra.cnr.ncsu.edu/foss4g2017/nc_orthophoto_1m_spm.zip > nc_orthophoto_1m_spm.zip\
  && unzip nc_orthophoto_1m_spm.zip \
  && mv nc_orthophoto_1m_spm.tif /home/$NB_USER/work \
  && rm nc_orthophoto_1m_spm.zip

RUN curl -SL http://fatra.cnr.ncsu.edu/foss4g2017/nc_tile_0793_016_spm.zip > nc_tile_0793_016_spm.zip\
  && unzip nc_tile_0793_016_spm.zip \
  && mv nc_tile_0793_016_spm.las /home/$NB_USER/work \
  && rm nc_tile_0793_016_spm.zip

RUN curl -SL http://fatra.cnr.ncsu.edu/foss4g2017/nc_uav_points_spm.zip > nc_uav_points_spm.zip \
  && unzip nc_uav_points_spm.zip \
  && mv nc_uav_points_spm.las /home/$NB_USER/work \
  && rm nc_uav_points_spm.zip

WORKDIR /home/$NB_USER/work

# there is some problem or bug with permissions
USER root
RUN chown -R $NB_USER:users /home/$NB_USER
USER $NB_USER

RUN source activate python2 && grass -c EPSG:4326 /home/$NB_USER/grassdata/latlon -e
RUN source activate python2 && grass /home/$NB_USER/grassdata/latlon/PERMANENT --exec g.extension r.geomorphon
RUN source activate python2 && grass /home/$NB_USER/grassdata/latlon/PERMANENT --exec g.extension r.skyview
RUN source activate python2 && grass /home/$NB_USER/grassdata/latlon/PERMANENT --exec g.extension r.local.relief
RUN source activate python2 && grass /home/$NB_USER/grassdata/latlon/PERMANENT --exec g.extension r.shaded.pca
RUN source activate python2 && grass /home/$NB_USER/grassdata/latlon/PERMANENT --exec g.extension r.area
RUN source activate python2 && grass /home/$NB_USER/grassdata/latlon/PERMANENT --exec g.extension r.terrain.texture
RUN source activate python2 && grass /home/$NB_USER/grassdata/latlon/PERMANENT --exec g.extension r.fill.gaps
RUN source activate python2 && grass /home/$NB_USER/grassdata/latlon/PERMANENT --exec g.extension v.lidar.mcc

COPY notebooks/* ./

# there is some problem or bug with permissions
USER root
RUN chown -R $NB_USER:users /home/$NB_USER
USER $NB_USER

RUN source activate python2 && grass -c EPSG:3358 /home/$NB_USER/grassdata/workshop -e
