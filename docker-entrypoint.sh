#!/bin/bash -xe

## run something other than zookeeper and kafka
if [ "$1" != "run" ]; then
  exec "$@"
fi

## run zookeeper
if [ "$2" = "zookeeper" ]; then
  exec /opt/kafka/bin/zookeeper-server-start.sh /opt/kafka/config/zookeeper.properties
fi

if [ "$2" != "kafka" ]; then
  echo "unknown target to run: $2"
  exit 1
fi

## run kafka

prop_file="/etc/kafka/server.properties"

if [ ! -z "$BROKER_ID" ]; then
  echo "broker id: $BROKER_ID"
  sed -r -i "s/^(broker.id)=(.*)/\1=$BROKER_ID/g" $prop_file
fi

ipwithnetmask="$(ip -f inet addr show dev eth0 | awk '/inet / { print $2 }')"
ipaddress="${ipwithnetmask%/*}"

[ -z "$ADVERTISED_HOSTNAME" ] && ADVERTISED_HOSTNAME="${ipaddress}"
[ -z "$CONTROLLER_PORT" ] && CONTROLLER_PORT=9090
[ -z "$INNER_PORT" ] && INNER_PORT=9091
[ -z "$PLAINTEXT_PORT" ] && PLAINTEXT_PORT=9092
[ -z "$SSL_PORT" ] && SSL_PORT=9093
[ -z "$SASL_SSL_PORT" ] && SASL_SSL_PORT=9095
[ -z "$SASL_PLAINTEXT_PORT" ] && SASL_PLAINTEXT_PORT=9096
[ -z "$ZOOKEEPER_CONNECT" ] && ZOOKEEPER_CONNECT="zookeeper:2181"

ZOOKEEPER_HOST=$(echo $ZOOKEEPER_CONNECT | cut -d':' -f1)
ZOOKEEPER_IP=$(getent ahostsv4 $ZOOKEEPER_HOST | head -1 | awk '{ print $1 }')
ZOOKEEPER_PORT=$(echo $ZOOKEEPER_CONNECT | cut -d':' -f2)

KAFKA_MAJOR=$(echo "$KAFKA_VERSION" | cut -d. -f1)

if [ "$KAFKA_MAJOR" -lt 3 ]; then
    until echo > /dev/tcp/$ZOOKEEPER_IP/$ZOOKEEPER_PORT; do
    >&2 echo "zookeeper is not ready, sleep wait"
    sleep 1
    done
fi

if [[ "$KAFKA_VERSION" = 0.9* ]]; then
  sed -r -i "s#^(advertised.listeners)=(.*)#\1=PLAINTEXT://$ADVERTISED_HOSTNAME:$PLAINTEXT_PORT,SSL://$ADVERTISED_HOSTNAME:$SSL_PORT#g" $prop_file
  sed -r -i "s#^(listeners)=(.*)#\1=PLAINTEXT://:$PLAINTEXT_PORT,SSL://:$SSL_PORT#g" $prop_file
elif [ "$KAFKA_MAJOR" -lt 3 ]; then
  sed -r -i "s#^(advertised.listeners)=(.*)#\1=PLAINTEXT://$ADVERTISED_HOSTNAME:$PLAINTEXT_PORT,SSL://$ADVERTISED_HOSTNAME:$SSL_PORT,SASL_SSL://$ADVERTISED_HOSTNAME:$SASL_SSL_PORT,SASL_PLAINTEXT://$ADVERTISED_HOSTNAME:$SASL_PLAINTEXT_PORT#g" $prop_file
  sed -r -i "s#^(listeners)=(.*)#\1=PLAINTEXT://:${PLAINTEXT_PORT},SSL://:${SSL_PORT},SASL_SSL://:${SASL_SSL_PORT},SASL_PLAINTEXT://:${SASL_PLAINTEXT_PORT}#g" $prop_file
  echo "sasl.enabled.mechanisms=PLAIN" >> $prop_file
