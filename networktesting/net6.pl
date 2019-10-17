#!/usr/bin/perl

#written by Andrew Stringer 09/2001 onwards
#Network device testing script
#hyperlinks added to detailed network description 22/04/2002 onwards
#revised 24/07/2002 to read in from text file
#revised 10/09/2002 - 29/09 to add support for commented out addresses
#renamed newnet5.pl
#revised 14/01/03 to add some snmp support to get uptimes
#renamed to net6.pl

sub Ping
{
#first read in the ip address to ping from array
local ($host)=@_;

#test if $host contains a "#" - treat as commented out line
#$comment is true(1) if $host contains a #
$comment = ($host =~ m/#/) ;
#if $comment is false (ie does not contain a #), proceed with ping
if ($comment == 0 )
{
# print $host, "1st line past # test<br>" ;
 #generate ping
 #on linux
 $result= `/bin/ping -c1 $host`;
 #on SGI
 #$result= `/usr/etc/ping -c1 $host`;
 
 #attempt to extract time from $result, $time contains time and $units the unit
 #first split ping res up by : char
 @array= split (/:/, $result);
 $sequence=@array[2];

 #next remove everything after --- in ping response
 @array1= split (/---/, $sequence);
 $sequence=@array1[0];

 #remove first two fields (icmp and seq no.) and extract time and units
 @array2= split (/ /, $sequence);
 $time=@array2[3];
 $units=@array2[4];

 #remove time= from $time
 @array3= split (/=/, $time);
 $time=@array3[1];
 
 #pattern match for reply to ping
 if ($result=~ m/1 received/){$alive="alive" ;
  $colour= $green;

#if host is alive true, call snmp routine
my $host = $host ;
   $rawsnmp = &SNMPget ($host, $mib, $community);
   #split $rawsnmp up by , char into days & hours
   @snmparray= split (/,/, $rawsnmp);
   #use only days portion
   $snmp=@snmparray[0];

  } 
 else 
  {$alive="NOT alive.\n";
  $colour= $red;
  $time= "";
  $units="No Response";
  $snmp="invalid";
  }
 #test time returned if longer than 20ms, set $colour = amber
 if ($time>20) {$colour="$amber" ;
 }

   #if alive is true, call snmp routine
   #if ($alive="alive")
   #{
   #my $host = $host ;
   #$rawsnmp = &SNMPget ($host, $mib, $community);
   #split $rawsnmp up by , char into days & hours
   #@snmparray= split (/,/, $rawsnmp);
   #use only days portion
   #$snmp=@snmparray[0];
   #}
   #else 
   #{
   #$snmp = "Invalid" ;
   #}

#end of test for #
}
#else if $comment is true(1), just set variables and exit
else
{
 $alive = "Not tested" ;
 $snmp = "Not tested" ;
 $time = "&nbsp;" ;
 $units = "&nbsp;" ;
 $colour = "$grey" ;
}


#return result
return $alive, $time, $units, $colour, $snmp;
#end sub with curly brace
}

#
sub Uptime
{

#generate uptime
$result= `/usr/bin/uptime`;

#attempt to extract uptime from $result,
#first split $result by , char
@uparray= split (/,/, $result);
$days1=@uparray[0];
$hours=@uparray[1];

#split 1st field by two spaces
@array1= split (/up/,$days1);
$days= @array1[1];


#return result
return $days, $hours;
#end sub with curly brace
}


sub SNMPget
{
use Net::SNMP;
#read in variables
my $host = shift;
my $mib = shift;
my $community = shift;

my ($session, $error) = Net::SNMP->session(
      -hostname  => shift || $host,
      -community => shift || $community,
      -port      => shift || 161 
   );

   if (!defined($session)) {
      printf("ERROR: %s.\n", $error);
      exit 1;
   }

#   my $sysUpTime = '1.3.6.1.2.1.1.3.0';
   my $sysUpTime = $mib ;

   my $result = $session->get_request(
      -varbindlist => [$sysUpTime]
   );

   if (!defined($result)) {
      printf("ERROR: %s.\n", $session->error);
      $session->close;
      exit 1;
   }
   
my $up=$result->{$sysUpTime} ;
 
   $session->close;

 
return $up;

#end sub with curly brace
}


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

#Define MIB value
my $sysUpTime = '1.3.6.1.2.1.1.3.0';
$mib = $sysUpTime ;
$community = "public" ;

#call uptime sub
&Uptime;

#get system date
$date = localtime;

print "Content-type: text/html\n\n";

print <<ENDTEXT1 ;

<HTML>
<HEAD>
<TITLE>The ERC Network's Status Page.</TITLE>
<META HTTP-EQUIV="refresh" CONTENT="60">
<SCRIPT language=JavaScript>
<!-- Beginning of JavaScript Applet -------------------
/*   Scrolling text in the status window  */

function scrollit_r2l( seed ) {

 	var m1  = "Welcome to Media Hub's status page . . .";
	var m2  = "This page has been generated automatically . . .";
	var m3  = "It will refresh in one minute. . .";
	var m4  = " . . ";
	var msg = m1 + m2 + m3 + m4;
	var out = " ";
	var c = 1;
	if (seed > 100) {
		seed--;
		var cmd = "scrollit_r2l(" + seed + ")";
		timerTwo = window.setTimeout( cmd, 100 );
	}
	else if (seed <= 100 && seed > 0) {
		for (c=0 ; c < seed ; c++) {
			out+=" ";
		}
		out += msg;
		seed--;
		var cmd = "scrollit_r2l(" + seed + ")";
		window.status = out;
		timerTwo = window.setTimeout( cmd, 100 );
	}
	else if (seed <= 0) {
		if (-seed < msg.length) {
			out += msg.substring( -seed, msg.length );
			seed--;
			var cmd = "scrollit_r2l(" + seed + ")";
			window.status = out;
			timerTwo = window.setTimeout( cmd, 100 );
		}
		else {
			window.status = " ";	
			timerTwo = window.setTimeout( "scrollit_r2l(100)", 75 );
		}
	}
}
// -- End of JavaScript code ---------------->
</SCRIPT>

</HEAD>

<BODY text="#000000" bgcolor="#ffffff" link="0000EE" vlink="#551A8B"

onload="timerONE=window.setTimeout('scrollit_r2l(100)',500);" text=#000000 >

<center>
<table BORDER="0" Width="80%">
<tr>
<td>
<a href="http://146.1.0.7/index.html">
<img SRC="/erclogo2.jpg" BORDER="0" height="100" alt="Click here to return to smaug's web page"></a></td>
<td align="center">
<font size=+3>en400.j4b.int</font>
<br> Uptime: $days $hours (hours:mins)
</td></tr></table>
</center>

<br><br>


<center>
<table border="1" BGCOLOR="#FFFFCC">
<tr>
<td>Last refresh</td><td> $date</td>
</tr>
<tr><td>Your ipaddress is </td><td>$remotehost</td>
</tr>
<tr>
<td>Your browser is </td><td>$useragent .
ENDTEXT1
#put some stuff here to detect MSIE browser string in $useragent
if ($useragent =~ m/MSIE/)
{print "<br>Update your browser to a more standards compliant one <a href=\"http://www.mozilla.org\">here</a>."}
print <<ENDTEXT1a ;
</td>
</tr>
</table>

ENDTEXT1a



open SITES, "<sites6.txt" or die "Cannot open file sites6.txt for input." ;

#read in all of sites.txt in to array "@inputarray"
@inputarray = <SITES> ;
#close sites.txt
close SITES ;


print <<ENDOFTEXT2 ;
<table border="1" bgcolor="#FFFFCC" width="95%">
ENDOFTEXT2

#start loop through inputarray
for ($index = 0; $index < $#inputarray ; $index++) 
#while ($index < $#inputarray)
#foreach $index (0..$#inputarray)
{
#split out pairs of ipaddress and text string on "," ie.convert scalar to array
@value = split /,/, $inputarray[$index] ;

#do this action for each line of text file
#call ping sub
&Ping ($value[0]);

print <<ENDOFTEXT3 ;
<tr>
<td><a href="/tech/$value[2].html">$value[1]</a></td><td>$snmp</td>
<td bgcolor="$colour">$time $units</td>
ENDOFTEXT3

#call ping sub
&Ping ($value[3]);

print <<ENDOFTEXT3a ;
<td><a href="/tech/$value[5].html">$value[4]</a></td><td>$snmp</td>
<td bgcolor="$colour">$time $units</td>
<td bgcolor="#ffffff">&nbsp</td>
ENDOFTEXT3a

#call ping sub
&Ping ($value[6]);

print <<ENDOFTEXT4 ;
<td><a href="/tech/$value[8].html">$value[7]</a></td><td>$snmp</td>
<td bgcolor="$colour">$time $units</td>
ENDOFTEXT4

#call ping sub
&Ping ($value[9]);

print <<ENDOFTEXT4a ;
<td><a href="/tech/$value[11].html">$value[10]</a></td><td>$snmp</td>
<td bgcolor="$colour">$time $units</td>
</tr>
ENDOFTEXT4a

#end loop with }
}

print <<ENDOFTEXT5 ;
</table>
</center>

</BODY>
</HTML>

ENDOFTEXT5

}
exit (0);
