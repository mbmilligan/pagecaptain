#!/usr/bin/perl

use Pg;
$arg = shift;
$connstr = shift || "dbname=scavhunt";
$conn = Pg::connectdb($connstr);
$error = $conn->errorMessage;
print "Connection Error: $error \n" if $error;
$q="select * from list where inum ~ \'$arg\'";
$res =$conn->exec($q);
$error = $conn->errorMessage;
print "Query Error: $error \n" if $error;

$n = $res->ntuples; print $n,"\n";

 for ( $i = 0; $i < $n; $i++ )
      { $r_index = $res->getvalue( $i, 0 );
	$r_score = $res->getvalue( $i, 1 );
	$r_type = $res->getvalue( $i, 2 );
	$r_status = $res->getvalue( $i, 3 );
	$r_desc = $res->getvalue( $i, 4 );
	$r_comm = $res->getvalue( $i, 5 );
	$r_notes = $res->getvalue( $i, 6 );

	print $r_index, " ", $r_desc, " ", $r_comm;
	print "\n"; }

#while ( $res->fetchrow ) { print @_ };
