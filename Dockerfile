ARG BASE_JDK_IMAGE
FROM ${BASE_JDK_IMAGE}

RUN apt-get update && \
    apt-get install -y zookeeper wget supervisor dnsutils && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

ARG SCALA_VERSION
ENV SCALA_VERSION ${SCALA_VERSION}

ARG KAFKA_VERSION
ENV KAFKA_VERSION ${KAFKA_VERSION}

RUN DOWNLOAD_URL_PREFIX="https://archive.apache.org/dist/kafka" && \
    KAFKA_DOWNLOAD_URL="$DOWNLOAD_URL_PREFIX/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz" && \
    wget -q "${KAFKA_DOWNLOAD_URL}" -O /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz && \
    tar xfz /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -C /opt && \
    rm /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz && \
    ln -s /opt/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION" /opt/kafka && \
    mkdir -p /etc/kafka

COPY docker-entrypoint.sh /docker-entrypoint.sh
COPY server.properties /etc/kafka/server.properties
COPY server.jks /etc/kafka/server.jks
COPY truststore.jks /etc/kafka/truststore.jks
COPY jaas-plain.conf /etc/kafka/jaas-plain.conf
COPY jaas-plain-scram.conf /etc/kafka/jaas-plain-scram.conf
COPY localhost-ca-crt.pem /localhost-ca-crt.pem
COPY localhost-client-key.pem /localhost-client-key.pem
COPY localhost-client-crt.pem /localhost-client-crt.pem

ENV PATH /opt/kafka/bin:$PATH

ENTRYPOINT ["/docker-entrypoint.sh"]

## run kafka by default, 'run zookeeper' to start zookeeper instead
CMD ["run", "kafka"]

