function Get-SQLInventory
{
    [CmdletBinding()]
    param 
    (
        [Parameter(Mandatory=$True, 
                   ValueFromPipeline=$True,
                   HelpMessage="Enter Computer Name / IP:")]

        [ValidateCount(1,10)]
        [Alias('hostname')]
        [string[]] $instanceName,

        [string]   $OutFolder = "C:\temp",

        [string]   $ErrorLog = "C:\temp\SQLErrorLog.txt",

        [switch]   $LogErrors
    )
   
    Begin 
    {
        $LEN = $instanceName.Length
        Write-Verbose "Beginning Get-SQLInventory"
        Write-Verbose "Number of Input Instances: $LEN"
        Write-Verbose "Output Folder: $OutFolder"
        Write-Verbose "Error Log: $ErrorLog"
    }

    Process 
    {
        Write-Verbose "Instance Name: $instanceName"
        try
        {
            $server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $instanceName  -ErrorAction Stop
        }
        catch 
        {
            if ($LogErrors)
                {
                    $instanceName | Out-File $ErrorLog -Append
                }    
        }

        $currentDate = Get-Date -Format "yyyy-MM-dd_hmmtt"

        $filename = "InstanceInventory_$($currentDate).csv"

        $fullpath = Join-Path $OutFolder $filename

        # export all server property stuff
        $server |
        Get-Member |
        Where-Object Name -NE "SystemMessages" |
        Where-Object membertype -EQ "Property" |
        Select name, @{Name="Value"; E={$server.($_.name)}} |
        Export-Csv -Path $fullpath -NoTypeInformation
        
        
        # now go after Job info and last run date
        $server.JobServer.Jobs |
        select @{N="Name";E={"Job: $($_.name)"}},
               @{N="Value";E={"Last Run: $($_.LastRunDate) ($($_.lastrunoutcome))"}} |
        Export-Csv -Path $fullpath -NoTypeInformation -Append

    }

    End 
    {
        Write-Verbose "Get-SQLInventory completed"
        Write-Verbose "CSV file written to: $fullpath"
    }
}