# roboshop-app

Microservices e-commerce demo used for my DevOps/SRE lab.
Based on [instana/robot-shop](https://github.com/instana/robot-shop) (Apache-2.0), imported at commit `$UPSTREAM_SHA`.
Original README: [UPSTREAM-README.md](UPSTREAM-README.md). LICENSE retained.

My changes: new Dockerfiles (multi-stage, non-root), CI with GitHub Actions, security scanning, Kubernetes manifests live in roboshop-gitops.
