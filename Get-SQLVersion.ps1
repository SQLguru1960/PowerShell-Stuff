function Get-SQLVersion
{
    [CmdletBinding()]

    param 
    (
        [Parameter (Mandatory = $true,
                    ValueFromPipeline = $true)]
        
        [ValidateCount(1,10)]

        [string[]] $Computername

    )


    BEGIN 
    {
        Import-Module SQLPS -DisableNameChecking | Out-Null
    }


    PROCESS 
    {
        Write-Verbose "Begin Process Block"

        foreach ($computer in $Computername)
        {

            $obj = $null

            # $props.clear()

            try 
            {
                $canPing = Test-Connection -ComputerName $computer -Count 1 -Quiet -ErrorAction Stop

                if ($canPing)
                {
                    Write-Output "Working Server: $computer"
                    $srv  = New-Object -TypeName Microsoft.sqlserver.management.smo.server  -ArgumentList $computer -ErrorAction Stop
                }
                else 
                {
                    Throw "Unable to Ping Server: $computer"
                }

            } 
            catch 
            {
                Write-Output "An Error Has Occured"
                $_.exception.message
                Write-Output ""
            }

            $props = [ordered] @{ 'SQLServerVersion' = $srv.Version
                                  'SQLSRVString'     = $srv.VersionString
		    }

            $obj = New-Object -TypeName PSObject -Property $props

            Write-Output $obj | ft -AutoSize
        } 
    
        Write-Verbose "WMI Queries Completed"
    }


    END {}

} # end function

Get-SqlVersion -Computername AUSDSQLGAGL09A