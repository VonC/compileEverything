#!/bin/bash
scriptPath=`pwd`
sp="$scriptPath"
echo $scriptPath
DIR="$( basename `pwd` )"
echo $DIR
#d=`date +"%Y%m%d"`
#echo $d
mkdir -p bin
mkdir -p logs
mkdir -p src/_pkgs
mkdir -p usr/local/._linked
#scriptPath=${0%/*}
donelist=""

set -o errexit
set -o nounset

function Ymd() { date +"%Y%m%d"; }
function _ldate() { date +"%Y/%M/%d-%H:%M:%S"; }
function _fdate() { date +"%Y%m%d.%H%M%S"; }
function _echod() { echo "$(_ldate) $1$2" ; }
function _echolog() { _echod "$1" "$2" | tee -a "$3"; if [[ $4 != "" ]]; then echo $4 >> "$3"; fi; }
function echolog() { _echolog "~ " "$1" "$sp/log" ""; }
function _echologcmd() { _echolog "~~~ $1" "$2" "$sp/logs/$3" "~~~~~~~~~~~~~~~~~~~"; }
function _log() { f=$2; rm -f "$sp"/logs/l; ln -s $f "$sp"/logs/l; _echologcmd "" "$1" $f ; $( $1 >> "$sp"/logs/$f 2>&1 ) ; }
function log() { f=$(_fdate).$2 ; _log "$1" $f ; }
function loge() { f=$(_fdate).$2.log ; echolog "(see logs/$f or simply tail -f logs/l)"; _log "$1" $f ; _echologcmd "DONE ~~~ " "$1" $f; true ; }
function mrf() { ls -t1 $1 | head -n1 ; }

