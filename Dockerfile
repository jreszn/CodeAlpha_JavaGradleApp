# ---- Stage 1: build the app with Gradle and JDK 21 ----
FROM gradle:9.9.1-jdk21 AS build
WORKDIR /home/gradle/project
COPY --chown=gradle:gradle . .
RUN gradle clean installDist --no-daemon

# ---- Stage 2: slim runtime image with only the packaged app ----
FROM eclipse-temurin:21-jre-alpine-3.23
WORKDIR /opt/app
RUN addgroup -S app && adduser -S app -G app
COPY --from=build /home/gradle/project/app/build/install/app/ ./
USER app
EXPOSE 8080
ENV PORT=8080
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1
ENTRYPOINT ["./bin/app"]
