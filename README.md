## Usage

Copy `rebuild.scratch` in the same dir than `xbps-src` and make it executable:

```
$ chmod +x ./rebuild.scratch
$ ./rebuild.scratch -h
```
```
XBPS bulk builder using a cleaned masterdir for each package build

Usage:

  ./rebuild.scratch [-n] [-h] [xbps-src-flags] [PKG1 PKG2 ...]

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
      ./rebuild.scratch '-a armv7hf' librsync

    * cross-build all packages in dev for x86_64-musl: 
      ./rebuild.scratch '-a x86_64-musl'

    * check output on massive builds in the mean time:
      $ watch -n 5 "ls -1tr */*.log | tail -n 3 | xargs du -sk && echo && ls -1tr */*.log | tail -n 1 | xargs tail"
```


## Rationale

`rebuild.scratch` is my personal wrapper on top of `xbps-src` to ease my packaging effort for VoidLinux distribution.

* each package to consider is built **one by one**, each in a new build environnement. This helps to track the real dependencies for each package (instead of benefit of packages unmentionned but aldready present because of a previous build)

* without argument: build each package that have changed between the `master` and your current git branch

* ease the use of `xbps-src`: 
  * manage calls of `binary-bootstrap` and `zap`
  * make cross-build easier : handle the `'-a <target-arch>` argument of `xbps-src`

* generate timestamped log and info file, that make easier to compare old/new builds:
  * log of xbps-src build
  * an xbps.info file for each built package containing various packages informations: package metada, what it's providing, its dependencies, the list of its files.  
      Some of these outputs are sorted to make the comparison easier


## Cons and workarounds

Since **each** package build is performed within a cleaned env (new masterdir), it takes a little bit longer: the build environnement has to be recreated first.

Workarounds:
* use a fast hard drive with more I/O like SSD drive
* enable use of `ccache` by `xbps-src`

The shell code is somewhat dirty ?

## Usage example

Let's rebuild `kdevelop` and `kdevplatform` for both the native arch/libc and for `aarch64-musl` crossbuild target platform; excerpt of the corresponding generated files is present in `samples/` dir of this repo.

```
$ ./rebuild.scratch kdevplatform kdevelop \
  && ./rebuild.scratch '-a aarch64-musl' kdevplatform kdevelop
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

The output for the 2nd call (command `./rebuild.scratch '-a aarch64-musl' kdevplatform kdevelop`) :
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
