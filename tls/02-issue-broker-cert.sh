#!/bin/bash -e

set -euo pipefail

cd "$(dirname "$0")"

PASSWORD="${KAFKA_SSL_KEY_PASSWORD:-nosecret}"

DN_C="${TLS_DN_C:-SE}"
DN_ST="${TLS_DN_ST:-Stockholm}"
DN_L="${TLS_DN_L:-Stockholm}"
DN_O="${TLS_DN_O:-zmstone}"
DN_OU="${TLS_DN_OU:-Kafka}"
DN_CN="localhost"
if [ -n "${KAFKA_ADVERTISED_LISTENERS:-}" ]; then
  DN_CN="$(echo "$KAFKA_ADVERTISED_LISTENERS" | sed 's#.*://\(.*\):[1-9].*#\1#p' | head -1)"
elif [ -n "${KAFKA_ADVERTISED_HOSTNAME:-}" ]; then
  DN_CN="$KAFKA_ADVERTISED_HOSTNAME"
fi

SAN_IP=""
if [ -n "${TLS_KAFKA_IP:-}" ]; then
  SAN_IP="IP = $TLS_KAFKA_IP"
fi
SAN_DNS="DNS = $DN_CN"
if [ -n "${TLS_KAFKA_DNS:-}" ]; then
  SAN_DNS="DNS = $TLS_KAFKA_DNS"
fi

# Openssl command oneliners do not support request extentions well
# hence the need of a config file

cat <<-EOF > config
[req]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[dn]
C = $DN_C
ST = $DN_ST
L = $DN_L
O = $DN_O
OU = $DN_OU
CN = $DN_CN

[req_ext]
subjectAltName = @alt_names

[alt_names]
$SAN_DNS
$SAN_IP

[ca]
default_ca      = kafkaCA

[kafkaCA]
dir            = ./ca
database       = \$dir/index.txt
new_certs_dir  = \$dir

certificate    = inter-ca.pem
private_key    = inter-ca.key
serial         = \$dir/serial

default_days   = 3650
default_crl_days= 30
default_md     = sha256

policy         = cert_policy
email_in_dn    = no

name_opt       = ca_default
cert_opt       = ca_default
copy_extensions = none

[ cert_policy ]
countryName            = supplied
stateOrProvinceName    = supplied
organizationName       = supplied
organizationalUnitName = supplied
commonName             = supplied
emailAddress           = optional
EOF

mkdir -p ca
rm -f ./ca/*
if [ ! -f ca/index.txt ]; then touch ca/index.txt; fi
if [ ! -f ca/index.txt.attr ]; then touch ca/index.txt.attr; fi
if [ ! -f ca/serial ]; then date '+%s' > ca/serial; fi

openssl genrsa -out kafka.key 2048
openssl req -newkey rsa:2048 -sha256 -keyout kafka.key -out kafka.csr -nodes -config ./config
openssl ca -batch -out kafka.pem -config config -extensions req_ext -infiles kafka.csr
rm -f kafka.csr

# create keystore
cat "inter-ca.pem" "ca.pem" > bundle.crt
openssl pkcs12 -export -name "$DN_CN" -in kafka.pem -inkey kafka.key -out kafka.p12 -chain -CAfile bundle.crt -passout pass:"$PASSWORD"
rm -f kafka.jks
echo "$PASSWORD" | keytool -importkeystore -destkeystore kafka.jks -srckeystore kafka.p12 -srcstoretype pkcs12 -alias "$DN_CN" -storepass "$PASSWORD"
rm -f kafka.p12 kafka.key bundle.crt kafka.pem config inter-ca.key inter-ca.pem
