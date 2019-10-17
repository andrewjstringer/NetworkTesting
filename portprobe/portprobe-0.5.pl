#!/usr/bin/perl

#written by Andrew Stringer 18/05/2003 onwards
#Copyright Andrew Stringer 18/05/2003 & onwards
#This script is licenced under the GPL.
#This script tests the port useage on SNMP ethernet switches.
#Ports are tested and the status written to a file. 
#Intended to find "patched" but unused ports
#Initially developed to test Cisco 2950-24
#30-05-03--0.4 re does the logic section, works this time!
#30-05-03--0.5 writes out to html file so it can be run from a cron job
#10/06/2004 added current time stamp

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
 $result= `/bin/ping -c1 -w2 $host`;
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
 if ($time>20)
 {
 $colour="$amber" ;
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

#print "Start of main: \n";

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

#read in config file for all the switches to be tested

$filename = "/data/config/portprobe.txt" ;
open PORTPROBE, "<$filename" or die "Cannot open file portprobe.txt for input." ;

#read in all of portprobe.txt in to array "@portprobe"
@portprobe = <PORTPROBE> ;
#close $filename
close PORTPROBE ;

#print "just after close PORTPROBE filehandle \n";
#print "size of portprobe", $#portprobe, "\n" ;

#start loop through inputarray
for ($loopindex = 1; $loopindex < ($#portprobe+1) ; $loopindex++)
{
#print "loopindex",$loopindex,"\n" ;

#split out pairs of ipaddress and text string on "," ie.convert scalar to array
@loopvalue = split /,/, @portprobe[$loopindex-1] ;

$host = @loopvalue[0];
$text = @loopvalue[1];



#first test if device is alive
#call ping sub
&Ping ($host);

if ($alive == "1")
 {
 $devuptime = &SNMPget ($host, $sysUpTime, $community);
#print "$devuptime \n" ;
 }
 else
 {
 $devuptime = "Invalid" ;
 }

#open html file for output
$path= "/data/html/portprobe/";
$htmlfile = ($path."switch".$host.".html");
open HTML, ">$htmlfile";


#start of html head & body, start with http header, refresh 1 hour
#print HTML "Content-type: text/html\n\n";
print HTML <<ENDOFTEXT10 ;

<html>
<head>
<title>PortProbe for $host.</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<meta HTTP-EQUIV="refresh" content="3600">
</head>

<body text="#000000" bgcolor="#ffffff" link="0000EE" vlink="#551A8B"
<center>
<table border="0" width="80%">
<tr>
<td>
<a href="./index.html">
<img src="../bnccable.gif" alt="BNC pic" border="0" 
height="100" title="Click here to return to en400's web page"></a></td>
<td align="center">
<font size=+3>$text</font>
<br> $host Uptime: $devuptime 
<br> Generated $date .
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


#read in last results file

$filename = "/data/config/device".$host.".txt" ;
open INPUTFILE, "<$filename" or die "Cannot open file device$host.txt for input." ;

#read in all of device.txt in to array "@inputarray"
@inputarray = <INPUTFILE> ;
#close $filename
close INPUTFILE ;

#do main loop of program

	for ($index = "1"; $index <= ($portspresent-2); $index++)
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
	 $inNow =  @inputvalue[4];
	 #use chomp to remove newline from $inNow
	 #$inNow =  chomp $inNow;

	 #test
	 #$testin = $inNow;

	 if ($Admin!="1")
	  {
	  $nowbgcolor = "$grey";
	  $Now = "Port Shutdown";
	  }
	  else #ie $admin is not shutdown (is up)
	  {
	   if (($Admin=="1") and ($Oper=="1")) #ie admin up and oper up
	    {
	    $Now = $date;
	    $nowbgcolor = "$lightgreen";
	    }
	   else #ie admin up, link down
	    {
	     if ($inNow =~ m/:/) #match for colon- only seen in date string
	      {
	      $Now = $inNow;
	      $nowbgcolor= $lightred;
	      }
	     else #must have been up at some time
	      {
	      $Now = "Never.";
	      $nowbgcolor= $lightblue;
	      #$Now = $inNow;
	      #$nowbgcolor= $lightred;
	      }
	    }
	  }

	 @outputarray[$index] = join(',',$Descr,$Speed,$Admin,$Oper,$Now,"\n");

	 if ($Admin =="1") {$Admin ="Port Enabled";} else {$Admin="Port Shutdown";}
	 if ($Oper =="1")  {$Oper ="Link Up";} else {$Oper="Link Down";}
	 
	 print HTML "<tr>\n";
	 #print "<td>\$testin = ", $testin, "</td>\n";
	 print HTML "<td>", $Descr, "</td>\n";
	 print HTML "<td>", $Speed/1000000, "MB\/s </td>\n";
	 print HTML "<td>", $Admin, "</td>\n";
	 print HTML "<td>", $Oper, "</td>\n";
	 print HTML "<td bgcolor=$nowbgcolor>Last seen :-  $Now </td>\n";
	 #print "Index is $index \n" ;
	 print HTML "</tr>\n" ;
	 }
	}
	else
	{
	 print HTML "<tr>\n<td bgcolor=\"$lightred\">$host cannot be tested (no ping response received). </td>\n" ;
	}

	#finish off html stuff
print HTML <<ENDOFTEXT50 ;
</tr>
</table>
</center>
</BODY>
</HTML>

ENDOFTEXT50

#close html file
close HTML;

#write output file
open OUTPUTFILE, ">$filename";
print OUTPUTFILE @outputarray ;
close OUTPUTFILE ;


#close main loop
#print "closing main loop \n" ;
}



#end program Main section
}
#exit (0);

