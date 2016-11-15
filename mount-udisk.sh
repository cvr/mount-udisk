#!/bin/bash
# vim: set fileencoding=utf-8 :
# -*- coding: utf-8 -*-
########################################################################
# mount-udisk.sh
# Simple command line interface (cli) in bash to mount mass storage devices
# such as USB disks and hard drives.  Mounts partitions by volume label.
#
# Usage:  mount-udisk.sh <label> [rw|ro|u]
# 
#   where <label> is the volume label.  The media is mounted on /media/<label>.
#
# Options:
#   rw - mount read-write (default) 
#   ro - mount read-only
#   u  - unmount
# 
# Caveats:
#   * No spaces in volume label. Won't work.
#   * If the mount point (/media/<label>) already exists,
#     (usually from an unclean shutdown), udmount will mount
#     the volume on /media/<label>_  
#
# Copyright (C) 2016 by Carlos Veiga Rodrigues. All rights reserved.
# author:  maxdev137 <maxdev137@sbcglobal.net> (original)
#          Carlos Veiga Rodrigues <cvrodrigues@gmail.com>
#
# This bash script was originally made by maxdev137 and made available at
# <http://stackoverflow.com/questions/483460/> with the GNU GPL v3 copyright.
# Originally it was a frontend to `udisks`. I made changes to output a list
# of available devices using `lsblk` and added commands to use `udisksctl`
# and `gvfs-mount` (the later are commented).
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# For more details consult the GNU General Public License at:
# <http://www.gnu.org/licenses/gpl.html>.
########################################################################

BEEP=$'\a'
VLABEL="${1}"     # volume label
MPOINT="/media" # default mount point for gnome-mount/udisks
YN=""           # yes/no string

c_red() { echo -n $(tput setaf 1)$1$(tput sgr0) ; }
c_grn() { echo -n $(tput setaf 2)$1$(tput sgr0) ; }
c_yel() { echo -n $(tput setaf 3)$1$(tput sgr0) ; }
c_blu() { echo -n $(tput setaf 4)$1$(tput sgr0) ; }
c_pur() { echo -n $(tput setaf 5)$1$(tput sgr0) ; }
c_aqu() { echo -n $(tput setaf 6)$1$(tput sgr0) ; }
c_wht() { echo -n $(tput setaf 7)$1$(tput sgr0) ; }

Y="SUCCESS" ; Y_c=$(c_grn "${Y}")
N="FAILURE" ; N_c=$(c_red "${N}")
SNAME=`echo "$0" | sed -e 's|.*/\(.*\)$|\1|'`

#--------------------------------------------------
AMV_LABEL=""    # already mounted volume label
MMSG=""         # "is mounted on" msg
AMF=0           # already mounted flag
AMV=""          # already mounted volume (from "mount -l")
AMV_DETAILS=""  # already mounted volume details
AMV_HELPER=""   # "uhelper" subsystem for mount/unmount ("hal" or "udisks")
COPT="$2"       # command line option
MOPT="rw"       # user input for mount option

#--------------------------------------------------
_copyright ()  {
  echo -e "\n\t${SNAME} is Copyright (C) 2016 by CVR <cvrodrigues@gmail.com>"
  echo -e "\tThis program comes with ABSOLUTELY NO WARRANTY. This is free"
  echo -e "\tsoftware and you are welcome to redistribute it under certain"
  echo -e "\tconditions, specified at: http://www.gnu.org/licenses/gpl.html"
}
#_usage ()      { echo -e "\nUsage: \t${SNAME} LABEL [rw|ro|u]" ; _copyright ; }
_usage ()      { echo -e "Usage: \t${SNAME} LABEL [rw|ro|u]\n" ; }
_error()       { echo "!!! Error: $1. !!!" >&2 ; echo -n "$BEEP"; _usage ; exit 1 ; }
_error_parm()  { _error "$2 Parameter Missing [$1]" ; }
_error_parm2() { _error "Command is wrong (only \"rw, ro, or u\") is alowed, not \"$1\"" ; }

