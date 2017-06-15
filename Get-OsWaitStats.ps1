function Get-OsWaitStats
{

<#

.Synopsis
Get-OsWaitStats returns values for all wait statistics on the database server.  These
are cumulative statistics, values shown are given since the last server restart.

.DESCRIPTION

.PARAMETER computername
Mandatory parameter, value used to connect to the database server.  Only a single server
may be queried at a time.

.PARAMETER InstanceName
Optional parameter, used if there is a specific instance to be used.

.PARAMETER To_Output_File
Optional Boolean parameter, if included, the output of the command will be directed to 
an output file vs. a GUI output screen.

.PARAMETER Out_Filename
Optional parameter, if used along with to_output_file, the filename given is used to
hold the result set. *Note: if the user does not include a filename path, the default
filepath/filename will be used: C:\temp\OsWaitStats.csv

.EXAMPLE
   Get-OSWaitStats -computername AUSDSQLGAGL13A 

   This example will query server: AUSDSQLGAGL13A and return a list of wait statistics to
   a GUI based grid report.  The user may sort or eliminate the waits returned.

.EXAMPLE
   Get-OSWaitStats -computername AUSDSQLGAGL13A -InstanceName someInstance -To_Output_file

   Wait statistics are queried from the server: AUSDSQLGAGL13A, Instance: someInstance and 
   returned to the default output filename: C:\temp\OsWaitStats.csv

#>

    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory = $true,  ValueFromPipeline = $true)] [ValidateNotNullOrEmpty()] [String] $computername,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)] [String] $InstanceName,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)] [switch] $To_Output_File,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)] [String] $Out_Filename
    )


BEGIN
{

Import-Module SQLPS -DisableNameChecking | Out-Null

$SQL = @"
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT
wait_type AS 'Wait Type',
waiting_tasks_count AS 'Waiting Tasks Count',
(wait_time_ms - signal_wait_time_ms) AS 'Resource Wait Time'
, signal_wait_time_ms AS 'Signal Wait Time'
, wait_time_ms AS 'Total Wait Time'
, COALESCE(wait_time_ms / NULLIF(waiting_tasks_count,0), 0) AS 'Average WaitTime'
FROM sys.dm_os_wait_stats;
"@

if( $Out_Filename.Length -eq 0) { $Out_Filename = "C:\temp\OsWaitStats.csv" } # Default filename

$QryTimeout = 10                                                              # Query Timeout for Invoke-SQLCMD

}


PROCESS
{
    try 
    {
        
        $test = Test-Connection -ComputerName $computername -Count 1 -Quiet  -ErrorAction Stop 

        if ( $test -eq $false )
        {
            throw "Unable to Ping Server: $computerName"
        }			


        $srv  = New-Object -typename microsoft.sqlserver.management.smo.server -argumentlist $computername  -ErrorAction Stop


        if ($srv -eq $null)
        {
            throw "Unable To Connect to Server: $computername"
        }

        # -- DEBUG ONLY --
        Write-Debug "computer: $computername"
        Write-Debug "instance: $InstanceName"
        Write-Debug "to file:  $To_Output_File"
        Write-Debug "output file name: $Out_Filename"
        
        
    
    }
    catch 
    {
        Write-Output "An Error Has Occurred!"
        Write-Output $_.exception.message
        return
    }
    

    try 
    {

        # Query instance based upon host and instance name - if given
        if ($InstanceName.Length -eq 0 -or $InstanceName.Contains("null"))
        {
            Write-Debug "In first sqlcmd statement"
            $results = Invoke-Sqlcmd -ServerInstance $computername -Query $SQL -QueryTimeout $QryTimeout -ErrorAction Stop 
        } 
        else
        {
            Write-Debug "In second sqlcmd statement"
            $results = Invoke-Sqlcmd -ServerInstance $InstanceName -HostName $computername -Query $SQL -QueryTimeout $QryTimeout -ErrorAction Stop 
        }


        # Display the results or write to output file
        if ( $To_Output_File -eq $true )
        {
            $results | Export-Csv -Path $Out_Filename -Append -NoTypeInformation -ErrorAction Stop

            if ( Test-Path -Path $Out_Filename ) 
            { 
                Write-Output "Output Written to File: $Out_Filename"
            }
            else 
            {
                Throw "Error Writing to File: $Out_Filename"
            }
        }
        else
        {
            $results | Out-GridView -Title "$computername OS Wait Statistics" 
        }

    }
    catch 
    {
        Write-Output "A SQL Error Has Occurred!"
        Write-Output $_.exception.message
        return
    }
     
}


END {}

} ## END Get-OsWaitStats
