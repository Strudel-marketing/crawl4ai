FROM python:3.12-slim-bookworm AS build

# Metadata
LABEL maintainer="unclecode"
LABEL description="🔥 Crawl4AI ready to rock"

# Build args & envs
ARG APP_HOME=/app
ARG GITHUB_BRANCH=v0.6.3
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    REDIS_HOST=localhost \
    REDIS_PORT=6379

# מערכת
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    wget \
    python3-dev \
    redis-server \
    supervisor \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# התקנת Python libs
RUN pip install --upgrade pip \
 && pip install \
    torch torchvision transformers gunicorn \
 && pip install git+https://github.com/unclecode/crawl4ai.git@$GITHUB_BRANCH

# בדיקה שההתקנה עברה
RUN python --version && pip list
RUN python -c "import crawl4ai; print('✅ crawl4ai installed')"

# טעינת המודל (עם הדפסה לשגיאות)
RUN python -m crawl4ai.model_loader || (echo '🔥 model_loader failed' && exit 1)

# הורדת NLTK
RUN python -m nltk.downloader punkt stopwords

# יצירת תיקייה לאפליקציה
WORKDIR ${APP_HOME}
COPY deploy/docker/* ${APP_HOME}/
COPY deploy/docker/static ${APP_HOME}/static

# הרשאות משתמש
RUN groupadd -r appuser && useradd -r -g appuser appuser \
 && mkdir -p /home/appuser \
 && chown -R appuser:appuser /home/appuser \
 && chown -R appuser:appuser ${APP_HOME}

# Redis תיקיות
RUN mkdir -p /var/lib/redis /var/log/redis && chown -R appuser:appuser /var/lib/redis /var/log/redis

# HEALTHCHECK
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD bash -c '\
    redis-cli ping > /dev/null && \
    curl -f http://localhost:11235/health || exit 1'

# חשיפה וניהול משתמש
EXPOSE 6379
USER appuser
ENV PYTHON_ENV=production

# התחלה
CMD ["supervisord", "-c", "supervisord.conf"]
