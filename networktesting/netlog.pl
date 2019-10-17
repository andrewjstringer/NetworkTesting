#!/usr/bin/perl

#written by Andrew Stringer 26/06/2003 onwards
#Network error log display



#
MAIN:
#start of body of program
{
#set up environment variables
$remotehost=$ENV{'REMOTE_ADDR'} ;
$useragent=$ENV{'HTTP_USER_AGENT'} ;

$green = "#00bb00" ;
$amber = "#ffff00" ;
$red = "#cc0000" ;
$white = "#ffffff" ;
$grey = "#999999" ;
$blue = "#8888ff" ;


#get system date
$date = localtime;


$lines = $ENV{'QUERY_STRING'};
#$lines = "10";


#remove extra characters with s///, use g to strip multiple matches

$lines =~ s/[a-z,A-Z,\/,\|,\,,\@]//g;

$result= `/usr/bin/tail -n $lines  /data/cgi-bin/netlog.txt `;




#start of html document

print "Content-type: text/html\n\n";

print <<ENDTEXT1 ;

<HTML>
<HEAD>
<TITLE>The ERC Network Network error log.
</TITLE>
<META HTTP-EQUIV="refresh" CONTENT="60">
</HEAD>

<BODY text="#000000" bgcolor="#ffffff" link="0000EE" vlink="#551A8B"

<center>
<h2>Error Log output:- &nbsp;&nbsp;&nbsp;&nbsp;(Last $lines lines)</h2>

<table border="0" BGCOLOR="#FFFFCC">
$result
</table>

</center>

</BODY>
</HTML>

ENDTEXT1

}
exit (0);
