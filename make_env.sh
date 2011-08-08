#!/bin/bash

function scriptpath() {
  local _sp=$1
  local ascript="$0"
  local asp="$(dirname $0)"
  if [[ "$asp" == "." ]] ; then asp=$(pwd) ;
  else
    echo "asp '$asp', ascript '$ascript'"
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
echo $H
mkdir -p "${_logs}"
mkdir -p "${_pkgs}"
mkdir -p "$H"/bin
mkdir -p "$H"/usr/local/._linked
if [[ -e "$H/README.md" ]] ; then mv -f "$H/README.md" "$H/.README.md" ; fi
ln -fs ${_hlog} "$H/.log"
donelist=""
namever=""
ver=""

set -o errexit
set -o nounset

trap "echo -e "\\\\e\\\[00\\\;31m!!!!_FAIL_!!!!\\\\e\\\[00m" | tee -a "${_log}"; tail -3 "${_log}" ; if [[ -e "${_logs}"/l ]]; then tail -5 "${_logs}"/l; rm "${_logs}"/l; fi" EXIT ;

function main {
  checkOs
  if [[ -e "$H/.bashrc_aliases_git" ]] ; then cp "$H/.cpl/.bashrc_aliases_git.tpl" "$H/.bashrc_aliases_git" ; fi
  if [[ ! -e "$H/.bashrc" ]]; then
    if [[ $# != 1 ]] ; then echolog "When there is no .bashrc, make_env.sh needs a title for that .bashrc as first parameter. Not needed after that" ; miss_bashrc_title ; fi  
    build_bashrc "$1"
  fi
  sc
  if [[ ! -e "${_vers}" ]]; then
    echolog "#### VERS ####"
    echolog "download compatible versions from SunFreeware"
    loge "wget http://sunfreeware.com/programlistsparc10.html -O ${_vers}$(Ymd)" "wget_vers_sunfreeware"
    log "ln -fs ${_vers}$(Ymd) ${_vers}" ln_vers
  fi
  cat "${_deps}" | while read line; do
    #echo $line
    if [[ "$line" != "__no_deps__" ]] ; then
      build_line "$line"
    fi
  done
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
function _log() { f=$2; rm -f "${_logs}"/l; ln -s $f "${_logs}"/l;rm -f "${H}"/.lastlog; ln -s "${_hlogs}/$f" "${H}"/.lastlog; _echologcmd "" "$1" $f ; echolog "(see ${_logs}/$f or simply tail -f ${_logs}/l)"; $( $1 >> "${_logs}"/$f 2>&1 ) ; }
function log() { f=$(_fdate).$2 ; _log "$1" $f ; }
function loge() { echo -ne "\e[1;33m" ; f=$(_fdate).$2.log ; _log "$1" $f ; _echologcmd "DONE ~~~ " "$1" $f; echo -ne "\e[m" ; true ;}
function mrf() { ls -t1 "$1"/$2 | head -n1 ; }

function sc() {
  source "$H/.bashrc" -force
}
function get_arc(){
  local _longbit=$1
  local unamem=$(uname -m)
  local alongbit="32"
  if [[ "${unamem//64/}" != "${unamem}" ]] ; then alongbit="64" ; fi
  eval $_longbit="'${alongbit}'"
}
function build_bashrc() {
  local title="$1"
  cp "$H/.cpl/.bashrc.tpl" "$H/.bashrc"
  export PATH=$H/bin:$PATH
  $H/bin/gen_sed -i "s/@@TITLE@@/${title}/g" "$H/.bashrc"
  get_arc longbit
  if [[ "$longbit" == "32" ]]; then $H/bin/gen_sed -i 's/ @@M64@@//g' "$H/.bashrc" ;
  elif [[ "$longbit" == "64" ]]; then $H/bin/gen_sed -i 's/@@M64@@/-m64/g' "$H/.bashrc" ;
  else echolog "Unable to get LONG_BIT conf (32 or 64bits)" ; getconf2 ; fi
}
function get_sources() {
  local name=$1
  local _namever=$2
  local _ver=$3
  get_param $name nameurl "${name}"
  get_param $name page "${_vers}"  
  if [[ "$page" == "none" ]] ; then eval $_namever="'${name}'" ; return 0 ; fi
  get_param $name ext "tar.gz"  
  if [[ -e "${page}" ]] ; then
    local asrcline=$(grep " ${nameurl}-" "${_vers}"|grep "Source Code")
  else
    local asrcline=$(wget -q -O - "${page}" | grep "${nameurl}" | grep "${ext}") 
  fi
  #echo "line0 source! $asrcline"
  get_param $name verexclude ""
  if [[ "${verexclude}" != "" ]]; then asrcline=$(echo "${asrcline}" | egrep -v -e "${verexclude}") ; fi
  get_param $name verinclude ""
  if [[ "${verinclude}" != "" ]]; then asrcline=$(echo "${asrcline}" | egrep -e "${verinclude}") ; fi
  #if [[ "${asrcline}" == "" ]]; then echolog "unable to get source version for ${name} with nameurl ${nameurl}, verinclude ${verinclude}, verexclude ${verexclude}" ; get_sources_failed ; fi
  #if [[ $name == "cyrus-sasl" ]] ; then echo line source! $asrcline ; fffg ; fi
  #echo "line1 source! $asrcline"
  local source="${asrcline%%${ext}\"\>*}"
  #echo "source0 ${source} vs. ${asrcline}"
  if [[ "${source}" == "${asrcline}" ]] ; then
    source="${asrcline%%${ext}\" *}" ; #"
    #echo "source00 ${source} vs. ${asrcline}"
  fi
  source="${source}${ext}"
  # echo "source0 ${source}"
  source="${source##*\"}"
  # echo "source1 ${source}"
  get_param $name url ""
  #echo "url0 ${url}"
  local targz=${source##*/}
  if [[ "$url" != "" ]] ; then
    #echo "IIIII url ${url} AAAAA targz ${targz}"
    source="${url}${targz}"
  fi
  #echo sources for $name: $targz from $source from $line
  if [[ ! -e "${_pkgs}/$targz" ]]; then
    echolog "get sources for $name in ${_hpkgs}/$targz"
    loge "wget $source -O ${_pkgs}/$targz" "wget_sources_$targz"
  fi
  local anamever="${targz%.${ext}}"
  eval $_namever="'${anamever}'"
  #echo "YYY anamever ${anamever} vs. name ${name}"
  local aver=${anamever#${nameurl}-}
  eval $_ver="'${aver}'"
}
function gen_which()
{
  local acmd="$1"
  local _res="$2"
  if [[ "$isSolaris" == true ]] ; then
    local ares=$(which "${acmd}" | tail -1)
  else
    local ares=$(which "${acmd}")
  fi
  eval $_res="'${ares}'"
}
function get_tar() {
  local _tarname=$1
  local atarname=""
  gen_which "gtar" gtarpath
  gen_which "tar" tarpath
  if [[ "${gtarpath}" != "" ]] ; then atarname="gtar xpvf";
  elif [[ "${tarpath}" != "" ]]; then
    local h=$(tar --help|grep GNU)
    if [[ "$h" != "" ]]; then atarname="tar xpvf"; else atarname="tar -xv -f" ; fi;
  fi
  if [[ "${atarname}" == "" ]] ; then echolog "Unable to find a GNU tar or gtar" ; tar2 ; fi
  eval $_tarname="'$atarname'";
}
function untar() {
  local name=$1
  local namever=$2
  if [[ ! -e "${_src}/$namever" ]]; then
    get_tar tarname
    get_param $name ext "tar.gz"  
    loge "${tarname} ${_pkgs}/$namever.${ext} -C ${_src}" "tar_xpvf_$namever.${ext}"
    local lastlog=$(mrf "${_logs}" "*tar_xpvf*")
    local actualname=$(head -3 "$lastlog"|tail -1)
    local anactualname=${actualname}
    #echo "anactualname=${anactualname}";
    actualname=${actualname%%/*}
    #echo "namever ${namever} actualver %/* ${anactualname%/*} actualname%%/* ${anactualname%%/*}, actualname#*/ ${anactualname#*/}, actualname##*/ ${anactualname##*/}"
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
  #echo "name $name, _param $_param, default $default, namever='${namever}', ver='${ver}'"
  if [[ ! -e "$H/.cpl/params/$name" ]] ; then echolog "unable to find param for $name" ; no_param ; fi
  local aparam=$(grep "$_param=" "$H/.cpl/params/$name"|head -1)
  if [[ "$aparam" != "" && "${aparam##$_param=}" != "$aparam" ]] ; then 
    aparam=${aparam##$_param=}
  else aparam="" ; fi
  if [[ "$aparam" == "" ]]; then aparam="$default" ; fi
  if [[ "$aparam" == "none" ]] ; then eval $_param="'$aparam'" ; return 0 ; fi
  if [[ "$aparam" == "##mandatory##" ]]; then echolog "unable to find $_param for $name" ; find2 ; fi
  aparam=${aparam//@@NAMEVER@@/${namever}}
  aparam=${aparam//@@VER@@/${ver}}
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
  if [[ "${name}" != "${namever}" ]] && [[ ! -e $makefile || ! -e ._config ]]; then
    local haspre="false"; if [[ -e "${_src}/${namever}/._pre" ]] ; then haspre=true ; fi
    rm -f "${_src}/${namever}"/._*
    if [[ "$haspre" == "true" ]] ; then echo "done" > "${_src}/${namever}/._pre" ; fi
    echo "done" > "${_src}/${namever}"/._pre
    #pwd
    get_param $name configcmd "##mandatory##"
    #echo "configcmd=${configcmd}"
    if [[ "${configcmd}" != "none" ]] ; then
      get_gnu_cmd ld path_ld without_gnu_ld with_gnu_ld
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
  echo "done" > ._config
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
  if [[ "${unameo}" == "Cygwin" && "${apath%/bin}" == "bin" && "${afile%.dll}" != "${afile}" ]] ; then
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
  cd "$src"
  find . -type f -print | while read line; do
    # echo check $line
    onelink "$dest" "$src" "$line"
  done
  find . -type l -print | while read line; do
    # echo check $line
    onelink "$dest" "$src" "$line"
  done
}
function action() {
  local name=$1
  local namever=$2
  local actionname=$3
  local actionpath=$4
  if [[ ! -e "${actionpath}/._${actionname}" ]]; then
     get_param $name ${actionname} ""
     local actioncmd=${!actionname}
     #if [[ "$name" == "perl" && "$actionname" == "pre" ]] ; then echo eval xx ${actioncmd} xx ; fi
     #echo actioname ${actionname} gives actioncmd ${actioncmd}; eee
     if [[ $actioncmd != "" ]]; then
       #echo pre $pre ; jj
       loge "eval ${actioncmd}" "${actionname}_${namever}"
     fi
     echo done > "${actionpath}/._${actionname}"
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
    get_sources $name namever ver
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
    if [[ "$type" == "APP" && ! -e "${HULA}/${name}" ]] ; then  ln -fs "${namever}" "${HULA}/${name}" ; fi
  else
    local asrc="${_src}/${namever}"
    if [[ "${type}" == "MOD" ]] ; then mkdir -p "${asrc}" ; fi
    sc
    if [[ "${type}" != "MOD" ]] ; then untar $name $namever ; fi
    action $name $namever precond "${asrc}"
    gocd $name $namever
    action $name $namever pre "${asrc}"
    configure $name $namever
    action $name $namever premake "${asrc}"
    if [[ ! -e "${asrc}"/._build ]] ; then
      get_param $name makecmd "make" ;
      if [[ "${makecmd}" != "none" ]] ; then loge "eval ${makecmd}" "make_$namever"; fi
      echo done > "${asrc}"/._build
    fi
    if [[ ! -e "${asrc}"/._installed ]] ; then
      get_param $name makeinstcmd "make install"
      echo "makeinstcmd ${makeinstcmd}"
      if [[ "${makeinstcmd}" != "none" ]] ; then loge "eval ${makeinstcmd}" "make_install_$namever"; fi
      echo done > "${asrc}"/._installed
    fi
    action $name $namever post "${asrc}"
    if [[ "${type}" != "MOD" ]] ; then
      if [[ "$type" == "APP" ]] ; then linksrcdef="$HULA/$namever/bin" ; linkdstdef="$H/bin" ; fi
      if [[ "$type" == "LIB" ]] ; then linksrcdef="$HULS/$namever" ; linkdstdef="$HUL" ; fi
      get_param $name linksrc $linksrcdef; linksrc=$(echo "${linksrc}") ; # echo "linksrc ${linksrc}"
      get_param $name linkdst $linkdstdef; linkdst=$(echo "${linkdst}") ; # echo "linkdst ${linkdst}"
    fi
    if [[ ! -e "${HUL}"/._linked/$namever ]] ; then
      if [[ "${type}" != "MOD" ]] ; then echolog "checking links of $type $namever"; links "$linkdst" "$linksrc" ; fi
      echo done > "${HUL}"/._linked/$namever ;
    fi
    if [[ "$type" == "APP" && ! -e "${HULA}/${name}" ]] ; then  ln -fs "${namever}" "${HULA}/${name}" ; fi
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
    if [[ $type == "app" ]]; then build_item "$name" "APP" "$lineori";
    elif [[ $type == "lib" ]] ; then build_item  "$name" "LIB" "$lineori";
    elif [[ $type == "mod" ]] ; then build_item "$name" "MOD" "$lineori"
    else echo "unknow type" ; exit 1 ; fi
  fi
}

main $*
trap - EXIT
echo -e "\e[00;32mAll Done.\e[00m"
exit 0
