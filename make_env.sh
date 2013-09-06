#!/bin/bash

function scriptpath() {
  local _sp=${1}
  local ascript="${0}"
  local asp="$(dirname ${0})"
  if [[ "${asp}" == "." ]] ; then asp=$(pwd) ;
  else
    # echo "D: asp '${asp}', ascript '${ascript}'"
    if [[ "${ascript#/}" != "${ascript}" ]]; then asp=${asp} ;
    elif [[ "${ascript#../}" != "${ascript}" ]]; then
      asp=$(pwd)
      while [[ "${ascript#../}" != "${ascript}" ]]; do
        asp=${asp%/*}
        ascript=${ascript#../}
      done
    elif [[ "${ascript#*/}" != "${ascript}" ]];  then
      asp="$(pwd)/${asp}"
    fi
  fi
  eval ${_sp}="'${asp}'"
}
scriptpath H
export H="${H}"
echo "make_env: define local home '${H}'."
isSolaris=""
longbit=""
alldone=""
unameo=$(uname -o)
refresh="false"

homed=${H##*/}
echo "homed='${homed}'"

_cpl="${H}/.cpl"
_hcpl=".cpl"
_deps="${_cpl}/_deps"
_log="${_cpl}/log"
_hlog="${_hcpl}/log"
_logs="${_cpl}/logs"
_hlogs="${_hcpl}/logs"
_src="${_cpl}/src"
_pkgs="${_src}/_pkgs"
_hsrc="${_hcpl}/src"
_hpkgs="${_hsrc}/_pkgs"
mkdir -p "${_pkgs}"
if [[ ! -e "${_src}/.keep_local" && -e "${H}/../.keep_local.${homed}" ]]; then
  echo "set keep_local for ${homed} sources"
  ln -fs "../../../.keep_local.${homed}" "${_src}/.keep_local"
fi
if [[ ! -e "${H}/.ports.ini.private" && -e "${H}/../.ports.ini.private.${homed}" ]]; then
  echo "set private ports for ${homed}"
  ln -fs "../.ports.ini.private.${homed}" "${H}/.ports.ini.private"
fi
if [[ ! -e "${H}/.envs.private" && -e "${H}/../.envs.private.${homed}" ]]; then
  echo "set private envs for ${homed}"
  ln -fs "../.envs.private.${homed}" "${H}/.envs.private"
fi

if [[ -d "${H}/../src" && ! -e "${_src}/.keep_local" ]] ; then
  if [[ -d "${_src}" && ! -h "${_src}" ]] ; then rm -Rf "${_src}" ; fi
  _src="${H}/../src"
  _hsrc="../src"
  ln -fs ../../src "${_cpl}"
fi
if [[ -d "${H}/../_pkgs" ]] ; then
  if [[ -d "${H}/.cpl/src/_pkgs" ]] ; then 
    if [[ ! -h "${H}/.cpl/src/_pkgs" ]] ; then
      rm -Rf "${H}/.cpl/src/_pkgs" ; 
      ln -fs ../../../_pkgs "${_src}"
    fi
  else
    ln -fs ../_pkgs "${_src}"  
  fi
  _pkgs="${H}/../_pkgs"
  _hpkgs="../_pkgs"
fi
# echo ${H}
mkdir -p "${_logs}"
mkdir -p "${_pkgs}"
mkdir -p "${H}/bin"
ln -fs ${_hlog} "${H}/.log"
donelist=""
namever=""
ver=""
title="${H}"

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
  echo "${chk}"
  if [[ ${chk} != "" ]] ; then
      bash ${H}/make_env.sh
  fi
  fi
}

