FROM python:3.12-slim-bookworm AS build

ARG GITHUB_BRANCH=v0.6.3
ENV APP_HOME=/app

# התקנת תלות בסיסיות
RUN apt-get update && apt-get install -y --no-install-recommends \
    git python3-dev build-essential curl wget supervisor redis-server \
    libglib2.0-0 libnss3 libnspr4 libatk1.0-0 libatk-bridge2.0-0 \
    libcups2 libdrm2 libdbus-1-3 libxcb1 libx11-6 libxcomposite1 \
    libxdamage1 libxext6 libxfixes3 libxrandr2 libgbm1 libpango-1.0-0 \
    libcairo2 libasound2 libatspi2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR $APP_HOME

# התקנת Crawl4AI והמודולים הנדרשים
RUN pip install --no-cache-dir --upgrade pip
RUN pip install git+https://github.com/unclecode/crawl4ai.git@$GITHUB_BRANCH
RUN pip install torch torchvision transformers gunicorn
RUN python -m crawl4ai.model_loader
RUN python -m nltk.downloader punkt stopwords

# התקנת Playwright ודפדפן
RUN pip install playwright && playwright install --with-deps

# הגדרת Supervisor
COPY deploy/docker/supervisord.conf .

EXPOSE 11235

CMD ["supervisord", "-c", "supervisord.conf"]
