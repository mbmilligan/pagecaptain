#!/bin/sh

PATH=/bin:/usr/bin
INSTALL_LOC=/usr/local/share/perl/5.6.1/

if [ ! -d $INSTALL_LOC ]
    then echo Bad install location: $INSTALL_LOC
    exit 1
fi
cp PageCapt/*.pm $INSTALL_LOC/PageCapt
cp PageCapt.pm $INSTALL_LOC

pushd $INSTALL_LOC

perl -i -p -e \
  's{dbname=scavhunt user=user password=password}
    {dbname=scavhunt user=milligan};
   s{(secret = ")foo}{$1nalk827};' PageCapt.pm

popd

touch /usr/local/lib/cgi-bin/mason_handler.pl

exit 0
