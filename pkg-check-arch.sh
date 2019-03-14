#! /bin/sh

# XXX package cache to speedup the checks
# XXX choose local or remote repo
# XXX work with local file(s) (download and uncompress package in temp) instead of download each file one/one ?
#
# 20180611 option to use local repo instead of remote
# 20180611 filter .py files
# 20180610 initial revision

# XXX handle command-line options
if [  "$1" = "-h" ] || [ $# -ne 1 ]
then
  echo
  echo "Description: check arch/noarch package(s)"
  echo "Usage      : $0 [-h] [-R] <package regex>"
  echo
  echo "  -h  this help"
  echo "  -R  use remote XBPS (instead of local one) XXX not yet handled"
  echo
  echo "Example: $0 '^perl-.*-'"
  exit 0
fi

xbps_opt_repo=""   # '' or '-R'
xbps_opt_repo="-R"   # '' or '-R'

echo "Retrieve list of package(s) that match '$1' ..."
if [ "${xbps_opt_repo}" = "-R" ]
then
  echo "from remote repo"
else
  echo "from LOCAL repo"
fi

pkglist=$( xbps-query ${xbps_opt_repo} --regex -s "$1" --property pkgver | cut -d: -f1)
nbpkg=$(printf "${pkglist}\n" | wc -l)

echo "found $nbpkg package(s)"
if [ $nbpkg -eq 0 ]
then
  echo "[ERROR] no package match regex '$1'"
  exit 1
fi

# for each package:
# - retrieve its "current" arch
# - retrieve its file list
# - check its file, if they are "arched" or not

for p in $pkglist
do
    parch=$(xbps-query ${xbps_opt_repo} $p --property architecture)
    pflist=$(xbps-query ${xbps_opt_repo} -f $p)
    echo "check package=$p arch=$parch"

    # shortcut: filter obvious cases via path or extension
    clist=$( printf "${pflist}\n" \
             | sed -e "/^\/usr\/share\/\(man\|doc\)/d" \
                   -e "/^\/usr\/\(lib\|share\)\/perl.*\.\(pod\|pm\|pl\)$/d" \
                   -e "/^\/usr\/lib\/python.*\.py$/d" )
    #echo "(dbg) cleaned pflist (exclude noarch file(s)):" ; echo "$clist"

    if [ "${clist}" = "" ]
    then
      if [ ! "$parch" = "noarch" ]
      then
        echo "[ERROR] package $p should have architecture=noarch"
      fi
      continue  # check next package $p
    fi

    pbinnb=0 # nb of binary file of current package

    for fcheck in ${clist}
    do
       # download file and query its kind
       ftype=$( xbps-query ${xbps_opt_repo} $p --cat $fcheck | file - | sed -e 's,^/dev/stdin: ,,')

       # current file: text (of any kind)
       if echo "$ftype" | grep -qw 'text'
       then
         continue # nothing to do: check next file
       fi

       # current file: ELF binary
       if echo "$ftype" | grep -q '^ELF '
       then
         pbinnb=$(( $pbinnb + 1 ))
         if [ "$parch" = "noarch" ]
         then
           # shortcut: ELF binary within a noarch package
           echo "[ERROR] package $p has archicture 'noarch' but contains at least one ELF binary:"
           echo "        $fcheck"
           break # stop check file(s) of current package
         fi
         continue # nothing to do more: check next file
       fi

       # current file: someting else (unknown)
       echo "(dbg) pkg=$p XXX file=$fcheck type=$ftype"
    done

    # package with an arch but without binary file
    if [ $pbinnb -eq 0 ] && [ ! "$parch" = "noarch" ]
    then
      echo "[ERROR] package $p is '$parch' but don't contain binary files ?"
    fi
done
