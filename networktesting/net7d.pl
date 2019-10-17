#!/usr/bin/perl

#written by Andrew Stringer 09/2001 onwards
#Network device testing script
#hyperlinks added to detailed network description 22/04/2002 onwards
#revised 24/07/2002 to read in from text file
#revised 10/09/2002 - 29/09 to add support for commented out addresses
#renamed newnet5.pl
#revised 14/01/03 to add some snmp support to get uptimes
#renamed to net6.pl
#revised 12/05/2003, added loop to count columns in html output, can now be
#set with $columncount variable. renamed to net6a.pl.
#revised 15/05/2003 to include timetesting for SLA hours
#renamed to net6b.pl
#revised 19/05/2003 to add blue for out of sla hours
#revised 29/05/2003 to use displaypage.pl?site number to provide links - could use 3rd octet of ip address??
#renamed 05/06/03 to net7a.pl to reflect stats collection
#renamed 24/06/2003 to net7b.pl because $missed added to allow the number of missed pings to be displayed
#renmaed 26/06/2003 to net7c.pl to add some logging info written to output file.
# 30/09/2003 <small> tags added to increase screen real estate
#renamed net7d.pl Core router temperature monitoring added for cisco 7507


sub Timetest
#check if we are in SLA service hours
{
#first declare some lexical variables
my $serviceday="0";
my $servicehour="0";
my $slatime="0";

#get time into @now array from localtime function
my @now = localtime time;	#@now gets date/time

# @now[6] is number of day of week
if ((@now[6] <"1") or (@now[6] >"5"))
{
$serviceday = "0";
}
else
{
$serviceday = "1";
}

# @now[2] is hour of day next check if time is past 17:30 or past 18:00
if ((@now[2] <"9") or ((@now[2]=="17") and (@now[1]>"29")) or (@now[2]>="18"))
{
$servicehour = "0";
}
else
{
$servicehour = "1";
}

#if all conditions are true, we are in SLA hours, else sla = false, don't care!
if ($servicehour =="1" and $serviceday =="1")
{
$slatime="1";
}
else
{
$slatime="0";
}
#print " SLA contract=$slatime \n";
return $slatime, $serviceday, $servicehour ;
#end sub with curly brace
}


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

 #generate ping
 #on linux
 $result= `/bin/ping -c1 -s900 -w2 $host` ;
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
 if ($time>30) {$colour="$amber" ;
 }

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


   my $sysUpTime = $mib ;

   my $result = $session->get_request(
      -varbindlist => [$mib]
   );

   if (!defined($result)) {
      printf("ERROR: %s.\n", $session->error);
      $session->close;
      exit 1;
   }
   
my $up=$result->{$mib} ;
 
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
$amber = "#ffa500" ;
$red = "#ff3030" ;
$white = "#ffffff" ;
$grey = "#999999" ;
$blue = "#8888ff" ;

#number of html columns in output
my $columncount = "4" ;

#Define MIB value
my $sysUpTime = '1.3.6.1.2.1.1.3.0';
$mib = $sysUpTime ;
$community = "public" ;

my $inletoid = '.1.3.6.1.4.1.9.9.13.1.3.1.3.1' ;
my $inletdescoid = '.1.3.6.1.4.1.9.9.13.1.3.1.2.1' ;
my $hotspotoid = '.1.3.6.1.4.1.9.9.13.1.3.1.3.2' ;
my $hotspotdescoid = '.1.3.6.1.4.1.9.9.13.1.3.1.2.2' ;
my $outletoid = '.1.3.6.1.4.1.9.9.13.1.3.1.3.3' ;
my $outletdescoid = '.1.3.6.1.4.1.9.9.13.1.3.1.2.3' ;

#set address for 7507
my $corerouter = "172.25.0.1" ;

#call uptime sub
&Uptime;

#get system date
$date = localtime;

#Are we in SLA hours?
@slareturn = &Timetest;
# ($slatime, $serviceday, $servicehour);

if (@slareturn[0] == "1")
{
$validsla = "In SLA Time";
$slacolour= $green;
}
else
{
$validsla = "Out of SLA Time";
$slacolour= $blue;
}

#Get core router temperature value.
$routeralive = `/bin/ping -c1 $corerouter ` ;
if ($routeralive =~ m/1 received/)
{
$inletdesc = &SNMPget($corerouter, $inletdescoid, $community);
$inlettemp = &SNMPget($corerouter, $inletoid, $community);
$hotspotdesc = &SNMPget($corerouter, $hotspotdescoid, $community);
$hotspottemp = &SNMPget($corerouter, $hotspotoid, $community);
$outlettemp = &SNMPget($corerouter, $outletoid, $community);
$outletdesc = &SNMPget($corerouter, $outletdescoid, $community); 
}
else
{
$inlettemp = "Not available" ;
$inletdesc = "Offline" ;
$hotspottemp = "Not available" ;
$hotspotdesc = "Offline" ;
$outlettemp = "Not Available" ;
$outletdesc = "Offline" ;
}

if ($inlettemp<20){$inletcol=$green};
if ($inlettemp>=20){$inletcol=$amber};
if ($inlettemp>=23){$inletcol=$red};

if ($hotspottemp<22){$hotcol=$green};
if ($hotspottemp>=22){$hotcol=$amber};
if ($hotspottemp>=25){$hotcol=$red};

if ($outlettemp<25){$outletcol=$green};
if ($outlettemp>=25){$outletcol=$amber};
if ($outlettemp>=28){$outletcol=$red};

