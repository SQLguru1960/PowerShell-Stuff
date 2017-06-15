<#
.SYNOPSIS
   <A brief description of the script>
.DESCRIPTION
   <A detailed description of the script>
.PARAMETER <paramName>
   <Description of script parameter>
.EXAMPLE
   <An example of using the script>
#>
function Get-DBInventory
{
   [CmdletBinding()]
   [Parameter (Mandatory = $True,
		       ValueFromPipeline = $True )]
    param ([string] $computerName, 
           [switch] $ToScreen)


BEGIN
{
    Import-Module sqlps -DisableNameChecking | Out-Null
}

PROCESS 
{

$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $computername -ErrorAction stop

$folder = "c:\temp"

$filename = "DB Inventory.csv"

$fullpath = Join-Path $folder $filename

$result = @()


foreach ($db in $server.Databases)
{
    Write-Verbose "Working DB: $db"

    $item = $null
	
	$hash = @{"DBName" 	            = $db.name
		      "CreateDate"		    = $db.CreateDate
		      "Owner"				= $db.owner
		      "RecoveryModel"	    = $db.recoverymodel
		      "Size/MB"			    = $db.size
		      "DataSpaceUsage/KB"	= $db.dataspaceusage
		      "IndexSpaceUsage/KB"	= $db.indexspaceusage
		      "Collation"			= $db.collation
		      "UserCount"			= $db.users.count
		      "TableCount" 		    = $db.tables.count
		      "SPCount"			    = $db.storedprocedures.count
		      "UDFCount"			= $db.userdefinedfunctions.count
              "ViewCount"           = $db.Views.Count
		      "LastBUPDate"		    = $db.lastbackupdate
		      "LastDiffBUPDate"     = $db.lastdifferentialbackupdate
		      "LastLogBUPDate"	    = $db.lastlogbackupdate
    }
	
	$item = New-Object PSObject -Property $hash
    $result += $item
}

    if ($ToScreen)
    {
        $result | 
	    Select DBName, createdate, owner, 
               recoverymodel, size/mb, dataspaceusage/kb, 
               indexspaceusage/kb, collation, usercount,
	           tablecount, spcount, udfcount, viewcount, lastbupdate, 
               lastdiffbupdate, lastlogbupdate |
        Out-GridView -Title "SQL Server Inventory: $computername" 
    }
    else
    {
        $result | 
	    Select DBName, createdate, owner, 
               recoverymodel, size/mb, dataspaceusage/kb, 
               indexspaceusage/kb, collation, usercount,
	           tablecount, spcount, udfcount, viewcount, lastbupdate, 
               lastdiffbupdate, lastlogbupdate |
         Export-Csv -Path $fullpath -NoTypeInformation
    }
} # End PROCESS block

END {}

} # End Function
# --------------------------------------------------------------------------------------------------------


Get-DBInventory -computerName WN7X64-1284N12\TEDS_INSTANCE -ToScreen