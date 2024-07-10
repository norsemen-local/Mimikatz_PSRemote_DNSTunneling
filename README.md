## Privilege Escalation
This was accomplished through using a dictionary attack on the locao Administrator, using
[THC-Hydra](https://github.com/vanhauser-thc/thc-hydra)

## Credential Harvesting

This was accomplished through use of Mimikatz.exe on a local Windows host within the domain, with 
these Mimi commands:

-
- log C:\Users\<username>\AppData\Local\Temp\MimiSAM.txt      lsadump::sam
- log C:\Users\<username>\AppData\Local\Temp\MimiPW.txt       sekurlsa::logonpasswords
- log C:\Users\<username>\AppData\Local\Temp\MimiHash.txt     lsadump::lsa
- log C:\Users\<username>\AppData\Local\Temp\MimiSecrets.txt  lsadump::secrets
- 
each exported to its log file within a directory.

Then, Cmdlet [Obfuscate-Pack](https://github.com/Jonathan-D-a-v-i-d/LabTools/blob/main/Functions/Obfuscate-Pack.ps1) was used, 
to scrape all mimi log files within the directory, obfuscate them in base64, then zip them.


## Lateral Movement
Firstly, I gained Domain Admin by using a dictionarty attack on the domain admin account, also using [THC-Hydra](https://github.com/vanhauser-thc/thc-hydra).


Afterwards, all was done through PS Remoting via domain admin, so WinRM must be enabled on both hosts for PS Remoting
to function properly. 

Firstly, I used Cmdlet [Transfer-OverPSSession](https://github.com/Jonathan-D-a-v-i-d/LabTools/blob/main/Functions/Transfer-OverPSSession.ps1), 
to transfer my zipped and obfuscated local credentials to transfer it to the Server hosting the Lab's network DNS.

Afterwards, used Cmdlet [Connect-Remotely](https://github.com/Jonathan-D-a-v-i-d/LabTools/blob/main/Functions/Connect-Remotely.ps1) to connect
to the DNS Server via domain admin.



## Exfiltration
Finally, once active through a Ps-Session via domain admin on the DNS Server, as well as on my 
Attacker host which will be receiving the exfiltration, I -


(1) Launch [InitiateDNS&Sniff.sh](https://github.com/Jonathan-D-a-v-i-d/Cyber-Bash/blob/main/InitiateDNS%26Sniff.sh) -Interface eth0 -Action Start, 
which launches a Bind server on your Linux attacker host, while also initiating tshark afterwards locked in on port 53, saving it to a .pcap file. 
This is now a Bind DNS server listening for DNS traffic on port 53, exporting to a Pcap file.

(2) Exfiltrate using Cmdlet [Invoke-DNStunneling]https://github.com/Jonathan-D-a-v-i-d/LabTools/blob/main/Functions/Invoke-DNStunneling.ps1 on the 
DNS server via domain admin through my remote connection. This accepts an "item" such as a file or folder as an argument, converts it to base64, 
then chunks it up with an index before each chunk, all as a subdomain to "example.com" since we're sending dns requests through nslookup and 
need only the syntax of a website but not for it to resolve. Finally, we give it the attacker IP as an argument to send the indexed base64 chunks 
through a DNS "A" Type request, exfiltrated through the subdomain.



