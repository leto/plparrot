Name:		postgresql-plparrot
Version:	0.04
Release:	1%{?dist}
Summary:	A PostgreSQL procedural language for the Parrot virtual machine

Group:		Applications/Databases
License:	Artistic 2.0
URL:		http://pl.parrot.org/
Source0:	http://github.com/downloads/leto/plparrot/plparrot-%{version}.tar.gz
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

BuildRequires:	postgresql-devel
BuildRequires:	parrot-devel
Requires:	postgresql-contrib

%description
PL/Parrot is the Parrot Virtual Machine, embedded into the PostgreSQL
relational database. This means that any Parrot language has the opportunity
to become a PostgreSQL Procedural Language (PL).


%prep
%setup -q -n plparrot-%{version}


%build
# do not build parallel
make CFLAGS="$RPM_OPT_FLAGS"


%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT


%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,root,root,-)
%doc LICENSE README ROADMAP CREDITS html
%{_libdir}/pgsql/plparrot.so
%{_datadir}/pgsql/contrib/plparrot.sql


%changelog
* Fri Oct 22 2010 Gerd Pokorra <gp@zimt.uni-siegen.de> 0.04-1
- update to new upstream, which includes more licensing information

* Fri Oct 22 2010 Gerd Pokorra <gp@zimt.uni-siegen.de> 0.03-4
- changed requires from postgresql to postgresql-contrib

* Tue Oct 19 2010 Gerd Pokorra <gp@zimt.uni-siegen.de> 0.03-3
- correct typo at CFLAGS

* Sun Oct 03 2010 Gerd Pokorra <gp@zimt.uni-siegen.de> 0.03-2
- shorten BuildRequires
- changed group

* Mon Sep 13 2010 Gerd Pokorra <gp@zimt.uni-siegen.de> 0.03-1
- initial .spec file
