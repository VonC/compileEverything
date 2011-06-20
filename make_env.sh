#!/bin/bash
myhome=`pwd`
echo $myhome
DIR="$( basename `pwd` )"
echo $DIR
#d=`date +"%Y%m%d"`
#echo $d
mkdir -p logs
mkdir -p src/_pkgs

set -o errexit
set -o nounset

function Ymd() { date +"%Y%m%d"; }
function _ldate() { date +"%Y/%M/%d-%H:%M:%S"; }
function _fdate() { date +"%Y%m%d.%H%M%S"; }
function _echod() { echo "$(_ldate) $1$2" ; }
function _echolog() { _echod "$1" "$2" | tee -a "$3"; if [[ $4 != "" ]]; then echo $4 >> "$3"; fi; }
function echolog() { _echolog "~ " "$1" log ""; }
function _echologcmd() { _echolog "~~~ $1" "$2" "logs/$3" "~~~~~~~~~~~~~~~~~~~"; }
function _log() { f=$2; rm -f logs/l; ln -s $f logs/l; _echologcmd "" "$1" $f ; $( $1 >> logs/$f 2>&1 ) ; }
function log() { f=$(_fdate).$2 ; _log "$1" $f ; }
function loge() { f=$(_fdate).$2 ; echolog "(see logs/$f or simply tail -f logs/l)"; _log "$1" $f ; _echologcmd "DONE ~~~ " "$1" $f; true ; }
function mrf() { ls -t1 $1 | head -n1 ; }

trap "echo -e "\\\\e\\\[00\\\;31m!!!!\nFAIL\n!!!!\\\\e\\\[00m" | tee -a log; tail -3 log ; tail -5 logs/l" EXIT ;

if [[ ! -e deps ]]; then
  echolog "#### DEPS ####"
  echolog "download deps from SunFreeware"
  loge "wget http://sunfreeware.com/programlistsparc10.html -O deps$(Ymd)" "wget_deps_sunfreeware"
  log "ln -fs deps$(Ymd) deps" ln_deps
fi
function get_sources() {
  local name=$1
  local _namever=$2
  local line=$(grep " $name-" deps|grep "Source Code")
  local IFS="\"" ; set -- $line ; local IFS=" "
  local source=$2
  local IFS="/" ; set -- $source ; local IFS=" "
  local targz=$7
  #echo sources for $name: $targz from $source from $line
  if [[ ! -e src/_pkgs/$targz ]]; then
    echolog "get sources for $name in src/_pkgs/$targz"
    loge "wget $source -O src/_pkgs/$targz" "wget_sources_$targz"
  fi
  eval $_namever="'${targz%.tar.gz}'"
}
function get_tar() {
  local _tarname=$1
  local atarname=""
  if [[ $(which gtar) != "" ]] ; then $atarname="gtar"; 
  elif [[ $(which tar) != "" ]]; then 
    local h=$(tar --help|grep GNU)
    if [[ "$h" != "" ]]; then atarname="tar"; fi;
  fi
  if [[ $atarname == "" ]] ; then echolog "Unable to find a GNU tar or gtar" ; tar2 ; fi
  eval $_tarname="'$atarname'";
}
function build_app() {
  local name="$1"
  echolog "##### Building APP $name ####"
  get_sources $name namever
  echo namever $namever
  if [[ -e usr/local/apps/$namever ]]; then
    echolog "$namever already installed"
  else
    if [[ ! -e src/$namever ]]; then
      get_tar tarname
      loge "$tarname xpvf src/_pkgs/$namever.tar.gz -C src" "tar_xpvf_$namever.tar.gz"
    fi
  fi
}
function build_lib() {
  local name="$1"
  echo Building LIB $name
}
function build_line() {
  local line="$1"
  #echo line $line
  set -- junk $line ; shift
  local type=$1; local name=$2 ; local deps=$3
  #echo deps $deps for $name with $type
  local IFS=”,”; declare -a Array=($deps); local IFS=" "
  for adep in "${Array[@]}"; do
    #echo adep $adep for $name with $type
    if [[ "$adep" != "none" ]]; then
      adepline=$(grep -E "(app|lib) $adep" _deps)
      #echo dep line: $adepline
      build_line "$adepline"
    fi
  done
  #echo done deps from $name with $type
  if [[ $type == "app" ]]; then build_app "$name" ;
  elif [[ $type == "lib" ]] ; then build_lib "$name" ; 
  else echo "unknow type" ; exit 1 ; fi
}
cat _deps | while read line; do
  #echo $line
  build_line "$line"
done
trap - EXIT
echo -e "\e[00;32mAll Done.\e[00m"
exit 0
