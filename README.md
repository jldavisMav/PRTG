# PRTG
Home for scripts written for PRTG monitoring system

## SNMPRoutingCheck.ps1
Initially based off of the powershell [PRTG script](https://kb.paessler.com/en/topic/25313-sensor-for-bgp-status) written by Luciano Lingnau. Uses snmpWalk.exe from [snmpsoft](https://syslogwatcher.com/cmd-tools/snmp-walk/) for much of its functionality. Much of the instructions on the PRTG link apply for this script, save for the particulars of the available parameters, checking for OSPF and BGP, as well as functionality for snmpv3 as well as snmpv2c.  Designed for use on Cisco systems (based on OID codes).
* hostAddr: Specifies the target router/switch to check, can be passed from PRTG as parameter %host
* snmpv2: Forces SNMP v2c mode, the default functionality for the script. Cannot be used with snmpv3.
* snmpv3: Forces SNMP v3 mode. Cannot be used with snmpv2.
* community: Speficies community string for SNMPv2c
* snmpUser: Specifies the SNMPv3 username to use. If using noAuth/noPriv this should be the only required parameter of the SNMPv3 options.
* authProt: Specify authentication protocol/method. Valid options are MD5 or SHA
* authPass: Specify authentication password. Passwords with special characters should be protected by single quotes.
* privProt: Specify privelege protocol/method. Valid options are DES, IDEA, AES128, AES192, AES256, and 3DES.
* routingProt: Specify routing protocol to check. Valid options are ospf and bgp. Default is ospf.
* port: Specify snmp port. Default is 161.
* timeout: Specify how many seconds to wait for snmp timeout. Default is 10.
* count: Option for output as count of neighbors in various states. For OSPF there are 8 states, for BGP there are 6. If any are not in full state, a warning is set for PRTG. For BGP router with 6 neighbors in full state, for example, it will show 6 in full, and 0 in the other 5 states.
* peerState: Option for output as list of neighbors and their current state. Neighbors will be listed by IP address and a number indicating their state. Any that are not in full state will set a warning, any in the null state will set an error.
* troubleshooting: Script will output the results of the snmpWalk command and the exit out. For testing parameters without trying to parse through PRTG xml.
#### Examples
* For testing by hand for snmpv3 with auth/priv for bgp: 

 ` .\snmpRoutingCheck.ps1 -snmpv3 -hostAddr -192.168.0.1 -snmpUser Username -authProt MD5 -authPass 'Te$7P@ss' -privProt AES128 -privPass '$3condP@$$' -routingProt bgp -troubleshooting ` 
* For snmpv2c check of ospf routing, only returning counts of states in xml: 

 ` .\snmpRoutingCheck.ps1 -hostAddr 192.168.1.1 -community public -count` 
* In PRTG, parameters returning all channels for OSPF, snmpv3 with noAuth/noPriv: 

 ` -hostAddr %host -snmpv3 -snmpUser 'U$3rN@me' -routingProt ospf -count -peerState `
