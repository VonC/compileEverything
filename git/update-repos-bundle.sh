#!/bin/sh

homed=${H##*/};
if [[ ! -e "${H}/../.offline.${homed}" ]]; then
  exit 0
fi

gen_sed -i "s;https://github.com/.*/\(.*\);${H}/.cpl/src/_pkgs/repos/\1.bundle;g" "${H}/.gitmodules"

bundles=$(grep "path = " "${H}/.gitmodules")
#http://superuser.com/questions/284187/bash-iterating-over-lines-in-a-variable

cd "${H}"
while read -r bundle; do
  path="${bundle##* = }"
  name="${path##*/}"
  if [[ "${name}" == "github" ]]; then
    name="${path%/*}"
    name="${name##*/}"
  fi
  fbundle=$(ls -rt1 "${H}/.cpl/src/_pkgs/repos/" | grep -i "${name}.bundle" | tail -1);
  if [[ "${fbundle}" == "" ]]; then
    echo "no bundle found for bundle name='${name}' for path '${path}'"
    exit 1
  fi
  echo "bundle '${fbundle}', name='${name}' for path '${path}'"
  git rm "${path}"
  git submodule add -f --name "${name}" -- "${H}/.cpl/src/_pkgs/repos/${fbundle}" "${path}"
done <<< "${bundles}"
