#!/bin/sh

DOCROOT=/var/www
TEST=testing

pushd htdocs/
cp *handler *css *mas *mhtml $DOCROOT/$TEST
echo Installed *handler *css *mas *mhtml to $DOCROOT/$TEST

pushd user/
cp *handler *css *mas *mhtml $DOCROOT/$TEST/user
echo Installed *handler *css *mas *mhtml to $DOCROOT/$TEST/user

popd
popd

pushd $DOCROOT/$TEST

perl -i -p -e "\$loc = '$TEST';" -e '
   s{(<%method base>/)}{$1$loc/};
   ' autohandler

echo Configured autohandler
popd
