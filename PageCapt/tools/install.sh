#!/bin/sh

PATH=/bin:/usr/bin
INSTALL_LOC=/home/mmilligan/perl5/

if [ ! -d $INSTALL_LOC ]
    then echo Bad install location: $INSTALL_LOC
    exit 1
fi
cp PageCapt/*.pm $INSTALL_LOC/PageCapt
cp PageCapt.pm $INSTALL_LOC

pushd $INSTALL_LOC

perl -i -p -e \
  's{dbname=scavhunt user=user password=password}
    {dbname=scavhunt user=webserver password=foobar host=ruby};
   s{(secret = ")foo}{$1nalk827};' PageCapt.pm

popd

touch /home/mmilligan/public_html/cgi/mason_handler.pl

exit 0
