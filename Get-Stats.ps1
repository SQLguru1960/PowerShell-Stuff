function Get-stats ($computer, $DB, $Table)
{
    $srv = New-Object Microsoft.SqlServer.Management.Smo.Server -ArgumentList $computer -ErrorAction Stop

    $database = $srv.Databases[$DB]

    $tablex = $database.Tables[$Table]

    $tablex.Statistics |
    select name, state, IsAutoCreated, lastupdated |
    fl 

}

Get-stats WN7X64-1284N12\TEDS_INSTANCE adventureworks2014 sales.salesorderheader