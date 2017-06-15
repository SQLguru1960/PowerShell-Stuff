function Get-DBCCTraceStatus
{

[CmdletBinding()]

param 
(
    [Parameter (Mandatory = $true)]
    [string[]] $serverList,
    [switch]   $isInputFile
)


BEGIN
{
    Import-Module SQLPS -DisableNameChecking | Out-Null

$sql = @"
DBCC TRACESTATUS(-1)
"@
}


PROCESS
{
    try 
    {
        if ( $isInputFile )
        {
            $validPath = Test-Path $serverList
            
            if( $validPath )
            {
                $servers = gc $serverList -ErrorAction Stop
            } 
            else 
            {
                Throw "File: $serverList - is not a valid file path, or the file does not exist!"
            }
        }
        else
        {
            $servers = $serverList
        }
        

        foreach ( $server in $servers ) 
        {
            try 
            {
                $canPing = Test-Connection -ComputerName $server -Count 1 -Quiet -ErrorAction Stop

                if ($canPing)
                {
                    Write-Output "Working Server: $server"
                    Invoke-Sqlcmd -ServerInstance $server -Query $sql -QueryTimeout 10 -ErrorAction Stop | ft -AutoSize
                }
                else 
                {
                    Throw "Unable to Ping Server: $server"
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
    catch 
    {
        Write-Output "An Error Has Occurred:"
		$_.exception.message
        Write-Output ""
    }
}


END {}

} ## END FUNCTION Get-DBCCTraceStatus
