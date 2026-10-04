# ---- Build stage ----
FROM dart:stable AS build

WORKDIR /app

# Resolve dependencies first so this layer is cached
COPY pubspec.* ./
COPY apps/soar_score_server/pubspec.yaml ./apps/soar_score_server/
COPY packages/soar_score_api/pubspec.yaml ./packages/soar_score_api/
COPY packages/soar_score_api_handlers/pubspec.yaml ./packages/soar_score_api_handlers/
COPY packages/soar_score_core/pubspec.yaml ./packages/soar_score_core/
COPY packages/soar_score_data/pubspec.yaml ./packages/soar_score_data/

RUN sed -i 's|- apps/\*|- apps/soar_score_server|g' pubspec.yaml

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

EXPOSE 8080
ENTRYPOINT ["/app/bin/server"]