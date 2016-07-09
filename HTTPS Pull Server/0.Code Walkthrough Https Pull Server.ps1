# 1. Set directory location for demo files
Set-Location -Path 'C:\Users\conner.henry\Documents\GitHub\Bahamas - School Deployment\HTTPS Pull Server\'
Remove-Item -Path .\*.mof -Force
#Remove-DnsServerResourceRecord -ComputerName dc.company.pri -ZoneName company.pri -Name DSC -RRType 'A' -Force
Break

# Let's start with some requirements and documentation
<#
1. You will need to install a certificate on the Pull servers - I will show you how
2. Add a DNS Entry for the Pull Server
2. You will need module xPSDesiredStateConfiguration on the Pull server - I will show you how
3. You should look at the documentation inside the module xPSDesiredStateConfiguration - I will...you get the idea
4. You should create YOUR OWN config -- I'll show you mine
5. Then deploy a pull server - AND test it.
#>

# Let's get started by installing a certificate on the Pull server

# Create a self-signed cert for labs
New-SelfSignedCertificate -CertStoreLocation 'CERT:\LocalMachine\MY' -DnsName "DSCPullCert" -OutVariable DSCCert
# Modify the Cderts Friendly name manually to "DSCCert"

# Install a cert from a PKI ADCS server
<#
$ComputerName = 'moe-bs-dsc1' # Enter you target web server
Invoke-Command -computername $ComputerName {
    Get-Certificate -template 'WebServer' -url 'https://localhost/ADPolicyProvider_CEP_Kerberos/service.svc/cep' `
    -CertStoreLocation Cert:\LocalMachine\My\ -SubjectName 'CN=DSC.Company.Pri, OU=IT, DC=Company, DC=Pri' -Verbose}
    
# Can Export to PFX if needed on other web servers for high availability - Get-Help *pfx*
#>


# Add DNS entry for Pull server
$PullServer = 'moe-bs-dsc1'
$IPPullServer ='172.21.2.230'
$DOmainZone = 'moe-bs.lan'
$DNSName = 'DSC'
$creds = Get-Credential
Enter-PSSession -ComputerName moe-bs-ad1 -Credential $creds
Add-DnsServerResourceRecordA -ComputerName $PullServer -name $DNSName -IPv4Address $IPPullServer

# You need this module - xPSDesiredStateConfiguration on Author box and future Pull server
# My PULL server config also requires xWebAdministration
Find-Module -tag DSCResourceKit
find-Module -name xPSDesired*
Install-Module -name xPSDesiredStateConfiguration, xWebAdministration -force
# Push the DSC Resource install to a remote servers
$remoteserver = '' #Remote Server Name Here
Invoke-Command -ComputerName $remoteserver {Install-Module -name xPSDesiredStateConfiguration, xWebAdministration -force}

# Check out the documentation - specifically
ISE 'C:\Program Files\WindowsPowerShell\Modules\xPSDesiredStateConfiguration\3.8.0.0\Examples\Sample_xDscWebService.ps1'

# Create HTTPS Pull server configuration with ThumbPrint
ISE .\1.Config_Pullserver-Advanced-Https.ps1

# Configure LCM if needed -- I like too.
ISE .\2.LCM_Settings.ps1
Set-DscLocalConfigurationManager -ComputerName $PullServer -Path .\ -Verbose

# Deploy HTTPS Pull Server
Start-DscConfiguration -ComputerName $PullServer -Path .\ -Verbose -Wait

# My config removes components, so you should restart the pull server, or wait and DSC will do it for you
Restart-computer -ComputerName $PullServer -wait
Start-DscConfiguration -ComputerName $PullServer -UseExisting -Wait -Verbose -Force

# TEst the Pull Server
Start-Process -FilePath iexplore.exe https://dsc.moe-bs.lan:8080/PSDSCPullServer.svc
Start-Process -FilePath inetmgr

#################################################################################################################


#############################################################################################


