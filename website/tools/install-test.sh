#!/bin/sh

DOCROOT=/var/www
TEST=testing/

cp *handler *css *mas *mhtml $DOCROOT/$TEST
echo Installed *handler *css *mas *mhtml to $DOCROOT/$TEST

pushd $DOCROOT/$TEST

perl -i -p -e "\$loc = '$TEST';" -e '
   s{(<%method base>/)}{$1$loc};
   ' autohandler

echo Configured autohandler
popd
