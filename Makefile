start: docker-up create-neiborhood

set-alberto-talib:
	@echo "Setting Alberto Talib URL" # Set the Talib URL to the dockerized Talib
	@sed -i 's/REACT_APP_TALIB_URL=.*/REACT_APP_TALIB_URL="http\:\/\/localhost\:3001\/api\/v1\/neighborhoods\/1\/"/g' ./alberto/.env
	@sed -i 's/REACT_APP_TALIB_URL=.*/REACT_APP_TALIB_URL="http\:\/\/localhost\:3001\/api\/v1\/neighborhoods\/1\/"/g' ./alberto/.env.staging

set-alberto-proxy:
	@echo "Setting Alberto proxy" # Set the proxy to the dockerized ABCI
	@sed -i 's/"proxy"\:.*/"proxy"\: "http\:\/\/many-abci\:8000"/g' ./alberto/package.json

set-alberto-http:
	@echo "Disabling HTTPS in Alberto" # This is needed for loading mixed active content
	@sed -i 's/HTTPS=.*/HTTPS=false/g' ./alberto/.env

docker-up: set-alberto-proxy set-alberto-talib set-alberto-http talib-enable-cors
	@echo "Setting up e2e infra"
	@docker compose up -d --wait

talib-enable-cors:
	@echo "Enabling CORS in Talib"
	@cd talib && if git apply -q --check ../patch/talib-enable-cors.patch; then git apply ../patch/talib-enable-cors.patch; else echo "CORS patch already applied, skipping"; fi && cd -

.ONESHELL:
create-neiborhood: docker-up
	@echo "Waiting on Talib to start"
	@while [ -z "$$ACCTOKEN" ]; do \
	  ACCTOKEN=$$(curl -s --location 'http://localhost:3001/api/v1/auth/login' --header 'Content-Type: application/json' --data '{"username": "admin", "password":"admin"}' | jq -r .access_token)
	  if [ -n "$$ACCTOKEN" ]; then
	  		@echo "Access token obtained"
			ABCIIP=$$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' migration-e2e-many-abci-1)
			@echo "Creating neighborhood in Talib"
			# TODO: The url cannot use hostnames, it must use IP addresses. This is a limitation of the current implementation
			@curl --location --request PUT 'http://localhost:3001/api/v1/neighborhoods/' --header 'Content-Type: application/json' --header 'Authorization: Bearer '$$ACCTOKEN'' --data '{"url": "http://'$$ABCIIP':8000", "name": "Ledger", "enabled": true, "description": "Ledger network"}'
			break
		else
			printf '.'
			sleep 5
		fi
	done

stop:
	@echo "Tearing down e2e infra"
	@docker compose down -v

build: clean set-alberto-proxy set-alberto-talib set-alberto-http talib-enable-cors
	@echo "Building e2e infra"
	@docker compose build

clean:
	@echo "Cleaning up e2e infra"
	@docker compose down -v
	@cd alberto && rm -rf node_modules && git reset --hard HEAD && cd -
	@cd talib && git reset --hard HEAD && cd -

.PHONY: start stop create-neiborhood set-alberto-proxy set-alberto-talib docker-up build talib-enable-cors clean