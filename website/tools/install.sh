#!/bin/sh

set -e

PREFIX=${PREFIX:-$HOME}
DOCROOT=${DOCROOT:-$PREFIX/public_html}

if [ ! -z "$1" ]
   then DOCROOT=$1
fi

echo Installing web content to $DOCROOT

install -d $DOCROOT/user

cd website/htdocs/
for file in *handler *css *mas *mhtml
do if [ -f $file ] 
   then install -p $file $DOCROOT
   fi
done

cd user/
for file in *handler *css *mas *mhtml
do if [ -f $file ]
   then install -p $file $DOCROOT/user
   fi
done

