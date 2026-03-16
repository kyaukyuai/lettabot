ARG LINEAR_CLI_VERSION=2.2.0

FROM node:22-slim AS build
WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

FROM node:22-slim
ARG LINEAR_CLI_VERSION
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates git xz-utils \
  && update-ca-certificates \
  && npm install -g "@kyaukyuai/linear-cli@${LINEAR_CLI_VERSION}" \
  && npm cache clean --force \
  && rm -rf /var/lib/apt/lists/*
WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY --from=build /app/dist ./dist
COPY skills ./skills
COPY .skills ./.skills

ENV NODE_ENV=production
EXPOSE 8080

CMD ["node", "dist/main.js"]
