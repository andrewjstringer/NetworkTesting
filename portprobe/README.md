Port Usage on Ethernet switches
-------------------------------

An organisation which we have a close relationship with has a number of large Cisco 5500 & 6500 chassis based ethernet switches serving many users. Looking at the spagehtti of wiring round each one and the number of patched ports with no link light on made me think it would be useful to have an idea of how many ports were actually in use. This series of scripts was written to test our much smaller 2950 24 port ethernet switches for the same reason. Users will phone up and complain that there are no free ports left to plug the latest pc purchase in to, but a quick look at the html output of this program will reveal what is actually in use.
 
The current version (portprobe-0.6.pl) is configured from a text file containing the ip address of the switch and a test description to display on the output page:-

192.168.0.2,MediaHub Switch,
192.168.1.2,Site 0 switch,
192.168.2.2,Site 2 switch,

The trailing comma is important. The program flow is basically one loop inside another. The inside loop does the work for each device tested and produces the html output whilst the outer loop iterates through the config text file and calls the inner loop for each line present.
 
Subroutines
-----------

sub Ping{} generates a ping from the variable passed to it, as it was copied from an earlier script which required the ping round trip duration, it takes the ping response apart and extracts the duration and sets a variable ($colour) if the time exceeds a threshold (20ms). It reports if the target is alive, the time and units of the ping response and the threshold colour. N.B. This subroutine is the most likely to break between different versions of os and indeed between different releases of ping. This is because of the slightly different text replies that ping produces. It can be fixed with little difficulty by studying the text and following the pattern matching.
sub Uptime{} returns the uptime of the local machine, NOT the target in days and hours.
subSNMPget{} actually does most of the work because it gets the value corresponding to the oid passed to it. It relies on the perl module Net::SNMP. It just returns the snmp response and maybe an error. The 0.6 version cleans this code up so it returns a sensible error if the OID asked for does not exist.

 
Main:
First we declare some colour variables for later use and also some snmp oids. Note that they end with a trailing "." because later on the instance is appended to this value. The exception is $ifNumber because it returns the number of interfaces present. This is used as a loop counter later.
Next we open the text config file and read the contents in to @portprobe. The for{ starts the outer loop which is controlled by the number of devices to be tested.
Inside this loop each line of the text file is split on ,'s $host and $text, the target and it's description respectively. Next ping is called and the result tested to check if the target is alive. No point really in timing out an snmp probe to a dead box.
Next we open the file we want to use for the html output and write a standard header to it containing the . The meta refresh tells the browser to reload the page every hour to keep reasonably current. The results table is opened. Note that an html header (Content-type: text/html\n\n) is not required as the file is saved to the filesystem as a static page and not piped through the web server to a client.
Next we have the interesting stuff, the size of the switch is evaluated to $portspresent and the results of the last run are read in to @inputarray and each line is split into scalars on ",". The corresponding port is probed with snmp to determine its description, operating speed admin status and operational status. The result is collated and added to the result array.
If it is down currently, we have a test to see if it was down last time or if it has never been seen active. Some output variables are set accordingly. A line of the result table is written (print HTML). This is carried out for each port present on the switch.
Finishing Off
To end the html file handle is closed, the result file is written out &closed and we finish off the main loop. 