_unmount () {
  ### unmount ###
  if [ "$COPT" = "u" ] ; then
    MPOINT=$(echo "$AMV" | grep "\[${VLABEL}\]" | \
      sed -e 's|^.* \(/.*\) type.*$|\1|')
    #echo "unmount MPOINT = [${MPOINT}]"
    if [ -z "${MPOINT}" ] ; then
      echo "${N_c} - ${VLABEL} not mounted."
    else
      _MSG=$(umount "${MPOINT}" 2>&1)
      _STATUS=$?
      if [ "${_STATUS}" -eq 0 ] ; then
        echo "${Y_c} - \"${MPOINT}\" is now unmounted"
      else echo "${N_c} - unmount \"${MPOINT}\" failed (${_MSG})"
      fi
    fi
  fi
}

#--------------------------------------------------
# [ -n "$VLABEL" ] || _error_parm "$VLABEL" "Volume Label"
_print_dev_labels () {
  echo -e "Volume LABEL missing. Printing available devices:"
  lsblk
  echo -e "Printing respective volume LABELS:"
  echo -e "DEVICE  \t    LABEL"
  for d in $(find /dev/disk/by-label -type l) ; do
    echo -e "$(readlink -m $d)\t<-  $(basename $d)"
  done
  echo ""
  _usage
  exit 1
  }

[ -n "$VLABEL" ] || _print_dev_labels


### command line option checck
case "$COPT" in
  "ro" ) ;;
  "rw" ) ;;
  "u"  ) ;;
     * ) _error_parm2 "$COPT" ;;
esac

### is VLABEL already mounted?
AMV=$(mount -l | grep "\[$VLABEL\]")
AMF=$?

### VLABEL is mounted somewhere
if  [ $AMF -eq 0 ] ; then
  AMV_LABEL=$(echo "$AMV" | sed 's/^.* \[\(.*\)\]$/\1/')
  AMV_DETAILS=$(echo $AMV | sed 's|^.*on \(.*\) \[.*$|on \"\1\"|')
  AMV_UHELPER=$(echo $AMV | grep uhelper | sed 's/^.*uhelper=\(.*\)).*$/\1/')
  #echo "AMV = [$AMV]"
  #echo "AMV_LABEL = [$AMV_LABEL]"
  #echo "AMV_DETAILS = [$AMV_DETAILS]"
  #echo "AMV_UHELPER = [$AMV_UHELPER]"

  ### unmount ###
  [ "$COPT" = "u" ] && _unmount && exit $?

  ### mounted on MPOINT (usually /media)
  if [ -d "${MPOINT}/${VLABEL}" ] ; then
    MOPT="ro" ; YN="${N_c}"
    [ -w "${MPOINT}/${VLABEL}" ] && MOPT="rw"
    [ "${MOPT}" = "${COPT}" ]    && YN="${Y_c}"
  ### mounted somewhere else
  else
    MOPT=$(echo "$AMV_DETAILS" | sed 's/^.*(\(.*\)).*$/\1/')
  fi
  echo "$N_c - $VLABEL is already mounted \"$MOPT\" $AMV_DETAILS"

### $VLABEL is not mounted anywhere, decide on "rw" or "ro"
else
  if [ "$COPT" = "u" ] ; then
    echo "$N_c - \"$VLABEL\" is not mounted"
  else
    [ "$COPT" = "rw" ] && MOPT="rw"
    [ "$COPT" = "ro" ] && MOPT="ro"
    ## using udisks
    #echo "udisks --mount /dev/disk/by-label/${VLABEL} --mount-options ${MOPT}"
    #udisks --mount /dev/disk/by-label/"${VLABEL}" --mount-options "${MOPT}"
    ## using udisksctl
    DEVICE=$(readlink -m /dev/disk/by-label/"${VLABEL}")
    echo "udisksctl mount -b ${DEVICE} -o ${MOPT}"
    udisksctl mount -b "${DEVICE}" -o "${MOPT}"
    ## using gvfs-mount
    # echo "gvfs-mount -d ${DEVICE}"
    # gvfs-mount -d ${DEVICE}
    _STATUS=$?
    [ $_STATUS -eq 0 ] && echo "$Y_c - $MPOINT/$VLABEL mounted ($MOPT)"
    [ $_STATUS -ne 0 ] && echo "$N_c - \"$VLABEL\""
  fi
fi

