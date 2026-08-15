%global goipath github.com/steveyegge/beads
%global go_version 1.26.2
%global debug_package %{nil}

Name:           beads
Version:        1.2.2
Release:        1%{?dist}
Summary:        Distributed graph issue tracker for AI agents
License:        MIT
URL:            https://github.com/gastownhall/beads
Source0:        %{name}-%{version}-vendor.tar.gz
Source1:        https://go.dev/dl/go%{go_version}.linux-amd64.tar.gz

ExclusiveArch:  x86_64

BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  git-core

%description
Beads provides a persistent, structured memory for coding agents. It
replaces messy markdown plans with a dependency-aware graph, allowing
agents to handle long-horizon tasks without losing context. Powered
by Dolt for version-controlled SQL with cell-level merge, native
branching, and built-in sync via Dolt remotes.

%prep
%setup -q -n %{name}-%{version}

# Unpack the pinned Go toolchain included in the source RPM.
mkdir -p _goroot
tar xzf %{SOURCE1} -C _goroot --strip-components=1

%build
export GOROOT=$(pwd)/_goroot
export PATH="${GOROOT}/bin:${PATH}"
export GOFLAGS="-mod=vendor"
export GOTOOLCHAIN=local
export CGO_ENABLED=1
export GOPATH=$(pwd)/_gopath

go build \
    -tags gms_pure_go \
    -ldflags="-X main.Version=%{version} -X main.Build=%{release}" \
    -o bd ./cmd/bd

%install
install -Dm755 bd %{buildroot}%{_bindir}/bd

# Generate shell completions.
install -d %{buildroot}%{_datadir}/bash-completion/completions
install -d %{buildroot}%{_datadir}/zsh/site-functions
install -d %{buildroot}%{_datadir}/fish/vendor_completions.d
%{buildroot}%{_bindir}/bd completion bash > %{buildroot}%{_datadir}/bash-completion/completions/bd || :
%{buildroot}%{_bindir}/bd completion zsh > %{buildroot}%{_datadir}/zsh/site-functions/_bd || :
%{buildroot}%{_bindir}/bd completion fish > %{buildroot}%{_datadir}/fish/vendor_completions.d/bd.fish || :

%files
%license LICENSE
%doc README.md CHANGELOG.md docs/
%{_bindir}/bd
%{_datadir}/bash-completion/completions/bd
%{_datadir}/zsh/site-functions/_bd
%{_datadir}/fish/vendor_completions.d/bd.fish

%changelog
* Sat Aug 15 2026 Greg Procunier - 1.2.2-1
- Update to upstream v1.2.2

* Wed Aug 12 2026 Greg Procunier - 1.2.1-1
- Update to upstream v1.2.1

* Mon Jul 27 2026 Greg Procunier - 1.1.2-1
- Update to upstream v1.1.2

* Sat Jul 04 2026 Greg Procunier - 1.1.0-1
- Update to upstream v1.1.0

* Fri May 29 2026 Greg Procunier - 1.0.5-1
- Update to upstream v1.0.5

* Sun May 24 2026 Greg Procunier - 1.0.4-1
- Update to upstream v1.0.4

* Tue Apr 28 2026 Greg Procunier - 1.0.3-1
- Initial RPM package for Fedora 43 and EPEL 10
