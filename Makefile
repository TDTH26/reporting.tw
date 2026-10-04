COMPOSE := docker compose -f deploy/docker-compose.yml
BACKEND := cd backend &&
FLUTTER ?= flutter

.PHONY: help up down logs migrate seed test lint openapi api-check conformance sim loadtest \
        app-get app-test app-analyze build-informant-web build-agency-web build-android

help:            ## Show targets
	@grep -E '^[a-z-]+:.*##' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  %-18s %s\n", $$1, $$2}'

up:              ## Start the dev stack (MySQL, api, worker, tusd, nginx)
	$(COMPOSE) up -d --build db db-grants api worker tusd web

down:            ## Stop the dev stack
	$(COMPOSE) down

logs:            ## Follow api + worker logs
	$(COMPOSE) logs -f api worker

migrate:         ## Apply database migrations (local venv against the compose db)
	$(BACKEND) uv run alembic upgrade head

seed:            ## Seed demo agencies, desks, zones, templates, dev feed key and dev staff accounts
	$(COMPOSE) exec api python -m uavr.seed --dev-feed-key dev-feed-key
	$(COMPOSE) exec -e UAVR_NEW_PASSWORD=dev-password-123 api sh -c '\
	  python -m uavr.users create admin --roles admin,national --agency NPA --clearance 2; \
	  python -m uavr.users create tpe.dispatcher --roles dispatcher --desk TCPD-DISPATCH --clearance 1; \
	  python -m uavr.users create apb.dispatcher --roles dispatcher --desk APB-OPS --clearance 1; \
	  python -m uavr.users create analyst --roles analyst,national --agency NPA --clearance 1; \
	  python -m uavr.users create tpe.field --roles field_officer --desk TCPD-DISPATCH --clearance 1; true'

test:            ## Backend test suite (needs the compose db)
	$(BACKEND) uv run pytest -q

lint:            ## Ruff
	$(BACKEND) uv run ruff check uavr tests && uv run ruff format --check uavr tests

openapi:         ## Export the OpenAPI spec to backend/openapi.json
	$(BACKEND) uv run python -m uavr.openapi > openapi.json

api-check: openapi   ## Check the Dart client against the OpenAPI spec (see docs/adr/0004)
	cd app && $(FLUTTER) pub get >/dev/null && dart run tool/check_api.dart ../backend/openapi.json

conformance:     ## Run the feed conformance kit on the bundled examples
	$(BACKEND) uv run python -m uavr.feeds.conformance --all-examples

sim:             ## Run all simulators against the dev stack (sensors, ADS-B, CAA data, informant surge)
	$(BACKEND) uv run python ../tools/simulators/run.py --api http://localhost:8480/api --feed-key dev-feed-key

loadtest:        ## Locust surge + spam-flood scenarios (UI on :8089)
	$(BACKEND) uv run locust -f ../tools/loadtest/locustfile.py --host http://localhost:8480/api

app-get:         ## Resolve Flutter workspace dependencies
	cd app && $(FLUTTER) pub get

app-test:        ## Flutter tests for all packages
	cd app && dart run melos run test

app-analyze:     ## Static analysis for all packages
	cd app && dart run melos run analyze

build-informant-web:  ## Build the informant web app into app/apps/uavr/build/informant-web
	cd app/apps/uavr && $(FLUTTER) build web -t lib/main_informant.dart --base-href /app/ -o build/informant-web

build-agency-web:   ## Build the agency console into app/apps/uavr/build/agency-web
	cd app/apps/uavr && $(FLUTTER) build web -t lib/main_agency.dart --base-href /console/ -o build/agency-web

build-android:   ## Build informant and field APKs
	cd app/apps/uavr && $(FLUTTER) build apk --flavor informant -t lib/main_informant.dart && \
	  $(FLUTTER) build apk --flavor field -t lib/main_field.dart

