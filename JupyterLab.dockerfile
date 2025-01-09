# syntax=docker/dockerfile:1
FROM python:3.9.19-slim-bullseye

# Add a few args for portability
ARG SCALA_VERSION=2.12
ARG SPARK_VERSION=3.5.3
ARG DELTA_LAKE_VERSION=3.2.1
ARG UNITY_CATALOG_VERSION=0.2.0
ARG HDFS_VERSION=3.3.4

# Add maintainer info
LABEL maintainer="netriganalytics"

# Set environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk
ENV SPARK_HOME=/opt/spark
ENV PATH="${JAVA_HOME}/bin:${SPARK_HOME}/bin:${PATH}"

# Install Java 11 and a few other common utils
# Note: running `apt-get update` is not a good practice since it will re-crawl the index during build time
# Since this image is expected to be used for non-Production containers, it's fine for now
RUN apt-get update && apt-get install -y \
    openjdk-11-jdk \
    wget \
    curl \
    bash \
    && rm -rf /var/lib/apt/lists/*

# Install Apache Spark(TM)
RUN wget https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz \
    && tar -xzf spark-${SPARK_VERSION}-bin-hadoop3.tgz -C /opt \
    && mv /opt/spark-${SPARK_VERSION}-bin-hadoop3 /opt/spark \
    && rm spark-${SPARK_VERSION}-bin-hadoop3.tgz

# Clean up time
RUN rm -rf /var/lib/apt/lists/*

# Download JAR dependencies from Maven
RUN mkdir -p ${SPARK_HOME}/jars && \
    curl -o ${SPARK_HOME}/jars/delta-spark_${SCALA_VERSION}-${DELTA_LAKE_VERSION}.jar https://repo1.maven.org/maven2/io/delta/delta-spark_${SCALA_VERSION}/${DELTA_LAKE_VERSION}/delta-spark_${SCALA_VERSION}-${DELTA_LAKE_VERSION}.jar && \
    curl -o ${SPARK_HOME}/jars/unitycatalog-spark_${SCALA_VERSION}-${UNITY_CATALOG_VERSION}.jar https://repo1.maven.org/maven2/io/unitycatalog/unitycatalog-spark_${SCALA_VERSION}/${UNITY_CATALOG_VERSION}/unitycatalog-spark_${SCALA_VERSION}-${UNITY_CATALOG_VERSION}.jar && \
    curl -o ${SPARK_HOME}/jars/hadoop-common-${HDFS_VERSION}.jar https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-common/${HDFS_VERSION}/hadoop-common-${HDFS_VERSION}.jar

# Install JupyterLab and a few common Python libs
RUN pip install --no-cache-dir \
    jupyterlab \
    mlflow \
    delta-spark \
    numpy \
    pandas \
    scikit-learn

    # Add a sample Jupyter notebook from GitHub
RUN mkdir -p /opt/notebooks \
    && wget -O /opt/notebooks/unity_catalog_getting_started.ipynb https://github.com/netriganalytics/openlakehouse/blob/main/samples/unity_catalog_getting_started.ipynb

# Expose JupyterLab port
EXPOSE 8888

# Start the JupyterLab server
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]
