#Script to Delete users from active directory based on date in description field
#Author: Mike Schuler
#Date: 11/3/2022

#Import Active Directory Module
Import-Module ActiveDirectory

#Set Variables
$termOU = "OU=Term,DC=company,DC=com"
$logFile = "C:\temp\Logs\termUserDelete.log"
$today = Get-Date -Format "MM/dd/yyyy"
$emailFromAddress = ""
$emailToAddress = ""
$smtp = " "


#test to see if log file exists and create if not
if (!(Test-Path $logFile))
{
    New-Item -Path $logFile -ItemType File
}

#Get AD users from Term OU
try {
    $termUsers = Get-ADUser -Filter * -SearchBase $termOU -Properties Description | Out-Null
}
catch {
    Write-Host "Error getting users from $termOU" -ForegroundColor Red
}


#if uers do not have a term date in the description field or not a valid date set to todays date
foreach ($user in $termUsers)
{
    if ($user.Description -eq $null)
    {
        $user.Description = Get-Date -Format "MM/dd/yyyy"
        Set-ADUser -Identity $user.SamAccountName -Description $user.Description
    }
    elseif ($user.Description -notmatch "\d{2}/\d{2}/\d{4}")
    {
        $user.Description = $today
        Set-ADUser -Identity $user.SamAccountName -Description $user.Description
    }
}

#Loop through users and delete if description date is 30 days or older
foreach ($user in $termUsers)
{
    try {
        if (($user.Description | Get-Date -Format "MM/DD/yyyy") -lt (Get-Date -Format "MM/dd/yyyy").AddDays(-30))
        {
            Remove-ADUser $user.SamAccountName -Confirm:$false
            Write-Host "User $user.SamAccountName has been deleted" -ForegroundColor Green
            
            #log user deletion
            $log = Get-Date -Format "MM/dd/yyyy" + " " + $user.SamAccountName + " has been deleted"
            Add-Content -Path $logFile -Value $log
        }
        
    }
    catch {
        write-host "Error deleting user $user.SamAccountName" -ForegroundColor Red
    }


}

#send email with deleted users
if ($deletedObjects.count -gt 0)
{
    $deletedObjects | Out-File "C:\temp\deletedUsers.txt"
    $body = Get-Content "C:\temp\deletedUsers.txt"
    $subject = "Company - Term Users Deleted"
    $from = $emailFromAddress 
    $to = $emailToAddress
    $smtpServer = $smtp
    Send-MailMessage -From $from -To $to -Subject $subject -Body $body -SmtpServer $smtpServer
}
