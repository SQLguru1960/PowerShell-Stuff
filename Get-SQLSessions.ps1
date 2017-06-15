function Get-SQLSessions
{

<#
.SYNOPSIS
Returns a list of current SQL Sessions on a server.
   
.DESCRIPTION
Get-SQLSessions returns a list of the current SQL Server sessions that exist on one, or more,
servers input by the user.  The output inclueds: the login name, session ID, status, connection
time, and others.

The output may be directed to the screen or to a GUI Grid View where the user can sort each 
column return, and perform additional search options.

.PARAMETER computername
Mandatory parameter that is used to identify the SQL Server server[s].  Several server names may
be entered, each separated by a comma.

.EXAMPLE
Get-SQLSessions -computername AUSDSQLGAGL09A [, ...]

Returns a list of sessions and session information to the user screen

.PARAMETER GridView
Optional parameter that directs the output to a GUI based Grid View

.EXAMPLE
Get-SQLSessions -computername AUSDSQLGAGL09A [, ...] -GridView

Returns a list of sessions and session information to a Grid View

#>


[CmdletBinding()]

param
(
       [Parameter (Mandatory = $True, ValueFromPipeline = $True )] [string[]] $computername,
       [switch] $GridView
)


BEGIN
{
$SQLQuery = @"
SELECT dec.client_net_address ,
des.program_name ,
des.host_name ,
des.login_name ,
dec.session_id,
des.status,
dec.connect_time,
des.last_request_start_time,
des.last_request_end_time
FROM sys.dm_exec_sessions AS des
INNER JOIN sys.dm_exec_connections AS dec
ON des.session_id = dec.session_id
GROUP BY dec.client_net_address ,
des.program_name ,
des.host_name, 
des.login_name,
dec.session_id,
dec.connect_time,
des.status,
des.last_request_start_time,
des.last_request_end_time
ORDER BY dec.session_id 
       , dec.connect_time desc
       , des.program_name
       , dec.client_net_address;
"@

Import-Module SQLPS -DisableNameChecking | Out-Null

}


PROCESS
{
    foreach ($computer in $computername)
    {
        try
        {
            $canPing = Test-Connection -ComputerName $computer -Count 1 -Quiet

            if ($canPing)
            {

                $SRV = New-Object microsoft.sqlserver.management.smo.server -ArgumentList $computer -ErrorAction Stop

                if ($GridView) 
                {
                    Invoke-Sqlcmd -Query $SQLQuery -ServerInstance $SRV -ErrorAction Stop | Out-GridView -Title "SQL Sessions for Server: $computer"
                }
                else 
                { 
                    Write-Output "Server: $computer"
                    Invoke-Sqlcmd -Query $SQLQuery -ServerInstance $SRV -ErrorAction Stop | ft -AutoSize 
                }

            }
            else
            {
                throw "Unable to Ping Server: $computer"
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


END {}


} ## END FUNCTION: Get-SQLSessions

