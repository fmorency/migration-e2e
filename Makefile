start: docker-up create-neiborhood

set-alberto-proxy:
	@echo "Setting Alberto proxy"
	@sed -i 's/"proxy"\:.*/"proxy"\: "http\:\/\/many-abci\:8000"/g' ./alberto/package.json

docker-up: set-alberto-proxy
	@echo "Setting up e2e infra"
	@docker compose up -d --wait

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

.PHONY: start stop create-neiborhood set-alberto-proxy docker-up