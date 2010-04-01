#!/bin/sh

set -e

PREFIX=${PREFIX:-$HOME}
SITEDIR=${SITEDIR:-perl5}

if [ ! -z "$1" ]
    then INSTALL_DIR=$1
fi

INSTALL_LOC=${INSTALL_DIR:-$PREFIX/$SITEDIR}
echo Installing PageCapt modules to $INSTALL_LOC

cd PageCapt
install -d $INSTALL_LOC/PageCapt
install -p PageCapt/*.pm $INSTALL_LOC/PageCapt
install -p PageCapt.pm $INSTALL_LOC

exit 0
