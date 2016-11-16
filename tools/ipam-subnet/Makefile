SHELL = /bin/bash

TARGET       = ipam-subnet
PROJECT_NAME = github.com/uniseraph/ipam-subnet

MAJOR_VERSION = $(shell cat VERSION)
GIT_VERSION   = $(shell git log -1 --pretty=format:%h)
GIT_NOTES     = $(shell git log -1 --oneline)

BUILD_IMAGE    = golang:1.7
IMAGE_NAME     = uniseraph/ipam-subnet


build-local:
	CGO_ENABLED=0 go build -a -installsuffix cgo -v -ldflags "-X ${PROJECT_NAME}/pkg/logging.ProjectName=${PROJECT_NAME}" -o ${TARGET}
build:
	docker run --rm -v $(shell pwd):/go/src/${PROJECT_NAME} -w /go/src/${PROJECT_NAME} ${BUILD_IMAGE} make build-local
image: build
	docker build --rm -t ${IMAGE_NAME}:${MAJOR_VERSION}-${GIT_VERSION} .
	docker push ${IMAGE_NAME}:${MAJOR_VERSION}-${GIT_VERSION}
	docker tag  ${IMAGE_NAME}:${MAJOR_VERSION}-${GIT_VERSION}   ${IMAGE_NAME}:${MAJOR_VERSION}
	docker push ${IMAGE_NAME}:${MAJOR_VERSION}



.PHONY: image build build-local 
