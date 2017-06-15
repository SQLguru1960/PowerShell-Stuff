function Get-MissingIndexes
{

<#
.SYNOPSIS
Returns missing indexes based upon those found in the Missing Index DMV's
   
.DESCRIPTION
Get-MissingIndexes will pull all the missing index information from three (3) DMV's:
sys.dm_db_missing_index_groups
sys.dm_db_missing_index_group_stats
sys.dm_db_missing_index_details

And return those ranked by a Total Cost column.  The system databases are not queried
for missing index information.

.PARAMETER computername
Mandatory parameter that is used to identify the SQL Server server[s]

.PARAMETER database
Optional parameter to only pull missing index information for a specific database
If this is not used, all missing index information for all databases is returned

.EXAMPLE
Get-MissingIndexes -computername AUSDSQLGAGL13A [, ...]

Returns all missing indexes identified for server: AUSDSQLGAGL13A

.EXAMPLE
Get-MissingIndexes -computername AUSDSQLGAGL13A -database common*

Returns all missing indexes identified for database: common*, on server: AUSDSQLGAGL13A

#>


    [CmdletBinding()]

param 
(
    [Parameter (Mandatory = $true)] [string[]] $computername,
    [string] $database,
    [switch] $showSQL
)

BEGIN 
{
    Import-Module SQLPS -DisableNameChecking | Out-Null

$SQL = @'
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT ROUND(s.avg_total_user_cost * s.avg_user_impact * (s.user_seeks + s.user_scans), 0) AS [Total Cost]
, dbs.name AS [Database Name]
, d.[statement] AS [Table Name]
, equality_columns
, inequality_columns
, included_columns
FROM sys.dm_db_missing_index_groups G
	INNER JOIN sys.dm_db_missing_index_group_stats S
		ON s.group_handle = g.index_group_handle
	INNER JOIN sys.dm_db_missing_index_details D
		ON d.index_handle = g.index_handle
    INNER JOIN sys.databases dbs
        ON D.database_id = dbs.database_id
WHERE D.DATABASE_ID NOT IN (1,2,3,4)
ORDER BY [Total Cost] DESC;
'@
}


PROCESS
{

    if ($showSQL)
    {
        Write-Output "SQL Statement: $SQL"
        Write-Output ""
    }


    foreach ( $computer in $computername ) 
    {
        try 
        {
            $canPing = Test-Connection -ComputerName $computer -Count 1 -Quiet -ErrorAction Stop

            if ($canPing)
            {
                Write-Output "Working Server: $computer"

                if($database)
                {
                    $tbl_list = Invoke-Sqlcmd -ServerInstance $computer -Query $SQL -QueryTimeout 10 -ErrorAction Stop
                    $tbl_list.where({$_."database name" -like $database}) | fl
                }
                else
                {
                    Invoke-Sqlcmd -ServerInstance $computer -Query $SQL -QueryTimeout 10 -ErrorAction Stop | fl
                }
            }
            else 
            {
                Throw "Unable to Ping Server: $computer"
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

} # END FUNCTION Get-MissingIndexes

