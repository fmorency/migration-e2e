# Dockerized E2E testing infrastructure

This repository contains a dockerized infrastructure for running end-to-end tests of the token migration process for the MANY protocol. 
The infrastructure consists of 

- Alberto, the MANY wallet (WebApp)
- Talib, the MANY blockchain explorer
- A MANY blockchain node
- A MANIFEST blockchain node
- MFX-Migrator, the token migration daemon

## Requirement

- Docker (tested against 25.0.3)
- Docker Compose (tested against 2.24.6)
- jq (tested against 1.6)
- curl (tested against 8.6.0)
- GNU make (tested against 4.4.1)
- GNU sed (tested against 4.9)

## Usage

To start the instance for local dev simply run `make start`.
To stop the instance and remove the containers and volumes, run `make stop`.

DO NOT run `docker compose up` directly.