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

## CI/CD pipeline (Azure)

The workflow lives in .github/workflows/azure-deploy.yml. It runs on every push to main and performs these steps:

Checks out the code and sets up JDK 21 (Temurin).
Runs ./gradlew build, which fails the pipeline if any test fails.
Logs in to Azure with azure/login@v2 using OIDC. GitHub issues a short-lived token, and Azure trusts it through a federated credential, so no password or client secret is stored.
Logs in to the registry with az acr login and builds the image.
Tags the image with the commit SHA (github.sha), so each deployment is traceable and no image is overwritten.
Pushes the image to codealphaacr1234.azurecr.io.
Deploys the image to the Azure Web App with azure/webapps-deploy@v3.

Azure resources

Resource	Name	Region	Purpose
Resource group	codealpha-devops-rg	East US	Holds all project resources
Container registry	codealphaacr1234 (Basic)	East US	Stores Docker images
App Service plan	plan-codealpha-linux (B1, Linux)	West US 3	Compute for the web app
Web app	codealpha-java-app-2026	West US 3	Runs the container
Entra app	codealpha-github-deploy	Tenant	Identity for the pipeline

Identities and roles



Identity	Role	Scope	Why
codealpha-github-deploy (service principal)	AcrPush	Registry	Pipeline pushes images
codealpha-github-deploy (service principal)	Contributor	Resource group	Pipeline updates the web app
Web app system-assigned managed identity	AcrPull	Registry	Web app pulls images without credentials

The registry's admin user is disabled. No secrets are stored for Azure: the repository secrets hold only the client ID, tenant ID and subscription ID, which are identifiers, not passwords.

Federated credential

The Entra app trusts tokens from this repository's main branch through a federated credential with the subject repo:jreszn/CodeAlpha_JavaGradleApp:ref:refs/heads/main. GitHub's token for the same branch can also carry the ID-based subject repo:jreszn@<owner-id>/CodeAlpha_JavaGradleApp@<repo-id>:ref:refs/heads/main, so the credential that matches that form is also registered. Both must match exactly, or Azure rejects the login with AADSTS700213.

Required GitHub secrets



Secret	Value
AZURE_CLIENT_ID	Application (client) ID of codealpha-github-deploy
AZURE_TENANT_ID	Directory (tenant) ID
AZURE_SUBSCRIPTION_ID	Azure subscription ID

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
![GitHub Secret](docs/screenshots/github-secret.png)
![Federated-Credential](docs/screenshots/federated-credential.png)

### Live endpoint
![Live health check](docs/screenshots/live-health.png)

Live endpoint: https://codealpha-java-app-2026-a5cjfta7dqfga7dr.westus3-01.azurewebsites.net/health

## Versioning

Images are tagged with a version and never overwritten:

1.0 initial web server
1.1 added HEALTHCHECK
1.2 /health returns application/json

Pipeline images are tagged with the Git commit SHA.

## Project structure

.
├── .github/
│   └── workflows/
│       └── azure-deploy.yml   # CI/CD pipeline
├── docs/
│   ├── architecture.mmd       # architecture diagram source
│   ├── architecture.png       # architecture diagram
│   └── screenshots/           # evidence screenshots
├── Dockerfile                 # multi-stage image build
├── .dockerignore              # files excluded from the build context
├── settings.gradle            # project name and modules
├── gradle/
│   ├── libs.versions.toml     # central dependency versions
│   └── wrapper/               # pinned Gradle 9.9.1
└── app/
    ├── build.gradle           # Java toolchain, plugins, dependencies
    └── src/
        ├── main/java/com/codealpha/app/App.java
        └── test/java/com/codealpha/app/AppTest.java

## Author

Adejare Oluwasegun Hassan (jreszn)
