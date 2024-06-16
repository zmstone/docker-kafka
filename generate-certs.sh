#!/bin/bash -xe

HOST="localhost"
DAYS=3650
PASS="brodtest1234"

# Generate self-signed server and client certificates
## generate CA
openssl req -new -x509 -keyout localhost-ca-key.pem -out localhost-ca-crt.pem -days $DAYS -nodes -subj "/C=SE/ST=Stockholm/L=Stockholm/O=brod/OU=test/CN=$HOST"

## generate server certificate request
openssl req -newkey rsa:2048 -sha256 -keyout localhost-server-key.pem -out server.csr -days $DAYS -nodes -subj "/C=SE/ST=Stockholm/L=Stockholm/O=brod/OU=test/CN=$HOST"

## sign server certificate
openssl x509 -req -CA localhost-ca-crt.pem -CAkey localhost-ca-key.pem -in server.csr -out localhost-server-crt.pem -days $DAYS -CAcreateserial

## generate client certificate request
openssl req -newkey rsa:2048 -sha256 -keyout localhost-client-key.pem -out client.csr -days $DAYS -nodes -subj "/C=SE/ST=Stockholm/L=Stockholm/O=brod/OU=test/CN=$HOST"

## sign client certificate
openssl x509 -req -CA localhost-ca-crt.pem -CAkey localhost-ca-key.pem -in client.csr -out localhost-client-crt.pem -days $DAYS -CAserial localhost-ca-crt.srl

# Convert self-signed certificate to PKCS#12 format
openssl pkcs12 -export -name $HOST -in localhost-server-crt.pem -inkey localhost-server-key.pem -out server.p12 -CAfile localhost-ca-crt.pem -passout pass:$PASS

# Import PKCS#12 into a java keystore
echo $PASS | keytool -importkeystore -destkeystore server.jks -srckeystore server.p12 -srcstoretype pkcs12 -alias $HOST -storepass $PASS

# Import CA into java truststore
echo yes | keytool -keystore truststore.jks -alias localhost -import -file localhost-ca-crt.pem -storepass $PASS
