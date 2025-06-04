# Kafka and Zookeeper in Docker Container

[![Build Status](https://travis-ci.org/zmstone/docker-kafka.svg?branch=master)](https://travis-ci.org/zmstone/docker-kafka)

Originally developed as a part of https://github.com/klarna/brod

## Build

make

## Run

For Kafka 3.3 or later:

```sh
docker compose -f docker-compose-kraft.yml up -d
```

For earlier versions:

```sh
docker compose up -d
```

Set `TOPICS` environment variable to have them created.

```sh
TOPICS='topic-1:1,topic-2:2' docker compose up -d
```

### Create Topic when containers are ready

```
create_topic() {
  TOPIC_NAME="$1"
  PARTITIONS="${2:-1}"
  REPLICAS="${3:-1}"
  CMD="kafka-topics.sh --zookeeper localhost --create --partitions $PARTITIONS --replication-factor $REPLICAS --topic $TOPIC_NAME"
  docker exec kafka-1 bash -c "$CMD"
}
create_topic "test-topic"
```

### Add sasl-scram Credentials (kafka 0.11 or later)

```
docker exec kafka-1 kafka-configs.sh --zookeeper localhost:2181 --alter --add-config 'SCRAM-SHA-256=[iterations=8192,password=ecila]' --entity-type users --entity-name alice
docker exec kafka-1 kafka-configs.sh --zookeeper localhost:2181 --alter --add-config 'SCRAM-SHA-512=[password=ecila]' --entity-type users --entity-name alice
```
