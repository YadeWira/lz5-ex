# lz5.spec - RPM spec for the LZ5 1.5.1 maintenance line
#
# Build with:  rpmbuild -ba lz5.spec
#
# Produces three packages, matching the split upstream distros use:
#   lz5        the command line tool        (GPLv2)
#   liblz5     the shared library            (BSD)
#   liblz5-devel  headers + pkg-config       (BSD)

Name:           lz5
Version:        1.5.1
Release:        1%{?dist}
Summary:        Fast and efficient LZ5 compression library

License:        BSD and GPLv2
URL:            https://github.com/lz4/lz5
Source0:        %{name}-%{version}.tar.gz

BuildRequires:  gcc
BuildRequires:  make

%description
LZ5 is a lossless data compressor built around a very fast, small core and a
complementary high-compression variant. This package is the maintenance line
based on the last 1.5.x release.

%package liblz5
Summary:        Fast and efficient LZ5 compression library
License:        BSD
%description liblz5
The shared library implementing the LZ5 block and frame APIs.

%package liblz5-devel
Summary:        Development files for liblz5
Requires:       liblz5 = %{version}-%{release}
License:        BSD
%description liblz5-devel
Headers, static library and the liblz5.pc pkg-config file.

%prep
%setup -q

%build
make lib
make -C programs lz5

%install
rm -rf %{buildroot}
make lib DESTDIR=%{buildroot} PREFIX=/usr install
make -C programs DESTDIR=%{buildroot} PREFIX=/usr install

%files
%license COPYING.programs
%doc README.md NEWS lz5_Block_format.md lz5_Frame_format.md
%{_bindir}/lz5
%{_bindir}/lz5cat
%{_bindir}/unlz5
%{_mandir}/man1/lz5.1*
%{_mandir}/man1/lz5cat.1*
%{_mandir}/man1/unlz5.1*

%files liblz5
%license LICENSE.lib
%{_libdir}/liblz5.so.*

%files liblz5-devel
%license LICENSE.lib
%{_libdir}/liblz5.so
%{_libdir}/liblz5.a
%{_libdir}/pkgconfig/liblz5.pc
%{_includedir}/lz5*.h

%changelog
* Mon Sep 28 2026 LZ5 maintainers <lz5@example.org> - 1.5.1-1
- Maintenance release of the 1.5.x line. See the NEWS file for the full list
  of fixes; the notable ones are the uninitialised high-compression tables and
  the out-of-bounds access on compression levels 1-3.
