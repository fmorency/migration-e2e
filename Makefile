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
	@sed -i 's/"proxy"\:.*/"proxy"\: "http\:\/\/localhost\:8001"/g' package.json
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

build-talib:
	@echo "Building talib"
	@cd talib
	@sed -i "s/- 3000:3000/- 3001:3000/g" docker-compose.yml
	@docker compose build
	@cd -

clean-talib:
	@echo "Cleaning talib"
	@cd talib
	@docker compose down -v
	@cd -

.PHONY: build-talib clean-talib

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

#### infra start ####

bin-for-cluster: many-rs
	@echo "Copying MANY binaries to cluster"
	@mkdir -p many-cluster/a-bins
	@cp many-rs/target/debug/many-abci many-cluster/a-bins/
	@cp many-rs/target/debug/many-ledger many-cluster/a-bins/
	@echo "Copying MANY configurations to cluster"
	@cp config/ledger_state.json5 many-cluster/
	@cp config/ledger_migrations.json many-cluster/a-bins/

infra-cluster: bin-for-cluster many-cluster
	@echo "Starting MANY cluster"
	@cd many-cluster
	@pm2 -n MANY-Cluster start make -- start-nodes
	@cd -

infra-alberto: build-alberto
	@echo "Starting alberto"
	@cd alberto
	@pm2 -n Alberto start npm -- run start
	@cd -

infra-talib: build-talib
	@echo "Starting talib"
	@cd talib
	@pm2 -n Talib start docker -- compose up
	@cd -

infra-manifest-ledger: build-manifest-ledger-image
	@echo "Starting manifest-ledger"
	$(eval TMP := $(shell mktemp -d))
	@mkdir -p $(TMP)/manifest-ledger/chains
	@cp config/manifest.json $(TMP)/manifest-ledger/chains/
	@cd $(TMP)/manifest-ledger
	@ICTEST_HOME=. pm2 -n Manifest-Ledger start local-ic -- start manifest
	@cd -

infra: infra-cluster infra-alberto infra-talib infra-manifest-ledger
	@echo "Starting e2e infrastructure"
	@echo "Connecting talib to ledger network"
	@docker network connect e2e-ledger_default talib-app-1
	@echo "Creating neighborhood for ledger network"
	$(eval ABCIIP := $(shell docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' e2e-ledger-abci-1-1))
	$(eval ACCTOKEN := $(shell curl -s --location 'http://localhost:3001/api/v1/auth/login' --header 'Content-Type: application/json' --data '{"username": "admin", "password":"admin"}' | jq .access_token))
	@curl --location --request PUT 'http://localhost:3001/api/v1/neighborhoods/' --header 'Content-Type: application/json' --header 'Authorization: Bearer '$(ACCTOKEN)'' --data '{"url": "http://'$(ABCIIP)':8000", "name": "Ledger", "enabled": true, "description": "Ledger network"}'

stop:
	@echo "Stopping e2e infrastructure"
	@pm2 stop MANY-Cluster
	@pm2 stop Alberto
	@pm2 stop Talib
	@docker kill talib-app-1
	@docker kill talib-db-1
	@pm2 stop Manifest-Ledger
	@docker kill manifest-2-val-0-manifestic
	@pm2 del all

reset:
	@echo "Resetting e2e infrastructure"
	@pm2 delete all
	@cd many-cluster
	@docker compose down -v
	@cd -
	@cd talib
	@docker compose down -v
	@cd -
	@docker rm manifest-2-val-0-manifestic
	@docker rm e2e-ledger-abci-1-1
	@docker rm e2e-ledger-abci-2-1
	@docker rm e2e-ledger-abci-3-1
	@docker rm e2e-ledger-abci-4-1
	@docker rm e2e-ledger-ledger-1-1
	@docker rm e2e-ledger-ledger-2-1
	@docker rm e2e-ledger-ledger-3-1
	@docker rm e2e-ledger-ledger-4-1
	@docker rm e2e-ledger-tendermint-1-1
	@docker rm e2e-ledger-tendermint-2-1
	@docker rm e2e-ledger-tendermint-3-1
	@docker rm e2e-ledger-tendermint-4-1
	@docker network rm e2e-ledger_default

reset-images:
	@echo "Resetting e2e infrastructure images"
	@docker rmi -f $$(docker images --filter=reference="ko.local/mfx-migrator:*" -q)
	@docker rmi -f $$(docker images --filter=reference="hybrid/many-ledger-a" -q)
	@docker rmi -f $$(docker images --filter=reference="hybrid/many-abci-a" -q)
	@docker rmi -f $$(docker images --filter=reference="manifest:local" -q)
	@docker rmi -f $$(docker images --filter=reference="talib-app" -q)


.PHONY: bin-for-cluster infra-cluster infra-alberto infra-talib infra