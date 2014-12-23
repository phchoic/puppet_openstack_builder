# Fedora 17 ships with ruby 1.9, RHEL 7 with ruby 2.0, which use vendorlibdir instead
# of sitelibdir
%if 0%{?fedora} >= 17 || 0%{?rhel} >= 7 || 0%{?amzn} >= 1
%global hiera_libdir   %(ruby -rrbconfig -e 'puts RbConfig::CONFIG["vendorlibdir"]')
%else
%global hiera_libdir   %(ruby -rrbconfig -e 'puts RbConfig::CONFIG["sitelibdir"]')
%endif

%if 0%{?rhel} == 5
%global _sharedstatedir %{_prefix}/lib
%endif

%define ruby            %{_bindir}/ruby

%global realversion 1.3.5
%global rpmversion 1.3.5

Name:           hiera
Version:        1.3.5
Release:        1%{?dist}
Summary:        A simple pluggable Hierarchical Database
Vendor:         %{?_host_vendor}
Group:          System Environment/Base
License:        ASL 2.0
URL:            http://projects.puppetlabs.com/projects/%{name}/
Source0:        http://192.168.242.5/%{name}-%{realversion}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
BuildArch:      noarch
BuildRequires:  ruby >= 1.8.5
Requires:       ruby >= 1.8.5
Requires:       rubygem-json

%description
A simple pluggable Hierarchical Database.

%prep
%setup -q  -n %{name}-%{realversion}


%build


%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/%{_sharedstatedir}/hiera
%{ruby} install.rb \
  --destdir=$RPM_BUILD_ROOT \
  --sitelibdir=%{hiera_libdir} \
  --bindir=%{_bindir} \
  --configdir=%{_sysconfdir} \
  --configs

%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,root,root,-)
%{_bindir}/hiera
%{hiera_libdir}/hiera.rb
%{hiera_libdir}/hiera
%config(noreplace) %{_sysconfdir}/hiera.yaml
%{_sharedstatedir}/hiera
%doc COPYING README.md


%changelog

* Mon May 14 2012 Matthaus Litteken <matthaus@puppetlabs.com> - 1.0.0-0.1rc2
- 1.0.0rc2 release

* Mon May 14 2012 Matthaus Litteken <matthaus@puppetlabs.com> - 1.0.0-0.1rc1
- 1.0.0rc1 release

* Thu May 03 2012 Matthaus Litteken <matthaus@puppetlabs.com> - 0.3.0.28-1
- Initial Hiera Packaging. Upstream version 0.3.0.28