trap "echo -e "\\\\e\\\[00\\\;31m!!!!_FAIL_!!!!\\\\e\\\[00m" | ftrap" EXIT ;

function getJDK {
  local afrom="$1"
  local name="jdk"
  #echo 'JDK ${type} ${donelist}' "${name} : ${donelist}"
  local isdone="false" ; isItDone "${name}" isdone ${afrom}
  if [[ "${isdone}" == "false" ]] ; then
    echolog "##### Getting JDK7 latest ####" ; echo -ne "\e[m"
    if [[ ! -z "${JAVA_HOME}" ]] && [[ -e "${JAVA_HOME}" ]]; then
       ajvv=$(${JAVA_HOME}/bin/java -version 2>&1) ;
       echo -ne "\e[1;32m" ; echolog "JDK (local) already installed" ; echo -ne "\e[m" ;
       echo "Java detected, version: ${ajvv}"
       if [[ ! -z "${ajvv}" ]] && [[ "${ajvv#*1.6.}" != "${ajvv}" ]] ; then donelist="${donelist}@${name}@" ; return 0;  fi
       if [[ ! -z "${ajvv}" ]] && [[ "${ajvv#*1.7.}" != "${ajvv}" ]] ; then donelist="${donelist}@${name}@" ; return 0;  fi
    fi
    if [[ ! -e "${_pkgs}/${name}" ]] ; then
      wget -q -O "${_pkgs}/${name}" http://www.oracle.com/technetwork/java/javase/downloads/index.html
    fi
    local ajdk=$(cat "${_pkgs}/${name}" | grep "technetwork/java/javase/downloads/jdk7")
    # echo "j1 ${ajdk}"
    ajdk=${ajdk#*archive-*href=\"}
    ajdk=${ajdk%%\"*}
    # echo "j2 ${ajdk}"
    ajdk="http://www.oracle.com${ajdk%%\"*}"
    echo "JDK address: ${ajdk}"
    local ajdkgrep="linux-i586.tar.gz"
    if [[ "${longbit}" == "64" ]]; then ajdkgrep="linux-x64.tar.gz" ; fi
    # echo "D: longbit = ${longbit}, ajdkgrep = ${ajdkgrep}"
    if [[ ! -e "${_pkgs}/${name}2" ]] ; then
      wget -q -O "${_pkgs}/${name}2" ${ajdk}
    fi
     echo "cat \"${_pkgs}/${name}2\" | grep \"http://download.oracle.com/otn-pub/java/jdk\" | grep \"${ajdkgrep}\""
    local ajdk2=$(cat "${_pkgs}/${name}2" | grep "http://download.oracle.com/otn-pub/java/jdk" | \
      grep "${ajdkgrep}")
    ajdk2=${ajdk2##*:\"}
    ajdk2=${ajdk2%%\"*}
    local ajdkn=${ajdk2##*/}
    echo "ajdk2: '$ajdk2', ajdkn '${ajdkn}'"
    if [[ ! -e "${_pkgs}/${ajdkn}" ]]; then
      cp_tpl "${H}/jdk/.cookies.tpl" "${H}/jdk"
      loge "wget --no-check-certificate --cookies=on --load-cookies=${H}/jdk/.cookies --keep-session-cookies $ajdk2 -O ${_pkgs}/${ajdkn}" "wget_sources_${ajdkn}"
    fi
    chmod 755 "${_pkgs}/${ajdkn}"
    cd "${H}/usr/local"
    if [[ ! -e jdk7 ]]; then
      loge "tar xpvf ${_pkgs}/${ajdkn}" "wget_extract_${ajdkn}"
      #loge "echo ${_pkgs}/${ajdkn}" "wget_extract_${ajdkn}" # TOCOMMENT
      ln -s jdk1.7* jdk7
    fi
    export JAVA_HOME="${HUL}/jdk7"
    cd "${H}"
    donelist="${donelist}@${name}@"
  fi
}

gline="_"
glastline=""

function main {
  if [[ "${glastline}" == "" ]] ; then
    checkOs
    set +o nounset
    until [ -z "$1" ] ; do # Until all parameters used up . . .
      read_param "$1"
      shift
    done
    set -o nounset
    get_arc longbit
    if [[ -e "${H}/.bashrc_aliases_git" ]] ; then cp "${H}/.cpl/.bashrc_aliases_git.tpl" "${H}/.bashrc_aliases_git" ; fi
    if [[ ! -e "${H}/.bashrc" ]]; then
      if [[ "${title}" == "" ]] ; then echolog "title should be set (to '${H}')" ; miss_bashrc_title ; fi
      build_bashrc
      echo "source \"${H}/.bashrc\" --force"
      trap - EXIT
      exit 0
    fi
    if [[ ! -e "${H}/addresses.txt" ]] ; then "${H}/sbin/cp_tpl" "${H}/.cpl/addresses.txt.tpl" "${H}" ; fi
    sc
    mkdir -p "${HUL}/._linked"
  fi
  ldd=$(cat "${_deps}")
  gstopat=""
  if [[ -e "${H}/../stopat.${homed}" ]] ; then gstopat=$(cat "${H}/../stopat.${homed}") ; fi
  # echo "gstopat='${gstopat}'"
  while read line; do
    # echo "D: main line '${line}'"
    gline="${line}"
    if [[ "${line}" != "__no_deps__" ]] ; then
      if [[ "${glastline}" == "" || "${line}" == "${glastline}" ]] ; then
        glastline=""
        build_line "${line}"
        if [[ "${gstopat}" != "" ]] ; then
          alinename=${line#* }
          alinename=${alinename%% *}
          # echo "alinename='${alinename}'"
          if [[ "${gstopat}" == "${alinename}" ]] ; then
            glastline="stop"
            gline="__no_deps__"
          fi
        fi
      fi
    fi
  done < <(echo "${ldd}")
  # echo "D: gline='${gline}', glastline='${glastline}'"
  if [[ "${gline}" != "__no_deps__" ]] ; then
    glastline="${gline}"
    gline=""
    # echo "D: fixed gline='${gline}', glastline='${glastline}'"
  fi
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
         echo "-refresh: force reading versions from website (default false)"
         echo -ne "\033[0m"
         echo "----"
         exit 0
    ;;
    -refresh ) refresh="true" ;;
    * ) echolog "unknwon option ${akey} with value ${avalue}" ; unknown_option ;;
  esac
}

function checkOs() {
  local platform=$(uname)
  if [[ "${platform}" == "SunOS" ]] ; then isSolaris="true" ; fi
}
function Ymd() { date +"%Y%m%d"; }
function _ldate() { date +"%Y/%m/%d-%H:%M:%S"; }
function _fdate() { date +"%Y%m%d.%H%M%S"; }
function _echod() { echo "$(_ldate) $1$2" ; }
function _echolog() { _echod "$1" "$2" | tee -a "$3"; if [[ $4 != "" ]]; then echo $4 >> "$3"; fi; }
function echolog() { _echolog "~ " "$1" "${_log}" ""; }
function _echologcmd() { _echolog "~~~ $1" "$2" "${_logs}/$3" "~~~~~~~~~~~~~~~~~~~"; }
function _log() { f=$2; rm -f "${_logs}"/l; ln -s ${f} "${_logs}"/l;rm -f "${H}"/.lastlog; sleep 1 ; ln -s "${_hlogs}/${f}" "${H}"/.lastlog; _echologcmd "" "$1" ${f} ; echolog "(see ${_logs}/${f} or simply tail -f ${_logs}/l)"; $( $1 >> "${_logs}"/${f} 2>&1 ) ; }
function log() { f=$(_fdate).$2 ; _log "$1" ${f} ; }
function loge() { echo -ne "\e[1;33m" ; f=$(_fdate).$2.log ; _log "$1" ${f} ; _echologcmd "DONE ~~~ " "$1" ${f}; echo -ne "\e[m" ; true ;}
function mrf() { ls -t1 "$1"/$2 | head -n1 ; }

function sc() {
  set +e
  set +u
  source "${H}/.bashrc" --force
  set -e
  set -u
}
function get_arc(){
  local _longbit=$1
  local unamem=$(uname -m)
  local alongbit="32"
  if [[ "${unamem//64/}" != "${unamem}" ]] ; then alongbit="64" ; fi
  eval ${_longbit}="'${alongbit}'"
}
function build_bashrc() {
  cp "${H}/.cpl/.bashrc.tpl" "${H}/.bashrc"
  export PATH="${H}/bin:${PATH}"
  "${H}/sbin/gen_sed" -i "s;@@TITLE@@;${title};g" "${H}/.bashrc"
  if [[ "${unameo}" == "Cygwin" ]] ; then
    "${H}/sbin/gen_sed" -i 's/ @@CYGWIN@@/ -DHAVE_STRSIGNAL/g' "${H}/.bashrc" ;
    "${H}/sbin/gen_sed" -i 's/ -fPIC//g' "${H}/.bashrc" ;
  else "${H}/sbin/gen_sed" -i 's/ @@CYGWIN@@//g' "${H}/.bashrc" ; fi
  if [[ "${longbit}" == "32" ]]; then "${H}/sbin/gen_sed" -i 's/ @@M64@@//g' "${H}/.bashrc" ;
  elif [[ "${longbit}" == "64" ]]; then "${H}/sbin/gen_sed" -i 's/@@M64@@/-m64/g' "${H}/.bashrc" ;
  else echolog "Unable to get LONG_BIT conf (32 or 64bits)" ; getconf2 ; fi
}

globalverinclude=""

function get_sources() {
  local name=$1
  local _namever=$2
  local _ver=$3
  echo "get_sources ${name}, _namever ${_namever}, _ver ${_ver}"
  globalverinclude=""
  if [[ -e "${H}/.cpl/fixed_versions" ]] ; then
    local aline=$(grep "#${name}#" "${H}/.cpl/fixed_versions")
    if [[ "${aline}" != "" ]] ; then
      asnamever=${aline##*#}
      asnamever=${asnamever%%~*}
      asver=${aline##*~}
      echo "fixed line: get_sources ${name}, acachenamever ${asnamever}, acachever ${asver}"
      globalverinclude="${asver}"
      get_sources_from_web ${name} asnamever asver
      echo "fixed line after get: get_sources ${name}, acachenamever ${asnamever}, acachever ${asver}"
    else
      get_sources_from_web ${name} asnamever asver
      echo "cache no line: get_sources ${name}, awebnamever ${asnamever}, awebver ${asver}"
    fi
  else
    get_sources_from_web ${name} asnamever asver
    echo "cache no cache: get_sources ${name}, awebnamever ${asnamever}, awebver ${asver}"
  fi
  update_cache "${name}" "${asnamever}" "${asver}"
  eval ${_namever}="'${asnamever}'"
  eval ${_ver}="'${asver}'"

}

function get_sources_from_web() {
  local name=$1
  local _namever=$2
  local _ver=$3
  echo "get_sources_from_web ${name}, _namever ${_namever}, _ver ${_ver}"
  local mgsd=0
  set +o nounset
  if [[ "${MGS}" == "${name}" ]]; then mgsd=1 ; fi
  set -o nounset
  echo "mgsd='${mgsd}'"
  get_param ${name} nameurl "${name}"
  get_param ${name} nameact "${nameurl}"
  get_param ${name} page ""
  get_param ${name} verexclude ""
  get_param ${name} verinclude ""
  if [[ "${globalverinclude}" != "" ]] ; then verinclude="${globalverinclude}" ; fi

  if [[ "${page}" == "none" ]] ; then eval ${_namever}="'${name}'" ; return 0 ; fi
  if [[ -e "${_pkgs}/${name}" && ! -s "${_pkgs}/${name}" ]] ; then rm "${_pkgs}/${name}" ; fi
  if [[ -e "${_pkgs}/${name}" ]] ; then
    page="${name}"
  else
    if [[ "${page#http}" == "${page}" && "${page#/}" == "${page}" && "${page}" != "l" ]] ; then 
      page=$("${H}/.cpl/scripts/${page}" ${name} ${verexclude})
    fi
  fi
  get_param ${name} ext "tar.gz"
  if [[ "${nameurl}" == "none" ]] ; then nameurl="" ; fi
  if [[ "${ext}" == "none" ]] ; then ext="" ; fi
  get_param ${name} exturl "${ext}"
  if [[ "${exturl}" == "none" ]] ; then exturl="" ; fi
  get_param ${name} extact "${ext}"
  if [[ "${page}" == "" ]] ; then
    echolog "unable to get web page for ${name} with nameact ${nameact}, nameurl ${nameurl}, verinclude ${verinclude}, verexclude ${verexclude}, ext _${ext}_, exturl _${exturl}_" ; get_sources_failed_no_page
  elif [[ "${page}" == "l" ]]; then
    local asrcline=$(ls -1 ${H}/.cpl/src/_pkgs | grep "${nameurl}-")
    if [[ ${mgsd} == 1 ]] ; then echo "D: l0 asrcline ${asrcline} from ext ${ext}" ; fi
    asrcline=${asrcline%${ext}}
    if [[ ${mgsd} == 1 ]] ; then echo "D: l asrcline ${asrcline} from ext ${ext}" ; fi
  else
    if [[ ${mgsd} == 1 ]] ; then echo "D: local asrcline wget -q -O - ${page} grep -e ${nameurl} grep ${ext}" ; fi
    local asrcline=""
    if [[ ! -e "${_pkgs}/${name}" ]] ; then
      wget -q -O "${_pkgs}/${name}" "${page}" 
    fi
    if [[ ${mgsd} == 1 ]] ; then  echo "D: local page: $(cat "${_pkgs}/${name}")" ; fi
    asrcline=$(cat "${_pkgs}/${name}"  | grep -e "${nameurl}" | grep -e "${ext}")
  fi
  
  if [[ "${verexclude}" != "" ]]; then asrcline=$(echo "${asrcline}" | egrep -v -e "${verexclude}") ; fi
  if [[ "${verinclude}" != "" ]]; then asrcline=$(echo "${asrcline}" | egrep -e "${verinclude}") ; fi
  if [[ ${mgsd} == 1 ]] ; then echo "D: line0 source! from page ${page}, nameurl ${nameurl}, ext _${ext}_, exturl _${exturl}_" ; fi
  if [[ ${mgsd} == 1 ]] ; then echo "D: line00 ${asrcline}" ; fi
  if [[ "${asrcline}" == "" ]]; then echolog "unable to get source version for ${name} with nameact ${nameact}, nameurl ${nameurl}, verinclude ${verinclude}, verexclude ${verexclude}, ext _${ext}_, exturl _${exturl}_" ; get_sources_failed ; fi
  #if [[ ${name} == "cyrus-sasl" ]] ; then echo line source! ${asrcline} ; fffg ; fi
  if [[ ${mgsd} == 1 ]] ; then echo "D: line1 source! ${asrcline}" ; fi
  local source="${asrcline%%${exturl}\"\>*}"
  if [[ ${mgsd} == 1 ]] ; then echo "D: line2 source! ${source}" ; fi
  if [[ "${source}" == "${asrcline}" ]] ; then source="${asrcline%%${exturl}\" *}" ; fi
  # "
  if [[ "${source}" == "${asrcline}" ]] ; then source="${asrcline%%${exturl}\'\>*}" ; fi
  if [[ "${source}" == "${asrcline}" ]] ; then source="${asrcline%%${exturl}\' *}" ; fi
  if [[ "${source}" == "${asrcline}" ]] ; then source="${asrcline%%${exturl}\#*}" ; fi
  if [[ "${source}" == "${asrcline}" ]] ; then source="${asrcline%%${exturl}\?*}" ; fi
  if [[ "${source}" == "${asrcline}" ]] ; then source="${asrcline%%${exturl}\"*}" ; fi
  if [[ "${source}" == "${asrcline}" ]] ; then source="${asrcline%%${exturl}:*}" ; fi
  # "
  source="${source}${exturl}"
  if [[ ${mgsd} == 1 ]] ; then echo "D: sour0 ${source}" ; fi
  local source0="${source}"
  source="${source0##*\"}"
  # "
  if [[ "${source}" == "${source0}" ]] ; then source="${source0##*\'}" ; fi
  if [[ ${mgsd} == 1 ]] ; then echo "D: source1 ${source}" ; fi
  get_param ${name} url ""
  if [[ "${url}" != "" && "${url#http}" == "${url}" ]] ; then url=$("${H}/.cpl/scripts/${url}" ${name} ${verexclude}) ; fi
  if [[ ${mgsd} == 1 ]] ; then echo "D: url0 ${url}" ; fi
  if [[ ${mgsd} == 1 ]] ; then echo "D: source ${source}" ; fi
  local targz="${source##*/}"
  local aver=""
  if [[ "${targz}" == "" ]] ; then
    aver="${source%%/*}"
  fi
  if [[ "${url}" != "" ]] ; then
    if [[ ${mgsd} == 1 ]] ; then echo "D: IIIII url ${url} AAAAA targz ${targz}" ; fi
    source="${url}${targz}"
  fi
  if [[ ${mgsd} == 1 ]] ; then echo "D: sources for ${name}: ${targz} from ${source} with aver ${aver}" ; fi
  if [[ "${exturl}" == "" ]] ; then targz="${targz}.${extact}" ; fi 
  if [[  "${nameurl}" != "${nameact}" ]] ; then targz="${nameact}-${targz#${nameurl}}" ; echo "new targz ${targz}" ; fi
  targz="${targz%-}"
  if [[ "${aver}" == "" ]] ; then
    local anamever="${targz%.${extact}}"
    aver=${anamever#${nameact}-}
    aver=${aver%-src}
  fi
  if [[ ${mgsd} == 1 ]] ; then echo "D: targz2 ${targz}" ; fi
  if [[ ${mgsd} == 1 ]] ; then echo "D: aver_b ${aver}" ; fi
  local aver_="${aver//\./_}"
  if [[ ${mgsd} == 1 ]] ; then echo "D: aver_ ${aver_}" ; fi
  source="${source//@@VER@@/${aver}}"
  source="${source//@@VER_@@/${aver_}}"
  targz="${targz//@@VER@@/${aver}}"
  targz="${targz//@@VER_@@/${aver_}}"
  if [[ ${mgsd} == 1 ]] ; then echo "D: source ${source}, with targz ${targz}" ; fi
  local anamever="${targz%.${extact}}"
  local ss="xx"
  if [[ -e "${_pkgs}/${targz}" ]] ; then ss=$(stat -c%s "${_pkgs}/${targz}") ; fi
  if [[ -e "${_pkgs}/${targz}" ]] && [[ "${ss}" == "0" ]] ; then
    rm -f "${_pkgs}/${targz}"
  fi
  if [[ ${mgsd} == 1 ]] ; then echo "D: YYY anamever ${anamever} vs. name ${name} and nameact ${nameact}" ; fi
  if [[ "${aver}" == "" ]] ; then
    aver=${anamever#${nameact}-}
    aver=${aver%-src}
  fi
  if [[ ${mgsd} == 1 ]] ; then echo "D: get sources final: anamever ${anamever}, aver ${aver}" ; fi
  if [[ "${aver}" == "${anamever}" ]] ; then aver=${anamever#${nameact}} ; fi
  ver=${ver##*~}
  if [[ ${mgsd} == 1 ]] ; then echo "D: get sources final2: anamever ${anamever}, aver ${aver} for source ${source}" ; fi
  source=${source//@@VER@@/${aver}}
  if [[ "${nameurl}" == "master" ]] ; then
    source=${source%/*}/master
    targz="${name}-master.tar.gz"
    anamever="${name}-master"
	aver="master"
  fi
  if [[ ${mgsd} == 1 ]] ; then echo "D: get sources final2: anamever ${anamever}, aver ${aver} for source ${source}" ; fi
  if [[ ! -e "${_pkgs}/${targz}" ]] && [[ ! -e "${HUL}/._linked/${anamever}" ]]; then
    echolog "get sources for ${name} in ${_hpkgs}/${targz}"
    loge "wget ${source} -O ${_pkgs}/${targz}" "wget_sources_${targz}"
  fi
  update_cache "${name}" "${anamever}" "${aver}"
  echo "get_sources_from_web RES ${name}, anamever ${anamever}, aver ${aver}"
  eval ${_namever}="'${anamever}'"
  eval ${_ver}="'${aver}'"
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
      get_sources ${name} acachenamever acachever
      # echo "cache no line: get_sources ${name}, acachenamever ${acache}${namever}, acachever ${acachever}"
    fi
  else
    get_sources ${name} acachenamever acachever
    # echo "cache no cache: get_sources ${name}, cache${namever} ${acache}${namever}, acachever ${acachever}"
  fi
  # echo "get_sources_from_cache cache${namever} ${acachenamever}, acachever ${acachever}"
  eval ${_namever}="'${acachenamever}'"
  eval ${_ver}="'${acachever}'"
}

function update_cache() {
  local name=$1
  local anamever=$2
  local aver=$3
  local aline="#${name}#${anamever}~${aver}"
  if [[ -e "${H}/.cpl/cache" ]] ; then
    local anExistingline=$(grep "#${name}#" "${H}/.cpl/cache")
    if [[ "${anExistingline}" != "" ]] ; then
      gen_sed -i "s/^#${name}#.*$/${aline}/g" "${H}/.cpl/cache"
    else
      $(echo "${aline}" >> "${H}/.cpl/cache")
    fi
  else
    $(echo "${aline}" > "${H}/.cpl/cache")
  fi
}

function gen_which()
{
  local acmd="$1"
  local _res="$2"
  if [[ "${isSolaris}" == true ]] ; then
    
    local ares=$(which "${acmd}" 2> /dev/null | tail -1)
  else
    local ares=$(which "${acmd}" 2> /dev/null)
  fi
  if [[ "${ares}" == "" ]] ; then 
    if [[ -e "${acmd}" ]] ; then ares="${acmd}" ; fi
    if [[ -e "/usr/sbin/${acmd}" ]] ; then ares="/usr/sbin/${acmd}" ; fi
  fi
  eval ${_res}="'${ares}'"
}
function get_tar() {
  local _tarname=$1
  local atarname=""
  get_param ${name} ext "tar.gz"
  get_param ${name} extact "${ext}"
  gen_which "gtar" gtarpath
  gen_which "tar" tarpath
  if [[ "${gtarpath}" != "" ]] ; then atarname="gtar xpvf";
  elif [[ "${tarpath}" != "" ]]; then
    local h=$(tar --help|grep GNU)
    if [[ "${H}" != "" ]]; then atarname="tar xpvf"; else atarname="tar -xv -f" ; fi;
  fi
  if [[ "${atarname}" == "" ]] ; then echolog "Unable to find a GNU tar or gtar" ; tar2 ; fi
  if [[ "${extact}" == "zip" ]] ; then
    gen_which "unzip" unzippath
    if [[ "${unzippath}" != "" ]] ; then atarname="unzip"; fi
    if [[ "${atarname}" == "" ]] ; then echolog "Unable to find unzip" ; unzip2 ; fi
  fi
  eval ${_tarname}="'${atarname}'";
}
function rmIfNeeded() {
  removing=false
  # echo "D: rmIfNeeded namever='${namever}'"
  if [[ -e "${_src}/${namever}/.lck" ]]; then
    local lock=$(cat "${_src}/${namever}/.lck")
    if [[ "${lock}" != "${H}" ]] ; then
      echolog "${_src}/${namever}/.lck for '${lock}' instead of '${H}'" ; get_source_lock_failed 
    fi
  fi
  if [[ -e "${_src}/${namever}/.cmp" ]]; then
    local cmp=$(cat "${_src}/${namever}/.cmp")
    if [[ "${cmp}" != "${H}" ]] ; then
      echolog "${_src}/${namever}/.cmp for '${cmp}' instead of '${H}': Removing"
      removing=true
    fi
  else
    echolog "${_src}/${namever} for unknown home: Removing"
    removing=true
  fi
  if [[ "${removing}" == "true" ]] ; then
    set +e
    rmdst="${_src}/"$(readlink "${_src}/${namever}")
    set -e
    if [[ "${rmdst}" == "${_src}/" ]] ; then rmdst="${_src}/${namever}" ; fi
    # echo "D: rm -Rf ${rmdst}"
    rm -Rf "${rmdst}"
    rm -f "${_src}/${namever}"
    rm -f "${_src}/${name}"
    if [[ "${type}" == "MOD" ]] ; then
      mkdir "${_src}/${namever}"
      echo "${H}" > "${_src}/${namever}/.cmp"
      echo "${H}" > "${_src}/${namever}/.lck"
    fi
  fi
}
function untar() {
  local name=$1
  local namever=$2
  if [[ -d "${_src}/${namever}" || -h "${_src}/${namever}" ]]; then
    rmIfNeeded
  fi
  if [[ ! -e "${_src}/${namever}" ]]; then
    get_tar tarname
    get_param ${name} ext "tar.gz"
    get_param ${name} extact "${ext}"
    local dirext="-C"
    if [[ "${extact}" == "zip" ]] ; then dirext="-d" ; fi
    loge "${tarname} ${_pkgs}/${namever}.${extact} ${dirext} ${_src}" "tar_xpvf_namever.${extact}"
    # loge "echo ${tarname} ${_pkgs}/${namever}.${extact} ${dirext} ${_src}" "tar_xpvf_namever.${extact}" # TOCOMMENT
    local lastlog=$(mrf "${_logs}" "*tar_xpvf*")
    local actualname=$(head -3 "${lastlog}"|tail -1)
    #echo "anactualname=${anactualname}";
    actualname=${actualname%%/*}
    if [[ "${actualname%%Archive*}" != "${actualname}" ]] ; then
      echo ok
      actualname=$(head -5 "${lastlog}"|tail -1)
      actualname=${actualname%/*}
      actualname=${actualname##*/}
    fi
    local anactualname=${actualname}
    # echo "namever ${namever} actualver %/* ${anactualname%/*} actualname%%/* ${anactualname%%/*}, actualname#*/ ${anactualname#*/}, actualname##*/ ${anactualname##*/}"
    if [[ "${namever}" != "${actualname}" ]] ; then
      echolog "ln to ido: ln -fs ${actualname} ${_src}/${namever}"
      # TOCOMMENT
      ln -fs "${actualname}" "${_src}/${namever}"
    fi
    # echo "D: ln -fs '${namever} ${_src}/${name}'"
    # mkdir -p "${_src}/${namever}" # TOCOMMENT
    ln -fs "${namever}" "${_src}/${name}"
    # echo "D: ${H} > ${_src}/${namever}/.cmp"
    echo "${H}" > "${_src}/${namever}/.cmp"
    echo "${H}" > "${_src}/${namever}/.lck"
  fi
  ln -fs "${namever}" "${_src}/${name}"
}
function getusername() {
  local _username=$1
  local _ausername=$(id) ; _ausername=${_ausername%%)*} ; _ausername=${_ausername##*(}
  eval ${_username}="'${_ausername}'"
}
function getusergroup() {
  local _usergroup=$1
  local _ausergroup=$(id) ; _ausergroup=${_ausergroup#*(} ; _ausergroup=${_ausergroup#*(} ; _ausergroup=${_ausergroup%%)*}
  eval ${_usergroup}="'${_ausergroup}'"
}

source "${H}/.cpl/scripts/get_param.sh"

function get_gnu_cmd() {
  local acmd=$1
  local _path=$2
  local _without_gnu_cmd=$3
  local _with_gnu_cmd=$4
  gen_which "${acmd}" apath
  apath=${apath/\/\///}
  if [[ "${apath}" == "" ]] ; then echolog "Unable to find a ${acmd}" ; cmd_not_found ; fi
  eval ${_path}="'${apath}'"
  local without_gnu_cmd="" ; local with_gnu_cmd=""
  if [[ ${apath#/usr/ccs*} != "${apath}" ]]; then without_gnu_cmd="--without-gnu-${acmd}"; else with_gnu_cmd="--with-gnu-${acmd}"; fi
  eval ${_without_gnu_cmd}="'${without_gnu_cmd}'"
  eval ${_with_gnu_cmd}="'${with_gnu_cmd}'"
}
function configure() {
  local name=$1
  local namever=$2
  get_param ${name} makefile Makefile
  local makefileExist=false
  if [[ -e "${_src}/${namever}/${makefile}" || "${makefile}" == "none" ]] ; then makefileExist=true ; fi
  # echo "makefileExist ${makefileExist}"
  # if [[ "${makefileExist}" == "false" ]] ; then echo "ee" ; fi
  if [[ "${name}" != "${namever}" ]] && [[ ! -e "${_src}/${namever}/._config" || "${makefileExist}" == "false" ]]; then
    local haspre="false"; if [[ -e "${_src}/${namever}/._pre" ]] ; then haspre=true ; fi
    rm -f "${_src}/${namever}"/._*
    if [[ "${haspre}" == "true" ]] ; then echo "done" > "${_src}/${namever}/._pre" ; fi
    echo "done" > "${_src}/${namever}"/._pre
    #pwd
    get_param ${name} configcmd "##mandatory##"
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
      if [[ "${longbit}" == "64" ]] ; then 
        configcmd=${configcmd/@@ENABLE_64BIT@@/--enable-64bit} ;
        configcmd=${configcmd/@@3264@@/64} ;
      else 
        configcmd=${configcmd/@@ENABLE_64BIT@@/} ; 
        configcmd=${configcmd/@@3264@@/32} ;
      fi
      # echo "D: configcmd=${configcmd}"
      if [[ "${configcmd#@@}" != "${configcmd}" ]] ; then
        configcmd="${configcmd#@@}"
        echo "${configcmd}" > ./configurecmd
        chmod 755 ./configurecmd
        configcmd="./configurecmd"
      fi
      #pwd
      loge "${configcmd}" "configure_${namever}"
      #loge "echo ${configcmd}" "configure_${namever}" # TOCOMMENT
    fi
  fi
  echo "done" > "${_src}/${namever}/._config"
}

source "${H}/.cpl/scripts/links.sh"

function action() {
  local name=$1
  local namever=$2
  local actionname=$3
  local actionpath=$4
  local actionstep=$5
  local actiondefault="$6"
  # echo "actionname='${actionname}', actionpath='${actionpath}', actionstep='${actionstep}'" 
  if [[ ! -e "${actionpath}/._${actionstep}" ]]; then
     get_param ${name} ${actionname} "${actiondefault}"
     local actioncmd=${!actionname}
     actioncmd=${actioncmd//@@VER@@/${ver}}
     if [[ "${actioncmd}" != "none" ]] && [[ "${actioncmd}" != "" ]] ; then 
       #if [[ "${name}" == "perl" && "${actionname}" == "pre" ]] ; then echo eval xx ${actioncmd} xx ; fi
       #echo actioname ${actionname} gives actioncmd ${actioncmd}; eee
       if [[ "${actioncmd#@@}" != "${actioncmd}" ]] ; then
       # if [[ "${actioncmd#@@}" == "${actioncmd}" ]] ; then # TOCOMMENT
         actioncmd="${actioncmd#@@}"
         # TOCOMMENT 
         echo "set -o errexit" > "./${actionname}"
         echo "${actioncmd}" >> "./${actionname}"
         # TOCOMMENT 
         chmod 755 "./${actionname}"
         actioncmd="./${actionname}"
       fi
       #echo pre ${pre} ; jj
       loge "eval ${actioncmd}" "${actionname}_${namever}"
       # loge "echo ${actioncmd}" "${actionname}_${namever}" # TOCOMMENT
     fi
     # pwd
     # echo "done > ${actionpath}/._${actionstep}"
     echo done > "${actionpath}/._${actionstep}"
     # ls -alrt "${actionpath}/._${actionstep}"
     #if [[ "${name}" == "perl" && "${actionname}" == "pre" ]] ; then echo "---- done" ; eee ; fi
  fi    
}
function isItDone() {
  local name="$1"
  local _isdone="$2"
  local aafrom="$3"
  local aisdone="false"
  # echo "D: isitdone name '${name}' from '${aafrom}': donelist '${donelist}'"
  if [[ "${donelist%@${name}@*}" != "${donelist}" ]] ; then aisdone="true" ; fi
  eval ${_isdone}="'${aisdone}'"
}
function gocd() {
  local name=$1
  local namever=$2
  get_param ${name} cdpath "${_src}/${namever}"
  cdpath=$(eval echo "${cdpath}")
  echolog "cd ${cdpath}"
  # TOCOMMENT
  cd "${cdpath}"
}

function build_item() {
  local name="$1"
  local type="$2"
  local afrom="$3"
  #echo '${type} ${donelist}' "${name} : ${donelist}"
  local isdone="false" ; isItDone "${name}" isdone ${afrom}
  if [[ "${isdone}" == "false" ]] ; then echo -ne "\e[1;34m" ; echolog "##### Building ${type} ${name} ####" ; echo -ne "\e[m" ; fi
  if [[ "${type}" != "MOD" ]] ; then
    if [[ "${refresh}" == "true" ]] ; then
      get_sources ${name} namever ver
      # echo "get_sources ${name}, namever ${namever}, ver ${ver}"
    else
      get_sources_from_cache ${name} namever ver
      # echo "get_sources_from_cache ${name}, namever ${namever}, ver ${ver}"
    fi
  else
    namever="${name}"
    ver=""
  fi
  # ver=${${namever}#${name}-}
  #echo "XXX ver ${ver}, namever ${namever} name ${name}"
  if [[ -e "${HUL}/._linked/${namever}" ]]; then
    if [[ "${isdone}" == "false" ]] ; then
      echo -ne "\e[1;32m" ; echolog "${type} ${namever} already installed" ; echo -ne "\e[m" ;
      donelist="${donelist}@${name}@" ;
    fi
    if [[ ! -e "${HULA}/${name}" && -e "${HULA}/${namever}" ]] ; then ln -fs "${namever}" "${HULA}/${name}" ; fi
    if [[ -h "${HULA}/${name}/${namever}" ]] ; then rm -f "${HULA}/${name}/${namever}" ; fi
    if [[ -h "${HULA}/${name}" && ! -e "${HULA}/${namever}" ]] ; then rm -f "${HULA}/${name}" ; fi
  else
    local asrc="${_src}/${namever}"
    if [[ "${type}" == "MOD" ]] ; then mkdir -p "${asrc}" ; fi
    sc
    if [[ "${type}" != "MOD" ]] ; then untar ${name} ${namever} ; else
      # echo "D: MOD namever='${namever}'"
      rmIfNeeded
    fi
    action ${name} ${namever} precond "${asrc}" precond "none"
    gocd ${name} ${namever}
    action ${name} ${namever} pre "${asrc}" pre "none"
    configure ${name} ${namever}
    action ${name} ${namever} premake "${asrc}" premake "none"
    action ${name} ${namever} makecmd "${asrc}" build "make"
    action ${name} ${namever} makeinstcmd "${asrc}" installed  "make install"
    action ${name} ${namever} post "${asrc}" post "none"
    if [[ "${type}" != "MOD" ]] ; then
      if [[ "${type}" == "APP" ]] ; then linksrcdef="${HULA}/${namever}/bin" ; linkdstdef="${H}/bin" ; fi
      if [[ "${type}" == "LIB" ]] ; then linksrcdef="${HULS}/${namever}" ; linkdstdef="${HUL}" ; fi
      get_param ${name} linksrc ${linksrcdef}; linksrc=$(echo "${linksrc}") ; # echo "linksrc ${linksrc}"
      get_param ${name} linkdst ${linkdstdef}; linkdst=$(echo "${linkdst}") ; # echo "linkdst ${linkdst}"
    fi
    if [[ "${type}" == "APP" && ! -e "${HULA}/${name}" ]] ; then  ln -fs "${namever}" "${HULA}/${name}" ; fi
    if [[ "${type}" == "LIB" && ! -e "${HULS}/${name}" ]] ; then  ln -fs "${namever}" "${HULS}/${name}" ; fi
    if [[ ! -e "${HUL}"/._linked/${namever} ]] ; then
      if [[ "${type}" != "MOD" ]] ; then 
        if [[ ! -e "${asrc}/._links" ]] ; then
          echolog "checking links of ${type} ${namever}"; links "${linkdst}" "${linksrc}" true; 
          if [[ "${type}" == "APP" ]] ; then 
            local l=$(ls "${HULA}/${namever}"/lib/*.so 2>/dev/null)
            local l64=$(ls "${HULA}/${namever}"/lib64/*.so 2>/dev/null)
            if [[ "${l}" != "" ]] ; then 
              echolog "checking links lib of ${type} ${namever}"; links "${HULL}" "${HULA}/${namever}/lib" true;
            fi
            if [[ "${l64}" != "" ]] ; then 
              echolog "checking links lib64 of ${type} ${namever}"; links "${HULL}" "${HULA}/${namever}/lib64" true;
            fi
            local lsb=$(ls "${HULA}/${namever}"/sbin/* 2>/dev/null)
            if [[ "${lsb}" != "" ]] ; then 
              echolog "checking links sbin of ${type} ${namever}"; links "${H}/bin" "${HULA}/${namever}/sbin" true;
            fi
          fi
          echo "done" > "${asrc}/._links"
        fi
        action ${name} ${namever} postcheck "${asrc}" postcheck "none"
      fi
      echo done > "${HUL}"/._linked/${namever} ;
    fi
    rm -f "${_src}/${namever}/.lck"
    if [[ "${type}" == "LIB" && ! -e "${HULS}/${namever}" ]] ; then  rm -f "${HULS}/${name}" ; fi
    if [[ "${type}" == "APP" || "${type}" == "LIB" ]] ; then
      set +e
      tldd "${name}"
      local atlddres="$?"
      set -e
      if [[ "${atlddres}" != "0" ]] ; then  echolog "${namever} has improper libs" ; reset_compil "${name}" ; tldd_failed ; fi
    fi
    donelist="${donelist}@${name}@"
    # echo "D: build_tem: donelist: '${donelist}'"
  fi
}

function build_line() {
  local line="$1"
  local lineori="$1"
  # echo "D: build_line line '${line}'"
  set -- junk ${line} ; shift
  local type=$1; local name=$2 ; local deps=${3//,/ }
  isItDone "${name}" aaisdone "${lineori}"
  if [[ "${aaisdone}" == "false" && "${glastline}" != "stop" ]] ; then
    # echo "D: build_line not done: deps '${deps}' for '${name}' with '${type}'"
    declare -a Array=(${deps})
    for adep in "${Array[@]}"; do
      # echo "D: build_line adep '${adep}' for '${name}' with '${type}'"
      if [[ "${adep}" != "none" && "${glastline}" != "stop" ]]; then
        adepline=$(egrep -e "((app|lib|mod) ${adep})|__no_deps__" "${_deps}")
        # echo "D: build_line: dep line: '${adepline}'"
        if [[ "${adepline}" == "__no_deps__" ]] ; then echolog "unable to find dependencies of ${adep}"; nodepfound ; fi
        adepline=$(echo "${adepline}" | egrep -e "${adep}")
        # echo "D: build_line: dep line2: '${adepline}'"
        build_line "${adepline}"
        if [[ "${gstopat}" != "" ]] ; then
          alinename=${adepline#* }
          alinename=${alinename%% *}
          # echo "alinenamedep='${alinename}'"
          if [[ "${gstopat}" == "${alinename}" ]] ; then
            glastline="stop"
            gline="__no_deps__"
          fi
        fi
      fi
    done
    # echo "D: build_line: done deps from ${name} with ${type}, now building '${name}'"
    if [[ "${glastline}" != "stop" ]] ; then
      if [[ ${type} == "app" ]] && [[ ${name} == "jdk" ]]; then getJDK "${lineori}";
      elif [[ ${type} == "app" ]]; then build_item "${name}" "APP" "${lineori}";
      elif [[ ${type} == "lib" ]] ; then build_item  "${name}" "LIB" "${lineori}";
      elif [[ ${type} == "mod" ]] ; then build_item "${name}" "MOD" "${lineori}"
      else echo "unknow type" ; exit 1 ; fi
      # echo "D: build_line: done building '${name}'"
    fi
    if [[ "${gstopat}" != "" ]] ; then
      alinename=${lineori#* }
      alinename=${alinename%% *}
      # echo "alinenameLINE='${alinename}'"
      if [[ "${gstopat}" == "${alinename}" ]] ; then
        glastline="stop"
        gline="__no_deps__"
      fi
    fi
  fi
}

while [[ "${gline}" != "__no_deps__" && "${gline}" != "${glastline}" && "${glastline}" != "stop" ]] ; do 
  if [[ "${gline}" == "_" ]] ; then gline="" ; fi
  # echo "D: before main gline='${gline}', glastline='${glastline}'"
  main $*
  # echo "D: after main gline='${gline}', glastline='${glastline}'"
done

trap - EXIT
echo -e "\e[00;32mAll Done.\e[00m"
exit 0
