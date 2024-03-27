start:
	@echo "Setting up e2e infra"
	@sed -i 's/"proxy"\:.*/"proxy"\: "http\:\/\/many-abci\:8000"/g' ./alberto/package.json
	@docker compose up -d --wait

stop:
	@echo "Tearing down e2e infra"
	@docker compose down -v

.PHONY: infra