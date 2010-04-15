#!/bin/sh

set -e

# parse options to get install directories (or just a prefix)

usage () {
	cat <<-END
	Usage: $0 [options]

	Each <dir> below should be an absolute pathname.
	Options:
	--base <dir>	base directory for install [$HOME]
	--webdir <dir>	install web files here [BASE/public_html]
	--cgidir <dir>	cgi progs go here [WEBDIR/cgi]
	--perldir <dir>	perl module path [BASE/perl5]
	--masndat <dir>	Mason data dir path [BASE/mason-data]
	-h, --help	this help message
	END
}

if [ -z "$1" ]
then usage; exit 1;
fi

OPTSTRING=$(getopt -o h -l help,base:,webdir:,cgidir:,perldir: -- "$@")
if [ $? != 0 ] ; then echo "Terminating..." >&2 ; exit 1 ; fi

eval set -- "$OPTSTRING"

BASE=
WEBDIR=
CGIDIR=
PERLDIR=
MASDIR=

while true
do case "$1" in
	-h|--help) usage; exit 1 ;;
	--base) BASE=$2; shift 2 ;;
	--webdir) WEBDIR=$2; shift 2 ;;
	--cgidir) CGIDIR=$2; shift 2 ;;
	--perldir) PERLDIR=$2; shift 2 ;;
	--masndat) MASDIR=$2; shift 2 ;;
	--) shift; break ;;
	*) echo "Error!"; exit 1 ;;
   esac
done

BASE=${BASE:-$HOME}
WEBDIR=${WEBDIR:-$BASE/public_html}
CGIDIR=${CGIDIR:-$WEBDIR/cgi-bin}
PERLDIR=${PERLDIR:-$BASE/perl5}
MASDIR=${MASDIR:-$BASE/mason-data}

# call PageCapt/tools/install.sh

echo Installing perl modules to $PERLDIR
PageCapt/tools/install.sh $PERLDIR

# call website/tools/install.sh

echo Installing site data to $WEBDIR
website/tools/install.sh $WEBDIR

# setup Mason CGI handler

sed -e '/^# -maybe-/ c \
use lib "'$PERLDIR'"; \
$mason_comp_root = "'$WEBDIR'"; \
$mason_data_dir = "'$MASDIR'";' \
website/tools/mason_handler.pl > tmp_mason_handler

install -D -m 755 tmp_mason_handler $CGIDIR/mason_handler.pl
rm tmp_mason_handler
install -m 777 -d $MASDIR
echo Created Mason handler script in $CGIDIR

echo "Now configure your local webserver. See website/tools/pagecapt.vhost for an example."

