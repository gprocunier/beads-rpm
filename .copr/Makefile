spec ?= $(CURDIR)/beads.spec
outdir ?= $(CURDIR)
topdir ?= $(CURDIR)/.rpmbuild-copr

.PHONY: srpm

srpm:
	mkdir -p "$(topdir)/BUILD" "$(topdir)/BUILDROOT" "$(topdir)/RPMS" "$(topdir)/SOURCES" "$(topdir)/SPECS" "$(topdir)/SRPMS" "$(outdir)"
	./scripts/prepare-sources.sh --spec "$(spec)" --sources-dir "$(topdir)/SOURCES"
	rpmbuild -bs --define "_topdir $(topdir)" "$(spec)"
	cp "$(topdir)"/SRPMS/*.src.rpm "$(outdir)"/
