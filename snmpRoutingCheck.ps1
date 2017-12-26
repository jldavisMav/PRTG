# This script is built using the snmpwalk.exe utility from snmpsoft, now owned by syslog watcher and may be obtained from:
# https://syslogwatcher.com/cmd-tools/snmp-walk/
# This script also borrows heavily from the script written by Paessler support's Luciano Lingnau in his post at:
# https://kb.paessler.com/en/topic/25313-sensor-for-bgp-status
# Save that this script adds functionality for SNMP v2c and v3, as well as neighbor monitoring for OSPF in addition to BGP
# and adds an option for specific neighbor state vs. a count of neighbor states

<#
.SYNOPSIS
Script designed for use with PRTG and Cisco equipment for monitoring the state of routing peers via OSPF or BGP using SNMP v2c or v3

.DESCRIPTION
Based on options passed to the script it will return data formatted for PRTG to add a custom sensor for network peers.

.EXAMPLE
snmpRouteringCheck.ps1 -snmpv3 -hostAddr 192.168.0.1 -snmpUser 'UserName' -authProt MD5 -authPass '@uThPa$2w0rd' -privProt AES128 -privPass '()*&123pass' -routingProt OSPF -peerState -count

.PARAMETER hostAddr
Specifies the target address/name of the device to return routing information for, may be passed as %host in the Parameters field in PRTG, ie -hostAddr %host. May be shortened to -host or -IP

.PARAMETER snmpv2
Forces use of SNMPv2c parameters. Cannot be used with -snmpv3. If neither snmp version is specified, this will be the default used. Can be shortened to simply -v2c.

.PARAMETER snmpv3
Forces use of SNMPv3 parameters. Cannot be used with -snmpv2. May be shortened to simply -v3

.PARAMETER community
Specifies SNMPv2c community string. May be passed from PRTG via %snmpcommunity in the parameters field. Single quotes may be required if special characters are included, ie. '$p3c!@1'. May be shortened to -c

.PARAMETER snmpUser
Specifies the SNMPv3 username to connect with. If using noAuth/noPriv should be the only parameter required. Single quotes may be required if special characters are included, ie. '$p3c!@1'. May be shortened to -u

.PARAMETER authProt
Specifies the SNMPv3 authentication Protocol to be used. Only accepts MD5 or SHA as options. May be shortened to -am.

.PARAMETER authPass
Specifies the SNMPv3 auth password. Passwords should be within single quotes if they have any special characters, ie. '$p3c!@1'. May be shortened to -ap.

.PARAMETER privProt
Specifies the privelage protocol to be used for SNMPv3. Valid options are DES, IDEA, AES128, AES192, AES256 and 3DES. May be shortened to -pm

.PARAMETER privPass
Specifics the privelage password to be used for SNMPv3. Passwords should be within single quotes if they have any special characters, ie. '$p3c!@1'. May be shortened to -pp

.PARAMETER routingProt
Specifies which routing protocol you want to monitor. Valid options are ospf or bgp. May be shortened to -rp

.PARAMETER port
Specifies which port SNMP is running on for the host. Default is 161.

.PARAMETER timeout
Specifies how long to wait before timing out SNMP. Default is 10 seconds.

.PARAMETER troubleshooting
Switch will output the SNMP walk results to the screen and terminate without reformatting for PRTG. May be shortened to -test.

.PARAMETER count
Formats output to PRTG as a list of routing states for the protocol and how many neighbors are in that state, ie. 12 full, 4 peers loading, etc. If any peers are not in the Full state a warning will be set for the sensor.

.PARAMETER peerState
Formats output to PRTG as a list of peers by IP as individual channels with their state returned as a number. For BGP 6 is full, for OSPF 8 is full. If any are not full a warning will be set. If any are in the down state an error is set.
#>


[CmdletBinding(DefaultParameterSetName="v2c")]

Param
(
    [alias("host","IP")]
    [String]$hostAddr,

    [Parameter(ParameterSetName='v2c')]
    [alias("c","comm")]
    [String]$community,

    [Parameter(ParameterSetName='v2c')]
    [alias("v2c")]
    [switch]$snmpv2,

    [Parameter(ParameterSetName='v3')]
    [alias("v3")]
    [switch]$snmpv3,

    [Parameter(ParameterSetName='v3')]
    [alias("user","u")]
    [string]$snmpUser,
    
    [Parameter(ParameterSetName='v3')]
    [ValidateSet("MD5","SHA")]
    [alias("am")]
    [string]$authProt,

    [Parameter(ParameterSetName='v3')]
    [alias("ap")]
    [string]$authPass,

    [Parameter(ParameterSetName='v3')]
    [ValidateSet("DES","IDEA","AES128","AES192","AES256","3DES")]
    [alias("pm")]
    [string]$privProt,
    
    [Parameter(ParameterSetName='v3')]
    [alias("pp")]
    [string]$privPass,

    [alias("rp")]
    [validateSet("ospf","bgp")]
    [string]$routingProt = 'ospf',

    [string]$port = '161',

    [alias("t")]
    [int]$timeout = '10',

    [alias("test")]
    [switch]$troubleshooting,

    [switch]$count,

    [switch]$peerState
)

