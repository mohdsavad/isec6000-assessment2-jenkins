# isec6000-assessment2-jenkins
Jenkins and Docker-in-Docker configuration using Docker Compose for ISEC6000 Assessment 2.

## Jenkins security configuration

- Jenkins is accessible through http://localhost:8080, with its published
  port bound to 127.0.0.1.
- Authentication uses Jenkins' own user database; self-registration is disabled.
- Matrix-based authorization grants Overall/Administer to mohdsavad.
- Anonymous and Authenticated Users have no blanket permissions.
- An unauthenticated request to /api/json returned HTTP 403.
- The inbound-agent TCP listener is disabled.
- The markup formatter uses plain text.
- Jenkins runs as the non-root jenkins user.
- Jenkins connects to the separate DinD daemon using verified TLS.
- Docker client certificates are mounted read-only in Jenkins.
- The DinD daemon has no ports published to the host.
- Standard DinD requires privileged mode. This is a security tradeoff
  of this local assessment setup; Docker access remains powerful.

These Jenkins UI settings are stored in the persistent Jenkins data volume.
They must be reapplied when setting up a fresh, empty Jenkins volume.
Pipeline runtime permissions will be configured and verified separately.
Pipeline validation was verified under Node 16.20.2 as UID 1000.
The application image is configured to run as the non-root node user.
## Prerequisites

- Ubuntu 20.04 or later.
- Docker Engine, Docker Compose plugin, and Git.
- Internet access to GitHub, Docker Hub, Jenkins plugin repositories,
  Docker package repositories, and npm.
- Port 8080 available on localhost.

## Repository files

- Dockerfile: builds the Jenkins image with Docker CLI, Buildx, and
  pipeline, Git, credentials, test-reporting, and authorization plugins.
- compose.yaml: defines Jenkins, DinD, networking, health checks,
  persistent volumes, and TLS connection settings.
- .gitignore: excludes local secrets and runtime data from version control.

## Services and network

The jenkins service uses our custom Jenkins image. Jenkins starts after
the docker service passes its health check and publishes its web interface
only on 127.0.0.1:8080.

The docker service runs Docker-in-Docker. It builds application images
and starts Node build containers using a daemon separate from the host.
Its health check runs docker info.

Both services connect to the dedicated ci bridge network. The network
allows outbound access for source checkout, package downloads, and image
publication.

## Persistent volumes

| Volume | Purpose |
|---|---|
| jenkins-data | Jenkins settings, credentials, plugins, jobs, workspaces, build logs, and archived artifacts |
| docker-certs | Docker daemon TLS certificate material |
| docker-client-certs | Client certificates shared read-only with Jenkins |
| docker-data | Docker daemon runtime and build data |
| containerd-data | Image content held by Docker's containerd image store |

The Jenkins data volume is mounted at /var/jenkins_home in both services.
This makes workspace paths accessible when DinD starts build containers.
Volumes survive normal container recreation; they are not a backup.

## Docker connection settings

- DOCKER_TLS_CERTDIR=/certs enables certificate generation in DinD.
- DOCKER_HOST=tcp://docker:2376 directs Jenkins to the DinD service.
- DOCKER_TLS_VERIFY=1 enables TLS verification.
- DOCKER_CERT_PATH=/certs/client identifies Jenkins' client certificates.

## Build and start

From this repository:

```bash
sudo docker compose config --quiet
sudo docker compose build jenkins
sudo docker compose up -d
sudo docker compose ps
```

Open http://localhost:8080.

For a fresh Jenkins volume, retrieve the initial setup password privately:

```bash
sudo docker compose exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Complete the setup wizard, create an administrator account, and apply the
security settings documented above. Do not publish the setup password.

## Verification

```bash
sudo docker compose exec jenkins whoami
sudo docker compose exec jenkins docker version
sudo docker compose exec jenkins docker buildx version
```

Expected results: the jenkins runtime user, Docker Client and Server
information, and an available Buildx plugin.

## Jenkins job and credentials

- Job: 21678527_Assessment2_pipeline
- Definition: Pipeline script from SCM
- SCM: Git
- Repository: https://github.com/mohdsavad/aws-elastic-beanstalk-express-js-sample.git
- Branch: */main
- Script path: Jenkinsfile
- Checkout credentials: none, because the repository is public
- Poll SCM: H/5 * * * *
- Git tool name: Default; executable: git; automatic installation disabled

Create a Username with password credential with ID dockerhub-credentials.
Use the Docker Hub username and a Read/Write personal access token.
Store the token in Jenkins credentials, never in repository files.

The Jenkinsfile defines a 30-minute timeout, disables concurrent builds,
and retains up to 20 builds for at most 30 days. Available reports are
archived even when a build fails.

## Verified outcomes

- Build #3: initial successful pipeline and image publication.
- Build #4: deliberate High-severity dependency on security-gate-demo;
  the security gate failed and image build/publication were skipped.
- Build #5: successful run after restoring the job to main.
- Build #6: successful automatic build following an SCM change.

The demonstration branch is separate from main and must not be merged.

## Stop and restart

```bash
sudo docker compose stop
sudo docker compose start
```

Stopping preserves the containers and named volumes.
Avoid docker compose down -v unless intentionally deleting persistent data.

## Limitations

This local assessment uses standard privileged DinD. A non-root Jenkins
process does not remove the authority provided by Docker daemon access.
Pipeline orchestration and Docker commands currently execute on the
Jenkins built-in node; Node validation runs in a separate container.
A production design should isolate build execution from the controller.

The npm audit gate scans npm dependencies, not the container operating
system or Node runtime. Node 16 is used to match the assessment requirement.
