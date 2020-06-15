# What

This directory includes a script (`generate-certs.sh`) which was used to
generate the key pairs committed to the git repo.

The script generates (but does not overwrite) root CA and client key pairs.
The root CA issues an intermediate CA which is then used to issue Kafka's
server certificate.
Kafka's truststore only has the root CA imported.
Kafka's keystore has the full certificate chain imported (root CA included).

## Root CA

The root CA key pair `ca.key` and `ca.crt` are committed to git,
so it will be the same root CA used for different docker image versions.

It also make it easier for users, so they do not have to copy the certificate
evey time when upgrading to a new docker image.

## Broker Certificate

The common name for broker certificate is taken from `KAFKA_ADVERTISED_LISTENERS`
or `KAFKA_ADVERTISED_HOSTNAME`.
If the bootstrap endpoint is different from advertised, the options are:
`TLS_KAFKA_IP` for IP address, and `TLS_KAFKA_DNS` for FQND.

## Client Certificates

The client certificate is issued by root CA.
The client key pair is commited to git only for users to test easier.
