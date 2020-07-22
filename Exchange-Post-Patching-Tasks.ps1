[CmdletBinding()]
param (
        [Parameter( Mandatory=$true)]
        [string]$emailRecipient
    )

$currentServer = $env:COMPUTERNAME
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn

Write-Host "Activating Server"
Set-ServerComponentState $currentServer –Component ServerWideOffline –State Active –Requester Maintenance

Write-Host "Resuming cluster node"
Resume-ClusterNode –Name $currentServer

Write-Host "Reverting Database Copy Auto Activation Policy to previous setting"
$DBActivationPolicy = Get-Content C:\temp\DBactivationpolicy.txt
    if ($DBActivationPolicy)
    {
    Set-MailboxServer $currentServer –DatabaseCopyAutoActivationPolicy $DBActivationPolicy
    }
        else
        {
        Set-MailboxServer $currentServer –DatabaseCopyAutoActivationPolicy Unrestricted
        }

Write-Host "Enabling DB activation on server"
Set-MailboxServer $currentServer –DatabaseCopyActivationDisabledAndMoveNow $false

Write-Host "Activating HubTransport"
Set-ServerComponentState $currentServer –Component HubTransport –State Active –Requester Maintenance


$timestamp = Get-Date -Format "MMddyyyy-HHmm"
$reportName = "C:\temp\ExchangePostPatchingReport_$timestamp.html"
#$emailRecipient = "administrator@test.lab"
#$emailSender = "administrator@test.lab"
$emailSubject = ""

Invoke-Expression -Command ".\Test-ExchangeServerHealth.ps1 -ReportMode -SendEmail -EmailServer $currentServer -EmailRecipient $emailRecipient"