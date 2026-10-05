# ---- Build stage ----
FROM dart:stable AS build

WORKDIR /app

# Resolve dependencies first so this layer is cached. The repo's root
# pubspec lists every app and package (Flutter ones included), so the build
# uses a workspace of just what the server needs. The lock file keeps the
# versions the repo resolved.
COPY pubspec.lock ./
COPY apps/soar_score_server/pubspec.yaml ./apps/soar_score_server/
COPY packages/soar_score_api/pubspec.yaml ./packages/soar_score_api/
COPY packages/soar_score_api_handlers/pubspec.yaml ./packages/soar_score_api_handlers/
COPY packages/soar_score_core/pubspec.yaml ./packages/soar_score_core/
COPY packages/soar_score_data/pubspec.yaml ./packages/soar_score_data/

RUN printf '%s\n' \
  'name: soar_score' \
  'publish_to: none' \
  'environment:' \
  '  sdk: ^3.13.3' \
  'workspace:' \
  '  - apps/soar_score_server' \
  '  - packages/soar_score_api' \
  '  - packages/soar_score_api_handlers' \
  '  - packages/soar_score_core' \
  '  - packages/soar_score_data' \
  > pubspec.yaml

RUN dart pub get

# Copy the rest of the source and compile to a native executable
COPY apps/soar_score_server ./apps/soar_score_server
COPY packages/soar_score_api ./packages/soar_score_api
COPY packages/soar_score_api_handlers ./packages/soar_score_api_handlers
COPY packages/soar_score_core ./packages/soar_score_core
COPY packages/soar_score_data ./packages/soar_score_data

RUN dart pub get --offline
RUN mkdir -p bin && dart compile exe apps/soar_score_server/lib/main.dart -o bin/server

# ---- Runtime stage ----
FROM scratch

# Minimal Dart runtime libs and certs, needed for the AOT binary and HTTPS calls
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server

# If you serve files or need other assets, copy them too, e.g.:
# COPY --from=build /app/public /app/public

# Run as an unprivileged user. The image is scratch, so there is no passwd
# file: a numeric id is all Docker needs.
USER 65532:65532

# All configuration comes from environment variables at run time (listed in
# the README and lib/config/server_config.dart); nothing secret is baked into
# the image.
EXPOSE 8080

# scratch has no shell or curl, so the server binary probes its own /health.
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD ["/app/bin/server", "--healthcheck"]

ENTRYPOINT ["/app/bin/server"]
