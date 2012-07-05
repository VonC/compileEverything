
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


function get_param() {
  local name="$1"
  local _param="$2"
  local default="$3"
  #echo ":D name ${name}, _param ${_param}, default ${default}, namever='${namever}', ver='${ver}'"
  if [[ ! -e "${H}/.cpl/params/${name}" ]] ; then echolog "unable to find param for ${name}" ; no_param ; fi
  local aparam=$(grep -e "^${_param}=" "${H}/.cpl/params/${name}"|head -1)
  local aparamname="${aparam%%=*}"
  if [[ "${aparam}" != "" && "${aparam##${_param}=}" != "${aparam}" ]] ; then
    aparam=${aparam##${_param}=}
  else aparam="" ; fi
  if [[ "${aparamname}" != "${_param}" ]] ; then aparam="" ; fi
  if [[ "${aparam}" == "" ]]; then aparam="${default}" ; fi
  if [[ "${aparam}" == "" ]] || [[ "${aparam}" == "none" ]] ; then eval ${_param}="'${aparam}'" ; return 0 ; fi
  if [[ "${aparam}" == "##mandatory##" ]]; then echolog "unable to find ${_param} for ${name}" ; find2 ; fi
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
  #if [[ "${_param}" == "pre" && "${name}" == "perl" ]] ; then echo ${name} ${_param} xx${aparam}xx ; fi
  eval ${_param}="'${aparam}'"
}
