SHELL:=/bin/bash

NODE_ENV:=production
MODULE_NAME:=$(shell basename $$PWD)
MODULE_VERSION:=$(shell sed -ne "s/\\\$$this->version *= *['\"]\([^'\"]*\)['\"] *;.*/\1/p" ${MODULE_NAME}.php | awk '{$$1=$$1};1')
ZIP_FILE:="${MODULE_NAME}-v${MODULE_VERSION}.zip"

FILES:=logo.gif
FILES+=logo.png
FILES+=LICENSE
FILES+=${MODULE_NAME}.php
FILES+=index.php
FILES+=controllers/**
FILES+=sql/**
FILES+=translations/**
FILES+=upgrade/**
FILES+=vendor/**
FILES+=views/index.php
FILES+=views/css/**
FILES+=views/img/**
FILES+=views/js/index.php
FILES+=views/js/jquery.sortable.js
FILES+=views/js/dist/*.min.js
FILES+=views/js/dist/index.php
FILES+=views/templates/**

.PHONY: all clean composer php-scoper node webpack zip
all: prod
prod: composer php-scoper node webpack zip
dev: setdev composer php-scoper node webpack

setdev:
export NODE_ENV=development

clean:
# Composer
	@rm -rf vendor/ 2>/dev/null || true
	@rm composer.lock 2>/dev/null || true

# Webpack / node.js
	@rm -rf views/js/src/node_modules/ 2>/dev/null || true
	@rm views/js/src/package-lock.json 2>/dev/null || true
	@rm views/js/src/yarn.lock 2>/dev/null || true
	@rm views/js/src/yarn.lock 2>/dev/null || true
	@rm -rf views/js/dist/ 2>/dev/null || true

# PHP scoper
	@rm -rf pre-scoper/ 2>/dev/null || true
	@rm php-scoper.phar 2>/dev/null || true
	@rm php-scoper.phar.pubkey 2>/dev/null || true

php-scoper:
# Check if php scoper is available, otherwise download it
ifeq (,$(wildcard php-scoper.phar))
	wget -q https://github.com/humbug/php-scoper/releases/download/0.10.2/php-scoper.phar
	wget -q https://github.com/humbug/php-scoper/releases/download/0.10.2/php-scoper.phar.pubkey
endif
ifeq (,$(wildcard pre-scoper/))
	@mkdir pre-scoper
endif
	@mv vendor pre-scoper/
	php ./php-scoper.phar add-prefix -p MollieModule -n
	@mv build/pre-scoper/vendor vendor
	@rm pre-scoper/ -rf
	@rm build/ -rf

composer:
ifeq (,$(wildcard vendor/))
# Composer install
	composer install --no-dev --prefer-dist
# Dump and optimize Composer autoloader
	composer -o dump-autoload
# Copy index.php files to vendor folder or Addons validation
	find vendor/ -type d -exec cp index.php {} \;
endif

node:
# Download node modules
# Skip if the node_modules directory already exists
ifeq (,$(wildcard views/js/src/node_modules/))
# Avoid yarn when not available
ifeq (,$(shell which yarn))
	cd views/js/src/; \
		npm i
else
	cd views/js/src/; \
		yarn
endif
endif

webpack:
# Webpack build
ifeq (,$(wildcard views/js/dist/))
	mkdir -p views/js/dist/
endif
	cp views/js/src/index.php views/js/dist/index.php
	cd views/js/src/;\
		webpack --mode $(NODE_ENV)

zip:
# Remove deprecated files from build
	@rm vendor/firstred/mollie-api-php/composer.json 2>/dev/null || true
	@rm vendor/firstred/mollie-reseller-api/composer.json 2>/dev/null || true
	@rm vendor/firstred/mollie-reseller-api/Makefile 2>/dev/null || true

	@echo Going to zip ${MODULE_NAME} version ${MODULE_VERSION}
	@$(foreach f,$(FILES),zip -9 $(ZIP_FILE) $(f);)

vartest:
# Use this to test if all environment variables are correctly set
	@echo "NODE_ENV: ${NODE_ENV}"
	@echo "MODULE_NAME: ${MODULE_NAME}"
	@echo "MODULE_VERSION: ${MODULE_VERSION}"
	@echo "ZIP_FILE: ${ZIP_FILE}"
