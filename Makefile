# Makefile to aid with local development and testing
# This is not required for automated builds

ifeq ($(OS),Windows_NT)
	PLATFORM ?= win
	ARCH ?= x86_64
else
	UNAME := $(shell uname)
    ifeq ($(UNAME),Linux)
        PLATFORM ?= linux
    endif
    ifeq ($(UNAME),Darwin)
        PLATFORM ?= mac
    endif
	UNAME_M := $(shell uname -m)
    ifeq ($(UNAME_M),x86_64)
        ARCH ?= x86_64
    endif
    ifeq ($(UNAME_M),aarch64)
        ARCH ?= aarch64
    endif
    ifeq ($(UNAME_M),amd64)
        ARCH ?= aarch64
    endif
endif

check-format:
	cargo +nightly fmt -- --check

clippy:
	cargo clippy --all-features --all-targets -- -D warnings

test-local:
	cargo test --all-features

# Full local validation, build and test all features including wasm
# Run this before pushing a PR to pre-validate
test: check-format clippy test-local

fmt: 
	cargo +nightly fmt

# Creates a folder wtih c2patool bin, samples and readme
c2patool-package:
	rm -rf target/c2patool*
	mkdir -p target/c2patool
	mkdir -p target/c2patool/sample
	cp target/release/c2patool target/c2patool/c2patool
	cp README.md target/c2patool/README.md
	cp sample/* target/c2patool/sample
	cp CHANGELOG.md target/c2patool/CHANGELOG.md

# These are for building the c2patool release bin on various platforms
build-release-win-x86:
	rustup target add x86_64-pc-windows-msvc
	cargo build --target=x86_64-pc-windows-msvc --release

build-release-mac-arm:
	rustup target add aarch64-apple-darwin
	MACOSX_DEPLOYMENT_TARGET=11.1 cargo build --target=aarch64-apple-darwin --release

build-release-mac-x86:
	rustup target add x86_64-apple-darwin
	MACOSX_DEPLOYMENT_TARGET=10.15 cargo build --target=x86_64-apple-darwin --release

build-release-mac-universal: build-release-mac-arm build-release-mac-x86
	lipo -create -output target/release/c2patool target/aarch64-apple-darwin/release/c2patool target/x86_64-apple-darwin/release/c2patool

build-release-linux-x86:
	rustup target add x86_64-unknown-linux-gnu
	cargo build --target=x86_64-unknown-linux-gnu --release

build-release-linux-arm:
	rustup target add aarch64-unknown-linux-gnu
	cargo build --target=aarch64-unknown-linux-gnu --release

# Builds and packages a zip for c2patool for each platform
ifeq ($(PLATFORM), mac)
release: build-release-mac-universal c2patool-package
	cd target && zip -r c2patool_mac_universal.zip c2patool && cd ..
endif
ifeq ($(PLATFORM), win)
release: build-release-win-x86 c2patool-package
	cd target && 7z a -r c2patool_win_intel.zip c2patool && cd ..
endif
ifeq ($(PLATFORM), linux)
ifeq ($(ARCH), x86_64)
release: build-release-linux-x86 c2patool-package
	cd target && tar -czvf c2patool_linux_intel.tar.gz c2patool && cd ..
endif
ifeq ($(ARCH), aarch64)
release: build-release-linux-arm c2patool-package
	cd target && tar -czvf c2patool_linux_aarch64.tar.gz c2patool && cd ..
endif
endif
