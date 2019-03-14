
*Contents*
* [build.scratch](#build.scratch)

<a id="build.scratch"></a>
## build.scratch

`build.scratch` is a wrapper on top of `xbps-src` to ease packaging for VoidLinux distribution: find which package(s) to build, manage cross-build, generate log file and binary package details in file.

More details:

* ease the use of `xbps-src`: 
  * manage calls of `binary-bootstrap` and `zap`
  * make cross-build easier : handle the `'-a <target-arch>` argument of `xbps-src`

* each package is built in a **fresh build environnement**.  
  This helps on tracking dependencies, since build environnement is not polluted by a previous build,

* list package(s) to build is taken from command-line or retrieved with the changes between `master` and current git branch

* generate timestamped log and info file, that helps to compare old/new builds:
  * `log/<date>.<pkgname>.log`: `xbps-src` build log of the package,
  * `log/<date>.<pkgname>.xbps.info`: various package info in the same file: package metadata, what is provides, its dependencies, list of its files. Some of these outputs are sorted to make comparison accross files easier.


Cons and workarounds:

* increase build time since **each** package build is performed within a new masterdir and builds restart from scratch. The use of a SSD drive with good IOPS greatly helps, usage of `ccache` by `xbps-src` dramatically reduces build time.

* some weird bugs on cross-build that requires native (re)build of packages. Not related to this script, but the way `xbps-src` handles storage of built noarch packages and share in the same location the rindex of various arch(es).


## Usage

Copy `build.scratch` in the same dir than `xbps-src` and make it executable:

```
$ cd void-packages
$ wget https://raw.githubusercontent.com/yopito/yopito-xbps-tools/master/build.scratch
$ chmod +x ./build.scratch
$ ./build.scratch -h
```
```
XBPS bulk builder using a cleaned masterdir for each package build

Usage:

  ./build.scratch [-n] [-h] [xbps-src-flags] [PKG1 PKG2 ...]

  -n              dry run
  -h              this help
  xbps-src-flags  QUOTE THEM if any (like '-a <arch> [-m <dir>] ...')
  PKG1 PKG2 ...   list of package(s) to build. Retrieve from git if not provided.

  Each package is built one by one in an cleaned masterdir,
  masterdir is created if not exist,
  xbps-src options '-C' and '-f' are already in use by this script,
  Packages are built with the right build dependency order,
  If package list is empty, use "git diff master ..." output to retrieve them.
  Build output and package(s) infos are generated in a timestamped log files (./log/ folder)

  Don't perform native and cross build with the same hostdir/repocache/ folder

  Examples:

    * cross-build librsync for armv7hf:
      ./build.scratch '-a armv7hf' librsync

    * cross-build all packages in dev for x86_64-musl: 
      ./build.scratch '-a x86_64-musl'

    * check output on massive builds in the mean time:
      $ watch -n 5 "ls -1tr */*.log | tail -n 3 | xargs du -sk && echo && ls -1tr */*.log | tail -n 1 | xargs tail"
```


## Usage example

Let's rebuild `kdevelop` and `kdevplatform` for both the native arch/libc and for `aarch64-musl` crossbuild target platform:

```
$ ./build.scratch kdevplatform kdevelop \
  && ./build.scratch '-a aarch64-musl' kdevplatform kdevelop
```

This outputs:

```

# input xbps-src arguments: ''
# implied binary boostrap argument: 

# cmd: ./xbps-src  zap > /dev/null
# cmd: ./xbps-src  binary-bootstrap  > /dev/null
ERROR: [reposync] failed to fetch file `https://repo.voidlinux.eu/current/musl/x86_64-repodata': Not Found
ERROR: [reposync] failed to fetch file `https://repo.voidlinux.eu/current/aarch64/x86_64-repodata': Not Found
# package(s) to consider:  kdevplatform kdevelop
# compute package build order and other needed package builds...
# list of package(s) to build sorted in build order:  kdevplatform kdevelop

# [kdevplatform] let's build ...
# [kdevplatform] logfile: log/2017-11-17_092026.kdevplatform.log ...
# cmd: ./xbps-src  -f -C pkg kdevplatform 2>&1 > log/2017-11-17_092026.kdevplatform.log
ERROR: [reposync] failed to fetch file `https://repo.voidlinux.eu/current/musl/x86_64-repodata': Not Found
ERROR: [reposync] failed to fetch file `https://repo.voidlinux.eu/current/musl/nonfree/x86_64-repodata': Not Found
ERROR: [reposync] failed to fetch file `https://repo.voidlinux.eu/current/aarch64/x86_64-repodata': Not Found
# [kdevplatform] subpackages: kdevplatform-devel
#
# [kdevplatform] XBPS infos into logfile: log/2017-11-17_092026.kdevplatform.xbps.info ...
# cmd: xbps-query -R -i --repository=/build/packages/hostdir/binpkgs/kdevelop-5.2.0 -S kdevplatform >> log/2017-11-17_092026.kdevplatform.xbps.info
# cmd: xbps-query -R -i --repository=/build/packages/hostdir/binpkgs/kdevelop-5.2.0 -x kdevplatform >> log/2017-11-17_092026.kdevplatform.xbps.info
# cmd: xbps-query -R -i --repository=/build/packages/hostdir/binpkgs/kdevelop-5.2.0 -f kdevplatform | sort >> log/2017-11-17_092026.kdevplatform.xbps.info
#
# [kdevplatform-devel] XBPS infos into logfile: log/2017-11-17_092026.kdevplatform-devel.xbps.info ...
# cmd: xbps-query -R -i --repository=/build/packages/hostdir/binpkgs/kdevelop-5.2.0 -S kdevplatform-devel >> log/2017-11-17_092026.kdevplatform-devel.xbps.info
# cmd: xbps-query -R -i --repository=/build/packages/hostdir/binpkgs/kdevelop-5.2.0 -x kdevplatform-devel >> log/2017-11-17_092026.kdevplatform-devel.xbps.info
# cmd: xbps-query -R -i --repository=/build/packages/hostdir/binpkgs/kdevelop-5.2.0 -f kdevplatform-devel | sort >> log/2017-11-17_092026.kdevplatform-devel.xbps.info

# [kdevelop] clean buildenv and do binary-bootstrap ...
# cmd: ./xbps-src  zap > /dev/null
# cmd: ./xbps-src  binary-bootstrap  > /dev/null
ERROR: [reposync] failed to fetch file `https://repo.voidlinux.eu/current/musl/x86_64-repodata': Not Found
ERROR: [reposync] failed to fetch file `https://repo.voidlinux.eu/current/aarch64/x86_64-repodata': Not Found
# [kdevelop] let's build ...
# [kdevelop] logfile: log/2017-11-17_092026.kdevelop.log ...
# cmd: ./xbps-src  -f -C pkg kdevelop 2>&1 > log/2017-11-17_092026.kdevelop.log
ERROR: [reposync] failed to fetch file `https://repo.voidlinux.eu/current/musl/x86_64-repodata': Not Found
ERROR: [reposync] failed to fetch file `https://repo.voidlinux.eu/current/musl/nonfree/x86_64-repodata': Not Found
ERROR: [reposync] failed to fetch file `https://repo.voidlinux.eu/current/aarch64/x86_64-repodata': Not Found
# [kdevelop] subpackages: 
#
# [kdevelop] XBPS infos into logfile: log/2017-11-17_092026.kdevelop.xbps.info ...
# cmd: xbps-query -R -i --repository=/build/packages/hostdir/binpkgs/kdevelop-5.2.0 -S kdevelop >> log/2017-11-17_092026.kdevelop.xbps.info
# cmd: xbps-query -R -i --repository=/build/packages/hostdir/binpkgs/kdevelop-5.2.0 -x kdevelop >> log/2017-11-17_092026.kdevelop.xbps.info
# cmd: xbps-query -R -i --repository=/build/packages/hostdir/binpkgs/kdevelop-5.2.0 -f kdevelop | sort >> log/2017-11-17_092026.kdevelop.xbps.info
# That's all folks !
```

The output for the 2nd call (command `./build.scratch '-a aarch64-musl' kdevplatform kdevelop`) :
```

# input xbps-src arguments: '-a aarch64-musl'
# implied binary boostrap argument: 

# cmd: ./xbps-src  zap > /dev/null
# cmd: ./xbps-src  binary-bootstrap  > /dev/null
ERROR: [reposync] failed to fetch file `https://repo.voidlinux.eu/current/musl/x86_64-repodata': Not Found
ERROR: [reposync] failed to fetch file `https://repo.voidlinux.eu/current/aarch64/x86_64-repodata': Not Found
# package(s) to consider:  kdevplatform kdevelop
# compute package build order and other needed package builds...
# list of package(s) to build sorted in build order:  kdevplatform kdevelop

# [kdevplatform] let's build ...
# [kdevplatform] logfile: log/2017-11-17_093309.kdevplatform.aarch64-musl.log ...
# cmd: ./xbps-src -a aarch64-musl -f -C pkg kdevplatform 2>&1 > log/2017-11-17_093309.kdevplatform.aarch64-musl.log
ERROR: [reposync] failed to fetch file `https://repo.voidlinux.eu/current/musl/x86_64-repodata': Not Found
ERROR: [reposync] failed to fetch file `https://repo.voidlinux.eu/current/musl/nonfree/x86_64-repodata': Not Found
ERROR: [reposync] failed to fetch file `https://repo.voidlinux.eu/current/aarch64/x86_64-repodata': Not Found
ERROR: [reposync] failed to fetch file `https://repo.voidlinux.eu/current/musl/aarch64-musl-repodata': Not Found
ERROR: [reposync] failed to fetch file `https://repo.voidlinux.eu/current/musl/nonfree/aarch64-musl-repodata': Not Found
ERROR: [reposync] failed to fetch file `https://repo.voidlinux.eu/current/aarch64-musl-repodata': Not Found
ERROR: [reposync] failed to fetch file `https://repo.voidlinux.eu/current/nonfree/aarch64-musl-repodata': Not Found
=> ERROR: python-gobject-devel-3.26.1_1: cannot be cross compiled, exiting...
# ERROR on cmd.
# exiting requested: stop here
```

(Excerpt of) content of `log/2017-11-17_092026.kdevelop.xbps.info`; various parts are separated with "`# <description>`":

```
# package information:
architecture: x86_64
build-date: 2017-11-17 09:33 CET
filename-sha256: 1a44fe74c1606e0258f4de0e7936ee344519ee3ff82f930b45943f61c58d947e
filename-size: 5175KB
homepage: https://www.kdevelop.org/
installed_size: 13MB
license: GPL-3
maintainer: yopito <pierre.bourgin@free.fr>
pkgver: kdevelop-4.7.3_2
repository: /build/packages/hostdir/binpkgs/kdevelop-5.2.0
shlib-provides:
	libkdev4cpprpp.so
	libkdev4cppduchain.so
	libkdev4cppparser.so
...
	libkdevcompilerprovider.so
shlib-requires:
	libkdevplatformutil.so.8
	libkdevplatforminterfaces.so.8
	libkdeui.so.5
...
	libkdeclarative.so.5
short_desc: Integrated Development Environment for C++/C
# package dependencies:
konsole>=0
kate>=0
kde-runtime>=0
kdevplatform>=1.7.3_1
kdelibs>=4.13.3_1
qt>=4.5.3_1
libstdc++>=4.4.0_1
glibc>=2.25_1
qjson>=0.8.1_1
qt-webkit>=2.3.4_1
kde-workspace>=4.10.4_1
libgcc>=4.4.0_1
okteta>=4.14.2_1
# package files:
/usr/bin/kdevelop
/usr/bin/kdevelop!
/usr/include/kdevelop/make/imakebuilder.h
/usr/lib/kde4/kcm_kdev_cmakebuilder.so
/usr/lib/kde4/kcm_kdev_makebuilder.so
/usr/lib/kde4/kcm_kdev_ninjabuilder.so
/usr/lib/kde4/kcm_kdevcmake_settings.so
/usr/lib/kde4/kcm_kdevcustombuildsystem.so
/usr/lib/kde4/kcm_kdevcustomdefinesandincludes.so
/usr/lib/kde4/kdevastyle.so
/usr/lib/kde4/kdevcmakebuilder.so
/usr/lib/kde4/kdevcmakedocumentation.so
/usr/lib/kde4/kdevcmakemanager.so
...
/usr/share/locale/zh_TW/LC_MESSAGES/plasma_runner_kdevelopsessions.mo
/usr/share/mime/packages/kdevelop.xml
```
