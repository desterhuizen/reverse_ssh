ifdef RSSH_HOMESERVER
	LDFLAGS += -X main.destination=$(RSSH_HOMESERVER)
endif

ifdef RSSH_FINGERPRINT
	LDFLAGS += -X main.fingerprint=$(RSSH_FINGERPRINT)
endif

ifdef RSSH_PROXY
	LDFLAGS += -X main.proxy=$(RSSH_PROXY)
endif

ifdef IGNORE
	LDFLAGS += -X main.ignoreInput=$(IGNORE)
endif

ifndef CGO_ENABLED
	export CGO_ENABLED=0
endif

BUILD_FLAGS := -trimpath

LDFLAGS += -X 'github.com/NHAS/reverse_ssh/internal.Version=$(shell git describe --tags)'

LDFLAGS_RELEASE = $(LDFLAGS) -s -w

debug: .generate_keys
	go build $(BUILD_FLAGS) -ldflags="$(LDFLAGS)" -o bin ./...
	GOOS=windows GOARCH=amd64 go build $(BUILD_FLAGS) -ldflags="$(LDFLAGS)" -o bin ./cmd/client

release: .generate_keys
	# Full list of Platforms and architectures: https://gist.github.com/zfarbp/121a76d5a3fde562c3955a606a9d6fcc
	GOOS=linux GOARCH=amd64 go build $(BUILD_FLAGS) -ldflags="$(LDFLAGS_RELEASE)" -o bin/client_x64 ./cmd/client
	GOOS=linux GOARCH=386 go build $(BUILD_FLAGS) -ldflags="$(LDFLAGS_RELEASE)" -o bin/client_x86 ./cmd/client
	GOOS=linux GOARCH=arm64 go build $(BUILD_FLAGS) -ldflags="$(LDFLAGS_RELEASE)" -o bin/client_arm64 ./cmd/client
	GOOS=linux GOARCH=arm go build $(BUILD_FLAGS) -ldflags="$(LDFLAGS_RELEASE)" -o bin/client_arm ./cmd/client
	GOOS=windows GOARCH=amd64 go build $(BUILD_FLAGS) -ldflags="$(LDFLAGS_RELEASE)" -buildmode=exe -o bin/client_x64.exe ./cmd/client
	GOOS=windows GOARCH=386 go build $(BUILD_FLAGS) -ldflags="$(LDFLAGS_RELEASE)" -o bin/client_x86.exe -buildmode=exe ./cmd/client
	GOOS=windows GOARCH=arm64 go build $(BUILD_FLAGS) -ldflags="$(LDFLAGS_RELEASE)" -o bin/client_arm64.exe -buildmode=exe ./cmd/client
	GOOS=darwin GOARCH=amd64 go build $(BUILD_FLAGS) -ldflags="$(LDFLAGS_RELEASE)" -o bin/darwin_client_x64.exe ./cmd/client
	GOOS=darwin GOARCH=arm64 go build $(BUILD_FLAGS) -ldflags="$(LDFLAGS_RELEASE)" -o bin/darwin_client_arm64 ./cmd/client

client: .generate_keys
	go build $(BUILD_FLAGS) -ldflags="$(LDFLAGS_RELEASE)" -o bin ./cmd/client

client_dll: .generate_keys
	test -n "$(RSSH_HOMESERVER)" # Shared objects cannot take arguments, so must have a callback server baked in (define RSSH_HOMESERVER)
	CGO_ENABLED=1 go build $(BUILD_FLAGS) -tags=cshared -buildmode=c-shared -ldflags="$(LDFLAGS_RELEASE)" -o bin/client.dll ./cmd/client

server:
	mkdir -p bin
	go build $(BUILD_FLAGS) -ldflags="$(LDFLAGS_RELEASE)" -o bin ./cmd/server

.generate_keys:
	mkdir -p bin
# Supress errors if user doesn't overwrite existing key
	ssh-keygen -t ed25519 -N '' -C '' -f internal/client/keys/private_key || true
# Avoid duplicate entries
	touch bin/authorized_controllee_keys
	@grep -q "$$(cat internal/client/keys/private_key.pub)" bin/authorized_controllee_keys || cat internal/client/keys/private_key.pub >> bin/authorized_controllee_keys
