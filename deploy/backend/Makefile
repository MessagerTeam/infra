SHELL := /bin/sh

COMPOSE ?= docker compose
OPENSSL ?= openssl

IMAGE_TAG ?= $(shell sed -n 's/^IMAGE_TAG=//p' .env 2>/dev/null)
GATEWAY_PORT ?= $(shell sed -n 's/^GATEWAY_PORT=//p' .env 2>/dev/null)
GATEWAY_PORT := $(if $(GATEWAY_PORT),$(GATEWAY_PORT),8080)

.DEFAULT_GOAL := help

.PHONY: help env deploy pull up down restart ps logs health config version backup

help:
	@echo "Доступные команды:"
	@echo "  make env       — создать .env со случайными паролями"
	@echo "  make deploy    — pull + запуск сервисов"
	@echo "  make pull      — скачать образы из GHCR"
	@echo "  make up        — запустить сервисы без pull"
	@echo "  make down      — остановить сервисы"
	@echo "  make restart   — перезапустить сервисы"
	@echo "  make ps        — показать состояние контейнеров"
	@echo "  make logs      — смотреть логи (SERVICE=gateway)"
	@echo "  make health    — проверить gateway /health"
	@echo "  make config    — проверить compose"
	@echo "  make version   — показать VERSION и IMAGE_TAG"
	@echo "  make backup    — сделать дамп PostgreSQL"
	@echo ""
	@echo "Для make env нужен openssl."

env:
	@if [ -f .env ]; then \
		echo "Файл .env уже существует, не перезаписываю."; \
	else \
		$(MAKE) .env; \
	fi

.env:
	@if [ -f .env ]; then \
		echo "Файл .env уже существует."; \
	else \
		cp .env.example .env; \
		sed -i.bak \
			-e "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$$($(OPENSSL) rand -hex 32)|" \
			-e "s|^USER_DB_PASSWORD=.*|USER_DB_PASSWORD=$$($(OPENSSL) rand -hex 32)|" \
			-e "s|^CHAT_DB_PASSWORD=.*|CHAT_DB_PASSWORD=$$($(OPENSSL) rand -hex 32)|" \
			-e "s|^RABBITMQ_DEFAULT_PASS=.*|RABBITMQ_DEFAULT_PASS=$$($(OPENSSL) rand -hex 32)|" \
			-e "s|^JWT_SECRET=.*|JWT_SECRET=$$($(OPENSSL) rand -hex 32)|" \
			.env; \
		if [ -f VERSION ]; then \
			sed -i.bak "s|^IMAGE_TAG=.*|IMAGE_TAG=$$(cat VERSION)|" .env; \
		fi; \
		rm -f .env.bak; \
		echo "Создан .env со случайными паролями."; \
	fi

deploy: .env pull up
	@echo "Сервисы запущены. Проверка: make health"

pull: .env
	$(COMPOSE) pull

up: .env
	$(COMPOSE) up -d --remove-orphans

down: .env
	$(COMPOSE) down

restart: .env
	$(COMPOSE) restart

ps: .env
	$(COMPOSE) ps -a

logs: .env
	@if [ -n "$(SERVICE)" ]; then \
		$(COMPOSE) logs -f --tail=100 "$(SERVICE)"; \
	else \
		$(COMPOSE) logs -f --tail=100; \
	fi

health: .env
	@curl -fsS "http://127.0.0.1:$(GATEWAY_PORT)/health"
	@echo

config: .env
	$(COMPOSE) config --quiet

version: .env
	@echo "VERSION:   $$(cat VERSION 2>/dev/null || echo unknown)"
	@echo "IMAGE_TAG: $(IMAGE_TAG)"

backup: .env
	@$(COMPOSE) exec -T postgres sh -c 'pg_dumpall -U "$$POSTGRES_USER"' > "backup-$$(date +%F-%H%M).sql"
	@echo "Дамп сохранён в backup-*.sql"
