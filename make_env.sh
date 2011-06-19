#!/bin/bash
myhome=`pwd`
echo $myhome
DIR="$( basename `pwd` )"
echo $DIR
#d=`date +"%Y%m%d"`
#echo $d
#mkdir -p logs

set -o errtrace
set -o nounset

function Ymd() { date +"%Y%m%d"; }
function _ldate() { date +"%Y/%M/%d-%H:%M:%S"; }
function _fdate() { date +"%Y%m%d.%H%M%S"; }
function _echod() { echo "$(_ldate) $1$2" ; }
function _echolog() { _echod "$1" "$2" | tee -a "$3"; if [[ $4 != "" ]]; then echo $4 >> "$3"; fi; }
function echolog() { _echolog "~ " "$1" log ""; }
function _echologcmd() { _echolog "~~~ $1" "$2" "logs/$3" "~~~~~~~~~~~~~~~~~~~"; }
function _log() { f=$2; rm -f logs/l; ln -fs $f logs/l; _echologcmd "" "$1" $f ; $( $1 >> logs/$f 2>&1 ) ; }
function log() { f=$(_fdate).$2 ; _log "$1" $f ; }
function loge() { f=$(_fdate).$2 ; echo "(see logs/$f)" >> log; _log "$1" $f ; _echologcmd "DONE ~~~ " "$1" $f; true ; }
function mrf() { ls -t1 $1 | head -n1 ; }
#trap "tail -3 log ; f=$(mrf logs) ; tail -5 logs/$f ; exit " EXIT ;
# see http://fvue.nl/wiki/Bash:_Error_handling#Solutions_revisited:_Combining_the_tools
function _onexit() {
  #echo -e "\e[00;31m!!!!\nFAIL\n!!!!\e[00m" | tee -a log
  #echo $(tail -3 log ; tail -5 logs/l)
  echo echo err
  true
}
function onexit() {
  local exit_status=${1:-$?} ;
  echo "echo Exiting ${0} with ${exit_status}"
  #echo Exiting ${0} with ${exit_status} ;
  if [[ $exit_status != 0 ]]; then 
    _onexit
  fi
}
trap 'onexit' 1 2 3 15 ERR
#trap "echo -e "\\\\e\\\[00\\\;31m!!!!\nFAIL\n!!!!\\\\e\\\[00m" | tee -a log; tail -3 log ; tail -5 logs/l" EXIT ;

if [[ ! -e dep ]]; then
  echolog "#### DEPS ####"
  echolog "download deps from SunFreeware"
  loge "wget http://sunfreeware.com/programlistsparc10.html -O deps$(Ymd)" "wget_deps_sunfreeware"
  log "ln -s deps$(Ymd) deps" ln_deps
fi

onexit
