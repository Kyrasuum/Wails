.PHONY: dev
#: Starts the project in dev mode
dev: deps
	@wails dev

.PHONY: clean-run
#: Performs a clean run of the project
clean-run: build run

.PHONY: run
#: Starts the project
run: deps
	@./build/bin/karalis

.PHONY: build
#: Performs a clean build of the project
build: dev-deps
	@wails build

.PHONY: release
#: Creates a saved copy of docker images
release: build
	@wails build -platform darwin || true;
	@wails build -platform darwin/amd64 || true;
	@wails build -platform darwin/arm64 || true;
	@wails build -platform darwin/universal || true;
	@wails build -platform linux || true;
	@wails build -platform linux/amd64 || true;
	@wails build -platform linux/arm64 || true;
	@wails build -platform linux/arm || true;
	@wails build -platform windows || true;
	@wails build -platform windows/amd64 || true;
	@wails build -platform windows/arm64 || true;
	@wails build -platform windows/386 || true;

.PHONY: clean
#: Cleans slate
clean:
	@rm -rf build/bin/*
	@rm -rf frontend/node_modules
	@rm -rf frontend/dist

.PHONY: clean-all
#: Complete Clean
clean-all: clean clean-vol

.PHONY: deps
#: Install dependencies for targets in this makefile
deps:
	@cd frontend/src/p2p && npm run setup
	@cd frontend/src/p2p && npm run build
 
.PHONY: dev-deps
#: Installs all depedencies for development
dev-deps: deps .dev-deps
.dev-deps:
	@go install github.com/wailsapp/wails/v2/cmd/wails@latest
	@wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
	@[ -s "$$NVM_DIR/nvm.sh" ] && \. $$NVM_DIR/nvm.sh \
		&& nvm install v18.6.0 && nvm use v18.6.0 \
		&& nvm install-latest-npm
	@sudo apt-add-repository --update ppa:longsleep/golang-backports
	@sudo apt install golang-1.18 libgtk-3-dev libwebkit2gtk-4.0-dev
	@touch .dev-deps

.PHONY: help
#: Lists available commands
help:
	@echo "Available Commands for project:"
	@grep -B1 -E "^[a-zA-Z0-9_-]+\:([^\=]|$$)" Makefile \
	 | grep -v -- -- \
	 | sed 'N;s/\n/###/' \
	 | sed -n 's/^#: \(.*\)###\(.*\):.*/\2###\1/p' \
	 | column -t  -s '###'
