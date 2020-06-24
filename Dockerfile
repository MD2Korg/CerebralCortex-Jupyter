<<<<<<< HEAD
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
ARG BASE_CONTAINER=jupyter/scipy-notebook
FROM $BASE_CONTAINER
MAINTAINER Timothy Hnat twhnat@memphis.edu

# Fix DL4006
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Spark dependencies
ENV APACHE_SPARK_VERSION=3.0.0 \
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

RUN jupyter lab build && \
    jupyter lab clean && \
    jlpm cache clean && \
    npm cache clean --force && \
    rm -rf $HOME/.node-gyp && \
    rm -rf $HOME/.local


# Using the preferred mirror to download Spark
WORKDIR /tmp
# hadolint ignore=SC2046
RUN wget -q $(wget -qO- https://www.apache.org/dyn/closer.lua/spark/spark-${APACHE_SPARK_VERSION}/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz\?as_json | \
    python -c "import sys, json; content=json.load(sys.stdin); print(content['preferred']+content['path_info'])") && \
    echo "f5652835094d9f69eb3260e20ca9c2d58e8bdf85a8ed15797549a518b23c862b75a329b38d4248f8427e4310718238c60fae0f9d1afb3c70fb390d3e9cce2e49 *spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" | sha512sum -c - && \
    tar xzf "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" -C /usr/local --owner root --group root --no-same-owner && \
    rm "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz"

WORKDIR /usr/local
RUN ln -s "spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}" spark

# Configure Spark
ENV SPARK_HOME=/usr/local/spark
ENV PYTHONPATH=$SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.7-src.zip \
    SPARK_OPTS="--driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info" \
    PATH=$PATH:$SPARK_HOME/bin

RUN mkdir /data
RUN chmod 777 /data

RUN mkdir /opt/conda/share/jupyter/kernels/pyspark
COPY pyspark/kernel.json /opt/conda/share/jupyter/kernels/pyspark/

RUN pip install cerebralcortex-kernel==3.2.1.post3 pennprov

USER $NB_UID

# Install pyarrow
# RUN conda install --quiet -y 'pyarrow' 'py4j' && \
#     conda clean --all -f -y && \
#     fix-permissions "${CONDA_DIR}" && \
#     fix-permissions "/home/${NB_USER}"

WORKDIR $HOME


VOLUME /data









# RUN apt-get -yqq update && \
#     apt-get install wget && \
#     apt-get install -yqq openjdk-8-jre python3-setuptools libyaml-dev libev-dev liblapack-dev libsnappy-dev gcc g++ && \
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/* && \
#     rm -rf /tmp/*
#
# RUN pip3 install wheel pytz==2017.2 PyYAML==4.2b1 influxdb==5.0.0 pympler scipy numpy py4j
#
# RUN apt-get remove -y nodejs && apt-get update && \
#      curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
#      apt-get install -y nodejs
#
#
# ENV SPARK_HOME  /usr/local/spark
# ENV PYTHONPATH $SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.4-src.zip
# ENV SPARK_OPTS --driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info
# ENV JAVA_HOME   /usr/lib/jvm/java-8-openjdk-amd64
# ENV PYSPARK_PYTHON /opt/conda/bin/python3
# ENV PATH        $JAVA_HOME/bin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH
#
#
#

# RUN pip install jupyter jupyterlab \
#     && jupyter nbextension enable --py widgetsnbextension \
#     && jupyter serverextension enable --py jupyterlab
#
#
# RUN mkdir /opt/conda/share/jupyter/kernels/pyspark
# COPY pyspark/kernel.json /opt/conda/share/jupyter/kernels/pyspark/
#
# RUN useradd -m md2k && echo "md2k:md2k" | chpasswd
#
# RUN pip3 install matplotlib sklearn python-snappy ipywidgets gmaps plotly seaborn ipyleaflet qgrid
