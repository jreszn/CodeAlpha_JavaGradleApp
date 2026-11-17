# CodeAlpha_JavaGradleApp

A Java 21 web service built with Gradle 9.9.1, packaged into a multi-stage Docker image, monitored with a health endpoint, and deployed to Azure through a GitHub Actions CI/CD pipeline. Built for the CodeAlpha DevOps internship (Task 1: CI/CD with Azure, Task 3: Java with Gradle, Task 4: Web server with Docker).

## Architecture

![Architecture of the CodeAlpha DevOps pipeline](docs/architecture.png)

A push to `main` triggers GitHub Actions. The workflow logs in to Azure with OpenID Connect (no stored client secret), builds and tests the Gradle project, pushes the Docker image to Azure Container Registry, and deploys it to the Azure Web App. The web app pulls the image with its managed identity.

## Features

- Java 21 application using the JDK's built-in HTTP server (no framework)
- Gradle Wrapper pinned to 9.9.1, so every build uses the same tool version
- JUnit 5 unit tests run on every build
- Multi-stage Dockerfile: build stage with Gradle, small runtime stage with a JRE
- Runs as a non-root user inside the container
- Docker HEALTHCHECK that polls `/health` every 30 seconds
- GitHub Actions pipeline: build, test, push to ACR, deploy to Azure Web App
- Passwordless deployment: OIDC federated credential for GitHub, managed identity for the web app's image pull

## Endpoints

| Method | Path      | Response           | Content-Type                      |
|--------|-----------|--------------------|-----------------------------------|
| GET    | `/`       | `Hello World!`     | `text/plain; charset=utf-8`       |
| GET    | `/health` | `{"status":"UP"}`  | `application/json; charset=utf-8` |

Live deployment: `https://codealpha-java-app-2026-a5cjfta7dqfga7dr.westus3-01.azurewebsites.net/`

## Prerequisites

- Docker Engine (or Docker Desktop)
- A GitHub account for the Actions pipeline
- An Azure subscription (for the cloud deployment only)
- JDK 21 only if you want to run without Docker
- No Gradle install needed: the wrapper downloads the right version

## Build and test

```bash
./gradlew build

This compiles the code, runs the JUnit tests, and produces the packaged app under app/build/install/app/.

Run locally (without Docker)

./gradlew run

The server listens on port 8080. Override it with the PORT environment variable:

PORT=9090 ./gradlew run

Build and run with Docker

docker build -t codealpha-java-app:1.2 .
docker run -d --name codealpha-web -p 8080:8080 codealpha-java-app:1.2

Check the health status and the endpoints:

docker inspect --format='{{.State.Health.Status}}' codealpha-web
curl -i http://localhost:8080/
curl -i http://localhost:8080/health

Stop and remove the container:

docker stop codealpha-web && docker rm codealpha-web

## Screenshots

### Build and test
![Gradle build](docs/screenshots/gradle-run.png)

### Docker image and health check
![Docker build](docs/screenshots/docker.png)
![Container health](docs/screenshots/dockerps-inspect-stats.png)

### CI/CD pipeline
![GitHub Actions run](docs/screenshots/github-actions.png)
![Container registry](docs/screenshots/acr-repository.png)
![Web app on Azure](docs/screenshots/webapp-overview.png)
![GitHub Secret](docs/screenshots/github-secret)
![Federated-Credential](docs/screenshots/federated-credential)

### Live endpoint
![Live health check](docs/screenshots/live-health.png)

Live endpoint: https://codealpha-java-app-2026-a5cjfta7dqfga7dr.westus3-01.azurewebsites.net/health

TagChange
1.0Initial HTTP server
1.1Added HEALTHCHECK
1.2/health returns application/json

Pipeline images are tagged with the Git commit SHA, so each deployment traces back to one commit.

Troubleshooting notes



SymptomCauseFix
Address already in use on port 8080A previous run is still holding the portStop the process with pkill -f com.codealpha.app.App, or stop the container
AADSTS530035 on az loginTenant Security Defaults block the sign-inKeep Security Defaults on and use the portal
SubscriptionIsOverQuotaForSkuFree trial has zero B1 allowance in the regionCreate the plan in a region with allowance
AADSTS700213 on the pipelineThe federated credential subject doesn't match the tokenAdd a credential whose subject equals the one in the error
Pipeline login authority errorAn empty or malformed tenant or client ID secretRe-enter the values from the app's Overview page

Project structure
.
├── .github/workflows/azure-deploy.yml   # CI/CD pipeline
├── Dockerfile                           # multi-stage image build
├── .dockerignore                        # files excluded from the build context
├── docs/
│   ├── architecture.mmd                 # architecture source
│   ├── architecture.png                 # architecture diagram
│   └── screenshots/                     # captured evidence
├── settings.gradle                      # project name and modules
├── gradle/
│   ├── libs.versions.toml               # central dependency versions
│   └── wrapper/                         # pinned Gradle 9.9.1
└── app/
    ├── build.gradle                     # Java toolchain, plugins, dependencies
    └── src/
        ├── main/java/com/codealpha/app/App.java
        └── test/java/com/codealpha/app/AppTest.java

Author
Adejare Oluwasegun Hassan

