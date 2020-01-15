FROM jupyterhub/jupyterhub
MAINTAINER Timothy Hnat twhnat@memphis.edu

RUN apt-get -yqq update && \
    apt-get install -yqq openjdk-8-jre python3-setuptools libyaml-dev libev-dev liblapack-dev libsnappy-dev gcc g++ && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*


# Spark dependencies
ENV APACHE_SPARK_VERSION 3.0.0-preview2
ENV HADOOP_VERSION 2.7

RUN easy_install pip==9.0.3
RUN pip3 install wheel pypandoc minio==2.2.4 pytz==2017.2 PyYAML==4.2b1 pyarrow==0.14.1 kafka influxdb==5.0.0 pympler scipy numpy py4j
#RUN pip3 install

RUN cd /tmp && \
        apt-get update &&\
        apt-get install -y wget &&\
        wget -q http://apache.cs.utah.edu/spark/spark-3.0.0-preview2/spark-3.0.0-preview2-bin-hadoop2.7.tgz && \
        tar xzf spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -C /usr/local && \
        rm spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz
RUN cd /usr/local && ln -s spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} spark

ENV SPARK_HOME  /usr/local/spark
ENV PYTHONPATH $SPARK_HOME/python:$SPARK_HOME/python/lib/py4j-0.10.4-src.zip
ENV SPARK_OPTS --driver-java-options=-Xms1024M --driver-java-options=-Xmx4096M --driver-java-options=-Dlog4j.logLevel=info
ENV JAVA_HOME   /usr/lib/jvm/java-8-openjdk-amd64
ENV PYSPARK_PYTHON /opt/conda/bin/python3
ENV PATH        $JAVA_HOME/bin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH
ENV HADOOP_HOME	   /opt/hadoop

RUN \
  wget http://apache.mirrors.tds.net/hadoop/common/hadoop-3.1.3/hadoop-3.1.3.tar.gz && \
    tar -xzf hadoop-3.1.3.tar.gz && \
    mv hadoop-3.1.3 $HADOOP_HOME && \
  echo "export JAVA_HOME=$JAVA_HOME" >> $HADOOP_HOME/etc/hadoop/hadoop-env.sh && \
  echo "PATH=$PATH:$HADOOP_HOME/bin" >> ~/.bashrc


RUN pip install cerebralcortex-kernel==3.1.1.post2
RUN pip install --upgrade jupyterhub
RUN pip install jupyter jupyterlab \
    && jupyter nbextension enable --py widgetsnbextension \
    && jupyter serverextension enable --py jupyterlab

RUN cd /usr/local/spark-${APACHE_SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}/python && \
    python3 setup.py install

RUN mkdir -p /opt/conda/share/jupyter/kernels/pyspark
COPY pyspark/kernel.json /opt/conda/share/jupyter/kernels/pyspark/

RUN useradd -m md2k && echo "md2k:md2k" | chpasswd

RUN pip3 install matplotlib sklearn ipywidgets gmaps plotly seaborn ipyleaflet qgrid



RUN jupyter labextension install nbdime-jupyterlab --no-build && \
    jupyter labextension install @jupyterlab/toc --no-build && \
    jupyter labextension install @jupyter-widgets/jupyterlab-manager --no-build && \
    jupyter labextension install jupyterlab_bokeh --no-build && \
    jupyter labextension install bqplot --no-build && \
    jupyter labextension install @jupyterlab/vega3-extension --no-build && \
    jupyter labextension install @jupyterlab/git --no-build && \
    jupyter labextension install @jupyterlab/hub-extension --no-build && \
    jupyter labextension install jupyterlab_tensorboard --no-build && \
    jupyter labextension install jupyterlab-kernelspy --no-build && \
    jupyter labextension install @jupyterlab/plotly-extension --no-build && \
    #jupyter labextension install jupyterlab-chart-editor --no-build && \
    #jupyter labextension install plotlywidget --no-build && \
    jupyter labextension install @jupyterlab/latex --no-build && \
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



HEALTHCHECK --interval=1m --timeout=3s --start-period=30s \
CMD wget --quiet --tries=1 http://localhost:8000/jupyterhub/ || exit 1

RUN mkdir /data
RUN chmod 777 /data

VOLUME /srv/jupyterhub/conf /data
