#!/usr/bin/env bash

if [ -z "${SUDO_USER}" ]; then
    echo "ERROR! You must use sudo to run this script: sudo ./$(basename "${0}")"
    exit 1
else
    BUILDS_DIR="$(getent passwd "${SUDO_USER}" | cut -d: -f6)"
fi

BUILDS_DIR="${OVERRIDE_BUILDS_DIR:-$BUILDS_DIR}"

if [ -z "${1}" ] || [ -z "${2}" ]; then
    echo "Usage: $(basename "${0}") <codename> <obs_ver>"
    exit 1
fi

DISTRO="${1}"
case "${DISTRO}" in
    jammy) DISTRO_VER="22.04";;
    lunar) DISTRO_VER="23.04";;
    oracular) DISTRO_VER="24.10";;
    noble) DISTRO_VER="24.04";;
    *) echo "ERROR! Unknown Ubuntu release: ${DISTRO}"
      exit 1;;
esac

OBS_VER="${2}"
OBS_MAJ_VER="${OBS_VER%%.*}"

SUFFIX=""
if [ "${3}" == "essential" ]; then
    SUFFIX="-essential"
fi

case "${OBS_MAJ_VER}" in
    30)
        if [ -d "${BUILDS_DIR}/Builds/obs-builder-${DISTRO}/root/obs-${OBS_MAJ_VER}" ]; then
            # Set source pattern to pass to find
            SOURCE_PATTERN="${BUILDS_DIR}/Builds/obs-builder-${DISTRO}/root/obs-${OBS_MAJ_VER}/obs-portable-${OBS_VER}*-ubuntu-${DISTRO_VER}${SUFFIX}.*"

            # Use find to handle safe expansion of filenames matching the pattern instead and pass the filenames to cp with -exec
            find $(dirname "$SOURCE_PATTERN") -type f -name "$(basename "$SOURCE_PATTERN")" -exec cp -v {} artefacts/ \;
            # Use find again but for chown as wildcards were also not being handled safely here.
            find artefacts/ -type f -name "obs-portable-${OBS_VER}*-ubuntu-${DISTRO_VER}${SUFFIX}.*" -exec chown "${SUDO_USER}:${SUDO_USER}" {} \;
            
            # Old format that caused 'No such file or directory' error with both cp and chown. Keeping this here just in case.
            # cp -v ${BUILDS_DIR}/Builds/obs-builder-${DISTRO}/root/obs-${OBS_MAJ_VER}/obs-portable-${OBS_VER}*-ubuntu-"${DISTRO_VER}${SUFFIX}".* artefacts/
            # chown "${SUDO_USER}":"${SUDO_USER}" artefacts/obs-portable-${OBS_VER}*-ubuntu-"${DISTRO_VER}${SUFFIX}".*
        fi;;
    *) echo "ERROR! Unsupported OBS Studio version: ${OBS_VER}"
       exit 1;;
esac
