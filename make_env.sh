#!/bin/bash

function scriptpath() {
  local _sp=$1
  local ascript="$0"
  local asp="$(dirname $0)"
  if [[ "$asp" == "." ]] ; then asp=$(pwd) ;
  else
    # echo "D: asp '$asp', ascript '$ascript'"
    if [[ "${ascript#/}" != "$ascript" ]]; then asp=$asp ;
    elif [[ "${ascript#../}" != "$ascript" ]]; then
      asp=$(pwd)
      while [[ "${ascript#../}" != "$ascript" ]]; do
        asp=${asp%/*}
        ascript=${ascript#../}
      done
    elif [[ "${ascript#*/}" != "$ascript" ]];  then
      asp="$(pwd)/${asp}"
    fi
  fi
  eval $_sp="'$asp'"
}
scriptpath H
export H="${H}"
echo "make_env: define local home '${H}'."
isSolaris=""
longbit=""
alldone=""
unameo=$(uname -o)
refresh="false"

_cpl="${H}/.cpl"
_hcpl=".cpl"
_deps="${_cpl}/_deps"
_vers="${_cpl}/_vers"
_log="${_cpl}/log"
_hlog="${_hcpl}/log"
_logs="${_cpl}/logs"
_hlogs="${_hcpl}/logs"
_src="${_cpl}/src"
_pkgs="${_src}/_pkgs"
_hsrc="${_hcpl}/src"
_hpkgs="${_hsrc}/_pkgs"
if [[ -d "${H}/../src" ]] ; then
  if [[ -d "${_src}" ]] ; then rm -Rf "${_src}" ; fi
  _src="${H}/../src"
  _hsrc="../src"
  ln -fs ../../src "${_cpl}"
fi
if [[ -d "${H}/../_pkgs" ]] ; then
  if [[ -d "${H}/.cpl/src/_pkgs}" ]] ; then 
    ln -fs ../../../_pkgs "${_src}"
    cp "${H}/.cpl/src/_pkgs/.readme" "${_src}/_pkgs" 
    rm -Rf "${H}/.cpl/src/_pkgs}" ; 
  else
    ln -fs ../_pkgs "${_src}"  
  fi
  _pkgs="${H}/../_pkgs"
  _hpkgs="../_pkgs"
fi
echo $H
mkdir -p "${_logs}"
mkdir -p "${_pkgs}"
mkdir -p "${H}/bin"
if [[ -e "$H/README.md" ]] ; then mv -f "$H/README.md" "$H/.README.md" ; fi
ln -fs ${_hlog} "$H/.log"
donelist=""
namever=""
ver=""
title=""

set -o errexit
set -o nounset

function ftrap {
  tee -a "${_log}";
  tail -3 "${_log}"
  if [[ -e "${_logs}"/l ]]; then
    tail -5 "${_logs}"/l
  rm "${_logs}"/l;
  fi
  if [[ "${unameo}" == "Cygwin" ]] ; then
    local chk=$(grep "cannot stat" "${H}/.lastlog"|grep ".libs/libgettext")
  echo $chk
  if [[ ${chk} != "" ]] ; then
      bash ${H}/make_env.sh
  fi
  fi
}

