SPEC := beads.spec
TOPDIR ?= $(CURDIR)/.rpmbuild
SOURCES := $(TOPDIR)/SOURCES
SRPMS := $(TOPDIR)/SRPMS
VERSION := $(shell awk '$$1 == "Version:" { print $$2; exit }' $(SPEC))
RPMBUILD_ARGS := --define "_topdir $(TOPDIR)"

ifneq ($(DIST),)
RPMBUILD_ARGS += --define "dist $(DIST)"
endif

.PHONY: srpm sources update latest local-rpm clean print-version

srpm: sources
	rpmbuild -bs $(RPMBUILD_ARGS) $(SPEC)
	@ls -1 $(SRPMS)/beads-$(VERSION)-*.src.rpm

sources:
	./scripts/prepare-sources.sh --spec $(SPEC) --sources-dir $(SOURCES)

update:
	./scripts/update-version.sh

latest:
	./scripts/latest-version.sh

local-rpm: srpm
	rpmbuild --rebuild --define "_topdir $(TOPDIR)" $(SRPMS)/beads-$(VERSION)-*.src.rpm

print-version:
	@printf '%s\n' "$(VERSION)"

clean:
	rm -rf $(TOPDIR)
