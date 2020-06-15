#!/bin/bash -e

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

# backward compatible for topics creation
if [ -n "${TOPICS:-}" ]; then
  export KAFKA_CREATE_TOPICS="{TOPICS},${KAFKA_CREATE_TOPICS:-}"
fi

# backward compatible for (advertised) listener's config
ipwithnetmask="$(ip -f inet addr show dev eth0 | awk '/inet / { print $2 }')"
ipaddress="${ipwithnetmask%/*}"

HOST="${ADVERTISED_HOSTNAME:-$ipaddress}"
PLAINTEXT_PORT="${PLAINTEXT_PORT:-9092}"
SSL_PORT="${SSL_PORT:-9093}"
SASL_PLAINTEXT_PORT="${SASL_PLAINTEXT_PORT:-9094}"
SASL_SSL_PORT="${SASL_SSL_PORT:-9095}"

if [ -z "${KAFKA_ADVERTISED_LISTENERS:-}" ]; then
  export KAFKA_ADVERTISED_LISTENERS="PLAINTEXT://$HOST:$PLAINTEXT_PORT,SSL://$HOST:$SSL_PORT,SASL_PLAINTEXT://$HOST:$SASL_PLAINTEXT_PORT,SASL_SSL://$HOST:$SASL_SSL_PORT"
  export KAFKA_LISTENERS="PLAINTEXT://:$PLAINTEXT_PORT,SSL://:$SSL_PORT,SASL_PLAINTEXT://:$SASL_PLAINTEXT_PORT,SASL_SSL://:$SASL_SSL_PORT"
fi

if [ -z "${KAFKA_SSL_KEYSTORE_LOCATION:-}" ]; then
  # generate certs and set env
  /opt/kafka/tls/generate-certs.sh
  export KAFKA_SSL_KEYSTORE_LOCATION=/opt/kafka/tls/kafka.jks
  export KAFKA_SSL_KEYSTORE_PASSWORD=nosecret
  export KAFKA_SSL_KEY_PASSWORD=nosecret
  export KAFKA_SSL_TRUSTSTORE_LOCATION=/opt/kafka/tls/truststore.jks
  export KAFKA_SSL_TRUSTSTORE_PASSWORD=nosecret
  export KAFKA_SSL_CLIENT_AUTH=none
  export KAFKA_SSL_ENDPOINT_IDENTIFICATION_ALGORITHM=" "
fi

export KAFKA_AUTO_CREATE_TOPICS_ENABLED="${KAFKA_AUTO_CREATE_TOPICS_ENABLED:-false}"
export KAFKA_DELETE_TOPIC_ENABLED="${KAFKA_DELETE_TOPIC_ENABLED:-true}"
export KAFKA_BROKER_ID="${KAFKA_BROKER_ID:-0}"
export KAFKA_SASL_ENABLED_MECHANISMS="${KAFKA_SASL_ENABLED_MECHANISMS:-PLAIN,SCRAM-SHA-256,SCRAM-SHA-512}"
export KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR="${KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR:-1}"
export KAFKA_OFFSETS_TOPIC_NUM_PARTITIONS="${KAFKA_OFFSETS_TOPIC_NUM_PARTITIONS:-7}"
export KAFKA_TRANSACTION_STATE_LOG_MIN_ISR="${KAFKA_TRANSACTION_STATE_LOG_MIN_ISR:-1}"
export KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR="${KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR:-1}"

if [ -z "${JAAS_CONF:-}" ]; then
  if [[ "$KAFKA_VERSION" = 0.10* ]]; then
    JAAS_CONF="-Djava.security.auth.login.config=/opt/kafka/sasl/jaas-plain.conf"
  else
    JAAS_CONF="-Djava.security.auth.login.config=/opt/kafka/sasl/jaas-plain-scram.conf"
  fi
fi

export KAFKA_OPTS="${JAAS_CONF}"

## run kafka
/usr/bin/start-kafka.sh
