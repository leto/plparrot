Name:		plparrot
Version:	0.02
Release:	1%{?dist}
Summary:	A PostgreSQL procedural language for the Parrot virtual machine

Group:		Development/Libraries
License:	Artistic 2.0
URL:		http://pl.parrot.org/
Source0:	http://github.com/downloads/leto/%{name}/%{name}-%{version}.tar.gz
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

BuildRequires:	postgresql-server, postgresql-devel
BuildRequires:	parrot-devel, parrot-tools
#Requires:	postgresql-server

%description
PL/Parrot is the Parrot Virtual Machine, embedded into the PostgreSQL relational database. This means that any Parrot language has the opportunity to become a PostgreSQL Procedural Language (PL).


%prep
%setup -q


%build
make


%install
rm -rf $RPM_BUILD_ROOT
make install DESTDIR=$RPM_BUILD_ROOT


%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,root,root,-)
%doc LICENSE README ROADMAP CREDITS html TODO
%{_libdir}/pgsql/plparrot.so
%{_datadir}/pgsql/contrib/plparrot.sql


%changelog
* Mon Sep 13 2010 Gerd Pokorra <gp@zimt.uni-siegen.de> 0.02-1
- initial .spec file
