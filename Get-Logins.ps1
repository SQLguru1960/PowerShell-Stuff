<#
.SYNOPSIS
   Allows the user to query multiple servers to find specific logins based upon a search string or login type.  
.DESCRIPTION
   
.PARAMETER <paramName>
   
.EXAMPLE
   Get-Logins -ServerList AUSDVSQLGRDAG05 
        this will list all logins on the server/instance:  AUSDVSQLGRDAG05
   
   Get-Logins -ServerList AUSDVSQLGRDAG05 -SearchString dev*
        this will show all logins that match the search string "dev*" if they exist

   Get-Logins -ServerList AUSDVSQLGRDAG05 -LoginType WindowsLogin
        this will show all logins that are a windows login type (vs. sql server or windows group)
#>
function Get-Logins
{

[CmdletBinding()]

[Parameter (Mandatory         = $True,
		    ValueFromPipeline = $True )]
    param ( [string[]] $ServerList,
            [string] $SearchString,
            [string] $LoginType,
            [string[]] $OrderBy = "name",
            [switch] $ShowAllLogins = $false
          )


FOREACH ($item IN $ServerList)
{
    Write-Output "Working server: $item"

    $srv = New-Object "microsoft.sqlserver.management.smo.server" -ArgumentList $item

    $LoginList = $srv.Logins
    
    if ($ShowAllLogins)
    {
        $LoginList | ft -AutoSize
        continue
    }
        

    $LoginList.Where({$_.name -like $filter}) |
    select name, @{N="Role";E={$_.ListMembers()}}, isDisabled, state |
    sort -Property $OrderBy |
    ft -AutoSize

    <#
    $srv.Logins.Where({$_.name -like $filter}) |
    select name, @{N="Role";E={$_.ListMembers()}}, isDisabled, state |
    sort -Property name, role |
    # Export-Csv -Path "c:\temp\ListSALogins_$item.csv" 
    ft -a   
    #>
}
} # End function Get-Logins