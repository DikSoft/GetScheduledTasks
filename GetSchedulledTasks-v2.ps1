function is-sid( $InputString )
{
if ($InputString.SubString(0,5) -eq "S-1-5") 
    {
    Return $True
    }
    else

    {
    Return $False
    }

}

$VerbosePreference = "continue"


#$computername='DC2CISFTP01'

Set-Location (Split-Path $MyInvocation.MyCommand.Path) # Set the path of the script as the working directory
$directorypath = Split-Path $MyInvocation.MyCommand.Path

$TimeLog= get-date -Format yyyy'-'MM'-'dd'--'HH'-'mm'-'ss

$LogFileName=$directorypath + '\TaskLog-'+$TimeLog+'.log'


$logfilepath = $LogFileName # "TasksLog-20201109---.csv"
Add-content -path $logfilepath -Value "Num;ComputerName;item;AuthorOfTask;RunLevel;UserId;LogonType;ActionString"

# Unrem for CSV
#read CSV without headers
#$csv = Import-Csv "hostlist.txt"  -Encoding UTF8 -Delimiter "," 
#$TotalHosts=($csv | Measure-Object).Count 
#Write-Verbose  -Message "Trying to query $TotalHosts servers form Hosts.txt"


# Unrem for AD
$list = (Get-ADComputer -LDAPFilter "(&(objectcategory=computer)(OperatingSystem=*server*))").Name
Write-Verbose  -Message "Trying to query $($list.count) servers found in AD"

$ErrorActionPreference = "SilentlyContinue"

$CurrentHost=0

# Unrem for CSV
# process all strings
#foreach ($line in $csv) 



Write-Progress -Activity "Requesing servers .." -Status "0% Complete:" -PercentComplete 0


# Unrem for AD
foreach ($computername in $list)
{
$CurrentHost=$CurrentHost+1
$percent=($currentHost/$list.count) * 100
Write-Progress -Activity "Requesing servers .." -Status "$percent% Complete:" -PercentComplete $percent
# Unrem for CSV
#$ComputerName= $line.ComputerName

$path = "\\" + $computername + "\c$\Windows\System32\Tasks"
    $tasks = Get-ChildItem -Path $path -File -Recurse

    if ($tasks)
    {
        Write-Verbose -Message "I found $($tasks.count) tasks for $computername"
    }

    foreach ($item in $tasks)
    {
        #$AbsolutePath = $path + "\" + $item.Name
        $AbsolutePath=$Item.Fullname
        $task = [xml] (Get-Content $AbsolutePath)
        
        [STRING]$AuthorOfTask=$task.Task.RegistrationInfo.Author
        
        [STRING]$RunLevel=$task.Task.Principals.Principal.RunLevel     
#        $objSID2 = New-Object System.Security.Principal.SecurityIdentifier($task.Task.Principals.Principal.UserId)
#        $objUser2=$objSID2.Translate( [System.Security.Principal.NTAccount])
#        [STRING]$UserId=$objUser2.Value
        [STRING]$TmpUserId=$task.Task.Principals.Principal.UserId

        $IsSid=is-sid($TmpUserId)

        If ( $IsSid ) 
        {
        $objSID2 = New-Object System.Security.Principal.SecurityIdentifier($TmpUserId)
        $objUser2=$objSID2.Translate( [System.Security.Principal.NTAccount])
        $UserId=$objUser2.Value
        }
        else
        {
        $UserId=$TmpUserId
        }
        [STRING]$LogonType=$task.Task.Principals.Principal.LogonType

        [STRING]$ActionString=$task.Task.Actions.Exec.Command + " "+  $task.Task.Actions.Exec.Arguments



        if ($task.Task.Principals.Principal.UserId)
        {
          Write-Verbose -Message "Writing the log file with values for $computername"           
          Add-content -path $logfilepath -Value "$CurrentHost;$computername;$item;$AuthorOfTask;$RunLevel;$UserId;$LogonType;$ActionString"
        }

    }
}
Write-Progress -Activity "Requesing servers .." -Status "100% Complete:" -PercentComplete 100