$command = ".\snmpWalk.exe"

if ($routingProt -eq 'ospf')
{
$startOID = '.1.3.6.1.2.1.14.10.1.6'
$endOID = '1.3.6.1.2.1.14.10.1.7'
$subLength = '27'
} elseif ($routingProt -eq 'bgp')
{
$startOID = '.1.3.6.1.2.1.15.3.1.2'
$endOID = '.1.3.6.1.2.1.15.3.1.3'
$subLength = '26'
}

$queryMeasurement = [System.Diagnostics.Stopwatch]::StartNew()

if ($snmpv2 -eq $true)
{
    $snmpversion='2c'
    $walkresult = (&$command -r:$hostaddr -v:$snmpVersion -os:$startOID -op:$endOID -t:$timeout -p:$port 2>&1)
    if($troubleshooting -eq $true){
        &$command -r:$hostaddr -v:$snmpVersion -os:$startOID -op:$endOID -t:$timeout -p:$port 2>&1
        exit
    }
} elseif ($snmpv3 -eq $true)
{
    $snmpversion='3'
    $walkresult = (&$command -r:$hostaddr -v:$snmpVersion -pp:$privProt -pw:$privPass -ap:$authProt -aw:$authPass -sn:$snmpUser -os:$startOID -op:$endOID -t:$timeout -p:$port 2>&1)
    if($troubleshooting -eq $true){
        &$command -r:$hostaddr -v:$snmpVersion -pp:$privProt -pw:$privPass -ap:$authProt -aw:$authPass -sn:$snmpUser -os:$startOID -op:$endOID -t:$timeout -p:$port 2>&1
        exit
    }
}

$walkEdit = @()
$loopCount=0
foreach($entry in $walkresult){
    $loopcount += 1
    if ($loopcount -gt 3 -and $loopcount -lt $walkresult.Count){
        $walkEdit += $entry.Substring($subLength)
    }
}

#Check if snmpwalk.exe suceeded.
if ($LASTEXITCODE -ne 0 ){
    write-host "<prtg>"
    write-host "<error>1</error>"
    write-host "<text>Error: $($walkEdit) / ScriptV: $($version) / PSv: $($PSVersionTable.PSVersion)</text>"
    write-host "</prtg>"
    Exit
}

#Validate output. Expects *INTEGER* in the result. Example: "12.34.56.78 = INTEGER: 6" - String and array have distinct handling.
if (($walkEdit -is [String]) -and ($walkEdit -notlike "*Integer*") -or ($walkEdit -is [array]) -and ($walkEdit[0].ToString() -notlike "*Integer*")){
    write-host "<prtg>"
    write-host "<error>1</error>"
    write-host "<text>Error: $($walkEdit) / ScriptV: $($version) / PSv: $($PSVersionTable.PSVersion)</text>"
    write-host "</prtg>"
    Exit
}

$peersmsg = $null
$queryMeasurement.Stop()

write-host "<prtg>"

