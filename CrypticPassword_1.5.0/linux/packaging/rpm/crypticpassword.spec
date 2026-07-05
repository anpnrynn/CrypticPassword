Name:           crypticpassword
Version:        1.5.0
Release:        1%{?dist}
Summary:        CrypticPassword native GTK+ password generation matrix tool
License:        Proprietary
URL:            https://example.invalid/cryptic-password
Source0:        %{name}-%{version}.tar.gz
BuildRequires:  gcc, make, pkgconfig(gtk+-3.0)
Requires:       gtk3

%description
A native GTK+ implementation of the CrypticPassword 3-matrix password generator.

%prep
%autosetup

%build
make -C linux

%install
rm -rf %{buildroot}
make -C linux DESTDIR=%{buildroot} install

%files
/usr/bin/crypticpassword-gtk
/usr/share/applications/org.cryptic.password.desktop

%changelog
* Thu Jul 02 2026 CrypticPassword Builder <unknown@example.invalid> - 1.5.0-1
- Initial RPM package.
