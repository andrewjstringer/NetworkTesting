#!/usr/bin/perl

#written by Andrew Stringer 18/05/2003 onwards
#This script tests the port useage on SNMP ethernet switches.
#Ports are tested and the status written to a file. 
#Intended to find "patched" but unused ports
#Initially developed to test Cisco 2950-24



sub Ping
{
#first read in the ip address to ping from array
local ($host)=@_;

#test if $host contains a "#" - treat as commented out line
#$comment is true(1) if $host contains a #
$comment = ($host =~ m/#/) ;
#if $comment is false (ie does not contain a #), proceed with ping
if ($comment == "0")
{
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
  if ($result=~ m/1 received/){$alive="1" ;
  $colour= $green;
  } 
 else 
  {$alive="0";
  $colour= $red;
  $time= "";
  $units="No Response";
 }
 #test time returned if longer than 20ms, set $colour = amber
 if ($time>20) {$colour="$amber" ;
 }


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
return $alive, $time, $units, $colour ;
#end sub with curly brace
}


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
      #$error =("ERROR: %s.\n", $error);
      printf("ERROR: %s.\n", $error);
      exit 1;
   }

   #my $sysUpTime = $mib ;
   my $result = $session->get_request(
      -varbindlist => [$mib]
   );

   if (!defined($result)) {
      $error1 =("ERROR: %s.\n", $error);
      printf("ERROR: %s.\n", $session->error);
      $session->close;
      exit 1;
   }
   
my $value=$result->{$mib} ;
my $error2=$result->{$mib} ; 
   $session->close;
 
return $value, $error2 ;

#end sub with curly brace
}


