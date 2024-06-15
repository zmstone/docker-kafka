#!/bin/bash -xe

HOST="localhost"
DAYS=3650
PASS="brodtest1234"

# Generate self-signed server and client certificates
## generate CA
openssl req -new -x509 -keyout ca.key -out ca.pem -days $DAYS -nodes -subj "/C=SE/ST=Stockholm/L=Stockholm/O=brod/OU=test/CN=$HOST"

## generate server certificate request
openssl req -newkey rsa:2048 -sha256 -keyout server.key -out server.csr -days $DAYS -nodes -subj "/C=SE/ST=Stockholm/L=Stockholm/O=brod/OU=test/CN=$HOST"

## sign server certificate
openssl x509 -req -CA ca.pem -CAkey ca.key -in server.csr -out server.pem -days $DAYS -CAcreateserial

## generate client certificate request
openssl req -newkey rsa:2048 -sha256 -keyout client.key -out client.csr -days $DAYS -nodes -subj "/C=SE/ST=Stockholm/L=Stockholm/O=brod/OU=test/CN=$HOST"

## sign client certificate
openssl x509 -req -CA ca.pem -CAkey ca.key -in client.csr -out client.pem -days $DAYS -CAserial ca.srl

# Convert self-signed certificate to PKCS#12 format
openssl pkcs12 -export -name $HOST -in server.pem -inkey server.key -out server.p12 -CAfile ca.pem -passout pass:$PASS

# Import PKCS#12 into a java keystore
echo $PASS | keytool -importkeystore -destkeystore server.jks -srckeystore server.p12 -srcstoretype pkcs12 -alias $HOST -storepass $PASS

# Import CA into java truststore
echo yes | keytool -keystore truststore.jks -alias localhost -import -file ca.pem -storepass $PASS
