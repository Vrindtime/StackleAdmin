# Step 1: Build Stage
FROM debian:bookworm-slim AS build-env

RUN apt-get update && apt-get install -y curl git unzip xz-utils zip libglu1-mesa && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/flutter/flutter.git -b stable /flutter
ENV PATH="$PATH:/flutter/bin"

WORKDIR /app
COPY . .
RUN flutter build web --release

# Step 2: Secure Runtime Stage
FROM caddy:2-alpine

RUN apk add --no-cache wget

# Explicitly use your host GID/UID 988
RUN addgroup -g 988 stackle && adduser -u 988 -G stackle -H -D stackle
USER 988

# Copy compiled assets to Caddy's public folder
COPY --from=build-env /app/build/web /usr/share/caddy

# Single page application fallback routing to handle Flutter's path routing natively
CMD ["caddy", "file-server", "--listen", ":8080", "--try-files", "{path}", "/index.html"]
