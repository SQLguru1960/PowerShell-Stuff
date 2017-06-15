function Get-DBInfo
{

<#

.Synopsis
Get-DBInfo will return all database information based upon the server SMO class.  The user
has three options for use:
1. database name:  provide a string for a specific database or group of databases
2. version information only:  this option will only return the OS and DB versions of the 
   specific server
3. all DB information: this option will return all parameters for the database object, this
   is the most verbose output.  Eliminating this option will cause the program to return
   the following information for those databases found:

name 
createdate
CompatibilityLevel
isaccessible
recoverymodel
lastbackupdate 
lastdifferentialbackupdate
lastlogbackupdate
LogReuseWaitStatus


.DESCRIPTION

.PARAMETER computername
Mandatory parameter, value used to connect to the database server. Multiple servers may
be listed.

.PARAMETER databasename
Optional parameter, may be used to seek a specific database or group of databases.  The
Regex wildcard '*' may be used.

.PARAMETER versionInfoOnly
Optional parameter that, when used, will only return the server name, server OS version, 
and server DB version.

.PARAMETER AllDBInfo
Optional parameter that will return all database parameters found in the database SMO
class.  If used on a server with many databases, the output will be large.


.EXAMPLE
   Get-DBInfo -computername AUSDSQLGAGL13A 

   This example will query server: AUSDSQLGAGL13A and return information (see above) for 
   all available databases.  

.EXAMPLE
   Get-DBInfo -computername AUSDSQLGAGL13A, AUSDSQLGAGL09A -versionInfoOnly
   
   Both servers, AUSDSQLGAGL13A and AUSDSQLGAGL09A, will be queried for their OS and Database
   version[s] only.


   .EXAMPLE
   Get-DBInfo -computername AUSDSQLGAGL13A, AUSDSQLGAGL09A -databasename DIT* -allDBInfo
   
   Both servers, AUSDSQLGAGL13A and AUSDSQLGAGL09A, are queried for any databases with names
   that begin with DIT.  Of those return, all will have every database parameter returned
   based upon those found in the SMO database class.

#>

    [CmdletBinding()]

    param 
    (
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)] [ValidateCount(1,10)] [string[]] $computername,
        [string]   $databasename = $null,
        [switch]   $versionInfoOnly,
        [switch]   $AllDBInfo
    )

    BEGIN
    {
        Import-Module SQLPS -DisableNameChecking | Out-Null
    }

    PROCESS 
    {
        foreach ($computer in $computername)
        {   
            try 
            {
                Write-Verbose "Testing server connection: $computer"

                $canConnect = Test-Connection -ComputerName $computer -Count 1 -Quiet -ErrorAction Stop

                if ($canConnect)
                {
            
                    Write-Verbose "`$canConnect is true - $canConnect"

                    $server = New-Object -TypeName microsoft.sqlserver.management.smo.server -ArgumentList $computer -ErrorAction Stop

                    if ($versionInfoOnly)  # User may just want a quick glance at the versions, nothing else
                    {
                        "Server: " + $server.Name.ToString()
                        "Server OS Version: " + $server.OSVersion.ToString()
                        "Server DB Version: " + $server.VersionString.ToString()
                        continue
                    }

                    # Print out server name and version info
                    "Server: " + $server.Name.ToString()

                    "Server OS Version: " + $server.OSVersion.ToString()

                    "Server DB Version: " + $server.VersionString.ToString()


                    $databases = $server.databases.Where({ $_.IsAccessible }) # be sure the DB[s] are accessible


                    # databases found on server?
                    if($databases.Count -eq 0)
                    {
                        Write-Output "No Databases Found!"
                        continue
                    }
                    else 
                    {
                        "Database Count: " + $databases.Count.ToString()
                    }

                
                    # specific database name entered?
                    if ($databasename)  
                    { 
                        $databases = $databases.where({$_.name -like $databasename}) 
                        # be sure something exists, if not, tell the user
                        if ( $databases.count -lt 1  ) {
                            throw "No Databases Found For Input String: $databasename"
                        }
                    }
                    
                
                    # list DB's to user...
                    if ($AllDBInfo)
                    {
                        Write-Output "Gathering ALL Database Information - Please Stand By ..."
                        $databases |
                        select * |
                        sort |
                        fl
                    } 
                    else
                    {
                        $databases |
                        select name, createdate, CompatibilityLevel, isaccessible, recoverymodel,
                        lastbackupdate, lastdifferentialbackupdate, lastlogbackupdate,
                        LogReuseWaitStatus  |
                        ft -AutoSize
                    }
                }
                else
                {
                    Throw "Unable to Connect to Server: $computer"
                }
            }
            catch 
            {
                Write-Output "An Error Has Occurred:"
		        $_.exception.message
                Write-Output ""
            }
        }
    }

END{}

} ## END Get-DBInfo