#
MAIN:
#start of body of program
{
#set up environment variables

$green = "#00bb00" ;
$amber = "#ffff00" ;
$red = "#cc0000" ;
$lightred = "#cc8888" ;
$green = "#00cc00" ;
$lightgreen = "#88cc88" ;
$blue = "#0000cc" ;
$lightblue = "#8888cc" ;
$white = "#ffffff" ;
$grey = "#999999" ;

#get input ipaddress from cgi get in form url....pl?ipaddress%Text-Description
#read in from ENV, split into $host and $devname, $devname cannot have spaces,
#so use hyphen instead and s/// to substitute space. /g to replace all occurances.
$inputstring= $ENV{'QUERY_STRING'};
@inputstring = split /%/, $inputstring ;
$host = @inputstring[0];
$devicename = @inputstring[1];
$devicename =~ s/-/ /g;


#Define MIB value
my $sysUpTime = ".1.3.6.1.2.1.1.3.0" ;
#number of interfaces present on device
my $ifNumber      = ".1.3.6.1.2.1.2.1.0";
my $ifDescr       = ".1.3.6.1.2.1.2.2.1.2.";
my $ifSpeed       = ".1.3.6.1.2.1.2.2.1.5.";
my $ifAdminStatus = ".1.3.6.1.2.1.2.2.1.7.";
my $ifOperStatus  = ".1.3.6.1.2.1.2.2.1.8.";

my $community = "public" ;

#get system date
$date = localtime;

#first test if device is alive
#call ping sub
&Ping ($host);

if ($alive == "1")
{
$devuptime = &SNMPget ($host, $sysUpTime, $community);
}
else
{
$devuptime = "Invalid" ;
}

#start of html head & body, start with http header, refresh 1 hour
print "Content-type: text/html\n\n";
print <<ENDOFTEXT10 ;

<HTML>
<HEAD>
<TITLE>PortProbe for switches.</TITLE>
<META HTTP-EQUIV="refresh" CONTENT="3600">
</HEAD>

<BODY text="#000000" bgcolor="#ffffff" link="0000EE" vlink="#551A8B"
<center>
<table BORDER="0" Width="80%">
<tr>
<td>
<a href="/index.html">
<img SRC="/erclogo2.jpg" BORDER="0" height="100" alt="Click here to return to en400's web page"></a></td>
<td align="center">
<font size=+3>$devicename</font>
<br> $host Uptime: $devuptime 
</td></tr>
</table>
</center>
<br><br>
<table border="0" bgcolor="#FFFFCC" width="95%">	
<tr>
<td>Port Description.</td><td>Port Speed.</td><td>Admin Status.</td><td>Op Status.</td><td>Activity.</td>
</tr>
<tr><td colspan=5>&nbsp;</td></tr>
ENDOFTEXT10


#result from ping device
if ($alive == "1")
{
#test how many ports are present for loop
$portspresent = &SNMPget ($host, $ifNumber, $community);


#read in file

$filename = "device".$host.".txt" ;
open INPUTFILE, "<$filename" or `touch $filename` ;
#die "Cannot open file device.txt for input." ;

#read in all of device.txt in to array "@inputarray"
@inputarray = <INPUTFILE> ;
#close $filename
close INPUTFILE ;

#do main loop of program

for ($index = "1"; $index <= $portspresent; $index++)
{
 #concatenate required MIB with port index number to get value to use
 $portDescr = $ifDescr.$index ;
 $Descr = &SNMPget ($host, $portDescr, $community); 
 $portSpeed = $ifSpeed.$index ;
 $Speed = &SNMPget ($host, $portSpeed, $community);
 $portAdmin = $ifAdminStatus.$index ;
 $Admin = &SNMPget ($host, $portAdmin, $community);
 $portOper= $ifOperStatus.$index ;
 $Oper = &SNMPget ($host, $portOper, $community);

#split up @inputvalue to get the different fields
 @inputvalue = split /,/, @inputarray[($index-1)] ;
 #test by printing values
 $inDescr = @inputvalue[0];
 $inSpeed = @inputvalue[1];
 $inAdmin = @inputvalue[2];
 $inOper = @inputvalue[3];
 #use chomp to remove newline from $inNow
 $inNow =  chomp(@inputvalue[4]);


#if admin up, oper down,  and inNow is blank, set to never seen
if (($Admin=="1") and ($Oper=="2") and ($inNow==""))
{
$Now = "Never Seen.";
$nowbgcolor = $lightblue ;
}

#check if admin is down
if ($Admin!="1")
{
#if it is, set now to unavailable,
$Now = "Unavailable";
$nowbgcolor = $grey ;
}

#check if both admin and oper are up
if (($Admin=="1") and ($Oper=="1"))
{
#if they are, set now to date, ie last time seen
$Now = $date;
$nowbgcolor = $lightgreen ;
}

if ($inNow=="Never seen.")
{
#if $oper id down, set now to inNow, ie last time seen
#$Now = $inNow;
$nowbgcolor = $lightblue ;
}

#if admin up, oper down, last oper down
if (($Admin=="1") and ($Oper=="2") and ($inOper =="2"))
{
#if $oper and $inOper was down last time , set $now to inNow, ie keep last seen time
$Now = $inNow;
$nowbgcolor = $lightred ;
}





 @outputarray[$index] = join(',',$Descr,$Speed,$Admin,$Oper,"$Now\n");
 
 if ($Admin =="1") {$Admin ="Port Enabled";} else {$Admin="Port Disabled";} ;
 if ($Oper =="1") {$Oper ="Link Up";} else {$Oper="Link Down";} ;
 print "<tr>\n";
 print "<td>", $Descr, "</td>\n";
 print "<td>", $Speed/1000000, "MB\/s </td>\n";
 print "<td>", $Admin, "</td>\n";
 print "<td>", $Oper, "</td>\n";
 print "<td bgcolor=$nowbgcolor>Last seen $Now </td>\n";
 #print "Index is $index \n" ;
 print "</tr>\n" ;
 }
}
else
{
 print "<tr>\n<td bgcolor=\"$lightred\">$host cannot be tested (no response received). </td>\n" ;
}

#finish off html stuff
print <<ENDOFTEXT50 ;
</tr>
</table>
</center>

</BODY>
</HTML>

ENDOFTEXT50

#write output file
open OUTPUTFILE, ">$filename";
print OUTPUTFILE @outputarray ;
close OUTPUTFILE ;

#end program Main section
}
#exit (0);

