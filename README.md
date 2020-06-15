# Kafka and Zookeeper in Docker Container

[![Build Status](https://travis-ci.org/zmstone/docker-kafka.svg?branch=master)](https://travis-ci.org/zmstone/docker-kafka)

Based on https://hub.docker.com/r/wurstmeister/kafka with SSL enabled by default

## Build

make

## Run

```sh
sudo docker-compose up -d
```

Set `KAFKA_CREATE_TOPICS` environment variable to have them created.

```sh
sudo TOPICS='topic-1:1,topic-2:2' docker-compose up -d
```

### Create Topic when containers are already up

```
TOPICS="topic1:1:1,topic2:2:1:compact"
sudo docker-compose exec -e KAFKA_PORT=9093 -e KAFKA_CREATE_TOPICS=$TOPICS kafka create-topics.sh
```

### Add sasl-scram Credentials (kafka 0.11 or later)

```
sudo docker-compose exec kafka kafka-configs.sh --zookeeper localhost:2181 --alter --add-config 'SCRAM-SHA-256=[iterations=8192,password=ecila],SCRAM-SHA-512=[password=ecila]' --entity-type users --entity-name alice
```

### TLS certificates

Mout truststore and keystore for container and set below variables

```
KAFKA_SSL_KEYSTORE_LOCATION=/opt/kafka/tls/kafka.jks
KAFKA_SSL_KEYSTORE_PASSWORD=nosecret
KAFKA_SSL_KEY_PASSWORD=nosecret
KAFKA_SSL_TRUSTSTORE_LOCATION=/opt/kafka/tls/truststore.jks
KAFKA_SSL_TRUSTSTORE_PASSWORD=nosecret
KAFKA_SSL_CLIENT_AUTH=none
KAFKA_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM=" "
```

When `KAFKA_SSL_KEYSTORE_LOCATION` is not provided, the certificates
are created by docker entrypoint script before Kafak starts up.

### Defaults For single node setup

See docker-entrypoint for more default values defined to fit single node tests.

