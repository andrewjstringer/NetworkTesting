# NetworkTesting
Simple Perl scripts to test network/switch status

Files imported from www.rainsbrook.co.uk

Portprobe
---------

This tests a cisco switch with snmp and created a page showing the port status at a point in time. It is intended to be run once per day and illustrates the port usage, so when a remote site says all the ports are patched and in use, you can see when a port was last active. 
It needs to be run at a time all devices at a site are active, say 10:00 in the morning, if you run it at midnight, it is likely to give you a false answer.



Network Testing
---------------

This is uploaded here for completeness, it was originally used to test a network for connectivity at the time when we couldn't afford any serious netowork monitoring tools, which were all closed source.
You're probably better off using Nagios these days, but this code may be of use as a public facing Status Page for example. 
Also, all the config is via text files, there is no login, so it may be a bit more secure for public exposure than Nagios or similar.

