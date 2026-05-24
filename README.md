# Beads RPM Packaging

This repository builds source RPMs for the Beads COPR package:

https://copr.fedorainfracloud.org/coprs/greg-at-redhat/beads/

Upstream source:

https://github.com/gastownhall/beads

## Build An SRPM

```bash
make srpm
```

The SRPM is written under `.rpmbuild/SRPMS/`.

## Update To The Latest Upstream Release

```bash
./scripts/update-version.sh
make srpm
```

To pin a specific upstream tag:

```bash
./scripts/update-version.sh 1.0.4
make srpm
```

The source-prep step clones the upstream tag, vendors Go modules, downloads the
pinned Go toolchain, and includes both artifacts in the SRPM so COPR binary
builds do not need network access.

COPR's `make_srpm` source method calls `.copr/Makefile`. The root `Makefile`
is for local use and delegates to the same source-prep script.

## COPR SCM Setup

Configure the COPR package to build from this repository:

```bash
copr-cli edit-package-scm greg-at-redhat/beads \
  --name beads \
  --clone-url https://github.com/gprocunier/beads-rpm.git \
  --commit main \
  --method make_srpm \
  --spec beads.spec \
  --webhook-rebuild on
```

Trigger a build from the configured package source:

```bash
copr-cli build-package greg-at-redhat/beads --name beads
```

The GitHub workflow checks for newer upstream tags and commits a spec bump when
one appears. With COPR webhook rebuild enabled, that push can trigger a new COPR
build automatically.
