# Kafka and Zookeeper in Docker Container

[![Build Status](https://travis-ci.org/zmstone/docker-kafka.svg?branch=master)](https://travis-ci.org/zmstone/docker-kafka)

Originally developed as a part of https://github.com/klarna/brod

## Build

make

## Run

```sh
sudo docker-compose up -d
```

Set `TOPICS` environment variable to have them created.

```sh
sudo TOPICS='topic-1:1,topic-2:2' docker-compose up -d
```

### Create Topic when containers are already up

```
create_topic() {
  TOPIC_NAME="$1"
  PARTITIONS="${2:-1}"
  REPLICAS="${3:-1}"
  CMD="kafka-topics.sh --zookeeper localhost --create --partitions $PARTITIONS --replication-factor $REPLICAS --topic $TOPIC_NAME"
  sudo docker-compose exec kafka bash -c "$CMD"
}
create_topic "test-topic"
```

### Add sasl-scram Credentials (kafka 0.11 or later)

```
sudo docker-compose exec kafka kafka-configs.sh --zookeeper localhost:2181 --alter --add-config 'SCRAM-SHA-256=[iterations=8192,password=ecila],SCRAM-SHA-512=[password=ecila]' --entity-type users --entity-name alice
```
