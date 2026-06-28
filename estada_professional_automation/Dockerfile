ARG BUILD_FROM=ghcr.io/home-assistant/base:latest
FROM ${BUILD_FROM}

RUN apk add --no-cache nodejs npm openssh samba

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY tsconfig.json ./
COPY src ./src
COPY project-template ./project-template
COPY run.sh /run.sh

RUN npm run build \
    && npm prune --omit=dev \
    && chmod a+x /run.sh

CMD ["/run.sh"]
