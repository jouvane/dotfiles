#!/bin/bash

set -euo pipefail

if [ "$EUID" != "0" ]; then
  echo "Please run this script as root"
  exit 2
fi

ALL_ARGS=$@
SHOW_HELP=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --help|-h)
    SHOW_HELP=true
    break
    ;;
    --verbose)
    VERBOSE=true
    shift
    ;;
    *)
    shift
    ;;
  esac
done

if $SHOW_HELP; then
  cat <<EOF
Packages installer.

Usage:
  `readlink -f $0` [flags]

Flags:
  -u, --update             Will download and install/reinstall even if the tools are already installed
      --verbose            Show verbose output
  -h, --help               help
EOF
  exit 0
fi

if $VERBOSE; then
  echo -e "\e[32mRunning `basename "$0"` $ALL_ARGS\e[0m"
fi

if ! [[ `locale -a` =~ 'en_US.utf8' ]]; then
  echo -e "\e[34mGenerate location.\e[0m"
  locale-gen en_US.UTF-8
else
  if $VERBOSE; then
    echo "Not generating location, it is already generated."
  fi
fi

if ! [ -f /etc/sudoers.d/10-cron ]; then
  echo -e "\e[34mAllow cron to start without su.\e[0m"
  echo "#allow cron to start without su
%sudo ALL=NOPASSWD: /etc/init.d/cron start" | tee /etc/sudoers.d/10-cron
  chmod 440 /etc/sudoers.d/10-cron
else
  if $VERBOSE; then
    echo "Not generating sudoers file for Cron, it is already there."
  fi
fi

function setAlternative() {
  NAME=$1
  EXEC_PATH=`which $2`
  if [ `update-alternatives --display $NAME | sed -n 's/.*link currently points to \(.*\)$/\1/p'` != $EXEC_PATH ]; then
    update-alternatives --set $NAME $EXEC_PATH
  else
    if $VERBOSE; then
      echo "Not updating alternative to $NAME, it is already set."
    fi
  fi
}

if $WSL; then
  if hash wslview 2>/dev/null; then
    setAlternative x-www-browser wslview
  else
    if $VERBOSE; then
      echo "Not setting browser to wslview, wslview is not available."
    fi
  fi
fi

setAlternative editor /usr/bin/vim.basic
