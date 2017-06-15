function Get-SQLServices
{
    [CmdletBinding()]
    
    param (
            [Parameter (Mandatory = $true)]
            [string]   $InputVar,

            [switch]   $isServerName,
            [switch]   $allSQLServices
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
                if ($allSQLServices) 
                {
                    Get-Service -ComputerName $server -displayname "*sql*" |
                    sort -Property status |
                    ft name, displayname, status  -AutoSize
                } else {
                    Get-Service -ComputerName $server -displayname "sql server (*" |
                    sort -Property status |
                    ft name, displayname, status  -AutoSize
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

} ## END FUNCTION Get-SQLServices
