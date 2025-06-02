LIB = zmstone
IMAGE_VERSION=1.1
VERSIONS = 2.11-0.9.0.1 \
		   2.11-0.10.2.2 \
		   2.11-0.11.0.3 \
		   2.11-1.1.1 \
		   2.12-2.8.2 \
		   2.12-3.9.1 \
		   2.13-4.0.0

scala_v = $(word 2, $(subst -, ,$(1)))
kafka_v = $(word 3, $(subst -, ,$(1)))
kafka_short_v = $(word 1, $(subst ., ,$(call kafka_v,$(1)))).$(word 2, $(subst ., ,$(call kafka_v,$(1))))
kafka_major = $(word 1, $(subst ., ,$(call kafka_v,$1)))
jdk_for_kafka = $(if $(filter 4,$(call kafka_major,$1)),17, \
				  $(if $(filter 3,$(call kafka_major,$1)),11, \
				    8))

.PHONY: all
all: build

.PHONY: clean
clean:
	git clean -fdx

truststore.jks:
	./generate-certs.sh

.PHONY: build
build: $(VERSIONS:%=build-%)

.PHONY: $(VERSIONS:%=build-%)
$(VERSIONS:%=build-%): truststore.jks
	docker build \
		--build-arg SCALA_VERSION=$(call scala_v,$@) \
		--build-arg KAFKA_VERSION=$(call kafka_v,$@) \
		--build-arg BASE_JDK_IMAGE=openjdk:$(strip $(call jdk_for_kafka,$@))-jdk-slim \
		-t $(LIB)/kafka:$(IMAGE_VERSION)-$(call kafka_short_v,$@) .

.PHONY: push
push: $(VERSIONS:%=push-%)

.PHONY: $(VERSIONS:%=push-%)
$(VERSIONS:%=push-%):
	docker push $(LIB)/kafka:$(IMAGE_VERSION)-$(call kafka_short_v,$@)