else
  sed -r -i "s#^(advertised.listeners)=(.*)#\1=INNER://${INNER_HOSTNAME}:${INNER_PORT},PLAINTEXT://$ADVERTISED_HOSTNAME:$PLAINTEXT_PORT,SSL://$ADVERTISED_HOSTNAME:$SSL_PORT,SASL_SSL://$ADVERTISED_HOSTNAME:$SASL_SSL_PORT,SASL_PLAINTEXT://$ADVERTISED_HOSTNAME:$SASL_PLAINTEXT_PORT#g" $prop_file
  sed -r -i "s#^(listeners)=(.*)#\1=PLAINTEXT://:${PLAINTEXT_PORT},SSL://:${SSL_PORT},SASL_SSL://:${SASL_SSL_PORT},SASL_PLAINTEXT://:${SASL_PLAINTEXT_PORT},INNER://:${INNER_PORT},CONTROLLER://:${CONTROLLER_PORT}#g" $prop_file
  echo "sasl.enabled.mechanisms=PLAIN" >> $prop_file
fi

if [ "$KAFKA_MAJOR" -lt 3 ]; then
  sed -r -i "s/^zookeeper\.connect=.*/zookeeper.connect=${ZOOKEEPER_CONNECT}/" $prop_file
else
  # KRaft mode: Add required configs
  echo "node.id=${BROKER_ID}" >> "$prop_file"
  echo "process.roles=broker,controller" >> "$prop_file"
  echo "controller.listener.names=CONTROLLER" >> "$prop_file"
  echo "controller.quorum.voters=${VOTERS}" >> "$prop_file"
  echo "inter.broker.listener.name=PLAINTEXT" >> "$prop_file"
  echo "log.dirs=/tmp/kraft-combined-logs" >> "$prop_file"
  echo "listener.security.protocol.map=PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_SSL:SASL_SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,CONTROLLER:PLAINTEXT,INNER:PLAINTEXT" >> "$prop_file"
  echo "inter.broker.listener.name=INNER" >> "$prop_file"
  CLUSTER_ID="cluster123"
  kafka-storage.sh format --config $prop_file --cluster-id $CLUSTER_ID
fi
echo "sasl.enabled.mechanisms=PLAIN,SCRAM-SHA-256,SCRAM-SHA-512" >> $prop_file
echo "offsets.topic.replication.factor=1" >> $prop_file
echo "transaction.state.log.min.isr=1" >> $prop_file
echo "transaction.state.log.replication.factor=1" >> $prop_file

if [[ "$KAFKA_VERSION" = 0.9* ]]; then
  JAAS_CONF=""
elif [[ "$KAFKA_VERSION" = 0.10* ]]; then
  JAAS_CONF="-Djava.security.auth.login.config=/etc/kafka/jaas-plain.conf"
else
  JAAS_CONF="-Djava.security.auth.login.config=/etc/kafka/jaas-plain-scram.conf"
fi

if [ "$KAFKA_MAJOR" -lt 3 ]; then
    BOOTSTRAP_OPTS="--zookeeper ${ZOOKEEPER_CONNECT}"
else
    BOOTSTRAP_OPTS="--bootstrap-server localhost:9092"
fi

wait_for_kafka() {
  echo '### waiting for kafka to be ready'
  if ! kafka-topics.sh $BOOTSTRAP_OPTS --list >/dev/null 2>&1; then
    wait_for_kafka
  fi
}

create_topic() {
  TOPIC_NAME="$1"
  PARTITIONS="${2:-1}"
  kafka-topics.sh $BOOTSTRAP_OPTS --create --partitions $PARTITIONS --replication-factor 1 --topic $TOPIC_NAME
}

create_topics() {
  wait_for_kafka
  LINES=$(echo "$TOPICS" | tr ',' '\n')
  for topic_partition in $LINES; do
    topic="$(echo $topic_partition | cut -d: -f1)"
    partitions="$(echo $topic_partition | cut -d: -f2)"
    [ $partitions == "" ] && partitions=1
    ## ignore error because the topic might be alredy there when working with a running zookeeper
    create_topic $topic $partitions || true
  done
}

# fork-start topic creator
[ -z "$TOPICS" ] || create_topics &

#-Djavax.net.debug=all
KAFKA_HEAP_OPTS="-Xmx1G -Xms1G $JAAS_CONF" /opt/kafka/bin/kafka-server-start.sh $prop_file

