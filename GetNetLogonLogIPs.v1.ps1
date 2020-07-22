# Script to get the IP addresses of clients from the Netlogon.log file of all domain controllers in the current domain
# from the current month and the previous month
# by Mike Cessna
#
# mcessna
#        @anexinet.com
   

################################Start Functions####################################

function GetDomainControllers {
    $DCs=[system.directoryservices.activedirectory.domain]::GetCurrentDomain() | ForEach-Object {$_.DomainControllers} | ForEach-Object {$_.Name}
    return $DCs
}

function GetNetLogonFile ($server) {
    #build Path variable
    $path= '\\' + $server + '\c$\windows\debug\netlogon.log'
    #Try to connect to $path and get the file contents or throw an error
    try {$netlogon=get-content -Path $path -ErrorAction stop}
    catch { "Can't open $path"}
    #reverse the array's order so we are now working from the end of the file back
    [array]::Reverse($netlogon)
	#clear out the holding variable
    $IPs=@()
    #go through the lines
    foreach ($line in $netlogon) {
        #split the line into pieces using a space as the delimiter
        $splitline=$line.split(' ')
        #Get the date stamp which is in the mm/dd format
        $logdate=$splitline[0]
        #split the date
        $logdatesplit=($logdate.split('/'))
        [int]$logmonth=$logdatesplit[0]
        #only worry about the last month and this month
        if (($logmonth -eq $thismonth) -or ($logmonth -eq $lastmonth)) {
            #only push it into an array if it matches an IP address format
            if ($splitline[5] -match '\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'){
                $objuser = new-object system.object
                $objuser | add-member -type NoteProperty -name IPaddress -value $splitline[5]
                $objuser | add-member -type NoteProperty -name Computername -value $splitline[4]
                $objuser | add-member -type NoteProperty -name Server -value $server
                $objuser | add-member -type NoteProperty -name Date -value $splitline[0]
                $objuser | add-member -type NoteProperty -name Time -value $splitline[1]
                $IPs+=$objuser
            }
        } else {
            #break out of loop if the date is not this month or last month
            break
        }
    }
    return $IPs
}

###############################End Functions#######################################

###############################Main Script Block###################################
#Get last month's date
$thismonth=(get-date).month
$lastmonth=((get-date).addmonths(-1)).month

#get all the domain controllers
$DomainControllers=GetDomainControllers
#Get the Netlogon.log from each DC
Foreach ($DomainController in $DomainControllers) {
    $IPsFromDC=GetNetLogonFile($DomainController)
    $allIPs+=$IPsFromDC
}
#Only get the unique IPs and dump it to a CSV file
$allIPs | Sort-Object -Property IPaddress -Unique | Export-Csv "E:\bin\NetlogonIPs.csv"

<#Set up mail variables
$from="IT@company.com"
$to="mcessna@company.com","testDL@company.com"
$subject="IP addresses in Netlogon.log file from the last month"
$attach="E:\bin\NetlogonIPs.csv"
$body="File containing all unique IPs listed in the netlogon.log file for all the Domain Controllers in the company domain."
#Send mail message
Send-MailMessage -from $from -To $to -subject $subject -SmtpServer 10.10.10.10 -Body $body -BodyAsHtml -Attachments $attach
#>