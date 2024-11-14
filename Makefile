
SHELL:=/bin/bash
.DEFAULT_GOAL := help
.PHONY: help docs

# ---
# Variables
# ---
# include .env
# export $(shell sed 's/=.*//' .env)

PROJECT_PATH := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
GIT_REMOTE=$(shell basename $(shell git remote get-url origin))
PROJECT_NAME=$(shell echo $(GIT_REMOTE:.git=))
CURRENT_VERSION=$(shell git tag -l --sort=-creatordate | head -n 1 | cut -d "v" -f2-)

DOCKER_IMAGE_NAME=ghcr.io/hsteinshiromoto/${PROJECT_NAME}/${PROJECT_NAME}

IMAGE_TAG=$(shell git ls-files -s Dockerfile | awk '{print $$2}' | cut -c1-16)

# ---
# Commands
# ---

## Build Docker base image
image:
	$(eval DOCKER_IMAGE_TAG=${DOCKER_IMAGE_NAME}:${IMAGE_TAG})

	@echo "Building docker image ${IMAGE_TAG}"
	docker buildx build	-t ${DOCKER_IMAGE_TAG} .
	@echo "Done"

## Run /bin/bash inteactively in the container
run:
	$(eval DOCKER_IMAGE_TAG=${DOCKER_IMAGE_NAME}:${IMAGE_TAG})

	@echo "Running docker image ${IMAGE_TAG} ..."
	docker run -it ${DOCKER_IMAGE_TAG} /bin/bash

## Tag docker image as latest
tag:
	$(eval DOCKER_IMAGE_TAG=${DOCKER_IMAGE_NAME}:${IMAGE_TAG})

	docker tag ${DOCKER_IMAGE_TAG} ${DOCKER_IMAGE_NAME}:latest 
# ---
# Self Documenting Commands
# ---

# Inspired by <http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html>
# sed script explained:
# /^##/:
# 	* save line in hold space
# 	* purge line
# 	* Loop:
# 		* append newline + line to hold space
# 		* go to next line
# 		* if line starts with doc comment, strip comment character off and loop
# 	* remove target prerequisites
# 	* append hold space (+ newline) to line
# 	* replace newline plus comments by `---`
# 	* print line
# Separate expressions are necessary because labels cannot be delimited by
# semicolon; see <http://stackoverflow.com/a/11799865/1968>

help:
	@echo "$$(tput bold)Available rules:$$(tput sgr0)"
	@echo
	@sed -n -e "/^## / { \
		h; \
		s/.*//; \
		:doc" \
		-e "H; \
		n; \
		s/^## //; \
		t doc" \
		-e "s/:.*//; \
		G; \
		s/\\n## /---/; \
		s/\\n/ /g; \
		p; \
	}" ${MAKEFILE_LIST} \
	| LC_ALL='C' sort --ignore-case \
	| awk -F '---' \
		-v ncol=$$(tput cols) \
		-v indent=19 \
		-v col_on="$$(tput setaf 6)" \
		-v col_off="$$(tput sgr0)" \
	'{ \
		printf "%s%*s%s ", col_on, -indent, $$1, col_off; \
		n = split($$2, words, " "); \
		line_length = ncol - indent; \
		for (i = 1; i <= n; i++) { \
			line_length -= length(words[i]) + 1; \
			if (line_length <= 0) { \
				line_length = ncol - indent - length(words[i]) - 1; \
				printf "\n%*s ", -indent, " "; \
			} \
			printf "%s ", words[i]; \
		} \
		printf "\n"; \
	}' \
	| more $(shell test $(shell uname) = Darwin && echo '--no-init --raw-control-chars')