if ($count -eq $true){
$peerstatus = new-object int[] 8
$peerstatus[7] = ($walkEdit | where-object { $_ -like "*=8"}).Count
$peerstatus[6] = ($walkEdit | where-object { $_ -like "*=7"}).Count
$peerstatus[5] = ($walkEdit | where-object { $_ -like "*=6"}).Count
$peerstatus[4] = ($walkEdit | where-object { $_ -like "*=5"}).Count
$peerstatus[3] = ($walkEdit | where-object { $_ -like "*=4"}).Count
$peerstatus[2] = ($walkEdit | where-object { $_ -like "*=3"}).Count
$peerstatus[1] = ($walkEdit | where-object { $_ -like "*=2"}).Count
$peerstatus[0] = ($walkEdit | where-object { $_ -like "*=1"}).Count

if ($routingProt -eq 'bgp'){

write-host "<result>"
write-host "<channel>Peers Established</channel>"
write-host "<value>$($peerstatus[5])</value>"
write-host "</result>"

write-host "<result>"
write-host "<channel>Peers OpenConfirm</channel>"
write-host "<value>$($peerstatus[4])</value>"
Write-host "<LimitMode>1</LimitMode>"
write-host "<LimitMaxWarning>1</LimitMaxWarning>"
write-host "</result>"

write-host "<result>"
write-host "<channel>Peers OpenSent</channel>"
write-host "<value>$($peerstatus[3])</value>"
Write-host "<LimitMode>1</LimitMode>"
write-host "<LimitMaxWarning>1</LimitMaxWarning>"
write-host "</result>"

write-host "<result>"
write-host "<channel>Peers Active</channel>"
write-host "<value>$($peerstatus[2])</value>"
Write-host "<LimitMode>1</LimitMode>"
write-host "<LimitMaxWarning>1</LimitMaxWarning>"
write-host "</result>"

write-host "<result>"
write-host "<channel>Peers Connect</channel>"
write-host "<value>$($peerstatus[1])</value>"
Write-host "<LimitMode>1</LimitMode>"
write-host "<LimitMaxWarning>1</LimitMaxWarning>"
write-host "</result>"

write-host "<result>"
write-host "<channel>Peers Idle</channel>"
write-host "<value>$($peerstatus[0])</value>"
Write-host "<LimitMode>1</LimitMode>"
write-host "<LimitMaxWarning>1</LimitMaxWarning>"
write-host "</result>"

foreach($entry in $walkEdit | where-object { $_ -notlike "*=6"}){
    $peersmsg += "$($entry.split()[-0]) "
}
} elseif ($routingProt = 'ospf'){

write-host "<result>"
write-host "<channel>Peers full</channel>"
write-host "<value>$($peerstatus[7])</value>"
write-host "</result>"

write-host "<result>"
write-host "<channel>Peers loading</channel>"
write-host "<value>$($peerstatus[6])</value>"
Write-host "<LimitMode>1</LimitMode>"
write-host "<LimitMaxWarning>1</LimitMaxWarning>"
write-host "</result>"

write-host "<result>"
write-host "<channel>Peers exchange</channel>"
write-host "<value>$($peerstatus[5])</value>"
Write-host "<LimitMode>1</LimitMode>"
write-host "<LimitMaxWarning>1</LimitMaxWarning>"
write-host "</result>"

write-host "<result>"
write-host "<channel>Peers exchangeStart</channel>"
write-host "<value>$($peerstatus[4])</value>"
Write-host "<LimitMode>1</LimitMode>"
write-host "<LimitMaxWarning>1</LimitMaxWarning>"
write-host "</result>"

write-host "<result>"
write-host "<channel>Peers twoWay</channel>"
write-host "<value>$($peerstatus[3])</value>"
Write-host "<LimitMode>1</LimitMode>"
write-host "<LimitMaxWarning>1</LimitMaxWarning>"
write-host "</result>"

write-host "<result>"
write-host "<channel>Peers init</channel>"
write-host "<value>$($peerstatus[2])</value>"
Write-host "<LimitMode>1</LimitMode>"
write-host "<LimitMaxWarning>1</LimitMaxWarning>"
write-host "</result>"

write-host "<result>"
write-host "<channel>Peers attempt</channel>"
write-host "<value>$($peerstatus[1])</value>"
Write-host "<LimitMode>1</LimitMode>"
write-host "<LimitMaxWarning>1</LimitMaxWarning>"
write-host "</result>"

write-host "<result>"
write-host "<channel>Peers down</channel>"
write-host "<value>$($peerstatus[0])</value>"
Write-host "<LimitMode>1</LimitMode>"
write-host "<LimitMaxWarning>1</LimitMaxWarning>"
write-host "</result>"

foreach($entry in $walkEdit | where-object { $_ -notlike "*=8"}){
    $peersmsg += "$($entry.split()[-0]) "
}
}

if ($peersmsg) {
    write-host "<text>Not Established: $($peersmsg)</text>"
    write-host "<Warning>1</Warning>"
}
}

if ($peerState -eq $true){
$neighborArrayIP = $null
$neighborArrayState = $null
$ipHolder = $null
foreach($entry in $walkEdit){
    $ipHolder = "$($entry.split(",")[0]) "
    $removeTail = $ipHolder.LastIndexOf(".")
    $neighborArrayIP = "$($ipHolder.Substring(0,$removeTail))"
    $neighborArrayState = "$($entry.split(",=")[4]) "
    write-host "<result>"
    write-host "<channel>Peer: $NeighborArrayIP</channel>"
    write-host "<value>$neighborArrayState</value>"
    Write-host "<LimitMode>1</LimitMode>"
    if ($routingProt -eq 'bgp'){
    write-host "<LimitMinWarning>5</LimitMinWarning>"
    } elseif ($routingProt -eq 'ospf'){
    write-host "<LimitMinWarning>7</LimitMinWarning>"
    }
    Write-Host "<LimitMinError>1</LimitMinError>"
    write-host "</result>"
}
}

Write-Host "<result>"
Write-Host "<channel>Script Execution Time</channel>"
Write-Host "<value>$($queryMeasurement.ElapsedMilliseconds)</value>"
Write-Host "<CustomUnit>msecs</CustomUnit>"
Write-Host "</result>"

write-host "</prtg>"