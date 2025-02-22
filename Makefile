.PHONY: build importer dump_region sync_diff_inspector ddl_checker test check deps version tools

# Ensure GOPATH is set before running build process.
ifeq "$(GOPATH)" ""
	$(error Please set the environment variable GOPATH before running `make`)
endif


CURDIR := $(shell pwd)
path_to_add := $(addsuffix /bin,$(subst :,/bin:,$(GOPATH)))
export PATH := $(path_to_add):$(PATH)


LDFLAGS += -X "github.com/pingcap/tidb-tools/pkg/utils.Version=$(shell git describe --tags --dirty --always)"
LDFLAGS += -X "github.com/pingcap/tidb-tools/pkg/utils.BuildTS=$(shell date -u '+%Y-%m-%d %I:%M:%S')"
LDFLAGS += -X "github.com/pingcap/tidb-tools/pkg/utils.GitHash=$(shell git rev-parse HEAD)"
LDFLAGS += -X "github.com/pingcap/tidb-tools/pkg/utils.GitBranch=$(shell git rev-parse --abbrev-ref HEAD)"

CURDIR   := $(shell pwd)
GO       := GO111MODULE=on go
GOTEST   := CGO_ENABLED=1 $(GO) test -p 3
PACKAGES := $$(go list ./... | grep -vE 'vendor')
FILES     := $$(find . -name '*.go' -type f | grep -vE 'vendor')
VENDOR_TIDB := vendor/github.com/pingcap/tidb
PACKAGE_LIST  := go list ./...
PACKAGES  := $$($(PACKAGE_LIST))
FAIL_ON_STDOUT := awk '{ print } END { if (NR > 0) { exit 1 } }'

define run_unit_test
	@echo "running unit test for packages:" $(1)
	@make failpoint-enable
	@export log_level=error; \
	$(GOTEST) -cover $(1) \
	|| { @make failpoint-disable; exit 1; }
	@make failpoint-disable
endef

build: prepare version check importer sync_diff_inspector ddl_checker finish


failpoint-enable: tools
	tools/bin/failpoint-ctl enable

failpoint-disable: tools
	tools/bin/failpoint-ctl disable

tools:
	@echo "install tools..."
	@cd tools && make

version:
	$(GO) version

prepare:
	cp go.mod1 go.mod
	cp go.sum1 go.sum

importer:
	$(GO) build -ldflags '$(LDFLAGS)' -o bin/importer ./importer

dump_region:
	$(GO) build -ldflags '$(LDFLAGS)' -o bin/dump_region ./dump_region

sync_diff_inspector:
	$(GO) build -ldflags '$(LDFLAGS)' -o bin/sync_diff_inspector ./sync_diff_inspector

ddl_checker:
	$(GO) build -ldflags '$(LDFLAGS)' -o bin/ddl_checker ./ddl_checker

test: version
	$(call run_unit_test,$(PACKAGES))

integration_test: prepare failpoint-enable importer sync_diff_inspector ddl_checker failpoint-disable finish
	@which bin/tidb-server
	@which bin/tikv-server
	@which bin/pd-server
	@which bin/sync_diff_inspector
	@which bin/mydumper
	@which bin/loader
	@which bin/importer
	tests/run.sh

fmt:
	@echo "gofmt (simplify)"
	@ gofmt -s -l -w $(FILES) 2>&1 | awk '{print} END{if(NR>0) {exit 1}}'

check: fmt
	#go get github.com/golang/lint/golint
	@echo "vet"
	@$(GO) vet -composites=false $(PACKAGES)
	@$(GO) vet -vettool=$(CURDIR)/bin/shadow $(PACKAGES) || true
	#@echo "golint"
	#@ golint ./... 2>&1 | grep -vE '\.pb\.go' | grep -vE 'vendor' | awk '{print} END{if(NR>0) {exit 1}}'

tidy:
	cp go.mod1 go.mod
	cp go.sum1 go.sum
	@$(GO) mod tidy
	cp go.mod go.mod1
	cp go.sum go.sum1

clean: prepare tidy finish

finish:
	cp go.mod go.mod1
	cp go.sum go.sum1
