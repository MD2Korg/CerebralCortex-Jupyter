# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
ARG BASE_CONTAINER=jupyter/scipy-notebook
FROM $BASE_CONTAINER
MAINTAINER Timothy Hnat twhnat@memphis.edu

# Fix DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Spark dependencies
ENV APACHE_SPARK_VERSION=3.0.1 \
    HADOOP_VERSION=2.7

RUN apt-get -y update && \
    apt-get install --no-install-recommends -y openjdk-8-jre-headless ca-certificates-java libyaml-dev libev-dev liblapack-dev libsnappy-dev gcc g++ && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install --upgrade jupyterlab-git matplotlib sklearn python-snappy ipywidgets gmaps plotly seaborn ipyleaflet qgrid

RUN jupyter labextension install nbdime-jupyterlab --no-build && \
    # jupyter labextension install @jupyterlab/toc --no-build && \
    # jupyter labextension install @jupyter-widgets/jupyterlab-manager --no-build && \
    jupyter labextension install @bokeh/jupyter_bokeh --no-build && \
    jupyter labextension install bqplot --no-build && \
    # jupyter labextension install @jupyterlab/vega3-extension --no-build && \
    jupyter labextension install @jupyterlab/git --no-build && \
    # jupyter labextension install @jupyterlab/hub-extension --no-build && \
    # jupyter labextension install jupyterlab_tensorboard --no-build && \
    jupyter labextension install jupyterlab-kernelspy --no-build && \
    jupyter labextension install jupyterlab-plotly --no-build && \
    jupyter labextension install jupyterlab-chart-editor --no-build && \
    jupyter labextension install plotlywidget --no-build && \
    # jupyter labextension install @jupyterlab/latex --no-build && \
    jupyter labextension install jupyter-matplotlib --no-build && \
    jupyter labextension install jupyterlab-drawio --no-build && \
    jupyter labextension install jupyter-leaflet --no-build && \
    jupyter labextension install qgrid --no-build

RUN jupyter lab build --dev-build=False --minimize=False && \
    jupyter lab clean && \
    jlpm cache clean && \
    npm cache clean --force && \
    rm -rf $HOME/.node-gyp && \
    rm -rf $HOME/.local


# Using the preferred mirror to download Spark
WORKDIR /tmp
# hadolint ignore=SC2046
RUN wget https://apache.osuosl.org/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
RUN tar xzf "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" -C /usr/local --owner root --group root --no-same-owner && \
    rm "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz"

WORKDIR /usr/local
RUN ln -s "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}" spark

# Configure Spark
ENV SPARK_HOME=/usr/local/spark
ENV PYSPARK_PYTHON=/opt/conda/bin/python3
ENV PYSPARK_DRIVER_PYTHON=/opt/conda/bin/python3
ENV PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.9-src.zip \
    SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info" \
    PATH=$PATH:$SPARK_HOME/bin

RUN mkdir /data
RUN chmod 777 /data

RUN mkdir /opt/conda/share/jupyter/kernels/pyspark
COPY pyspark/kernel.json /opt/conda/share/jupyter/kernels/pyspark/

RUN pip install pennprov
RUN pip install cerebralcortex-kernel

RUN useradd -m md2k && echo "md2k:md2k" | chpasswd

USER $NB_UID

WORKDIR $HOME


VOLUME /data
