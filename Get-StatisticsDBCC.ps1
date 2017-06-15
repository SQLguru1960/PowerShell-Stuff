function Get-StatsDBCC ($computer, $DB, [string] $Table)
{
    Import-Module sqlps -DisableNameChecking | out-null
    
    
    $srv = New-Object Microsoft.SqlServer.Management.Smo.Server -ArgumentList $computer -ErrorAction Stop

    $database = $srv.Databases[$DB]

    $tables = $database.Tables

    $tbl = $tables['salesorderheader']

    $database

    $tbl

<#
    $tables |
    % {$_} |
    select schema, name |
    ft -AutoSize

 
$SQL = @"
DBCC ($tablex,$Object)
GO
"@    
    
    
    if ($Option -ne $null)
    {
            
    }


    $tablex.Statistics |
    select name, state, IsAutoCreated, lastupdated |
    fl
    #>

}

Get-statsDBCC WN7X64-1284N12\TEDS_INSTANCE adventureworks2014 sales.salesorderheader 