#start output of html page
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

 	var m1  = "Welcome to The ERC's network status page . . .";
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
<a href="/index.html">
<img SRC="/media_logo_sml.gif" BORDER="0" height="73" width="200"  alt="Click here to return to en400's web page"></a></td>
<td align="center">
<font size=+3>en400.j4b.int</font>
<br> Uptime: $days $hours (hours:mins)
</td></tr></table>
</center>

<br><br>


<center>
<table border="1" bgcolor="#FFFFCC">
<tr>
<td><small>Last refresh</small></td>
<td><small> $date</small></td>
<td bgcolor="$slacolour"><small>$validsla</small></td>
<td width="80"><small>$inletdesc</small></td><td width="30" bgcolor="$inletcol"><small>$inlettemp<sup>o</sup>C</small></td>
</tr>
<tr><td><small>Your ipaddress is </small></td><td><small>$remotehost</small></td>
<td><small>View error log
(<A HREF="javascript:void(0)"onclick="window.open('/cgi-bin/netlog.pl?10','netlog','width=600,height=300,scrollbars=1')">10</A>,
<A HREF="javascript:void(0)"onclick="window.open('/cgi-bin/netlog.pl?20','netlog','width=600,height=300,scrollbars=1')">20</A> or
<A HREF="javascript:void(0)"onclick="window.open('/cgi-bin/netlog.pl?30','netlog','width=600,height=300,scrollbars=1')">30</A> lines or
<A HREF="javascript:void(0)"onclick="window.open('/cgi-bin/netlog.pl?10000','netlog','width=600,height=300,scrollbars=1')">everything!</A>.)
</small>
</td>
<td><small>$hotspotdesc</small></td><td bgcolor="$hotcol"><small>$hotspottemp<sup>o</sup>C</small></td>
</tr>
<tr>
<td><small>Your browser is </small></td><td colspan="2"><small>$useragent .</small>
ENDTEXT1
#put some stuff here to detect MSIE browser string in $useragent
if ($useragent =~ m/MSIE/)
{print "<br><small>Update your browser to a more standards compliant one <a href=\"http://www.mozilla.org\">here</a>.</small>"}
print <<ENDTEXT1a ;
</td>
<td><small>$outletdesc<small></td><td bgcolor="$outletcol"><small>$outlettemp<sup>o</sup>C</small></td>
</tr>
</table>

ENDTEXT1a



open SITES, "<sites7c.txt" or die "Cannot open file sites7c.txt for input." ;

#read in all of sites.txt in to array "@inputarray"
@inputarray = <SITES> ;
#close sites.txt
close SITES ;

#start result table & print out 1st tr outside loop
print <<ENDOFTEXT2 ;
<table border="1" bgcolor="#FFFFCC" width="95%">
<tr>
ENDOFTEXT2

#set html table column counter to 1 outside loop
$colcount = "0" ;

#start loop through inputarray
for ($index = 0; $index < $#inputarray ; $index++)
{
#increment $colcount each time through loop
$colcount++ ;
#split out pairs of ipaddress and text string on "," ie.convert scalar to array
@value = split /,/, $inputarray[$index] ;

$total = $value[3];
$success = $value[4];
#increment total
$total++ ;

#do this action for each line of text file
#call ping sub
&Ping ($value[0]);


#if ping fails, write line to log file.

if ($colour eq $red)
{
#create write out to log file.
$log = "<tr><td>".$date."</td><td>".$value[0]."</td><td>".$value[1]."</td><td><font color=\"#ff0000\"> Failed ping response.</font></td></tr>\n";

#print to stdout for testing
#print $log;

#write out to netlog.txt
open LOGFILE, ">>/data/logs/netlog.txt";
print LOGFILE $log ;
close LOGFILE ;
};

if ($colour eq $amber)
{
#create write out to log file.
$log = "<tr><td>".$date."</td><td>".$value[0]."</td><td>".$value[1]."</td><td><font color=\"#ff00ff\"> Slow ping response ($time ms).</font></td></tr>\n";

#print to stdout for testing
#print $log;

#write out to netlog.txt
open LOGFILE, ">>/data/logs/netlog.txt";
print LOGFILE $log ;
close LOGFILE ;
};


#increment $success if ping is returned.
if (($colour eq $green) or ($colour eq $amber))
{$success++;};

#work out percent, use some convoluted logic to get 2 decimal places,
#multiply by 100*100 (10,000), truncate to integer, and divide by 100 to get 999.99% format
$percent = (int(($success/$total)*10000))/100 ;
#if colour is grey, pings not sent, so reduce total by 1 to compensate for $total++
if ($colour eq $grey)
{$total--;};

#work out missed pings
$missed = ($total - $success);

#create array to wite back
@outputarray[$index] = join(',',$value[0],$value[1],$value[2],$total,$success,$percent,"$missed,\n");


print <<ENDOFTEXT3 ;
<td><small><a href="/cgi-bin/displaypage.pl?$value[2]">$value[1]</a></small></td><td><small>$snmp</small></td>
<td bgcolor="$colour"><small>$time $units</small></td>
ENDOFTEXT3

#test if last column in table, if so print /tr & tr
if ($colcount == $columncount)
{
print "</tr>\n<tr>\n" ;
$colcount = "0" ;
}

#end main for loop with }
}

print <<ENDOFTEXT5 ;
</tr>
</table>
</center>

</BODY>
</HTML>

ENDOFTEXT5

@outputarray[($index+1)] = "\n";

#write output file
#check if we are in sla time, else do not write results out.
if (@slareturn[0] eq "1")
{
open OUTPUTFILE, ">sites7c.txt";
print OUTPUTFILE @outputarray ;
close OUTPUTFILE ;
};

}
exit (0);
