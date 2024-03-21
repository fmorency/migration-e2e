#### manifest-ledger start ####

build-manifest-ledger-image:
	@echo "Building manifest:local image"
	@cd manifest-ledger && make local-image
	@cd -

clean-manifest-ledger:
	@echo "Cleaning manifest-ledger"
	@cd manifest-ledger
	@docker rmi -f manifest:local
	@cd -

.PHONY: build-manifest-ledger-image

#### manifest-ledger end ####

#### alberto start ####

.ONESHELL:
build-alberto:
	@echo "Building alberto"
	@. ${HOME}/.nvm/nvm.sh
	@nvm install v20.9.0
	@cd alberto
	@rm -rf nodes_modules && npm i
	@cd -

.ONESHELL:
clean-alberto:
	@echo "Cleaning alberto"
	@. ${HOME}/.nvm/nvm.sh
	@nvm install v20.9.0
	@cd alberto
	@rm -rf nodes_modules
	@cd -

.PHONY: build-alberto clean-alberto

#### alberto end ####

#### mfx-migrator start ####

build-migrator-image:
	@echo "Building ko.local/mfx-migrator:latest image"
	@cd mfx-migrator && ko build -B -L ./
	@cd -

clean-migrator:
	@echo "Cleaning mfx-migrator"
	@docker rmi -f $$(docker images --filter=reference="ko.local/mfx-migrator:*" -q)

.PHONY: build-migrator-image clean-migrator

#### mfx-migrator end ####

#### talib start

build-talib-images:
	@echo "Building talib images"
	@cd talib
	@docker compose build
	@cd -

clean-talib:
	@echo "Cleaning talib"
	@cd talib
	@docker compose down -v
	@cd -

.PHONY: build-talib-images clean-talib

#### talib end ####

#### many-cluster start ####

many-cluster:
	@echo "Building hybrid/many-ledger-a and hybrid/many-abci-a images"
	@cd many-cluster
	@make genfiles/buildA
	@echo "Generating genfiles/docker_compose.json"
	@make genfiles/docker_compose.json
	@cd -

clean-many-cluster-config:
	@echo "Cleaning many-cluster"
	@cd many-cluster
	@make clean
	@cd -

clean-many-cluster-images:
	@echo "Cleaning many-cluster images"
	@cd many-cluster
	@docker rmi -f hybrid/many-ledger-a hybrid/many-abci-a
	@cd -

clean-many-cluster: clean-many-cluster-config clean-many-cluster-images
	@echo "Cleaning many-cluster"

.PHONY: many-cluster clean-many-cluster-config clean-many-cluster-images clean-many-cluster

#### many-cluster end ####

#### many-rs start ####

many-rs:
	@echo "Building many-abci and many-ledger"
	@cd many-rs
	@cargo build --bin many-abci --bin many-ledger
	@cd -

clean-many-rs:
	@echo "Cleaning many-rs"
	@cd many-rs
	@cargo clean
	@cd -

.PHONY: many-rs clean-many-rs

#### many-rs end ####
