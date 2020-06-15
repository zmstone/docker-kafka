ARG BASE_IMAGE_VERSION
FROM wurstmeister/kafka:${BASE_IMAGE_VERSION}

ARG KAFKA_VERSION
RUN apk upgrade --update-cache --available && \
    apk add openssl && \
    rm -rf /var/cache/apk/*
ADD docker-entrypoint.sh /
COPY tls/ /opt/kafka/tls/
COPY jaas-plain.conf /opt/kafka/sasl/
COPY jaas-plain-scram.conf /opt/kafka/sasl/
ENV KAFKA_VERSION ${KAFKA_VERSION}

ENTRYPOINT ["/docker-entrypoint.sh"]

## run kafka by default, 'run zookeeper' to start zookeeper instead
CMD ["run", "kafka"]
