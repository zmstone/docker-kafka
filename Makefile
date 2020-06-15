LIB = zmstone
VERSIONS = 2.11-0.10.2.2 2.11-0.11.0.3 2.11-1.1.1 2.12-2.2.2 2.12-2.3.1 2.12-2.4.1 2.12-2.5.0 2.13-2.6.0
kafka_vsn = $(word 2,$(subst -, ,$1))
kafka_vsn_nums = $(subst ., ,$(call kafka_vsn,$1))
short_vsn = $(word 1,$(call kafka_vsn_nums,$1)).$(word 2,$(call kafka_vsn_nums,$1))

.PHONY: all
all: build

.PHONY: build
build: $(VERSIONS:%=build-%)

.PHONY: $(VERSIONS:%=build-%)
$(VERSIONS:%=build-%):
	docker build --build-arg BASE_IMAGE_VERSION=$(subst build-,,$@) \
		           --build-arg KAFKA_VERSION=$(call kafka_vsn,$(subst build-,,$@)) \
							 -t $(LIB)/kafka:$(call short_vsn,$(subst build-,,$@)) .

.PHONY: push
push: $(VERSIONS:%=push-%)

.PHONY: $(VERSIONS:%=push-%)
$(VERSIONS:%=push-%):
	docker push $(LIB)/kafka:$(call short_vsn,$(subst push-,,$@))

.PHONY: test
test: $(VERSIONS:%=test-%)

.PHONY: $(VERSIONS:%=test-%)
$(VERSIONS:%=test-%):
	./test.sh $(LIB)/kafka:$(call short_vsn,$(subst push-,,$@))

