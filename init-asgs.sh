#!/usr/bin/env bash

if [ ! -d $HOME/asgs ]; then
  git clone https://github.com/jasonfleming/asgs.git
  if [ $? -gt 0 ]; then
    echo error cloning ASGS
    exit 1
  fi
fi

echo "pod            - POD (Penguin)"
echo "hatteras       - Hatteras (RENCI)"
echo "supermike      - Supermike (LSU)"
echo "queenbee       - Queenbee (LONI)"
echo "supermic       - SuperMIC (LSU HPC)"
echo "lonestar5      - Lonestar (TACC)"
echo "stampede2      - Stampede2 (TACC)"
echo "frontera       - Frontera (TACC)"
echo "desktop        - desktop"
echo "desktop-serial - desktop-serial"
echo "poseidon       - Poseidon"
echo "penguin        - Penguin"
echo "rostam         - rostam"
echo "vagrant        - vagrant/virtual box (local workstation)"

default_platform_hint=" "
if [ "$USER" = 'vagrant' ]; then
  default_platform="vagrant"
  default_platform_hint=" [$default_platform] "
fi
echo
read -p "Which platform environment would you like to use for ASGS bootstrapping?$default_platform_hint" platform

if [[ -z "$platform" && -z "$default_platform" ]]; then
  echo "A platform must be selected."
  exit 1
elif [[ -z "$platform" && -n "$default_platform" ]]; then
  platform=$default_platform
fi

echo
read -p "Which asgs branch would you like to checkout from Github ('.' to skip)? [master] " repo

if [ -z "$repo" ]; then
  repo=master
fi

cd ./asgs 2> /dev/null

if [ "$repo" != "." ]; then
  git checkout $repo 
  if [ $? -gt 0 ]; then
   echo error checking out $repo
   exit 1
  fi
else
  echo leaving git repo in current state 
fi

echo
read -p "Which compiler family would you like to use, 'gfortran' or 'intel'? " compiler

if [[ "$compiler" != 'gfortran' && "$compiler" != "intel" ]]; then
  echo "compiler must be 'gfortran' or 'intel'"
  exit 1
fi

. ./monitoring/logging.sh
. ./platforms.sh 
if [ $? -gt 0 ]; then
  echo error sourcing logging.sh and platforms.sh
  exit 1
fi


_default_installdir=$HOME/opt
if [ -n "$WORK" ]; then
  _default_installdir=$WORK/opt
fi
echo
echo "Where do you want to install libraries and some utilities? [$_default_installdir] "
read -p "(note: shell variables like \$HOME or \$WORK will not be expanded)? " installdir

if [ -z "$installdir" ]; then
  installdir=$HOME/opt
fi

echo
read -p "What is a short name you'd like to use to name the asgsh profile associated with this installation? [\"default\"] " profile

if [ -z "$profile" ]; then
  profile=$$
fi

echo Bootstrapping ASGS for installation...
env_dispatch $platform

# $MAKEJOBS is defined in platforms.sh
cmd="./cloud/general/asgs-brew.pl --install-path=$installdir --asgs-profile=$profile --compiler=$compiler --machinename=$platform --make-jobs=$MAKEJOBS"

echo
echo $cmd
echo
read -p "Run command above, y/N? [N] " run

if [ "$run" = "y" ]; then
  $cmd
else
  echo command not run
fi
