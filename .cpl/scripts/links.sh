create_links=true

function cleanPath() {
  local path="$1"
  local _path="$2"
  while [[ "${path%/.}" != "${path}" ]] ; do path="${path%/.}"; done
  while [[ "${path#./}" != "${path}" ]] ; do path="${path#./}"; done
  #echo "D: '${palibssh2th%/./*}' ${path%/./*}"
  while [[ "${path%/./*}" != "${path}" ]] ; do path="${path/\/.\///}"; done
  eval ${_path}="'${path}'"
}
function relpath() {
  local source="$1"; cleanPath "${source}" source
  local target="$2"; cleanPath "${target}" target
  local _relp="$3"
  local common_part="${source}"
  local back=
  # echo target ${target} common_part $common_part
  # echo '${target#${common_part}/}' ${target#$common_part/}
  while [ "${target#$common_part/}" == "${target}" ]; do
    if [[ -d "${common_part}" ]] ; then back="../${back}" ; fi
    common_part=${common_part%/*}
    # echo "D: common_part ${common_part} back $back"
  done
  # echo "D: \${back}\${target#\$common_part/}' ${back}${target#${common_part}/}"
  eval ${_relp}="'${back}${target#${common_part}/}'";
}
function onelink() {
  local dest="$1"
  local src="$2"
  local line="$3"
  local apath=${line%/*}; apath=${apath#*/}
  local afile=${line##*/}
  # echo "D: check apath '${apath}' for afile '${afile}'"
  mkdir -p "${dest}/${apath}"
  #ln -fs "${src}/${apath}/${afile}" "${dest}/${apath}/${afile}"
  # echo "D: src '${src}/${apath}/${afile}', dest '${dest}/${apath}/${afile}'"
  #relpath "${src}/${apath}/${afile}" "${dest}/$apath/${afile}" relp
  relpath "${dest}/${apath}/${afile}" "${src}/$apath/${afile}" relp
  # echo "D: relp '${relp}"
  # echo "D: unameo '${unameo}' apath%/bin '${apath%/bin}' afile%.dll '${afile%.dll}'"
  if [[ "${unameo}" == "Cygwin" ]] && [[ "${afile%.dll}" != "${afile}" || "${afile%.a}" != "${afile}" ]] ; then
    # echo "D: rm -f then cp -f '${src}/${apath}/${afile}' '${dest}/${apath}/${afile}'"
    rm -f "${dest}/${apath}/${afile}"
    if [[ "${create_links}" == "true" ]] ; then
      cp -f "${src}/${apath}/${afile}" "${dest}/${apath}/${afile}"
    fi  
  else
    #echo ln -fs "${relp}" "${dest}/$apath/${afile}"
    if [[ "${create_links}" == "true" ]] ; then
      #echo "D: About to ln -fs '${relp}' '${dest}/$apath/${afile}'"
      ln -fs "${relp}" "${dest}/$apath/${afile}"
    else
      #echo "D: About to rm -f '${dest}/${apath}/${afile}'"
      rm -f "${dest}/${apath}/${afile}"
    fi  
  fi
}
function links() {
  local dest="$1"
  local src="$2"
  create_links="${3}"
  if [[ "${create_links}" != "true" && "${create_links}" != "false" ]] ; then
    echo  -e "\e[1;31m! incorrect create_links parameter for links\e[0m" 1>&2
    exit 1
  fi
  # echo "D: links dest '$1', src '$2'"
  if [[ -d "${src}" ]] ; then
    cd "${src}"
    find . -type f -print | while read line; do
      # echo "D: check ${line}"
      onelink "${dest}" "${src}" "${line}"
    done
    find . -type l -print | while read line; do
      # echo "D: check ${line}"
      onelink "${dest}" "${src}" "${line}"
    done
  fi
}

