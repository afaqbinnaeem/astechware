# Production deploy

## Build and run

```bash
docker compose -f docker-compose.production.yml up -d --build
```

Test the production image on another port before switching traffic:

```bash
# Example: map host 3001 to container 3000
docker compose -f docker-compose.production.yml up -d --build
# Then hit home, a service page, a case study, a blog post, contact form, and chatbot.
```

Confirm the live container is production:

```bash
docker exec -it <web> bin/rails runner 'puts Rails.env'
docker inspect <web> --format '{{.Config.Image}} {{.Config.Cmd}}'
```

`curl -sI https://astechware.com | grep -i miniprofiler` must return nothing.

## Required `.env` variable names (no values)

Required:

- `RAILS_ENV` (must be `production`)
- `SECRET_KEY_BASE`
- `RAILS_SERVE_STATIC_FILES` (set so Rails can serve assets from the container)
- Database: either `DATABASE_URL`, or `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_HOST` / `POSTGRES_DB`

Commonly used in production (set as needed):

- `RAILS_LOG_TO_STDOUT`
- `RAILS_MAX_THREADS`
- `WEB_CONCURRENCY`
- `PORT`
- `ALLOWED_HOSTS`
- `REDIS_URL` (or `REDIS_HOST` / `REDIS_PORT`)
- `GOOGLE_WORKSPACE_SMTP_USER`
- `GOOGLE_WORKSPACE_SMTP_PASSWORD`
- `OPENAI_API_KEY`
- `OPENAI_MODEL` / `OPENAI_MODEL_NEW`
- `CHATBOT_NEW`
- `RECAPTCHA_SITE_KEY`
- `RECAPTCHA_SECRET_KEY`
- `RECAPTCHA_MINIMUM_SCORE`

Do not put secret values in this file or in the image.

## nginx proxy headers (required for `force_ssl`)

Pass these to the Rails/Puma upstream so SSL redirects do not loop:

```nginx
proxy_set_header Host $host;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
```

Redirect both HTTP and www to the canonical host:

```nginx
# http:// and https://www.astechware.com → https://astechware.com$request_uri
return 301 https://astechware.com$request_uri;
```

Verify:

```bash
curl -sI http://astechware.com
curl -sI https://www.astechware.com
# both should 301 to https://astechware.com/...
```