trap "echo -e "\\\\e\\\[00\\\;31m!!!!_FAIL_!!!!\\\\e\\\[00m" | tee -a "$sp"/log; tail -3 "$sp"/log ; if [[ -e "$sp"/logs/l ]]; then tail -5 "$sp"/logs/l; rm "$sp"/logs/l; fi" EXIT ;

function sc() {
  source "$scriptPath/.bashrc" -force
}
function build_bashrc() {
  local title="$1"
  cp _cpl/.bashrc.tpl .bashrc
  sed -i "s/@@TITLE@@/${title}/g" .bashrc
  local longbit=$(getconf LONG_BIT)
  if [[ $longbit == "32" ]]; then sed -i 's/ @@M64@@//g' .bashrc ;
  elif [[ $longbit == "64" ]]; then sed -i 's/@@M64@@/-m64/g' .bashrc ;
  else echolog "Unable to get LONG_BIT conf (32 or 64bits)" ; getconf2 ; fi
}
if [[ ! -e .bashrc ]]; then build_bashrc "$1"; fi
sc
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
function untar() {
  local namever=$1
  if [[ ! -e src/$namever ]]; then
    get_tar tarname
    loge "$tarname xpvf src/_pkgs/$namever.tar.gz -C src" "tar_xpvf_$namever.tar.gz"
  fi
}
function get_param() {
  local name="$1"
  local _param="$2"
  local default="$3"
  local aparam=$(grep "$_param=" "$scriptPath/_cpl/params/$name")
  if [[ "$aparam" != "" && "${aparam##$_param=}" != "$aparam" ]] ; then aparam=${aparam##$_param=} ; 
  else aparam="" ; fi
  if [[ "$aparam" == "" ]]; then aparam="$default" ; fi
  if [[ "$aparam" == "##mandatory##" ]]; then echolog "unable to find $_param for $name" ; find2 ; fi
  eval $_param="'$aparam'" 
}  
function get_gnu_cmd() {
  local acmd=$1
  local _path=$2
  local _without_gnu_cmd=$3
  local _with_gnu_cmd=$4
  local apath=$(which ${acmd})
  apath=${apath/\/\///}
  if [[ "$apath" == "" ]] ; then echolog "Unable to find a ${acmd}" ; cmd_not_found ; fi
  eval $_path="'$apath'"
  local without_gnu_cmd="" ; local with_gnu_cmd=""
  if [[ ${apath#/usr/css*} != "${apath}" ]]; then without_gnu_cmd="--without-gnu-${acmd}"; else with_gnu_cmd="--with-gnu_${acmd}"; fi
  eval $_without_gnu_cmd="'$without_gnu_cmd'"
  eval $_with_gnu_cmd="'$with_gnu_cmd'"
}
function configure() {
  local name=$1
  local namever=$2
  get_param $name makefile Makefile
  if [[ ! -e $makefile ]]; then
    rm -f "$H"/src/${namever}/._*
    get_param $name configcmd "##mandatory##"
    configcmd=${configcmd/@@NAMEVER@@/${namever}}
    get_gnu_cmd ld path_ld without_gnu_ld with_gnu_ld
    configcmd=${configcmd/@@PATH_LD@@/${path_ld}}
    configcmd=${configcmd/@@WITHOUT_GNU_LD@@/${without_gnu_ld}}
    configcmd=${configcmd/@@WITH_GNU_LD@@/${with_gnu_ld}}
    get_gnu_cmd as path_as without_gnu_as with_gnu_as
    configcmd=${configcmd/@@PATH_AS@@/${path_as}}
    configcmd=${configcmd/@@WITHOUT_GNU_AS@@/${without_gnu_as}}
    configcmd=${configcmd/@@WITH_GNU_AS@@/${with_gnu_as}}
    echo configcmd $configcmd
    loge "$configcmd" "configure_$namever"
  fi
}
function cleanPath() {
  local path="$1"
  local _path="$2"
  while [[ "${path%/.}" != "${path}" ]] ; do path="${path%/.}"; done
  while [[ "${path#./}" != "${path}" ]] ; do path="${path#./}"; done
  #echo '${path%/./*}' ${path%/./*}
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
function _links() {
  local dest="$1"
  local src="$2"
  cd "$src"
  find . -type f -print | while read line; do
    #echo check $line
    local apath=${line%/*}; apath=${apath#*/}
    local afile=${line##*/}
    #echo check $apath $afile
    mkdir -p "$dest/$apath"
    #ln -fs "$src/$apath/$afile" "$dest/$apath/$afile"   
    #echo src "$src/$apath/$afile" dest "$dest/$apath/$afile"   
    #relpath "$src/$apath/$afile" "$dest/$apath/$afile" relp
    relpath "$dest/$apath/$afile" "$src/$apath/$afile" relp
    #echo relp $relp
    #echo ln -fs "$relp" "$dest/$apath/$afile"
    ln -fs "$relp" "$dest/$apath/$afile"
  done 
}
function links() {
  local namever=$1
  _links "$HUL" "$HUL/libs/$namever"
}
function pre() {
  local name=$1
  local namever=$2
  if [[ ! -e $H/src/$namever/._pre ]]; then
     get_param $name pre ""
     if [[ $pre != "" ]]; then
       local precmd=$pre
       while [[ "${precmd%@@NAMEVER@@*}" != "${precmd}" ]]; do
         precmd=${precmd/@@NAMEVER@@/${namever}}
       done
       loge "eval $precmd" "pre_$namever"
     fi
     echo done > $H/src/$namever/._pre
  fi 
}
function post() {
  local name=$1
  local namever=$2
  if [[ ! -e $H/src/$namever/._post ]]; then
     get_param $name post ""
     if [[ $post != "" ]]; then
       local postcmd=$post
       while [[ "${postcmd%@@NAMEVER@@*}" != "${postcmd}" ]]; do
         postcmd=${postcmd/@@NAMEVER@@/${namever}}
       done
       loge "eval $postcmd" "post_$namever"
     fi
     echo done > $H/src/$namever/._post
  fi 
}
function isItDone() {
  local name="$1"
  local _isdone="$2"
  local aisdone="false"
  #echo '${donelist}' "${donelist}"
  if [[ "${donelist%@${name}@*}" != "${donelist}" ]] ; then aisdone="true" ; fi
  eval $_isdone="'$aisdone'"
}
function gocd() {
  local name=$1
  local namever=$2
  get_param $name cdpath "$H/src/$namever"
  while [[ "${cdpath%@@NAMEVER@@*}" != "${cdpath}" ]]; do
    cdpath=${cdpath/@@NAMEVER@@/${namever}}
  done
  cdpath=$(eval echo "${cdpath}")
  echolog "cd $cdpath"
  cd "${cdpath}"
}
function build_app() {
  local name="$1"
  #echo 'APP ${donelist}' "$name : ${donelist}"
  local isdone="false" ; isItDone "$name" isdone
  if [[ "$isdone" == "false" ]] ; then echolog "##### Building APP $name ####" ; fi
  get_sources $name namever
  if [[ -e $HULA/$namever && -e $HULA/$name ]]; then
    if [[ "$isdone" == "false" ]] ; then echolog "APP $namever already installed" ; 
    donelist="${donelist}@${name}@" ; fi
  else
    local asrc="${H}/src/${namever}"
    sc
    untar $namever
    pre $name $namever
    gocd $name $namever
    configure $name $namever 
    if [[ ! -e "${asrc}"/._build ]] ; then loge "make" "make_$namever"; echo done > "${asrc}"/._build ; fi
    if [[ ! -e "${asrc}"/._installed ]] ; then loge "make install" "make_install_$namever"; echo done > "${asrc}"/._installed ; fi
    post $name $namever
    if [[ ! -e $HUL/._linked/$namever ]] ; then echolog "checking links of APP $namever"; _links "$H/bin" "$HULA/$namever/bin" ; echo done > $HUL/._linked/$namever ; fi
    ln -fs "${namever}" "${HULA}/${name}"
    donelist="${donelist}@${name}@"
    xxx_done_building_app
  fi
}
function build_lib() {
  local name="$1"
  #echo 'LIB ${donelist}' "$name : ${donelist}"
  local isdone="false" ; isItDone "$name" isdone
  if [[ "$isdone" == "false" ]] ; then echolog "#### Building LIB $name ####"; fi
  get_sources $name namever
  if [[ -e "$HUL/._linked/$namever" ]]; then
    if [[ "$isdone" == "false" ]] ; then echolog "LIB $namever already installed" ; 
    donelist="${donelist}@${name}@" ; fi
  else
    local asrc="${H}/src/${namever}"
    sc
    untar $namever
    pre $name $namever
    gocd $name $namever
    configure $name $namever
    if [[ ! -e "${asrc}"/._build ]] ; then loge "make" "make_$namever"; echo done > "${asrc}"/._build ; fi
    if [[ ! -e "${asrc}"/._installed ]] ; then loge "make install" "make_install_$namever"; echo done > "${asrc}"/._installed ; fi
    post $name $namever
    if [[ ! -e $HUL/._linked/$namever ]] ; then echolog "checking links of LIB $namever"; links $namever ; echo done > $HUL/._linked/$namever ; fi
    donelist="${donelist}@${name}@"
    xxx_done_building_lib # for breaking here
  fi
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
#sc ; which gcc ; gcc --version
exit 0
