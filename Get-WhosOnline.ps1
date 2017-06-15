function Get-WhosOnline {

[CmdletBinding()]

param
    (
        [Parameter (Mandatory = $True,
	                ValueFromPipeline = $True )]
        [string]  $serverInstance
    )


BEGIN {
Import-Module SQLPS -DisableNameChecking | Out-Null

$SQL = @"
SELECT
SPID AS [SPID]
, RTRIM(HOSTNAME) AS [HOST NAME]
, CONVERT(SYSNAME, RTRIM(LOGINAME)) AS [LOGIN NAME]
, RTRIM(SP.[PROGRAM_NAME]) AS [PROGRAM NAME]
, CMD AS [COMMAND]
, DB.NAME AS [DB NAME]
, CONVERT(NVARCHAR, LAST_BATCH, 113) AS [LAST BATCH TIME]
, SP.STATUS AS [STATUS]
, PHYSICAL_IO
, BLOCKED
, SP.REQUEST_ID
, SP.uid AS UID
FROM SYS.SYSPROCESSES SP     WITH (NOLOCK)
INNER JOIN SYS.DATABASES DB  WITH (NOLOCK)
ON  DB.DATABASE_ID = SP.DBID
WHERE SP.spid >= 50
ORDER BY HOSTNAME DESC
, CMD DESC
,[DB NAME] DESC;
"@
}


PROCESS {
    
    try {

        $test = Test-Connection -ComputerName $serverInstance  -Count 1  -Quiet  -ErrorAction Stop

        if ( $test -eq $false )
        {
            throw "Unable to Ping Server: $serverInstance"
        }

        $currentDate = Get-Date 
        
        Invoke-Sqlcmd -Query $SQL -ServerInstance $serverInstance | 
        Out-GridView -Title "Current SQL Connections: $serverInstance Date: $currentDate" 
    }
    catch {
        Write-Output "An Error Has Occurred"
		$_.exception.message
		return
    }

}

END {}

} # END FUNCTION GET-WhosOnline
