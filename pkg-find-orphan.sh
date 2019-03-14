#! /bin/bash
#
# XXX repo: always retrieve datas, in a temporary location (not on system)
# XXX repo: store repo data in temp location or use 'xbps-query -M' ?
# XXX repo: list of all repo: hardcoded ?
# XXX repo: check all (known) ones
# XXX repo: display date, metadata about it
# XXX repo: option to choose repo(s) to work on
# XXX repo: loop on repo, loop on target arch
# XXX git: path to git repo as option

# list of URLs repo (that contains -repodata file):
#   https://repo.voidlinux.eu/current/
#   https://repo.voidlinux.eu/current/nonfree/
#   https://repo.voidlinux.eu/current/multilib/
#   https://repo.voidlinux.eu/current/multilib/nonfree/
#   https://repo.voidlinux.eu/current/aarch64/
#   https://repo.voidlinux.eu/current/aarch64/nonfree/
#   https://repo.voidlinux.eu/current/musl/
#   https://repo.voidlinux.eu/current/musl/nonfree/
#   https://repo.voidlinux.eu/current/musl/debug/
#   https://repo.voidlinux.eu/current/debug/
#
#
# list of repo "databases":
#   https://repo.voidlinux.eu/current/armv6l-repodata
#   https://repo.voidlinux.eu/current/armv7l-repodata
#   https://repo.voidlinux.eu/current/i686-repodata
#   https://repo.voidlinux.eu/current/x86_64-repodata
#
#   https://repo.voidlinux.eu/current/nonfree/armv6l-repodata
#   https://repo.voidlinux.eu/current/nonfree/armv7l-repodata
#   https://repo.voidlinux.eu/current/nonfree/i686-repodata
#   https://repo.voidlinux.eu/current/nonfree/x86_64-repodata
#
#   https://repo.voidlinux.eu/current/multilib/x86_64-repodata
#
#   https://repo.voidlinux.eu/current/multilib/nonfree/x86_64-repodata
#   
#   https://repo.voidlinux.eu/current/aarch64/aarch64-musl-repodata
#   https://repo.voidlinux.eu/current/aarch64/aarch64-repodata
#
#   https://repo.voidlinux.eu/current/aarch64/nonfree/aarch64-musl-repodata
#   https://repo.voidlinux.eu/current/aarch64/nonfree/aarch64-repodata
#   https://repo.voidlinux.eu/current/aarch64/nonfree/x86_64-repodata
#
#   https://repo.voidlinux.eu/current/musl/armv6l-musl-repodata
#   https://repo.voidlinux.eu/current/musl/armv6l-repodata
#   https://repo.voidlinux.eu/current/musl/armv7l-musl-repodata
#   https://repo.voidlinux.eu/current/musl/armv7l-repodata
#   https://repo.voidlinux.eu/current/musl/i686-musl-repodata
#   https://repo.voidlinux.eu/current/musl/i686-repodata
#   https://repo.voidlinux.eu/current/musl/x86_64-musl-repodata
#   https://repo.voidlinux.eu/current/musl/x86_64-repodata
#
#   https://repo.voidlinux.eu/current/musl/nonfree/armv6l-musl-repodata
#   https://repo.voidlinux.eu/current/musl/nonfree/armv6l-repodata
#   https://repo.voidlinux.eu/current/musl/nonfree/armv7l-musl-repodata
#   https://repo.voidlinux.eu/current/musl/nonfree/armv7l-repodata
#   https://repo.voidlinux.eu/current/musl/nonfree/i686-musl-repodata
#   https://repo.voidlinux.eu/current/musl/nonfree/i686-repodata
#   https://repo.voidlinux.eu/current/musl/nonfree/x86_64-musl-repodata
#   https://repo.voidlinux.eu/current/musl/nonfree/x86_64-repodata
#
#   XXX https://repo.voidlinux.eu/current/musl/debug/
#   XXX https://repo.voidlinux.eu/current/debug/
#
# tests:
#
# OK $ xbps-query -R -M -p pkgver,build-date,architecture,repository librsync 
#      librsync-2.0.2_1
#      2018-03-13 06:01 CET
#      x86_64
#      https://repo.voidlinux.eu/current
#
# OK $ XBPS_ARCH=armv7l xbps-query -R -M -p pkgver,build-date,architecture,repository librsync
#    librsync-2.0.2_1
#    2018-03-13 06:10 CET
#    armv7l
#    https://repo.voidlinux.eu/current
#
# KO $ XBPS_ARCH=aarch64 xbps-query -R -M -p pkgver,build-date,architecture,repository librsync
#    (rien)
#    => "normal": on tape sur /current alors que le depot est dans /aarch64
#    => cette information provient de la conf par defaut ?
#
# OK $ echo "repository=https://repo.voidlinux.eu/current/aarch64" > /tmp/toto/toto.conf
#    $ XBPS_ARCH=aarch64 xbps-query -C /tmp/toto -R -M -p pkgver,build-date,architecture,repository librsync
#    librsync-2.0.2_1
#    2018-03-13 02:11 CET
#    aarch64
#    https://repo.voidlinux.eu/current/aarch64

# 20180614 initial revision
 
# XXX handle command-line options
if [ "$1" = "-h" ]
then
  echo
  echo "Description: list package of repo that do not have template anymore"
  echo "Usage      : $0 [-h]"
  echo
  echo "  -h this help"
  echo
  echo "Example: $0 XXX"
  exit 0
fi

echo "start: $(date)"

################################################################################
## git data: use filesystem as srcpkgs/<packagename>
################################################################################

echo
echo "- Retrieve list of git defined packages (srcpkgs/<pkgname>) ..."

echo "git last commit:"
git log  --date=short --pretty='%cd %h: %s' HEAD^1..HEAD
[ $? -ne 0 ] && echo "[ERROR] an error occured" && exit 1


gitpkg=$( ls srcpkgs )
[ $? -ne 0 ] && echo "[ERROR] an error occured" && exit 1

gitpkgnb=$( printf "${gitpkg}\n" | wc -l)
echo "found ${gitpkgnb} package definition in git"


echo
echo "- Retrieve list of package in repo index ..."

repopkg=$( xbps-query -R -s '' -p pkgver | sed 's/\(.*\)-.*: .*/\1/')
[ $? -ne 0 ] && echo "[ERROR] an error occured" && exit 1

repopkgnb=$(printf "${repopkg}\n" | wc -l)
echo "found ${repopkgnb} package(s) in repository"

echo
echo "- Compute list of packages present in repo but without a git template ..."
orphanpkg=$(diff -bB -U 0 <(printf "${repopkg}\n") <(printf "${gitpkg}\n") | grep "^-[^-]" | sed -e 's/^-//')
echo "found $( printf "${orphanpkg}\n" | wc -l ) orphan packages:"
for p in $orphanpkg
do
  echo "[ERROR] package $p is orphaned: no entry in git repo"
done
