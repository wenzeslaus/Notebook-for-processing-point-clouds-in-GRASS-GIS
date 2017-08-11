# Copyright (C) Vaclav Petras.
# Distributed under the terms of the BSD 2-Clause License.

FROM jupyter/scipy-notebook

MAINTAINER Vaclav Petras <wenzeslaus@gmail.com>

USER root

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN apt-get update \
    && apt-get install -y --install-recommends \
        autoconf2.13 \
        autotools-dev \
        bison \
        flex \
        g++ \
        gettext \
        libblas-dev \
        libbz2-dev \
        libcairo2-dev \
        libfftw3-dev \
        libfreetype6-dev \
        libgdal-dev \
        libgeos-dev \
        libglu1-mesa-dev \
        libjpeg-dev \
        liblapack-dev \
        liblas-c-dev \
        libncurses5-dev \
        libnetcdf-dev \
        libpng-dev \
        libpq-dev \
        libproj-dev \
        libreadline-dev \
        libsqlite3-dev \
        libtiff-dev \
        libxmu-dev \
        make \
        netcdf-bin \
        proj-bin \
        python \
        python-dev \
        python-numpy \
        python-pil \
        python-ply \
        sqlite3 \
        unixodbc-dev \
        zlib1g-dev \
    && apt-get autoremove \
    && apt-get clean

# other software
RUN apt-get update \
    && apt-get install -y --install-recommends \
        imagemagick \
        p7zip \
        unzip \
        subversion \
    && apt-get autoremove \
    && apt-get clean

# GRASS GIS needs to be build with Python 2
RUN ln -s /usr/bin/python2 /bin/python

# install GRASS GIS
WORKDIR /usr/local/src
RUN source activate python2 \
    && svn checkout https://svn.osgeo.org/grass/grass/trunk grass \
    && cd grass \
    &&  ./configure \
        --enable-largefile=yes \
        --with-nls \
        --with-cxx \
        --with-readline \
        --with-bzlib \
        --with-pthread \
        --with-proj-share=/usr/share/proj \
        --with-geos=/usr/bin/geos-config \
        --with-cairo \
        --with-opengl-libs=/usr/include/GL \
        --with-freetype=yes --with-freetype-includes="/usr/include/freetype2/" \
        --with-sqlite=yes \
        #--with-liblas=yes --with-liblas-config=/usr/bin/liblas-config \
    && make ; make install ; ldconfig
# make gives errors which are not that important now, so we ignore them
WORKDIR /usr/local
# separately for now
RUN rm -r /usr/local/src

# enable simple grass command regardless of version number
RUN ln -s /usr/local/bin/grass* /usr/local/bin/grass

# TODO: move up
# other software
RUN apt-get update \
    && apt-get install -y --install-recommends \
        curl \
    && apt-get autoremove \
    && apt-get clean

USER $NB_USER

WORKDIR /home/$NB_USER

RUN mkdir -p /home/$NB_USER/grassdata

RUN curl -SL http://fatra.cnr.ncsu.edu/foss4g2017/nc_orthophoto_1m_spm.zip \
  && unzip nc_orthophoto_1m_spm.zip \
  && mv nc_orthophoto_1m_spm.tif /home/$NB_USER/work \
  && rm nc_orthophoto_1m_spm.zip

RUN curl -SL http://fatra.cnr.ncsu.edu/foss4g2017/nc_tile_0793_016_spm.zip \
  && unzip nc_tile_0793_016_spm.zip \
  && mv nc_tile_0793_016_spm.tif /home/$NB_USER/work \
  && rm nc_tile_0793_016_spm.zip

RUN curl -SL http://fatra.cnr.ncsu.edu/foss4g2017/nc_uav_points_spm.zip \
  && unzip nc_uav_points_spm.zip \
  && mv nc_uav_points_spm.tif /home/$NB_USER/work \
  && rm nc_uav_points_spm.zip

WORKDIR /home/$NB_USER/work

COPY notebooks/* ./

# there is some problem or bug with permissions
USER root
RUN chown -R $NB_USER:users /home/$NB_USER
USER $NB_USER

RUN grass -c EPSG:4326 /home/$NB_USER/grassdata/latlon
RUN grass /home/$NB_USER/grassdata/latlon/PERMANENT --exec g.extension
RUN grass /home/$NB_USER/grassdata/latlon/PERMANENT --exec g.extension r.geomorphon
RUN grass /home/$NB_USER/grassdata/latlon/PERMANENT --exec g.extension r.skyview
RUN grass /home/$NB_USER/grassdata/latlon/PERMANENT --exec g.extension r.local.relief
RUN grass /home/$NB_USER/grassdata/latlon/PERMANENT --exec g.extension r.shaded.pca
RUN grass /home/$NB_USER/grassdata/latlon/PERMANENT --exec g.extension r.area
RUN grass /home/$NB_USER/grassdata/latlon/PERMANENT --exec g.extension r.terrain.texture
RUN grass /home/$NB_USER/grassdata/latlon/PERMANENT --exec g.extension r.fill.gaps
RUN grass /home/$NB_USER/grassdata/latlon/PERMANENT --exec g.extension v.lidar.mcc

# needed again, or enough for the root?
RUN source activate python2
