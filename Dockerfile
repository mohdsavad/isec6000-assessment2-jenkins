# Jenkins version and Java runtime used for this assessment.
FROM jenkins/jenkins:2.580.1-jdk21

# Root is needed only during image creation to install packages.
USER root

# Install Docker CLI from Docker's official Debian repository.
# The Jenkins image uses Debian, even though our host uses Ubuntu.
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg \
       -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
       > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli docker-buildx-plugin \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Run Jenkins as the image's non-root Jenkins user.
USER jenkins

# Install support for pipelines, Git, Docker agents, and test reports.
RUN jenkins-plugin-cli --plugins \
    workflow-aggregator \
    git \
    docker-workflow \
    credentials-binding \
    junit \
    matrix-auth
