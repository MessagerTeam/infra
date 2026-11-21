# Deploy-набор backend

Этот каталог попадает в релизный артефакт `backend-deploy-vX.Y.Z.zip`.
Infra-репозиторий скачивает артефакт, настраивает `.env` и запускает compose.
**Собирать backend на сервере не нужно и нельзя.**

## 1. Что внутри

```text
backend-deploy-v0.1.0/
├── docker-compose.yml   # готовые образы + Postgres + RabbitMQ
├── .env.example         # шаблон переменных, без секретов
├── init-db.sh           # идемпотентно создаёт БД и роли
├── VERSION              # версия релиза
├── images.txt           # точные образы этого релиза
└── README.md            # этот файл
```

Образы лежат в GHCR:

```text
ghcr.io/messagerteam/backend-gateway:v0.1.0
ghcr.io/messagerteam/backend-user:v0.1.0
ghcr.io/messagerteam/backend-chat:v0.1.0
ghcr.io/messagerteam/backend-realtime:v0.1.0
```

Платформа: `linux/amd64`.

## 2. Требования к серверу

- Linux VPS, `x86_64` (`uname -m` → `x86_64`).
- Docker Engine 24+ и Docker Compose v2.
- Открытые наружу порты: `80`, `443`.
- Свободное место под образы, `pg_data` и `rabbitmq_data`.
- Доступ к `ghcr.io` (для приватного пакета — read-only token).

Postgres и RabbitMQ **не публикуются наружу**. Наружу смотрит только
reverse proxy infra на `127.0.0.1:8080`.

## 3. Первый деплой

### 3.1. Скачать релиз

Вариант через GitHub CLI:

```bash
gh release download v0.1.0 \
  --repo MessagerTeam/backend \
  --pattern 'backend-deploy-*.zip'
unzip backend-deploy-v0.1.0.zip
cd backend-deploy-v0.1.0
```

Или скачать zip вручную со страницы Releases.

### 3.2. Создать `.env`

```bash
cp .env.example .env
```

Сгенерировать пароли и секрет:

```bash
openssl rand -base64 32   # POSTGRES_PASSWORD
openssl rand -base64 32   # USER_DB_PASSWORD
openssl rand -base64 32   # CHAT_DB_PASSWORD
openssl rand -base64 32   # RABBITMQ_DEFAULT_PASS
openssl rand -base64 48   # JWT_SECRET
```

Заполнить `.env`. В release-артефакте `IMAGE_TAG` уже подставлен CI
и совпадает с версией артефакта. Если берёшь `.env.example` из репозитория
вручную, тег нужно выставить самому.
`JWT_SECRET` одинаковый для gateway, user, chat и realtime — иначе
токены не будут приниматься.

### 3.3. Логин в GHCR

Если пакеты публичные, логин не нужен. Если приватные:

```bash
echo "$GHCR_READ_TOKEN" | docker login ghcr.io -u <github-user> --password-stdin
```

Токену достаточно права `read:packages`.

### 3.4. Запуск

```bash
docker compose pull
docker compose up -d
docker compose ps
```

Проверить gateway:

```bash
curl -fsS http://127.0.0.1:8080/health
```

Ожидаемый ответ — `Healthy`.

## 4. Домен и reverse proxy

Схема same-origin:

```text
https://app.example.com/
├── /              → frontend dist (статика)
├── /api/v1/*      → 127.0.0.1:8080
├── /hubs/chat     → 127.0.0.1:8080 (WebSocket)
└── /health        → 127.0.0.1:8080 (по желанию)
```
