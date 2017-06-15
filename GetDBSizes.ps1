function Get-DatabaseSizes 
{

[CmdletBinding()]

param
(
    [string] $computername 
)

BEGIN { Import-Module sqlps -DisableNameChecking | Out-Null }

PROCESS
{
    try 
    {
        $test = Test-Connection -ComputerName $computername -Count 1 -Quiet -ErrorAction stop # Ping test only
    
        $srv = New-Object -TypeName microsoft.sqlserver.management.smo.server -ArgumentList $computername -ErrorAction Stop

        if ( $test -eq $false )
        {
           throw "Unable to Ping Server: $computerName"
        }	

        # Where ... gets rid of system db's and makes sure db's are available
        $databases = $srv.Databases.Where({ -not $_.IsSystemObject -and $_.IsAccessible })


        $databases |
        sort -Property size -Descending |
        ft Name, 
               @{N = "Size(MB)"; E={$_.size};formatstring='N2'}, 
               @{N = "DataSpaceUsage(KB)";  E={$_.dataspaceusage};formatstring='N2'},
               @{N = "IndexSpaceUsage(KB)"; E={$_.indexspaceusage};formatstring='N2'}, 
               @{N = "SpaceAvailable(KB)";  E={$_.Spaceavailable};formatstring='N2'} -AutoSize
        }
    catch 
    {
        Write-Output "AN ERROR HAS OCCURRED:"
	    Write-Output $_.exception.message
	    return        
    }
}

END {}

} # END Function Get-DatabaseSizes 

# Get-DatabaseSizes BLRPWRCACMDB01.blr.amer.dell.com
# Get-DatabaseSizes AUSPRSQLGRDCL01