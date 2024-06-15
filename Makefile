LIB = zmstone
IMAGE_VERSION=1.0
VERSIONS = 2.11-0.9.0.1 \
		   2.11-0.11.0.3 \
		   2.11-1.1.1 \
		   2.12-2.8.2 \
		   2.12-3.6.2

scala_v = $(word 2, $(subst -, ,$(1)))
kafka_v = $(word 3, $(subst -, ,$(1)))
kafka_short_v = $(word 1, $(subst ., ,$(call kafka_v,$(1)))).$(word 2, $(subst ., ,$(call kafka_v,$(1))))

# define kafka_short_v
# $(eval KAFKA_FULL_V := $(call kafka_v,$(1)))
# $(word 1, $(subst ., ,$(KAFKA_FULL_V))).$(word 2, $(subst ., ,$(KAFKA_FULL_V)))
# endef

.PHONY: all
all: build

.PHONY: build
build: $(VERSIONS:%=build-%)

.PHONY: $(VERSIONS:%=build-%)
$(VERSIONS:%=build-%):
	docker build \
		--build-arg SCALA_VERSION=$(call scala_v,$@) \
		--build-arg KAFKA_VERSION=$(call kafka_v,$@) \
		-t $(LIB)/kafka/$(IMAGE_VERSION):$(call kafka_short_v,$@) .

.PHONY: push
push: $(VERSIONS:%=push-%)

.PHONY: $(VERSIONS:%=push-%)
$(VERSIONS:%=push-%):
	docker push $(LIB)/kafka:$(call short_vsn,$(subst push-,,$@))
