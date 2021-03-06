toEth0  :: Queue(200) -> ToDevice(IDS-eth0);

FromDevice(IDS-eth1) -> toEth0;

IPctr :: AverageCounter;
IPctr, HTTPctr, DROPctr, ALLOWctr :: Counter;

classifier      :: Classifier(12/0800 /* IP packets */, - /* everything else */);
ip_classifier   :: IPClassifier(dst tcp port 80 and tcp opt ack /* relevant UDP packets */,
                                - /* everything else */);
in_device       :: FromDevice(IDS-eth0);
out             :: Queue(200) -> ToDevice(IDS-eth1);
toLogger        :: Queue(200) -> ToDevice(IDS-eth2);
IDS             :: HTTPRequestInspector("GET-HEAD-OPTIONS-TRACE-DELETE-CONNECT-","cat%20/etc/passwd-cat%20/var/log/-INSERT-UPDATE-DELETE-");


in_device -> classifier
        -> CheckIPHeader(14, CHECKSUM false) // don't check checksum for speed
	-> IPctr
        -> ip_classifier
	-> HTTPctr
        -> IDS
	-> ALLOWctr
        -> out;
classifier[1] -> out;
ip_classifier[1] -> out;
IDS[1] -> DROPctr -> toLogger;
DriverManager(pause, wait 2s,
	print "\n\r IDS Logs dumped at /tmp/IDS.log :",
	save "=====================IDS Report=====================
Input Packet Rate (pps): $(IPctr.rate)
Output Packet Rate (pps): $(IPctr.rate)
-----------------INBOUND--------------------
Total # of packets: $(IPctr.count)
Total # of HTTP packets: $(HTTPctr.count)
      # of allowed: $(ALLOWctr.count)
      # of dropped: $(DROPctr.count)	
--------------------------------------------
====================================================
	" /tmp/IDS.log,
	stop);
	