trap "echo -e "\\\\e\\\[00\\\;31m!!!!_FAIL_!!!!\\\\e\\\[00m" | ftrap" EXIT ;

function getJDK {
  local afrom="$1"
  local name="jdk"
  #echo 'JDK $type ${donelist}' "$name : ${donelist}"
  local isdone="false" ; isItDone "$name" isdone ${afrom}
  if [[ "$isdone" == "false" ]] ; then
    echolog "##### Getting JDK6 latest ####" ; echo -ne "\e[m"
    if [[ ! -z "${JAVA_HOME}" ]] && [[ -e "${JAVA_HOME}" ]]; then
       ajvv=$(${JAVA_HOME}/bin/java -version 2>&1) ;
       echo -ne "\e[1;32m" ; echolog "JDK6 already installed" ; echo -ne "\e[m" ;
       echo "Java detected, version: ${ajvv}"
       if [[ ! -z "${ajvv}" ]] && [[ "${ajvv#*1.6.}" != "${ajvv}" ]] ; then donelist="${donelist}@${name}@" ; return 0;  fi
    fi
    # local ajdk=$(wget -q -O - http://www.oracle.com/technetwork/java/javase/downloads/index.html | \
    #  grep -e "(?ms)Java SE \d(?: Update \d+)?<.*?href=\"(/technetwork[^\"]+)\"><img")
    local ajdk=$(wget -q -O - http://www.oracle.com/technetwork/java/javase/downloads/index.html | \
      grep "jdk6-downloads-")
    ajdk=${ajdk#*releasenotes*f=\"}
    ajdk="http://www.oracle.com${ajdk%%\"*}"
    echo $ajdk
    local ajdkgrep="linux-i586.bin"
    if [[ "${longbit}" == "64" ]]; then ajdkgrep="linux-x64.bin" ; fi
    # echo "D: longbit = ${longbit}, ajdkgrep = ${ajdkgrep}"
    local ajdk2=$(wget -q -O - ${ajdk} | grep "http://download.oracle.com/otn-pub/java/jdk" | \
      grep "${ajdkgrep}")
    ajdk2=${ajdk2##*:\"}
    ajdk2=${ajdk2%%\"*}
    local ajdkn=${ajdk2##*/}
    echo $ajdk2 $ajdkn
    if [[ ! -e "${_pkgs}/${ajdkn}" ]]; then
      cp_tpl "${H}/jdk/.cookies.tpl" "${H}/jdk"
      loge "wget --cookies=on --load-cookies=${H}/jdk/.cookies --keep-session-cookies $ajdk2 -O ${_pkgs}/$ajdkn" "wget_sources_${ajdkn}"
    fi
    chmod 755 "${_pkgs}/$ajdkn"
    cd "${H}/usr/local"
    if [[ ! -e jdk6 ]]; then
      loge "${_pkgs}/$ajdkn" "wget_extract_${ajdkn}"
      ln -s jdk1.6* jdk6
    fi
    export JAVA_HOME="${HUL}/jdk6"
    cd "${H}"
    donelist="${donelist}@${name}@"
  fi
}

function main {
  checkOs
  set +o nounset
  until [ -z "$1" ] ; do # Until all parameters used up . . .
    read_param "$1"
    shift
  done
  set -o nounset
  get_arc longbit
  if [[ -e "$H/.bashrc_aliases_git" ]] ; then cp "$H/.cpl/.bashrc_aliases_git.tpl" "$H/.bashrc_aliases_git" ; fi
  if [[ ! -e "$H/.bashrc" ]]; then
    if [[ "${title}" == "" ]] ; then echolog "When there is no .bashrc, make_env.sh needs a title for that .bashrc as first parameter. Not needed after that" ; miss_bashrc_title ; fi
    build_bashrc
  fi
  sc
  mkdir -p "${HUL}/._linked"
  mkdir -p "${HUL}/ssl/lib"
  mkdir -p "${HULA}/svn/lib"
  mkdir -p "${HULA}/python/lib"
  mkdir -p "${HULA}/gcc/lib"
  if [[ ! -e "${_vers}" ]]; then
    echolog "#### VERS ####"
    echolog "download compatible versions from SunFreeware"
    loge "wget http://www.sunfreeware.com/programlistsparc10.html -O ${_vers}$(Ymd)" "wget_vers_sunfreeware"
    log "ln -fs ${_vers}$(Ymd) ${_vers}" ln_vers
    gen_sed -i 's/ftp:\/\/ftp.sunfreeware.com/http:\/\/ftp.sunfreeware.com\/ftp/g' ${_vers}$(Ymd)
    gen_sed -i 's/\/SOURCES\//http:\/\/www.sunfreeware.com\/SOURCES\//g' ${_vers}$(Ymd)
  fi
  cat "${_deps}" | while read line; do
    #echo $line
    if [[ "$line" != "__no_deps__" ]] ; then
      build_line "$line"
    fi
  done
}

function read_param {
  local aparam="$1"
  local akey="${aparam%%=*}"
  local avalue="${aparam##*=}"
  if [[ "${akey}" == "" ]] ; then akey="${aparam}" ; fi
  case "${akey}" in
    -h ) echo "make_env.sh help"
         trap - EXIT
         echo -ne "\033[32m"
         echo "-h: display this page"
         echo "-title=atitle: (only for the first usage)"
         echo "-refresh: force reading versions from website (default false)"
         echo -ne "\033[0m"
         echo "----"
         exit 0
    ;;
    -title ) title="${avalue}" ;;
    -refresh ) refresh="true" ;;
    * ) echolog "unknwon option ${akey} with value ${avalue}" ; unknown_option ;;
  esac
}

function checkOs() {
  local platform=$(uname)
  if [[ "$platform" == "SunOS" ]] ; then isSolaris="true" ; fi
}
function Ymd() { date +"%Y%m%d"; }
function _ldate() { date +"%Y/%m/%d-%H:%M:%S"; }
function _fdate() { date +"%Y%m%d.%H%M%S"; }
function _echod() { echo "$(_ldate) $1$2" ; }
function _echolog() { _echod "$1" "$2" | tee -a "$3"; if [[ $4 != "" ]]; then echo $4 >> "$3"; fi; }
function echolog() { _echolog "~ " "$1" "${_log}" ""; }
function _echologcmd() { _echolog "~~~ $1" "$2" "${_logs}/$3" "~~~~~~~~~~~~~~~~~~~"; }
function _log() { f=$2; rm -f "${_logs}"/l; ln -s $f "${_logs}"/l;rm -f "${H}"/.lastlog; sleep 1 ; ln -s "${_hlogs}/$f" "${H}"/.lastlog; _echologcmd "" "$1" $f ; echolog "(see ${_logs}/$f or simply tail -f ${_logs}/l)"; $( $1 >> "${_logs}"/$f 2>&1 ) ; }
function log() { f=$(_fdate).$2 ; _log "$1" $f ; }
function loge() { echo -ne "\e[1;33m" ; f=$(_fdate).$2.log ; _log "$1" $f ; _echologcmd "DONE ~~~ " "$1" $f; echo -ne "\e[m" ; true ;}
function mrf() { ls -t1 "$1"/$2 | head -n1 ; }

function sc() {
  set +e
  set +u
  source "$H/.bashrc" -force
  set -e
  set -u
}
function get_arc(){
  local _longbit=$1
  local unamem=$(uname -m)
  local alongbit="32"
  if [[ "${unamem//64/}" != "${unamem}" ]] ; then alongbit="64" ; fi
  eval $_longbit="'${alongbit}'"
}
function build_bashrc() {
  cp "$H/.cpl/.bashrc.tpl" "$H/.bashrc"
  export PATH=$H/bin:$PATH
  "${H}/sbin/gen_sed" -i "s/@@TITLE@@/${title}/g" "$H/.bashrc"
  if [[ "${unameo}" == "Cygwin" ]] ; then
    "${H}/sbin/gen_sed" -i 's/ @@CYGWIN@@/ -DHAVE_STRSIGNAL/g' "$H/.bashrc" ;
    "${H}/sbin/gen_sed" -i 's/ -fPIC//g' "$H/.bashrc" ;
  else "${H}/sbin/gen_sed" -i 's/ @@CYGWIN@@//g' "$H/.bashrc" ; fi
  if [[ "$longbit" == "32" ]]; then "${H}/sbin/gen_sed" -i 's/ @@M64@@//g' "$H/.bashrc" ;
  elif [[ "$longbit" == "64" ]]; then "${H}/sbin/gen_sed" -i 's/@@M64@@/-m64/g' "$H/.bashrc" ;
  else echolog "Unable to get LONG_BIT conf (32 or 64bits)" ; getconf2 ; fi
}
function get_sources() {
  local name=$1
  local _namever=$2
  local _ver=$3
  get_param $name nameurl "${name}"
  get_param $name nameact "${nameurl}"
  get_param $name page "${_vers}"
  if [[ "$page" == "none" ]] ; then eval $_namever="'${name}'" ; return 0 ; fi
  get_param $name ext "tar.gz"
  if [[ "${nameurl}" == "none" ]] ; then nameurl="" ; fi
  if [[ "${ext}" == "none" ]] ; then ext="" ; fi
  get_param $name exturl "${ext}"
  if [[ "${exturl}" == "none" ]] ; then exturl="" ; fi
  get_param $name extact "${ext}"
  if [[ -e "${page}" ]] ; then
    local asrcline=$(grep " ${nameurl}-" "${_vers}"|grep "Source Code")
  else
    # echo "D: local asrcline wget -q -O - ${page} grep -e ${nameurl} grep ${ext}"
    # local asrcpage=$(wget -U Mozilla -q -O - "${page}")
    # echo "D: local page: ${asrcpage}"
    local asrcline=$(wget -q -O - "${page}" | grep -e "${nameurl}" | grep -e "${ext}")
  fi
  get_param $name verexclude ""
  if [[ "${verexclude}" != "" ]]; then asrcline=$(echo "${asrcline}" | egrep -v -e "${verexclude}") ; fi
  get_param $name verinclude ""
  if [[ "${verinclude}" != "" ]]; then asrcline=$(echo "${asrcline}" | egrep -e "${verinclude}") ; fi
  # echo "D: line0 source! from page ${page}, nameurl ${nameurl}, ext _${ext}_, exturl _${exturl}_"
  # echo "D: line00 ${asrcline}"
  if [[ "${asrcline}" == "" ]]; then echolog "unable to get source version for ${name} with nameact ${nameact}, nameurl ${nameurl}, verinclude ${verinclude}, verexclude ${verexclude}, ext _${ext}_, exturl _${exturl}_" ; get_sources_failed ; fi
  #if [[ $name == "cyrus-sasl" ]] ; then echo line source! $asrcline ; fffg ; fi
  # echo "D: line1 source! $asrcline"
  local source="${asrcline%%${exturl}\"\>*}"
  # echo "D: line2 source! $source"
  if [[ "${source}" == "${asrcline}" ]] ; then source="${asrcline%%${exturl}\" *}" ; fi
  # "
  if [[ "${source}" == "${asrcline}" ]] ; then source="${asrcline%%${exturl}\'\>*}" ; fi
  if [[ "${source}" == "${asrcline}" ]] ; then source="${asrcline%%${exturl}\' *}" ; fi
  if [[ "${source}" == "${asrcline}" ]] ; then source="${asrcline%%${exturl}\#*}" ; fi
  # "
  source="${source}${exturl}"
  # echo "D: sour0 ${source}"
  local source0="${source}"
  source="${source0##*\"}"
  # "
  if [[ "${source}" == "${source0}" ]] ; then source="${source0##*\'}" ; fi
  # echo "D: source1 ${source}"
  get_param $name url ""
  # echo "D: url0 ${url}"
  # echo "D: source ${source}"
  local targz="${source##*/}"
  local aver=""
  if [[ "${targz}" == "" ]] ; then
    aver="${source%%/*}"
  fi
  if [[ "$url" != "" ]] ; then
    # echo "D: IIIII url ${url} AAAAA targz ${targz}"
    source="${url}${targz}"
  fi
  # echo "D: sources for $name: $targz from $source, with aver ${aver}"
  if [[ "${exturl}" == "" ]] ; then targz="${targz}.${extact}" ; fi 
  if [[  "${nameurl}" != "${nameact}" ]] ; then targz="${nameact}-${targz#${nameurl}}" ; echo "new targz ${targz}" ; fi
  targz="${targz%-}"
  if [[ "${aver}" == "" ]] ; then
    local anamever="${targz%.${extact}}"
    aver=${anamever#${nameact}-}
    aver=${aver%-src}
  fi
  # echo "D: targz2 ${targz}"
  # echo "D: aver_b ${aver}"
  local aver_="${aver//\./_}"
  # echo "D: aver_ ${aver_}"
  source="${source//@@VER@@/${aver}}"
  source="${source//@@VER_@@/${aver_}}"
  targz="${targz//@@VER@@/${aver}}"
  targz="${targz//@@VER_@@/${aver_}}"
  # echo "D: source ${source}, with targz ${targz}"
  local anamever="${targz%.${extact}}"
  local ss="xx"
  if [[ -e "${_pkgs}/$targz" ]] ; then ss=$(stat -c%s "${_pkgs}/$targz") ; fi
  if [[ -e "${_pkgs}/$targz" ]] && [[ "${ss}" == "0" ]] ; then
    rm -f "${_pkgs}/$targz"
  fi
  # echo "D: YYY anamever ${anamever} vs. name ${name} and nameact ${nameact}"
  if [[ "${aver}" == "" ]] ; then
    aver=${anamever#${nameact}-}
    aver=${aver%-src}
  fi
  # echo "D: get sources final: anamever ${anamever}, aver ${aver}"
  if [[ "${aver}" == "${anamever}" ]] ; then aver=${anamever#${nameact}} ; fi
  ver=${ver##*~}
  # echo "D: get sources final2: anamever ${anamever}, aver ${aver} for source ${source}"
  source=${source//@@VER@@/${aver}}
  if [[ "${nameurl}" == "master" ]] ; then
    source=${source%/*}/master
    targz="${name}-master.tar.gz"
    anamever="${name}-master"
	aver="master"
  fi
  # echo "D: get sources final2: anamever ${anamever}, aver ${aver} for source ${source}"
  if [[ ! -e "${_pkgs}/$targz" ]] && [[ ! -e "$HUL/._linked/${anamever}" ]]; then
    echolog "get sources for $name in ${_hpkgs}/$targz"
    loge "wget $source -O ${_pkgs}/$targz" "wget_sources_$targz"
  fi
  update_cache "${name}" "${anamever}" "${aver}"
  eval $_namever="'${anamever}'"
  eval $_ver="'${aver}'"
}

function get_sources_from_cache() {
  local name=$1
  local _namever=$2
  local _ver=$3
  acachenamever=""
  acachever=""
  if [[ -e "${H}/.cpl/cache" ]] ; then
    local aline=$(grep "#${name}#" "${H}/.cpl/cache")
    if [[ "${aline}" != "" ]] ; then
      acachenamever=${aline##*#}
      acachenamever=${acachenamever%%~*}
      acachever=${aline##*~}
    else
      get_sources $name acachenamever acachever
      # echo "cache no line: get_sources $name, acachenamever $acachenamever, acachever $acachever"
    fi
  else
    get_sources $name acachenamever acachever
    # echo "cache no cache: get_sources $name, cachenamever $acachenamever, acachever $acachever"
  fi
  # echo "get_sources_from_cache cachenamever $acachenamever, acachever $acachever"
  eval $_namever="'${acachenamever}'"
  eval $_ver="'${acachever}'"
}

function update_cache() {
  local name=$1
  local anamever=$2
  local aver=$3
  local aline="#${name}#${anamever}~${aver}"
  if [[ -e "${H}/.cpl/cache" ]] ; then
    local anExistingline=$(grep "#${name}#" "${H}/.cpl/cache")
    if [[ "${anExistingline}" != "" ]] ; then
      gen_sed -i "s/^#${name}#.*$/${aline}/g" "$H/.cpl/cache"
    else
      $(echo "${aline}" >> "$H/.cpl/cache")
    fi
  else
    $(echo "${aline}" > "$H/.cpl/cache")
  fi
}

function gen_which()
{
  local acmd="$1"
  local _res="$2"
  if [[ "$isSolaris" == true ]] ; then
    
    local ares=$(which "${acmd}" 2> /dev/null | tail -1)
  else
    local ares=$(which "${acmd}" 2> /dev/null)
  fi
  eval $_res="'${ares}'"
}
function get_tar() {
  local _tarname=$1
  local atarname=""
  get_param $name ext "tar.gz"
  get_param $name extact "${ext}"
  gen_which "gtar" gtarpath
  gen_which "tar" tarpath
  if [[ "${gtarpath}" != "" ]] ; then atarname="gtar xpvf";
  elif [[ "${tarpath}" != "" ]]; then
    local h=$(tar --help|grep GNU)
    if [[ "$h" != "" ]]; then atarname="tar xpvf"; else atarname="tar -xv -f" ; fi;
  fi
  if [[ "${atarname}" == "" ]] ; then echolog "Unable to find a GNU tar or gtar" ; tar2 ; fi
  if [[ "${extact}" == "zip" ]] ; then
    gen_which "unzip" unzippath
    if [[ "${unzippath}" != "" ]] ; then atarname="unzip"; fi
    if [[ "${atarname}" == "" ]] ; then echolog "Unable to find unzip" ; unzip2 ; fi
  fi
  eval $_tarname="'$atarname'";
}
function untar() {
  local name=$1
  local namever=$2
  if [[ ! -e "${_src}/$namever" ]]; then
    get_tar tarname
    get_param $name ext "tar.gz"
    get_param $name extact "${ext}"
    local dirext="-C"
    if [[ "${extact}" == "zip" ]] ; then dirext="-d" ; fi
    loge "${tarname} ${_pkgs}/$namever.${extact} ${dirext} ${_src}" "tar_xpvf_$namever.${extact}"
    local lastlog=$(mrf "${_logs}" "*tar_xpvf*")
    local actualname=$(head -3 "$lastlog"|tail -1)
    local anactualname=${actualname}
    #echo "anactualname=${anactualname}";
    actualname=${actualname%%/*}
    # echo "namever ${namever} actualver %/* ${anactualname%/*} actualname%%/* ${anactualname%%/*}, actualname#*/ ${anactualname#*/}, actualname##*/ ${anactualname##*/}"
    if [[ "$namever" != "$actualname" ]] ; then
      echolog "ln do to: ln -fs $actualname ${_src}/$namever"
      ln -fs "$actualname" "${_src}/$namever"
    fi
  fi
}
function getusername() {
  local _username=$1
  local _ausername=$(id) ; _ausername=${_ausername%%)*} ; _ausername=${_ausername##*(}
  eval $_username="'$_ausername'"
}
function getusergroup() {
  local _usergroup=$1
  local _ausergroup=$(id) ; _ausergroup=${_ausergroup#*(} ; _ausergroup=${_ausergroup#*(} ; _ausergroup=${_ausergroup%%)*}
  eval $_usergroup="'$_ausergroup'"
}
function get_param() {
  local name="$1"
  local _param="$2"
  local default="$3"
  #echo ":D name $name, _param $_param, default $default, namever='${namever}', ver='${ver}'"
  if [[ ! -e "$H/.cpl/params/$name" ]] ; then echolog "unable to find param for $name" ; no_param ; fi
  local aparam=$(grep -e "^${_param}=" "$H/.cpl/params/${name}"|head -1)
  local aparamname="${aparam%%=*}"
  if [[ "${aparam}" != "" && "${aparam##${_param}=}" != "${aparam}" ]] ; then
    aparam=${aparam##${_param}=}
  else aparam="" ; fi
  if [[ "${aparamname}" != "${_param}" ]] ; then aparam="" ; fi
  if [[ "$aparam" == "" ]]; then aparam="$default" ; fi
  if [[ "$aparam" == "" ]] || [[ "$aparam" == "none" ]] ; then eval $_param="'$aparam'" ; return 0 ; fi
  if [[ "$aparam" == "##mandatory##" ]]; then echolog "unable to find $_param for $name" ; find2 ; fi
  aparam=${aparam//@@NAMEVER@@/${namever}}
  if [[ "${aparam%@@USERNAME@@*}" != "${aparam}" ]] ; then
    getusername ausername
    aparam=${aparam//@@USERNAME@@/${ausername}}
  fi
  if [[ "${aparam%@@USERGROUP@@*}" != "${aparam}" ]] ; then
    getusergroup ausergroup;
    aparam=${aparam/@@USERGROUP@@/${ausergroup}}
  fi;
  aparam=${aparam//\$H\//${H}/}
  aparam=${aparam//\$\{H\}/${H}}
  aparam=${aparam//\$\{HB\}/${HB}}
  aparam=${aparam//\$\{HU\}/${HU}}
  aparam=${aparam//\$\{HUL\}/${HUL}}
  aparam=${aparam//\$\{HULL\}/${HULL}}
  aparam=${aparam//\$\{HULI\}/${HULI}}
  aparam=${aparam//\$\{HULB\}/${HULB}}
  aparam=${aparam//\$\{HULA\}/${HULA}}
  aparam=${aparam//\$\{HULS\}/${HULS}}

  aparam=${aparam//\$EH\//${H//\//\\/}/}
  aparam=${aparam//\$\{EH\}/${H//\//\\/}}
  aparam=${aparam//\$\{EHB\}/${HB//\//\\/}}
  aparam=${aparam//\$\{EHU\}/${HU//\//\\/}}
  aparam=${aparam//\$\{EHUL\}/${HUL//\//\\/}}
  aparam=${aparam//\$\{EHULL\}/${HULL//\//\\/}}
  aparam=${aparam//\$\{EHULI\}/${HULI//\//\\/}}
  aparam=${aparam//\$\{EHULB\}/${HULB//\//\\/}}
  aparam=${aparam//\$\{EHULA\}/${HULA//\//\\/}}
  aparam=${aparam//\$\{EHULS\}/${HULS//\//\\/}}
  if [[ "${aparam%@@HULifnotCygwin@@*}" != "${aparam}" ]] ; then
    if [[ "${unameo}" == "Cygwin" ]] ; then
        aparam=${aparam/@@HULifnotCygwin@@/no}
    else
        aparam=${aparam/@@HULifnotCygwin@@/${HUL}}
    fi
  fi;
  #if [[ "$_param" == "pre" && "$name" == "perl" ]] ; then echo $name $_param xx${aparam}xx ; fi
  eval $_param="'$aparam'"
}
function get_gnu_cmd() {
  local acmd=$1
  local _path=$2
  local _without_gnu_cmd=$3
  local _with_gnu_cmd=$4
  gen_which "${acmd}" apath
  apath=${apath/\/\///}
  if [[ "$apath" == "" ]] ; then echolog "Unable to find a ${acmd}" ; cmd_not_found ; fi
  eval $_path="'$apath'"
  local without_gnu_cmd="" ; local with_gnu_cmd=""
  if [[ ${apath#/usr/ccs*} != "${apath}" ]]; then without_gnu_cmd="--without-gnu-${acmd}"; else with_gnu_cmd="--with-gnu-${acmd}"; fi
  eval $_without_gnu_cmd="'$without_gnu_cmd'"
  eval $_with_gnu_cmd="'$with_gnu_cmd'"
}
function configure() {
  local name=$1
  local namever=$2
  get_param $name makefile Makefile
  local makefileExist=false
  if [[ -e "${_src}/${namever}/$makefile" || "${makefile}" == "none" ]] ; then makefileExist=true ; fi
  # echo "makefileExist ${makefileExist}"
  # if [[ "${makefileExist}" == "false" ]] ; then echo "ee" ; fi
  if [[ "${name}" != "${namever}" ]] && [[ ! -e "${_src}/${namever}/._config" || "${makefileExist}" == "false" ]]; then
    local haspre="false"; if [[ -e "${_src}/${namever}/._pre" ]] ; then haspre=true ; fi
    rm -f "${_src}/${namever}"/._*
    if [[ "$haspre" == "true" ]] ; then echo "done" > "${_src}/${namever}/._pre" ; fi
    echo "done" > "${_src}/${namever}"/._pre
    #pwd
    get_param $name configcmd "##mandatory##"
    #echo "configcmd=${configcmd}"
    if [[ "${configcmd}" != "none" ]] ; then
      get_gnu_cmd ld path_ld without_gnu_ld with_gnu_ld
      configcmd=${configcmd/@@PATH@@/${PATH}}
      configcmd=${configcmd/@@PATH_LD@@/${path_ld}}
      configcmd=${configcmd/@@WITHOUT_GNU_LD@@/${without_gnu_ld}}
      configcmd=${configcmd/@@WITH_GNU_LD@@/${with_gnu_ld}}
      get_gnu_cmd as path_as without_gnu_as with_gnu_as
      configcmd=${configcmd/@@PATH_AS@@/${path_as}}
      configcmd=${configcmd/@@WITHOUT_GNU_AS@@/${without_gnu_as}}
      configcmd=${configcmd/@@WITH_GNU_AS@@/${with_gnu_as}}
      if [[ $longbit == "64" ]] ; then configcmd=${configcmd/@@ENABLE_64BIT@@/--enable-64bit} ;
      else configcmd=${configcmd/@@ENABLE_64BIT@@/} ; fi
      echo "configcmd=${configcmd}"
      if [[ "${configcmd#@@}" != "${configcmd}" ]] ; then
        configcmd="${configcmd#@@}"
        echo "${configcmd}" > ./configurecmd
        chmod 755 ./configurecmd
        configcmd="./configurecmd"
      fi
      #pwd
      loge "${configcmd}" "configure_${namever}"
    fi
  fi
  echo "done" > "${_src}/${namever}/._config"
}
function cleanPath() {
  local path="$1"
  local _path="$2"
  while [[ "${path%/.}" != "${path}" ]] ; do path="${path%/.}"; done
  while [[ "${path#./}" != "${path}" ]] ; do path="${path#./}"; done
  #echo '${palibssh2th%/./*}' ${path%/./*}
  while [[ "${path%/./*}" != "${path}" ]] ; do path="${path/\/.\///}"; done
  eval $_path="'$path'"
}
function relpath() {
  local source="$1"; cleanPath "$source" source
  local target="$2"; cleanPath "$target" target
  local _relp="$3"
  local common_part="$source"
  local back=
  #echo target $target common_part $common_part
  #echo '${target#$common_part/}' ${target#$common_part/}
  while [ "${target#$common_part/}" == "${target}" ]; do
    if [[ -d $common_part ]] ; then back="../${back}" ; fi
    common_part=${common_part%/*}
    #echo common_part $common_part back $back
  done
  #echo '${back}${target#$common_part/}' ${back}${target#$common_part/}
  eval $_relp="'${back}${target#$common_part/}'";
}
function onelink() {
  local dest="$1"
  local src="$2"
  local line="$3"
  local apath=${line%/*}; apath=${apath#*/}
  local afile=${line##*/}
  #echo check $apath $afile
  mkdir -p "$dest/$apath"
  #ln -fs "$src/$apath/$afile" "$dest/$apath/$afile"
  #echo src "$src/$apath/$afile" dest "$dest/$apath/$afile"
  #relpath "$src/$apath/$afile" "$dest/$apath/$afile" relp
  relpath "$dest/$apath/$afile" "$src/$apath/$afile" relp
  #echo relp $relp
  #echo "{unameo} ${unameo} {apath%/bin} ${apath%/bin} {afile%.dll} ${afile%.dll}"
  if [[ "${unameo}" == "Cygwin" ]] && [[ "${afile%.dll}" != "${afile}" || "${afile%.a}" != "${afile}" ]] ; then
    #echo rm -f then cp -f "$src/$apath/$afile" "$dest/$apath/$afile"
    rm -f "$dest/$apath/$afile"
    cp -f "$src/$apath/$afile" "$dest/$apath/$afile"
  else
    #echo ln -fs "$relp" "$dest/$apath/$afile"
    ln -fs "$relp" "$dest/$apath/$afile"
  fi
}
function links() {
  local dest="$1"
  local src="$2"
  if [[ -d "${src}" ]] ; then
    cd "$src"
    find . -type f -print | while read line; do
      # echo check $line
      onelink "$dest" "$src" "$line"
    done
    find . -type l -print | while read line; do
      # echo check $line
      onelink "$dest" "$src" "$line"
    done
  fi
}
function action() {
  local name=$1
  local namever=$2
  local actionname=$3
  local actionpath=$4
  local actionstep=$5
  local actiondefault="$6"
  # echo "actionname='${actionname}', actionpath='${actionpath}', actionstep='${actionstep}'" 
  if [[ ! -e "${actionpath}/._${actionstep}" ]]; then
     get_param $name ${actionname} "${actiondefault}"
     local actioncmd=${!actionname}
     actioncmd=${actioncmd//@@VER@@/${ver}}
     if [[ "${actioncmd}" != "none" ]] && [[ "${actioncmd}" != "" ]] ; then 
       #if [[ "$name" == "perl" && "$actionname" == "pre" ]] ; then echo eval xx ${actioncmd} xx ; fi
       #echo actioname ${actionname} gives actioncmd ${actioncmd}; eee
       if [[ "${actioncmd#@@}" != "${actioncmd}" ]] ; then
          actioncmd="${actioncmd#@@}"
          echo "${actioncmd}" > "./${actionname}"
          chmod 755 "./${actionname}"
          actioncmd="./${actionname}"
        fi
        #echo pre $pre ; jj
        loge "eval ${actioncmd}" "${actionname}_${namever}"
     fi
     # pwd
     # echo "done > ${actionpath}/._${actionstep}"
     echo done > "${actionpath}/._${actionstep}"
     # ls -alrt "${actionpath}/._${actionstep}"
     #if [[ "$name" == "perl" && "$actionname" == "pre" ]] ; then echo "---- done" ; eee ; fi
  fi    
}
function isItDone() {
  local name="$1"
  local _isdone="$2"
  local aafrom="$3"
  local aisdone="false"
  #echo "name ${name} from ${aafrom}: donelist ${donelist}"
  if [[ "${donelist%@${name}@*}" != "${donelist}" ]] ; then aisdone="true" ; fi
  eval $_isdone="'$aisdone'"
}
function gocd() {
  local name=$1
  local namever=$2
  get_param $name cdpath "${_src}/${namever}"
  cdpath=$(eval echo "${cdpath}")
  echolog "cd $cdpath"
  cd "${cdpath}"
}

function build_item() {
  local name="$1"
  local type="$2"
  local afrom="$3"
  #echo '$type ${donelist}' "$name : ${donelist}"
  local isdone="false" ; isItDone "$name" isdone ${afrom}
  if [[ "$isdone" == "false" ]] ; then echo -ne "\e[1;34m" ; echolog "##### Building $type $name ####" ; echo -ne "\e[m" ; fi
  if [[ "${type}" != "MOD" ]] ; then
    if [[ "${refresh}" == "true" ]] ; then
      get_sources $name namever ver
      # echo "get_sources $name, namever $namever, ver $ver"
    else
      get_sources_from_cache $name namever ver
      # echo "get_sources_from_cache $name, namever $namever, ver $ver"
    fi
  else
    namever="${name}"
    ver=""
  fi
  # ver=${namever#${name}-}
  #echo "XXX ver ${ver}, namever ${namever} name ${name}"
  if [[ -e "$HUL/._linked/$namever" ]]; then
    if [[ "$isdone" == "false" ]] ; then
      echo -ne "\e[1;32m" ; echolog "$type $namever already installed" ; echo -ne "\e[m" ;
      donelist="${donelist}@${name}@" ;
    fi
    if [[ ! -e "${HULA}/${name}" && -e "${HULA}/${namever}" ]] ; then ln -fs "${namever}" "${HULA}/${name}" ; fi
    if [[ -h "${HULA}/${name}/${namever}" ]] ; then rm -f "${HULA}/${name}/${namever}" ; fi
    if [[ -h "${HULA}/${name}" && ! -e "${HULA}/${namever}" ]] ; then rm -f "${HULA}/${name}" ; fi
  else
    local asrc="${_src}/${namever}"
    if [[ "${type}" == "MOD" ]] ; then mkdir -p "${asrc}" ; fi
    sc
    if [[ "${type}" != "MOD" ]] ; then untar $name $namever ; fi
    action $name $namever precond "${asrc}" precond "none"
    gocd $name $namever
    action $name $namever pre "${asrc}" pre "none"
    configure $name $namever
    action $name $namever premake "${asrc}" premake "none"
    action $name $namever makecmd "${asrc}" build "make"
    action $name $namever makeinstcmd "${asrc}" installed  "make install"
    action $name $namever post "${asrc}" post "none"
    if [[ "${type}" != "MOD" ]] ; then
      if [[ "$type" == "APP" ]] ; then linksrcdef="$HULA/$namever/bin" ; linkdstdef="$H/bin" ; fi
      if [[ "$type" == "LIB" ]] ; then linksrcdef="$HULS/$namever" ; linkdstdef="$HUL" ; fi
      get_param $name linksrc $linksrcdef; linksrc=$(echo "${linksrc}") ; # echo "linksrc ${linksrc}"
      get_param $name linkdst $linkdstdef; linkdst=$(echo "${linkdst}") ; # echo "linkdst ${linkdst}"
    fi
    if [[ ! -e "${HUL}"/._linked/$namever ]] ; then
      if [[ "${type}" != "MOD" ]] ; then echolog "checking links of $type $namever"; links "$linkdst" "$linksrc" ; fi
      if [[ "$type" == "APP" ]] ; then 
        local l=$(ls "${HULA}/$namever"/lib/*.so 2>/dev/null)
        local l64=$(ls "${HULA}/$namever"/lib64/*.so 2>/dev/null)
        if [[ "${l}" != "" ]] ; then 
          echolog "checking links lib of $type $namever"; links "${HULL}" "$HULA/$namever/lib" ;
        fi
        if [[ "${l64}" != "" ]] ; then 
          echolog "checking links lib64 of $type $namever"; links "${HULL}" "$HULA/$namever/lib64" ;
        fi
      fi
      echo done > "${HUL}"/._linked/$namever ;
    fi
    if [[ "$type" == "APP" && ! -e "${HULA}/${name}" ]] ; then  ln -fs "${namever}" "${HULA}/${name}" ; fi
    if [[ "$type" == "LIB" && ! -e "${HULS}/${name}" ]] ; then  ln -fs "${namever}" "${HULS}/${name}" ; fi
    if [[ "$type" == "LIB" && ! -e "${HULS}/${namevar}" ]] ; then  rm -f "${HULS}/${name}" ; fi
    donelist="${donelist}@${name}@"
  fi
}
function build_line() {
  local line="$1"
  local lineori="$1"
  #echo line $line
  set -- junk $line ; shift
  local type=$1; local name=$2 ; local deps=${3//,/ }
  isItDone "$name" aaisdone "${lineori}"
  if [[ "$aaisdone" == "false" ]] ; then
    #echo deps $deps for $name with $type
    declare -a Array=($deps)
    for adep in "${Array[@]}"; do
      #echo adep $adep for $name with $type
      if [[ "$adep" != "none" ]]; then
        adepline=$(egrep -e "((app|lib|mod) $adep)|__no_deps__" "${_deps}")
        #echo dep line: "xx${adepline}xx"
        if [[ "$adepline" == "__no_deps__" ]] ; then echolog "unable to find dependencies of $adep"; nodepfound ; fi
        adepline=$(echo "${adepline}" | egrep -e "${adep}")
        build_line "$adepline"
      fi
    done
    #echo done deps from $name with $type
    if [[ $type == "app" ]] && [[ $name == "jdk" ]]; then getJDK "$lineori";
    elif [[ $type == "app" ]]; then build_item "$name" "APP" "$lineori";
    elif [[ $type == "lib" ]] ; then build_item  "$name" "LIB" "$lineori";
    elif [[ $type == "mod" ]] ; then build_item "$name" "MOD" "$lineori"
    else echo "unknow type" ; exit 1 ; fi
  fi
}

main $*
trap - EXIT
echo -e "\e[00;32mAll Done.\e[00m"
exit 0
