$currentServer = $env:COMPUTERNAME
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn

#Set the HubTransport component to “Draining”, and redirect any messages currently in the queue to another server.
Set-ServerComponentState $currentServer –Component HubTransport –State Draining –Requester Maintenance
Redirect-Message -Server $currentServer -Target EX2016SRV2.exchangeserverpro.net

#Suspend the node from the cluster
Suspend-ClusterNode –Name $currentServer

#Disable database copy auto-activation. This command will also move any active database copies to other DAG members, assuming there are other healthy DAG members available. This is not instantaneous, it can take several minutes for the moves to occur. 
Set-MailboxServer $currentServer –DatabaseCopyActivationDisabledAndMoveNow $true

#Get current DB activation policy
$currentDBActivationPolicy = Get-MailboxServer $currentServer | Select -ExpandProperty DatabaseCopyAutoActivationPolicy
Set-Content -Path C:\temp\DBactivationpolicy.txt -Value $currentDBActivationPolicy
If ($currentDBActivationPolicy -ne "Blocked")
    {
    Set-MailboxServer $currentServer –DatabaseCopyAutoActivationPolicy Blocked
    }

Get-MailboxDatabaseCopyStatus -Server $currentServer | Where {$_.Status -eq "Mounted"}

Set-ServerComponentState $currentServer –Component ServerWideOffline –State InActive –Requester Maintenance


#Set-MailboxServer $currentServer –DatabaseCopyAutoActivationPolicy Unrestricted