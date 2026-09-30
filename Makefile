# Makefile

.PHONY: up down build rebuild logs test tests requirements

up:
	docker compose up -d auth main streamlit

down:
	docker compose down

build:
	docker compose build

rebuild:
	docker compose down
	docker compose build
	docker compose up -d

logs:
	docker compose logs -f --tail=50

tests:
	docker compose up -d auth main
	docker compose run --rm tests
	docker compose stop auth main

# Regenerate each service requirements.txt from pyproject.toml (uv.lock versions)
requirements:
	uv lock
	uv export --frozen --no-default-groups --group auth --no-hashes --no-emit-project -o src/api/authentification/requirements.txt
	uv export --frozen --no-default-groups --group assistant --no-hashes --no-emit-project -o src/api/assistant/requirements.txt
	uv export --frozen --no-default-groups --group streamlit --no-hashes --no-emit-project -o src/requirements.txt
