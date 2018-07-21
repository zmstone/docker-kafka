# Kafka and Zookeeper in Docker Container

## Build

make

## Start Zookeeper

```sh
docker run -d -p 2181:2181 --name zookeeper zmstone/kafka run zookeeper
```

## Start Kafka

```sh
docker run -d -e BROKER_ID=0 \
              -e PLAINTEXT_PORT=9092 \
              -e SSL_PORT=9093 \
              -e SASL_SSL_PORT=9094 \
              -e SASL_PLAINTEXT_PORT=9095 \
              -p 9092-9095:9092-9095 \
              --link zookeeper \
              --name kafka-1 \
              zmstone/kafka run kafka
```

### Create Topic

```
create_topic() {
  TOPIC_NAME="$1"
  PARTITIONS="${2:-1}"
  REPLICAS="${3:-1}"
  CMD="kafka-topics.sh --zookeeper zookeeper --create --partitions $PARTITIONS --replication-factor $REPLICAS --topic $TOPIC_NAME"
  sudo docker exec kafka-1 bash -c "$CMD"
}
create_topic "test-topic"
```

### Add sasl-scram Credentials (kafka 0.11 or later)

```
docker exec kafka-1 kafka-configs.sh --zookeeper zookeeper:2181 --alter --add-config 'SCRAM-SHA-256=[iterations=8192,password=ecila],SCRAM-SHA-512=[password=ecila]' --entity-type users --entity-name alice
```
