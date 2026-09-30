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
