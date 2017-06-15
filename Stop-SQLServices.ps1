function Stop-SQLServices
{
    [CmdletBinding()]
    
    param (
            [Parameter (Mandatory = $true)]
            [string]   $InputVar,

            [switch]   $isServerName
          )


BEGIN { Import-Module SQLPS -DisableNameChecking | Out-Null }    


PROCESS
{

    Write-Verbose "Value of InputVar variable: $InputVar, isServerName: $isServerName"

    try {
            if ($isServerName)    
            {
                $ServerList = $InputVar
            } 
            else 
            {
                $validPath = Test-Path $InputVar  

                if($validPath)
                {
                    $ServerList = gc $InputVar -ErrorAction Stop
                } 
                else 
                {
                    Throw "File: $InputVar, is not a valid file path, or the file does not exist"
                }
            }
    } 
    catch 
    {
        Write-Output "An Error Has Occurred:"
		$_.exception.message
        Write-Output ""
    }


    foreach ($server in $ServerList)
    {
        try {

            $CanPing = Test-Connection -ComputerName $server -Count 1 -Quiet -ErrorAction Stop

            if ($CanPing)
            {
                Write-Output "Working server: $server"

                # the magic happens here:
                if ((Get-Service -ComputerName $server -displayname "sql server (*" | Where {$_.status -eq "running"}))
                {
                    try {
                        Get-Service -ComputerName $server -displayname "sql server (*" | 
                        Where {$_.status -eq "running"} |
                        Stop-Service -Force -Confirm -ErrorAction Stop
                    } catch {
                        Write-Output "An Error Has Occurred:"
		                $_.exception.message
                        Write-Output ""
                    }
                } else {
                    Write-Output "SQL Server Service is Already Stopped on Server: $server"
                }
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

END {}
    
} ## END FUNCTION STOP-SQLServices
