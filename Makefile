LIB = zmstone
VERSIONS = 0.10.2.2 0.11.0.3 1.0.2 1.1.1 2.2.1 2.4.0
short_vsn = $(word 1,$(subst ., ,$1)).$(word 2,$(subst ., ,$1))

.PHONY: all
all: build

.PHONY: build
build: $(VERSIONS:%=build-%)

.PHONY: $(VERSIONS:%=build-%)
$(VERSIONS:%=build-%):
	docker build --build-arg KAFKA_VERSION=$(subst build-,,$@) -t $(LIB)/kafka:$(call short_vsn,$(subst build-,,$@)) .

.PHONY: push
push: $(VERSIONS:%=push-%)

.PHONY: $(VERSIONS:%=push-%)
$(VERSIONS:%=push-%):
	docker push $(LIB)/kafka:$(call short_vsn,$(subst push-,,$@))

