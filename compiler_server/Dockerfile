FROM node:22-bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        g++ \
        openjdk-17-jdk-headless \
        tesseract-ocr \
        tesseract-ocr-eng \
    && tesseract --list-langs | grep -qx eng \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY package.json ./package.json
RUN npm install --omit=dev --no-audit --no-fund
COPY server.mjs ./server.mjs
RUN mkdir -p /workspace && chown node:node /workspace

ENV PORT=8787
EXPOSE 8787
USER node
CMD ["node", "server.mjs"]
