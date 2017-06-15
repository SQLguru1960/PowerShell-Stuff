function Get-DBInventory
{
<#
.SYNOPSIS
Pulls database information back to the user based upon a server name.
   
.DESCRIPTION
Get-DBInventory allows the user to write database information to either the output screen
or to a .CSV file.  The input parameter (computername) is used to connect to the server
where the SQL Server instance[s] are located. 
  
Output from the command includes:
    Database name
	Status
    Creation date
    Database Owner
    Recovery model
    Database size
    Data space used
    Index space used
    Collation
    User count
    Table count
    Stored Procedure count
    User Defined Function count
    View count
    Last backup date
    Last differential backup date
    Last Log backup date

.PARAMETER computerName
Mandatory parameter that is used to identify the server where the SQL Server databases can be found

.PARAMETER ToScreen
Optional parameter: if included - used to direct the output to the user screen

.EXAMPLE
Get-DBInventory -computername AUSDBSQLMASTER3
Compile a database inventory from server: AUSDBSQLMASTER3 and output the results to a .CSV file: ("AUSDBSQLMASTER3 - DB Inventory" in this example)
The default filepath is:  "C:\temp\<computername> - DB Inventory"

.EXAMPLE
Get-DBInventory -computername AUSDBSQLMASTER4 -ToScreen
Compile a database inventory from server: AUSDBSQLMASTER4 and output the results to the screen in a GUI grid format
#>
[CmdletBinding()]

param 
(
    [Parameter (Mandatory = $True,
	 ValueFromPipeline = $True )]
    [string] $computerName,

	[switch] $ToScreen
)


BEGIN
{
	Import-Module sqlps -DisableNameChecking | Out-Null
}


PROCESS 
{
		
	try
	{
		$test = Test-Connection -ComputerName $computername -Count 1 -Quiet -ErrorAction stop # Ping test only
			
		$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $computername -ErrorAction stop
            
        if ( $test -eq $false )
        {
            throw "Unable to Ping Server: $computerName"
        }			


		if ( -not $server.Databases["master"].IsAccessible ) 
		{
			throw "Unable to Access Databases";
		}
	}
	catch
	{
		Write-Output "AN ERROR HAS OCCURRED:"
		Write-Output $_.exception.message
		return
	}
		
	$folder = "c:\temp"

	$filename = "$($computername.toUpper()) - DB Inventory.csv"

	$fullpath = Join-Path $folder $filename

	if (-not $ToScreen)
	{
		Write-output "Output path: $fullpath"
	}

	$result = @()

	foreach ( $db in $server.Databases )
	{
		Write-Verbose "Working DB: $db"

		$item = $null

		$hash = @{"DBName" = $db.name
			"Status"       = $db.status
			"Version"      = $db.version
			"CreateDate"   = $db.CreateDate
			"Owner"        = $db.owner
			"RecoveryModel" = $db.recoverymodel
			"Size/MB"       = $db.size
			"DataSpaceUsage/KB"  = $db.dataspaceusage
			"IndexSpaceUsage/KB" = $db.indexspaceusage
			"Collation"    = $db.collation
			"UserCount"    = $db.users.count
			"TableCount"   = $db.tables.count
			"SPCount"      = $db.storedprocedures.count
			"UDFCount"     = $db.userdefinedfunctions.count
			"ViewCount"    = $db.Views.Count
			"LastBUPDate"  = $db.lastbackupdate
			"LastDiffBUPDate" = $db.lastdifferentialbackupdate
			"LastLogBUPDate"  = $db.lastlogbackupdate
		}

		$item = New-Object PSObject -Property $hash
		$result += $item
	}

	if ( $ToScreen )
	{
		$result | 
		Select DBName, status, version, createdate, owner, 
		recoverymodel, size/mb, dataspaceusage/kb, 
		indexspaceusage/kb, collation, usercount,
		tablecount, spcount, udfcount, viewcount, lastbupdate, 
		lastdiffbupdate, lastlogbupdate |
		Out-GridView -Title "SQL Server Inventory: $computername" 
	}
	else
	{
		$result | 
		Select DBName, status, version, createdate, owner, 
		recoverymodel, size/mb, dataspaceusage/kb, 
		indexspaceusage/kb, collation, usercount,
		tablecount, spcount, udfcount, viewcount, lastbupdate, 
		lastdiffbupdate, lastlogbupdate |
		Export-Csv -Path $fullpath -NoTypeInformation -ErrorAction stop 

		if ( Test-Path $fullpath )
			{ Write-Output "DB Inventory written to path: $fullpath" }
		else
			{ Write-Output "Error writing file to: $fullpath" }
	}

} 


END {}


} # End Function Get-DBInventory

# --------------------------------------------------------------------------------------------------------

function Get-SystemInfo
{
<#
.SYNOPSIS
Returns the system information based upon a server Name or IP address
 
.DESCRIPTION
Uses WMI objects to pull the OS version, SP version, BIOS, Manufacturer and other
system information.

.PARAMETER computerName
Mandatory parameter that is used to identify the server, you may enter one or several
server names seperated by commas.  Note: the maximum number of servernames is 10.

.EXAMPLE
Get-SystemInfo -computername AUSDBSQLMASTER3
Returns the system information for server: AUSDBSQLMASTER3

.EXAMPLE
Get-SystemInfo -computername AUSDBSQLMASTER3, AUSDVSQLGRD04
Returns the system information for servers AUSDBSQLMASTER3 and AUSDVSQLGRD04
#>
[CmdletBinding()]

param 
(
	[Parameter (Mandatory = $true,
		ValueFromPipeline = $true)] 
	[ValidateCount(1,10)]
	[string[]] $Computername
)


BEGIN {}


PROCESS 
{
	Write-Verbose "Begin Process Block"

	foreach ($computer in $Computername)
	{
		Write-Verbose "Working Server: $Computer"

		$obj = $null

		try 
		{
			$os   = Get-WmiObject -Class win32_operatingsystem  -ComputerName $computer -ErrorAction Stop
			$comp = Get-WmiObject -Class win32_computersystem   -ComputerName $computer -ErrorAction Stop
			$bios = Get-WmiObject -Class win32_BIOS             -ComputerName $Computer -Erroraction Stop
            $phys = Get-WmiObject -Class win32_PhysicalMemory   -ComputerName $computer -ErrorAction Stop
		} catch 
		{
				write-output "An Error Has Occurred:"
				Write-Output "Server Name: $computer"
				$_.exception.message
				continue
		}

		$props = [ordered] @{'ComputerName' = $computer
			'Staus'      = $os.status
			'OS Name'    = $os.name
			'OSVersion'  = $os.version
			'SPVersion'  = $os.servicepackmajorversion
			'BIOSSerial' = $bios.serialnumber
			'NoOfProcessors' = $comp.numberOfProcessors
			'FreeMemory/KB'  = $os.freePhysicalMemory
			'FreeVirtualMemory/KB' = $os.freeVirtualMemory
            'TotalVirtualMemory/KB' = $os.totalvirtualmemorysize
            'TotalPhysicalMemory/Bytes' = $Comp.TotalPhysicalMemory
            'MemoryCapacity/Bytes' = $phys.capacity
			'NoOfUsers'    = $os.numberOfUsers
			'Manufacturer' = $comp.manufacturer
			'Model'        = $comp.model
		}

		$obj = New-Object -TypeName PSObject -Property $props 

		Write-Output $obj

		$props.clear()
	} 

	Write-Verbose "WMI Queries Completed"
}


END {}


} # End Function Get-SystemInfo

# --------------------------------------------------------------------------------------------------------

function Script-Jobs
{
<#
.SYNOPSIS
 Scripts all SQL Jobs defined on a server

.DESCRIPTION
 The function will script all SQL jobs defined on the server that the user has specified.  The
 script may be written to a command file (.sql), to the screen, or may return the total number
 of jobs defined.

.PARAMETER computerName
Mandatory parameter that is used to identify the server.

.PARAMETER filepath
Optional parameter allows user to set the output filepath and file Name.  The default 
is: "C:\temp\ServerAgentJobs.sql"

.PARAMETER ToScreen
Boolean parameter: if included - directs the output to the user screen instead of a
command file.

.PARAMETER CountOnly
Boolean parameter: if included - the function will only return the total number (count)
of existing jobs on the system.

.EXAMPLE
Script-Jobs -computername AUSDBSQLMASTER3
Returns all the jobs defined on server: AUSDBSQLMASTER3

.EXAMPLE
Script-Jobs -computername AUSDBSQLMASTER3 -ToScreen
Returns all jobs for server: AUSDBSQLMASTER3, and writes the output to the user screen.

.EXAMPLE
Script-Jobs -computername AUSDBSQLMASTER3 -filepath "C:\SQL_SERVER\Jobs.sql"
Returns all jobs for server: AUSDBSQLMASTER3, and writes the output to the user defined filepath.

.EXAMPLE
Script-Jobs -computername AUSDBSQLMASTER3 -CountOnly
Returns the total number of jobs defined on server: AUSDBSQLMASTER3
#>
[CmdletBinding()]

param
(
 [Parameter (Mandatory = $true,
	 ValueFromPipeline = $true)]
 [string] $computername,

 [string] $filepath = "C:\temp\ServerAgentJobs.sql",

 [switch] $ToScreen, 
 
 [switch] $CountOnly
)


BEGIN
{
	Import-Module sqlps -DisableNameChecking | Out-Null
}


PROCESS
{
    
	try 
	{
        $test = Test-Connection -ComputerName $computername -Count 1 -Quiet -ErrorAction Stop

        if ( $test -eq $false )
        {
            throw "Unable to Ping Server: $computername"
        }
        
		$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $computername -ErrorAction Stop
	}
	catch
	{
		Write-Output "An Error Has Occurred"
		$_.exception.message
		return
	}
	

	if ( $CountOnly )
	{
		$count = $srv.JobServer.Jobs.Count 
		Write-Output "Job Count: $count"
	}
	else
	{
		$count = $srv.JobServer.Jobs.Count
		Write-Output "Job Count: $count"

		if ( $ToScreen )
		{
			$srv.JobServer.Jobs | 
			foreach {"-- " + $_.NAME + "`r`n" + $_.Script() + "GO`r`n"} | 
			ft -AutoSize 
		}
		else
		{
			$srv.JobServer.Jobs | 
			foreach { "-- " + $_.NAME + "`r`n" + $_.Script() + "GO`r`n"} | 
			Out-File -FilePath $filepath -Append

			# ---- another way -----
			# $srv.JobServer.Jobs | foreach-object -process {out-file -filepath $(".\$filepath\" + $($_.Name -replace '\\', '') + ".sql") -inputobject $_.Script() }
		}
	}
}


END {}


} # END FUNCTION Script-Jobs

# --------------------------------------------------------------------------------------------------------

function Script-DBObjects
{
<#
.SYNOPSIS
Scripts database objects based upon user input, and writes the output to a SQL command file
 
.DESCRIPTION
Script-DBObjects will script all SQL objects (tables, views, indices, keys, and relations) found
within a database.  The user may select all, or a portion, of the objects to be scripted.

The script will create a SQL command file (.sql) with the following format:
"C:\temp\[database_name] - DB Objects - [date:MM-DD-YYYY].sql"

.PARAMETER computerName
Mandatory parameter that is used to identify the server where the SQL Server databases can be found

.PARAMETER database
Mandatory parameter identifying a specific database used to create the script

.PARAMETER ObjectType
Optional parameter used to select All objects, or a particular object, to script
Valid Objects are: All, Table, Index, View, StoredProcedure, UserDefinedFunction, DRI (relation keys),
                   login, and user

Note: The default is All

.EXAMPLE
Script-DBObjects -computername AUSDBSQLMASTER3 -database ABSP 
Scripts all database objects for database ABSP on server AUSDBSQLMASTER3

.EXAMPLE
Script-DBObjects -computername AUSDBSQLMASTER3 -database ABSP -ObjectType table, view, index
Scripts table, view and index objects for database ABSP on server AUSDBSQLMASTER3

#>
[CmdletBinding()]

param
(
    [Parameter (Mandatory = $true,
   	            ValueFromPipeline = $true)]
    [string] $computername,

    [Parameter (Mandatory = $true,
                ValueFromPipeline = $true)]
    [string] $database,

    [Parameter (Mandatory = $false)]
    [ValidateSet("Table", "View", "Index", "StoredProcedure", "UserDefinedFunction", "DRI", "Login", "User", "ALL")]
    [string[]] $ObjectType = "ALL"
)


BEGIN
{
	Import-Module sqlps -DisableNameChecking | Out-Null	-ErrorAction stop
}


PROCESS
{
	try 
	{
		$test = Test-Connection -ComputerName $computername -Count 1 -Quiet         -ErrorAction stop 
		
		$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $computername -ErrorAction Stop

        $trxobj = New-Object -TypeName microsoft.sqlserver.management.smo.transfer  -ErrorAction Stop
		
		$db = $srv.Databases["$database"]

        
        if ( $test -eq $false )
        {
            throw "Unable to Ping Server: $computername"
        }
		
		if ( -not $db.isAccessible )
		{
			Throw "Database: $database, Is Not Accessible"
		}


	    $date = get-date -Format "MM-dd-yyyy"
	    $suffix = $date
	    $database = $database.ToUpper()
        $filepath = "C:\temp\"
	    $filepath = $filepath + $database + " - DB Objects - " + $suffix + ".sql"

        $trxobj.Database = $srv.Databases[$database]

        foreach ( $item in $ObjectType )
        {
            switch ( $item )
            {
                "Table" { $trxobj.CopyAllTables   = $true; break; }
                "View"  { $trxobj.CopyAllViews    = $true; break; }
                "Index" { $trxobj.Options.Indexes = $true; break; }
                "StoredProcedure" { $trxobj.CopyAllStoredProcedures = $true; break; }
                "UserDefinedFunction" { $trxobj.CopyAllUserDefinedFunctions = $true; break; }
                "DRI" { $trxobj.Options.DriAll  = $true; break; }
                "Login" { $trxobj.CopyAllLogins = $true; break; }
                "User"  { $trxobj.CopyAllUsers  = $true; break; }
                "ALL"   {
					      $trxobj.CopyAllObjects  = $true;
					      $trxobj.CopyAllTables   = $true;
					      $trxobj.CopyAllViews    = $true;
					      $trxobj.Options.Indexes = $true;
					      $trxobj.CopyAllStoredProcedures = $true;
					      $trxobj.CopyAllUserDefinedFunctions = $true; 
					      $trxobj.Options.DriAll  = $true; 
					      $trxobj.CopyAllLogins = $true; 
					      $trxobj.CopyAllUsers  = $true; break;
					    }
                Default {Write-Warning "No value found for option: $item"}
            }
        }
	
	    # set certain values to false ...
	    if ($ObjectType -notcontains "ALL")
	    {
		    $trxobj.copyallobjects = $false
	    }
	
        $trxobj.Options.ContinueScriptingOnError = $true

        $trxobj.ScriptTransfer() | Out-File -FilePath $filepath


        if( Test-Path -Path $filepath )
    	    { Write-Output "Script File Written to: $filepath" }
        else
    	    { Write-Warning "Error Writing Script File to: $filepath!" }

    }
	catch
	{
		Write-Output "AN ERROR HAS OCCURRED"
		$_.exception.message
		return
	}

}


END {}


} # END FUNCTION Script-DBObjects

# --------------------------------------------------------------------------------------------------------

function Script-CreateDatabase
{
<#
.SYNOPSIS
 Scripts the "Create Database ..." statement based upon the server and database options entered by the user
 
.DESCRIPTION
Script-CreateDatabase creates the DDL script used to create a database. The CREATE DATABASE ... command 
and Options are scripted.

.PARAMETER computerName
Mandatory parameter that is used to identify the server where the SQL Server databases can be found.

.PARAMETER database
Optional parameter identifying a specific database or databases used to create the script
If a database is not given as an argument, all available non-system databases are scripted

.PARAMETER filepath
Optional parameter used to set the output drive / directory where the script file will be placed
The default directory Path is: "C:\temp\CreateDBScript.sql"

.PARAMETER ToScreen
Optional parameter used to direct the output to the screen instead of a SQL command file (.sql)

.EXAMPLE
Script-CreateDatabase -computername AUSDBSQLMASTER3
Scripts all non-system databases on server AUSDBSQLMASTER3

.EXAMPLE
Script-CreateDatabase -computername AUSDBSQLMASTER3, AUSDBSQLMASTER4
Scripts all non-system databases on servers AUSDBSQLMASTER3 and AUSDBSQLMASTER4

.EXAMPLE
Script-CreateDatabase -computername AUSDBSQLMASTER3, AUSDBSQLMASTER4 -database test_db
Scripts test_db database on servers AUSDBSQLMASTER3 and AUSDBSQLMASTER4

.EXAMPLE
Script-CreateDatabase -computername AUSDBSQLMASTER3 -ToScreen
Scripts all non-system databases on server AUSDBSQLMASTER3 and writes the DDL to the user screen

.EXAMPLE
Script-CreateDatabase -computername AUSDBSQLMASTER3 -database test_db, some_other_db
Scripts test_db and some_other_db databases on server AUSDBSQLMASTER3

.EXAMPLE
Script-CreateDatabase -computername AUSDBSQLMASTER3 -database test_db -filepath "C:\SQL_Scripts\"
Scripts test_db database on server AUSDBSQLMASTER3 and uses "C:\SQL_Scripts\" as the directory for the output file
#>
[CmdletBinding()]

param
(
	[Parameter (Mandatory = $true,
	 ValueFromPipeline = $true)]
	[string[]] $computername,

	[Parameter (Mandatory = $false,
     ValueFromPipeline = $true)]
	[string[]] $database = $null,

	[string] $filepath = "C:\temp\CreateDBScript.sql",

	[switch] $ToScreen
)


BEGIN 
{
	Import-Module sqlps -DisableNameChecking | Out-Null -ErrorAction stop
}


PROCESS 
{

	foreach ( $computer in $computername )
	{

        try 
        {
            # Test that the server exists and is ping-able...
            $test = Test-Connection -ComputerName $computer -Count 1 -Quiet -ErrorAction Stop 

            if ($test -eq $false)
            {
                throw 
            }
        }
        catch 
        {
            Write-Output "Whoops! and Error Occurred Connecting to Server: $computer"
            Write-Output "Cannot Ping Server: $computer"
            Write-Output ""
            continue
        }


        try 
        {

		    $Srv = New-Object Microsoft.SqlServer.Management.Smo.Server "$computer" 

            $databases = $Srv.Databases | where { -not $_.IsSystemObject }
		
		    if ( $database -eq $null )
		    {
			    foreach ( $db in $databases )
			    {
				    if ( $db.isAccessible )
				    {
					    if ( $ToScreen )
					    {
                            Write-Output "---------------------------------------------------------------------------------------------------------"
                            Write-Output "Database: $db"
                            Write-Output "========================================================================================================="
                            $db.Script()
					    }
					    else
					    {
                            Write-Output "---------------------------------------------------------------------------------------------------------" | Out-File -FilePath $filepath -Append
                            Write-Output "Database: $db" | Out-File -FilePath $filepath -Append
						    Write-Output "=========================================================================================================" | Out-File -FilePath $filepath -Append
                            $db.Script() | Out-File -FilePath $filepath -Append
					    }
				    }
				    else
				    {
                        Write-Output ""
					    Write-Output "                 >>>>>>>>>>>>>>>> Database: $db is Not Accessible <<<<<<<<<<<<<<<<<<<<                   "
					    Write-Output ""
				    }
			    }
		    }
		    else
		    {
			    if ( $Srv.Databases[$database].isAccessible )
			    {
				    if ( $ToScreen )
				    {
					    $Srv.Databases[$database].Script()
				    }
				    else
				    {
			   		    $Srv.Databases[$database].Script() | Out-File -FilePath $filepath 
				    }
			    }
			    else
			    {
				    Write-Output ">>>>>>>>>>>>>>>> Database: $database is Not Accessible <<<<<<<<<<<<<<<<<<<<"
			    }
		    }

            if ( -not $ToScreen )
            {
                if ( Test-Path -Path $filepath )
                {
                    Write-Output "Output successfully written to: $filepath"
                } else {
                    Write-Output "An Error Occurred Writing File to: $filepath"
                    throw
                }
            }

        } catch {
            Write-Output "An Error Has Occurred"
            Write-Output "Server: $computer"
            $_.exception.message
            Write-Output ""
            continue
        }
	}
}


END {}


} # END FUNCTION Script-CreateDatabase

# --------------------------------------------------------------------------------------------------------

function Get-Databases
{
<#
.SYNOPSIS
Returns a database list based upon the server name entered 
 
.DESCRIPTION
Returns database information such as the name, owner, compatability level, recovery model, version, and collation for all 
non-system databases on the server

.PARAMETER computerName
Mandatory parameter that is used to identify the server where the SQL Server databases can be found

.EXAMPLE
Get-Databases -computername AUSDBSQLMASTER4
Returns all non-system database information on server AUSDBSQLMASTER4

.EXAMPLE
Get-Databases -computername AUSDBSQLMASTER4, AUSDBSQLMASTER3
Returns all non-system database information on servers AUSDBSQLMASTER4 and AUSDBSQLMASTER3
#>
[CmdletBinding()]

param 
(
    [Parameter(Mandatory = $True, 
               ValueFromPipeline = $True)]
    [ValidateCount(1,10)]
    [string[]] $computername
)


BEGIN
{
    Import-Module SQLPS -DisableNameChecking | Out-Null
}


PROCESS 
{
    foreach ($computer in $computername)
    {   

        try 
        {
            # Test that the server exists and is ping-able...
            $test = Test-Connection -ComputerName $computer -Count 1 -Quiet -ErrorAction Stop 

            if ($test -eq $false)
            {
                throw 
            }
        }
        catch 
        {
            Write-Output "Whoops! and Error Occurred Connecting to Server: $computer"
            Write-Output "Cannot Ping Server: $computer"
            Write-Output ""
            continue
        }
            
            
        try
        {

            $server = New-Object -TypeName microsoft.sqlserver.management.smo.server -ArgumentList $computer  -ErrorAction Stop 

            if ( -not $server.Databases["master"].IsAccessible ) 
			{
				throw "Unable to Access Databases on Server: $computer";
			}

            $databases = $server.databases 
                    
            "Server: " + $server.Name.ToString()

            $DBcount = $( $databases | where {$_.IsSystemObject -eq $false} ).Count  # Omits counting System DB's 
                    
            if($DBcount -gt 0)
            {
                "Database Count: " + $DBcount
            }
            else 
            {
                Write-Output "No User Databases Found!"
                continue
            }

            # list DB's to user...
            $databases | where {$_.IsSystemObject -eq $false} | ft -AutoSize
        }
        catch
        {
            Write-Output "An Error Has Occurred"
            Write-Output "Server Name: $computer"
            $_.exception.message
            Write-Output ""
            continue
        } 
    }

} 


END {}


} # END Function Get-Databases

# --------------------------------------------------------------------------------------------------------

function Get-FileGroupInfo
{
<#
.SYNOPSIS
Returns the file group information for each non-system database located on a server
 
.DESCRIPTION
Returns the database name, file group[s], file names ( *.ndf, *.mdf ), current size, and current usage for each
database on the server, or those databases based upon the optional SearchString parameter

.PARAMETER computerName
Mandatory parameter that is used to identify the server where the SQL Server databases can be found

.PARAMETER SearchString
Optional parameter used to identify a database, or group of databases
The default is "*" or all databases

.EXAMPLE
Get-FileGroupInfo -computername AUSDBSQLMASTER3
Returns filegroup information for all databases on server AUSDBSQLMASTER3

.EXAMPLE
Get-FileGroupInfo -computername AUSDBSQLMASTER3 -SearchString w*
Returns filegroup information for all databases that begin with "w" in their name on server AUSDBSQLMASTER3
#>
[CmdletBinding()]

param 
(
    [Parameter (Mandatory = $true,
	    ValueFromPipeline = $true)]
    [string] $computername,

    [string] $SearchString = "*"
)


BEGIN
{
    Import-Module SQLPS -DisableNameChecking | Out-Null
}


PROCESS
{ 

    try 
    {
        # Test that the server exists and is ping-able...
        $test = Test-Connection -ComputerName $computername -Count 1 -Quiet -ErrorAction Stop 

        if ($test -eq $false)
        {
            throw 
        }
    }
    catch 
    {
        Write-Output "Whoops! and Error Occurred Connecting to Server: $computername"
        Write-Output "Cannot Ping Server: $computername"
        Write-Output ""
        return
    }
    

    try 
    {
        $database = $SearchString

        $server = New-Object "Microsoft.SqlServer.Management.Smo.Server" $computername  -ErrorAction Stop

        $result = @() 

        $dbs = $server.Databases

        $server.Databases |
        ForEach-Object { 
              if($_.name -like $database -and -not $_.isSystemObject -and $_.isAccessible -eq $true)
              {
                $db = $_

                Write-Output "Working database: $db"
            
                $db.FileGroups | 
                ForEach-Object { 
                   $fg = $_
            
                   $fg.Files | 
            
                   ForEach-Object { 
                        $file = $_
            
                        $object = [PSCustomObject] @{Database  = $db.Name 
                                                     FileGroup = $fg.Name 
                                                     FileName  = $file.FileName # |
                                                        #Split-Path -Parent
                                                        "Size(MB)"      = "{0:N2}" -f ($file.Size/1024) # in KB
                                                        "SpaceUsed(MB)" = "{0:N2}" -f ($file.UsedSpace/1024) # in KB
                                                    }


                        $result += $object 
                   } 
                 } 
              }
        }
    }
    catch
    {
        Write-Output "An Error Has Occurred:"
        $_.exception.message
        Write-Output ""
    }


    if($result -ne $null)
    {
        $result |  Format-Table -AutoSize
    } 
    else 
    {
        Write-Output "No Databases found for search string: $SearchString"
    }

}


END {}


} # End Function Get-FileGroupInfo

# --------------------------------------------------------------------------------------------------------

function Get-LogFileInfo
{
<#
.SYNOPSIS
Returns log file information for each non-system database located on a server
 
.DESCRIPTION
Returns the log file name, status, filename, MaxSize, Size, and UsedSpace for each database on the server,
or those databases based upon the optional SearchString parameter

.PARAMETER computerName
Mandatory parameter that is used to identify the server where the SQL Server databases can be found

.PARAMETER SearchString
Optional parameter used to identify a database, or group of databases
The default is "*" or all databases

.EXAMPLE
Get-LogFileInfo -computername AUSDBSQLMASTER3
Returns log file information for all databases on server AUSDBSQLMASTER3

.EXAMPLE
Get-LogFileInfo -computername AUSDBSQLMASTER3 -SearchString w*
Returns log file information for all databases that begin with "w" in their name on server AUSDBSQLMASTER3
#>
[CmdletBinding()]

param 
(
    [Parameter (Mandatory = $true,
	    ValueFromPipeline = $true,
	    HelpMessage = "Computer Name or IP Address")]
    [string] $computername,

    [string] $SearchString = "*"
)


BEGIN
{
    Import-Module sqlps -DisableNameChecking | Out-Null 
}


PROCESS
{
    try 
    {
        # Test that the server exists and is ping-able...
        $test = Test-Connection -ComputerName $computername -Count 1 -Quiet -ErrorAction Stop 

        if ($test -eq $false)
        {
            throw 
        }
    }
    catch 
    {
        Write-Output "Whoops! and Error Occurred Connecting to Server: $computername"
        Write-Output "Cannot Ping Server: $computername"
        Write-Output ""
        return
    }


    try {

        $srv = New-Object -TypeName microsoft.sqlserver.management.smo.server -ArgumentList $computername

        $result = @()

        foreach ($db in $srv.Databases)
        {
            if ( $db.IsAccessible -and -not $db.IsSystemObject -and $db.Name -like $SearchString ) {
        
                $logs = $db.LogFiles

                foreach ($log in $logs)
                {
                    $object = [PSCustomObject] @{Database  = $db.Name 
                                                 Name      = $log.name
                                                 State     = $log.State
                                                 FileName  = $log.FileName 
                                                 "MaxSize(MB)" = "{0:N2}" -f ($log.MaxSize)      # in MB
                                                 "Size(MB)"    = "{0:N2}" -f ($log.Size/1024)    # in KB
                                                 "UsedSpace(MB)" = "{0:N2}" -f ($log.UsedSpace/1024) # in KB
                                                }

                    $result += $object 
                }
            }
        }


        if ( $result.Count -ne 0 )
        {
            $result | 
            ft -AutoSize -Wrap
        }
        else
        {
            Write-Output "No Log Files Found for Server: $serverName, Search String: $SearchString"
        }
    
    }
    catch 
    {
        Write-Output "An Error Has Occurred:"
        $_.exception.message
        Write-Output ""
        return
    }

}

END {}

} # End Function Get-LogFileInfo

# --------------------------------------------------------------------------------------------------------

function Get-OrphanUsers {
<#
.SYNOPSIS
Returns orphaned user information for each database on the server
 
.DESCRIPTION
Returns any orphaned user listed for each database on the server[s].  The usertype field
will show "NOLOGIN" if it detects an orphan.  

.PARAMETER computerName
Mandatory parameter that is used to identify the server, or servers

.EXAMPLE
Get-OrphanUsers ausdbsqlmaster3
Returns any orphaned users on server AUSDBSQLMASTER3

.EXAMPLE
Get-OrphanUsers ausdbsqlmaster3, ausdbsqlmaster4 -showallusers
Returns information on all users found on servers AUSDBSQLMASTER3, and AUSDBSQLMASTER4

.LINK

#>
[CmdletBinding()]

param 
(
    [Parameter(Mandatory = $True, 
        ValueFromPipeline = $True)]
    [ValidateCount(1,10)]
    [string[]] $computername,

    [switch]   $showAllUsers
)


BEGIN 
{
   Import-Module SQLPS -DisableNameChecking | Out-Null
}


PROCESS 
{

    foreach ($computer in $computername)
    {   
        try 
        {
            # Test that the server exists and is ping-able...
            $test = Test-Connection -ComputerName $computer -Count 1 -Quiet -ErrorAction Stop 

            if ($test -eq $false)
            {
                throw 
            }
        }
        catch 
        {
            Write-Output "Whoops! and Error Occurred Connecting to Server: $computer"
            Write-Output "Cannot Ping Server: $computer"
            Write-Output ""
            continue
        }

        try 
        {

            $server = New-Object -TypeName microsoft.sqlserver.management.smo.server -ArgumentList $computer -ErrorAction stop

            Write-Output "Server: $server"

            $databases = $server.Databases | where { -not $_.IsSystemObject -and $_.IsAccessible }

            foreach ($db in $databases)
            {
                $users = $db.users

                $user_count = $users.count

                $db_name = $db.name

                Write-Output "Database: $db_name"
            
                Write-Output "Total Users: $user_count"
            
                if ($showAllUsers)
                {
                    $users | 
                    Select name, login, logintype, usertype |
                    ft -AutoSize
                } else {
                    $users | 
                    Where usertype -Like "NoLogin" |
                    Select name, login, logintype, usertype | 
                    ft -AutoSize
                }
            }
        }
        catch 
        {
            Write-Output "An Error Has Occurred:"
            $_.exception.message
            Write-Output ""
            continue
        }
    } 
} 


END {}


} # End Function Get-OrphanUsers

# --------------------------------------------------------------------------------------------------------

function Get-DiskSizes
{
<#
.SYNOPSIS
Returns disk size information for each server argument listed
 
.DESCRIPTION
Returns the disk size information: name, disk, and freespace for all drives on a server, or group
of servers

.PARAMETER computerName
Mandatory parameter that is used to identify the server, or servers

.EXAMPLE
Get-DiskSizes ausdbsqlmaster3
Returns disk size information for disks on server AUSDBSQLMASTER3

.EXAMPLE
Get-DiskSizes ausdbsqlmaster4, ausdbsqlmaster3
Returns disk size information for disks on servers AUSDBSQLMASTER3 and AUSDBSQLMASTER4

.LINK
https://technet.microsoft.com/en-us/systemcenter/aa394173(v=vs.85).aspx
#>
[CmdletBinding()]

param 
(
    [Parameter (Mandatory = $true,
	 ValueFromPipeline = $true)]
    [string[]] $computername
)


BEGIN {}  

  
PROCESS 
{  
    foreach ( $computer in $computername )
    {
            
        try 
        {
            # Test that the server exists and is ping-able...
            $test = Test-Connection -ComputerName $computer -Count 1 -Quiet -ErrorAction Stop 

            if ($test -eq $false)
            {
                throw 
            }
        }
        catch 
        {
            Write-Output "Whoops! and Error Occurred Connecting to Server: $computer"
            Write-Output "Cannot Ping Server: $computer"
            Write-Output ""
            continue
        }

        $computer = $computer.ToUpper()

        Write-Output "Server: $computer"

        try 
        {
            Get-WmiObject win32_logicaldisk -ComputerName $computer -Filter "drivetype = 3" -ErrorAction Stop | 
            ft Name, Volumename, @{n='Disk Size(GB)'; e={$_.size/1GB};formatstring='N2'}, @{n='FreeSpace(GB)'; e={$_.freespace/1GB};formatstring='N3'} -AutoSize
        }
        catch 
        {
            Write-Output "An Error Has Occurred:"
            Write-Output "Server: $computer"
            $_.exception.message
            Write-Output ""
            continue
        }

    }

}  


END {}


} # End Function Get-DiskSizes

# --------------------------------------------------------------------------------------------------------

function Get-IndexFragmentation
{
<#
.SYNOPSIS
Returns average index fragmentation for all indexes on a table
 
.DESCRIPTION
Lists the index name, number of pages and average index fragmenation for all indexes found on a table.
Unless the -showall option (below) is included, only values for indices with fragmentation are shown.
By default, all non-system databases are queried.  You may use the optional $database parameter to limit
the scope of the query by selecting a specific database on the server.

.PARAMETER computerName
Mandatory parameter that is used to identify the server, or servers

.PARAMETER databasename
Optional parameter to identify a database on the server to query

.PARAMETER showall
Optional boolean parameter which will show all fragmentation values, including zero fragmentation

.EXAMPLE
Get-IndexFragmentation ausdbsqlmaster3
Returns index fragmentation information for all indexes on all non-system databases on server AUSDBSQLMASTER3

.EXAMPLE
Get-IndexFragmentation ausdbsqlmaster4, ausdbsqlmaster3 -database MyReportServer -showall
Returns all fragmentation information for indexes in database MyReportServer on servers AUSDBSQLMASTER3 and AUSDBSQLMASTER4

.LINK

#>
[CmdletBinding()]

param 
(
    [Parameter (Mandatory = $true,
	 ValueFromPipeline = $true)]
    [string[]] $computername,

    [string] $databaseName,

    [string] $schemaName   = "dbo",

    [switch] $showall
)


BEGIN
{
    Import-Module SQLPS -DisableNameChecking | Out-Null

    $tableCount = 0
    $indexCount = 0
    $databaseCount = 0
    $serverCount   = 0
}


PROCESS
{

    foreach ( $computer in $computername )
    {

        try 
        {
            # Test that the server exists and is ping-able...
            $test = Test-Connection -ComputerName $computer -Count 1 -Quiet -ErrorAction Stop 

            if ($test -eq $false)
            {
                throw 
            }
        }
        catch 
        {
            Write-Output "Whoops! and Error Occurred Connecting to Server: $computer"
            Write-Output "Cannot Ping Server: $computer"
            Write-Output ""
            continue
        }


        try
        {

            $server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $computer  -ErrorAction stop

            $serverCount += 1

            if ( $databaseName.Length -eq 0 )
            {
                $databases = $server.Databases | where { -not $_.IsSystemObject -and $_.IsAccessible  }

                foreach ( $database in $databases )
                {

                    $databaseCount += 1
                
                    write-output "Database: $database"

                    $tables = $database.tables | where { -not $_.IsSystemObject }

                    foreach ( $table in $tables )
                    {
                        $tableCount += 1
                        
                        Write-Output "TABLE: $table"
                
                        $indexes = $table.Indexes | sort -Property indextype | where { -not $_.IsSystemObject }

                        if ( $indexes.Count -gt 0 ) 
                        {
                            if ($showall) # show all value, even if it equals 0.0000
                            {
                                $indexes | 
                                Foreach { 
                                $indexCount +=1
                                $_.EnumFragmentation() | 
                                Select Index_Name, Indextype, pages, @{Name="AVG. Fragmentation";Expression = { ($_.AverageFragmentation).ToString("0.0000") }}} | 
                                Format-Table -AutoSize
                            }
                            else # only display indexes with fragmentation greater-than 0.0000
                            {
                                $indexes |
                                Foreach { 
                                $indexCount += 1
                                $_.EnumFragmentation() |
                                where { $_.AverageFragmentation -gt 0 } |
                                Select Index_Name, Indextype, pages, @{Name="AVG. Fragmentation";Expression = { ($_.AverageFragmentation).ToString("0.0000") }}} | 
                                Format-Table -AutoSize   
                            }

                        } else
                        {
                            Write-Output "*** No Indexes Found ***"
                        }
                    }
                }
            }
            else
            {
                $database = $server.Databases[$databasename] 

                if ( $database.isAccessible ) 
                {
                    $databaseCount += 1

                    write-output "Database: $database"

                    $tables = $database.tables | where { -not $_.IsSystemObject }

                    foreach ( $table in $tables )
                    {
                        $tableCount += 1

                        Write-Output "TABLE: $table"
                
                        $indexes = $table.Indexes | sort -Property indextype | where { -not $_.IsSystemObject }

                        if ( $indexes.Count -gt 0 ) 
                        {
                            
                            if ($showall) # show all value, even if it equals 0.0000
                            {
                                $indexes |
                                Foreach { 
                                $indexCount += 1
                                $_.EnumFragmentation() |
                                Select Index_Name, Indextype, pages, @{Name="AVG. Fragmentation";Expression = { ($_.AverageFragmentation).ToString("0.0000") }}} |
                                Format-Table -AutoSize
                            } 
                            else  # only display indexes with fragmentation greater than 0.0000
                            {
                                $indexes |
                                Foreach { 
                                $indexCount += 1
                                $_.EnumFragmentation() |
                                where { $_.AverageFragmentation -gt 0 } |
                                Select Index_Name, Indextype, pages, @{Name="AVG. Fragmentation";Expression = { ($_.AverageFragmentation).ToString("0.0000") }}} | 
                                Format-Table -AutoSize
                            }

                        } 
                        else
                        {
                            Write-Output "*** No Indexes Found ***"
                        }
                    }
                }
                else
                {
                    Write-Output "Database: $database, is not accessible"
                    $status = $database.status 
                    Write-Output "Status: $status"
                }   
            }
        }
        catch
        {
            Write-Output "An Error Has Occurred:"
            Write-Output "Server: $computer"
            $_.exception.message
            Write-Output ""
            continue
        }
    }
}

END 
{
    Write-Output ""
    Write-Output "Statistics:             "
    Write-Output "************************"
    Write-Output "Server Count:    $serverCount"
    Write-Output "Database Count:  $databaseCount"
    Write-Output "Table Count:     $tableCount"
    Write-Output "Index Count:     $indexCount"
}


} # End Function Get-IndexFragmentation 

# --------------------------------------------------------------------------------------------------------

function Get-Statistics 
{
<#
.SYNOPSIS
Returns statistics information based upon a servername, database, and table
 
.DESCRIPTION
Returns the statistics name, state, IsAutoCreated and Last Updated information for any statistics 
that exist on a table.

.PARAMETER computerName
Mandatory parameter that is used to identify the server, or servers

.PARAMETER databasename
Optional parameter to identify a database on the server to query - all tables within the database
are then queried for statistical data

.PARAMETER table
Optional parameter to identify a specific table to pull statistical data

.EXAMPLE
Get-Statistics ausdbsqlmaster3
Returns statistical information for all tables on all non-system databases on server AUSDBSQLMASTER3

.EXAMPLE
Get-Statistics ausdbsqlmaster4 -database MyReportServer 
Returns statistical information for all tables on database MyReportServer on server AUSDBSQLMASTER3

.EXAMPLE
Get-Statistics ausdbsqlmaster4 -database MyReportServer -table Report_Error
Returns statistical information for table Report_Error on database MyReportServer on server AUSDBSQLMASTER3

.LINK

#>
[CmdletBinding()]

param 
(
    [Parameter (
     Mandatory = $true,
	 ValueFromPipeline = $true)]
    [string[]] $computername,

    [Parameter (
     Mandatory = $false,
	 ValueFromPipeline = $true)]
    [string] $databaseName,

    [string] $table
)


BEGIN
{
    Import-Module SQLPS -DisableNameChecking | Out-Null 
}


PROCESS
{
    
    foreach ( $computer in $computername )
    {

        try 
        {
            # Test that the server exists and is ping-able...
            $test = Test-Connection -ComputerName $computer -Count 1 -Quiet -ErrorAction Stop 

            if ($test -eq $false)
            {
                throw 
            }
        }
        catch 
        {
            Write-Output "Whoops! and Error Occurred Connecting to Server: $computer"
            Write-Output "Cannot Ping Server: $computer"
            Write-Output ""
            continue
        }


        try 
        {

            $srv = New-Object Microsoft.SqlServer.Management.Smo.Server -ArgumentList $computer -ErrorAction Stop

            if ( $databaseName.Length -eq 0 )
            {
                # no system db's and make sure all db's are accessible
                $databases = $srv.Databases | where { -not $_.IsSystemObject -and $_.IsAccessible }

                # do all tables, all databases ...
                foreach ( $db in $databases )
                {
                    Write-Output "Database: $db"

                    $tables = $db.tables | where { -not $_.IsSystemObject -and $_.IsAccessible } 

                    $tables |
                    foreach {
                        $tablename = $_.name

                        Write-Output "Statistics for Table: $tablename"

                        $_.Statistics |
                        select Name, State, IsAutoCreated, LastUpdated |
                        fl    
                    }
                }
                
            }
            else
            {
                # we have a database entry, so choose it
                if ( $srv.Databases[$databaseName].IsAccessible )
                {
                    $db = $srv.Databases[$databaseName]

                    if ( $table.Length -eq 0 )
                    {
                        # do all tables in the database $db
                        $tables = $db.tables | where { -not $_.IsSystemObject } 

                        $tables |
                        foreach {
                            $tablename = $_.name
                            Write-Output "Statistics for table: $tablename"

                            $_.Statistics |
                            select Name, State, IsAutoCreated, LastUpdated |
                            fl    
                        }
                    }
                    else
                    {
                        # else, do a single table $table, in database $db
                        $tables = $db.tables

                        $tbl = $tables | where {$_.name -like $table}
                        
                        if ($tbl -eq $null)
                        {
                            Write-Output "Table: $table does not exist or is not accessible"
                            throw
                        }

                        Write-Output "Statistics for Table: $table"
                        $tbl.Statistics |
                        select name, state, IsAutoCreated, lastupdated |
                        fl 
                    }
                }
                else
                {
                    Write-Output "$databaseName is not Accessible!"
                    Write-Output ""
                    throw
                }

            }
        }
        catch
        {
            Write-Output "An Error Has Occurred:"
            Write-Output "Server: $computer"
            $_.exception.message
            Write-Output ""
            continue
        }
    } 
}


END {}


} # End Function Get-Statistics

# --------------------------------------------------------------------------------------------------------

function Get-BlockingProcesses
{
<#
.SYNOPSIS
Returns a list of any blocking processes
 
.DESCRIPTION
Returns a list of blocking processes based upon the server argument entered.  The name, SPID, Command,
status, login, database, and BlockingSPID are returned.  Using the optional argument: GetAllProcs - will
also return a list of all processes found; without it, only the blocking processes are returned.

.PARAMETER computerName
Mandatory parameter that is used to identify the server, or servers

.PARAMETER GetAllProcs
Optional parameter to include a list of all processes found, not just blocking processes

.EXAMPLE
Get-BlockingProcesses ausdbsqlmaster3
Returns any blocking processes found on server AUSDBSQLMASTER3

.EXAMPLE
Get-BlockingProcesses ausdbsqlmaster3 -GetAllProcs
Returns a list of current processes and any blocking processes found on server AUSDBSQLMASTER3

.EXAMPLE
Get-BlockingProcesses ausdbsqlmaster3, ausdbsqlmaster4 -GetAllProcs
Returns a list of current processes and any blocking processes found on servers AUSDBSQLMASTER3 and AUSDBSQLMASTER4
#>

[CmdletBinding()]

param 
(
    [Parameter (
     Mandatory = $true,
	 ValueFromPipeline = $true)]
    [string[]] $computername,

    [switch]   $GetAllProcs
)


BEGIN
{
    Import-Module SQLPS -DisableNameChecking | Out-Null
}


PROCESS
{
    foreach ( $computer in $computername )
    {

        try 
        {
                
            $computer = $computer.ToUpper()   

            $test = Test-Connection -ComputerName $computer -Count 1 -Quiet  -ErrorAction Stop

            if ( $test -eq $false )
            {
                throw "Unable to Ping Server: $computer"
            }

            $server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $computer -ErrorAction Stop
            

            Write-Output ""
            Write-Output "Working Server: $computer"


            if ( $GetAllProcs )
            {
                $ALL_PROCS = $server.EnumProcesses() | 
                Select Name, Spid, Command, Status, Login, Database, BlockingSpid | 
                Format-Table –AutoSize

                if ( $ALL_PROCS.Count -gt 0 )
                {
                    Write-Output "------------------------------------ CURRENT PROCESSES ------------------------------------"
                    $ALL_PROCS
                }
            }
 

            $BLOCKERS = $server.EnumProcesses() |
            Where-Object BlockingSpid -ne 0 | 
            Select Name, Spid, Command, Status, Login, Database, BlockingSpid | 
            Format-Table -AutoSize 

            if( $BLOCKERS.count -gt 0 ) 
            {
                Write-Output "------------------------------------ BLOCKING PROCESSES -----------------------------------"
                $BLOCKERS
            } else {
                Write-Output "------------------------------- No Blocking Processes Found -------------------------------"
            }

        }
        catch 
        {
            Write-Output "An Error Has Occurred:"
            Write-Output "Server: $computer"
            $_.exception.message
            Write-Output ""
            continue
        }
    }
}


END {}


} # End Function Get-BlockingProcesses

# --------------------------------------------------------------------------------------------------------

function Get-UnusedIndexes
{
<#
.SYNOPSIS
Returns a list of indexes that are not being used 
 
.DESCRIPTION
Returns a list of indexes that have not been used (chosen by the optimizer) since a SQL restart or index recreation 

.PARAMETER computerName
Mandatory parameter that is used to identify the server, or servers

.PARAMETER database
Mandatory parameter identifying the database to query

.PARAMETER ShowSQL
Optional boolean parameter, when chosen the procedure will write out the SQL used in the query
to the screen.  The default is false or not to write the SQL output

.EXAMPLE
Get-UnusedIndexes -computername ausdbsqlmaster3 -database Homer
Returns any unused indices found on server AUSDBSQLMASTER3, for database Homer

.EXAMPLE
Get-UnusedIndexes -computername ausdbsqlmaster3, ausdvsqlgrdcl05 -database Homer
Returns any unused indices found on servers AUSDBSQLMASTER3, and AUSDVSQLGRDCL05 for database Homer
#>
[CmdLetBinding()]

Param 
(
    [Parameter (
     Mandatory = $true,
	 ValueFromPipeline = $true)]
    [string[]] $computername,
       
    [Parameter (
     Mandatory = $true,
	 ValueFromPipeline = $true)]
    [string] $database,

    [switch] $ShowSQL
)


BEGIN 
{

Import-Module SQLPS -DisableNameChecking | Out-Null


$SQL = @"
SELECT OBJECT_NAME(i.[object_id]) AS [Table Name]
, i.name AS [Unused Index Name]
, i.type_desc AS [Index Type]
, [Index Enabled] =
    CASE 
	WHEN i.is_disabled = 1 THEN 'FALSE' 
	WHEN I.is_disabled = 0 THEN 'TRUE'
	ELSE 'UNKNOWN'
    END
FROM sys.indexes AS i
INNER JOIN sys.objects AS o ON 
            i.[object_id] = o.[object_id]
WHERE i.index_id NOT IN ( SELECT ddius.index_id
                            FROM sys.dm_db_index_usage_stats AS ddius
                            WHERE ddius.[object_id] = i.[object_id]
                            AND   i.index_id = ddius.index_id
                            AND   database_id = DB_ID() 
                        )
AND o.[type] = 'U'
AND i.name IS NOT NULL
ORDER BY OBJECT_NAME(i.[object_id]) ASC,
            [Index Type];
"@

}


PROCESS 
{
    
    foreach ( $computer in $computername )
        {

            try 
            {
                $result = $null

                $computer = $computer.ToUpper()   

                $test = Test-Connection -ComputerName $computer -Count 1 -Quiet  -ErrorAction Stop

                if ( $test -eq $false )
                {
                    throw "Unable to Ping Server: $computer"
                }

                
                $server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $computer -ErrorAction Stop
            

                if ( $ShowSQL )
                {
                    Write-Output "SQL Commands:"
                    Write-Output $SQL
                }

                
                Write-Output ""
                Write-Output "Working Server: $computer"


                if ( $server.Databases[$database].IsAccessible )
                {
                    $result = Invoke-Sqlcmd -Query $SQL -ServerInstance $server -Database $database -ErrorAction Stop
                }
                else 
                {
                    throw "Database: $database, Is Not Accessible"
                }

                if ($result -ne $null)
                {
                    $result | ft -AutoSize
                } else {
                    Write-Output "No Unused Indexes Found on Server: $computername, Database: $database"
                }

        } catch {
            Write-Output "An Error Has Occurred:"
            $_.exception.message
            Write-Output ""
            continue
        }
    }

}


END {}


} # End Function Get-UnusedIndexes

# --------------------------------------------------------------------------------------------------------

function Get-RecordCounts
{
<#
.SYNOPSIS
Returns record/row counts for all tables within a defined database.  
 
.DESCRIPTION
Returns record/row counts for all tables within a defined database; excluding those of schema: "sys"

If the database is not accessible, the procedure throws an error

.PARAMETER computerName
Mandatory parameter that is used to identify the server, or servers

.PARAMETER database
Mandatory parameter identifying the database to query

.EXAMPLE
Get-RecordCounts -computername ausdbsqlmaster4 -database ACL
Returns a list of table record/row counts on server AUSDBSQLMASTER4, for database ACL
#>
[CmdLetBinding()]

Param 
(
    [Parameter (
     Mandatory = $true,
	 ValueFromPipeline = $true)]
    [string[]] $computername,
       
    [Parameter (
     Mandatory = $true,
	 ValueFromPipeline = $true)]
    [string] $database
)


BEGIN 
{
    
Import-Module SQLPS -DisableNameChecking | Out-Null

$SQL = @'
SELECT object_schema_name(ddps.object_id) + '.' + OBJECT_NAME(ddps.object_id) AS [Table Name] ,
SUM(ddps.row_count) AS [Row Count]
FROM sys.dm_db_partition_stats AS ddps
JOIN sys.indexes ON indexes.object_id = ddps.object_id
AND indexes.index_id = ddps.index_id
WHERE indexes.type_desc IN ( 'CLUSTERED', 'HEAP' ) and
      object_schema_name(ddps.object_id) <> 'sys'
GROUP BY ddps.object_id 
ORDER BY [Table Name] ;
'@

}


PROCESS 
{

    foreach ( $computer in $computername )
        {

            try 
            {
                
                $computer = $computer.ToUpper()   

                $test = Test-Connection -ComputerName $computer -Count 1 -Quiet  -ErrorAction Stop

                if ( $test -eq $false )
                {
                    throw "Unable to Ping Server: $computer"
                }

                
                $server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $computer -ErrorAction Stop
            
                
                Write-Output ""
                Write-Output "Working Server: $computer"


                if ( $server.Databases[$database].IsAccessible )
                {
                    Invoke-Sqlcmd -Query $SQL -ServerInstance $server -Database $database -ErrorAction Stop | FT -AutoSize
                }
                else 
                {
                    throw "Database: $database, Is Not Accessible"
                }

        } catch {
            Write-Output "An Error Has Occurred:"
            $_.exception.message
            Write-Output ""
            continue
        }
    }

}


END {}


} # End Function Get-RecordCounts

# --------------------------------------------------------------------------------------------------------

function Get-WhosOnline {
<#
.SYNOPSIS
Returns a Grid view of the current connections to the SQL Server instance. 
 
.DESCRIPTION
Running the Get-WhosOnline cmdlet will return current connection information that
includes: Host Name, Login Name, SPID, status, Command, Program Name, DB Name and others.

.PARAMETER serverInstance
Mandatory parameter that identifies the server to be queried.  If there are multiple instances
on the server, such as:  SomeServer/InstanceOne, this cmdlet will error.  Only the server name
can be given at this time, additional functionality will allow for instance names in the 
future.

.EXAMPLE
Get-WhosOnline AUSDVSQLGRDAG01
This will produce a grid view (GUI) window listing all current SQL connections.

#>

[CmdletBinding()]

param
    (
        [Parameter (Mandatory = $True,
	                ValueFromPipeline = $True )]
        [string]  $serverInstance
    )


BEGIN {
Import-Module SQLPS -DisableNameChecking | Out-Null

$SQL = @"
SELECT
SPID AS [SPID]
, RTRIM(HOSTNAME) AS [HOST NAME]
, CONVERT(SYSNAME, RTRIM(LOGINAME)) AS [LOGIN NAME]
, RTRIM(SP.[PROGRAM_NAME]) AS [PROGRAM NAME]
, CMD AS [COMMAND]
, DB.NAME AS [DB NAME]
, CONVERT(NVARCHAR, LAST_BATCH, 113) AS [LAST BATCH TIME]
, SP.STATUS AS [STATUS]
, PHYSICAL_IO
, BLOCKED
, SP.REQUEST_ID
, SP.uid AS UID
FROM SYS.SYSPROCESSES SP     WITH (NOLOCK)
INNER JOIN SYS.DATABASES DB  WITH (NOLOCK)
ON  DB.DATABASE_ID = SP.DBID
WHERE SP.spid >= 50
ORDER BY HOSTNAME DESC
, CMD DESC
,[DB NAME] DESC;
"@
}


PROCESS {
    
    try {

        $test = Test-Connection -ComputerName $serverInstance  -Count 1  -Quiet  -ErrorAction Stop

        if ( $test -eq $false )
        {
            throw "Unable to Ping Server: $serverInstance"
        }

        $currentDate = Get-Date 
        
        Invoke-Sqlcmd -Query $SQL -ServerInstance $serverInstance | 
        Out-GridView -Title "Current SQL Connections: $serverInstance Date: $currentDate" 
    }
    catch {
        Write-Output "An Error Has Occurred"
		$_.exception.message
		return
    }

}

END {}

} # END FUNCTION GET-WhosOnline

# --------------------------------------------------------------------------------------------------------

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

        Write-Output "Working Server: $computername"
        Write-Output "Stand By ..."

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

# --------------------------------------------------------------------------------------------------------

function Start-SQLServices
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
                if ((Get-Service -ComputerName $server -displayname "sql server (*" | Where {$_.status -eq "stopped"}))
                {
                    try {
                        Get-Service -ComputerName $server -displayname "sql server (*" | 
                        Where {$_.status -eq "stopped"} |
                        Start-Service  -Confirm  -ErrorAction Stop
                    } catch {
                        Write-Output "An Error Has Occurred:"
                        $_.exception.message
                        write-output ""
                    }
                }
                else
                {
                    Write-Output "SQL Server Service Already Running on Server: $server"
                }
                
                # additional code to start the SQLAGENT Service
                if ((Get-Service -ComputerName $server -displayname "sql server agent (*" | Where {$_.status -eq "stopped"}))
                {
                    try {
                        Get-Service -ComputerName $server -displayname "sql server agent (*" | 
                        Where {$_.status -eq "stopped"} |
                        Start-Service  -ErrorAction Stop
                    } catch {
                        Write-Output "An Error Has Occurred:"
                        $_.exception.message
                        write-output ""
                    }
                }
                else
                {
                    Write-Output "SQL Server Agent Service Already Running on Server: $server"
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

# --------------------------------------------------------------------------------------------------------

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

# --------------------------------------------------------------------------------------------------------

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

# --------------------------------------------------------------------------------------------------------

function Get-DBCCTraceStatus
{

[CmdletBinding()]

param 
(
    [Parameter (Mandatory = $true)]
    [string[]] $serverList,
    [switch]   $isInputFile
)


BEGIN
{
    Import-Module SQLPS -DisableNameChecking | Out-Null

$sql = @"
DBCC TRACESTATUS(-1)
"@
}


PROCESS
{
    try 
    {
        if ( $isInputFile )
        {
            $validPath = Test-Path $serverList
            
            if( $validPath )
            {
                $servers = gc $serverList -ErrorAction Stop
            } 
            else 
            {
                Throw "File: $serverList - is not a valid file path, or the file does not exist!"
            }
        }
        else
        {
            $servers = $serverList
        }
        

        foreach ( $server in $servers ) 
        {
            try 
            {
                $canPing = Test-Connection -ComputerName $server -Count 1 -Quiet -ErrorAction Stop

                if ($canPing)
                {
                    Write-Output "Working Server: $server"
                    Invoke-Sqlcmd -ServerInstance $server -Query $sql -QueryTimeout 10 -ErrorAction Stop | ft -AutoSize
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
    catch 
    {
        Write-Output "An Error Has Occurred:"
		$_.exception.message
        Write-Output ""
    }
}


END {}

} ## END FUNCTION Get-DBCCTraceStatus

# --------------------------------------------------------------------------------------------------------

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

# --------------------------------------------------------------------------------------------------------

function Get-SQLProperties
{

<#
.SYNOPSIS
Pulls SQL Server Instance Properties, Configuration Properties, Settings, and User Options
   
.DESCRIPTION
Get-SQLProperties allows the user to view SQL Server settings and properties for an instance.
Multiple server instances can be entered, each separated by a comma.

.PARAMETER serverList
Mandatory parameter that is used to identify the SQL Server instance[s]

.EXAMPLE
Get-SQLProperties -serverList AUSDBSQLMASTER3 [, ...]

Returns a list of SQL Server properties configured for server: AUSDBSQLMASTER3
#>

[CmdletBinding()]

param 
(
    [Parameter (Mandatory = $true)] [string[]] $serverList
)


BEGIN
{
    Import-Module SQLPS -DisableNameChecking | Out-Null
}


PROCESS 
{
    foreach ( $server in $serverList ) 
    {
        try 
        {
            $canPing = Test-Connection -ComputerName $server -Count 1 -Quiet -ErrorAction Stop

            if ($canPing)
            {
                Write-Output "Working Server: $server"
                
                $srv = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $server -ErrorAction stop

                $srv.Information.Properties |
                select name, value  |
                sort -Property name |
                ft -AutoSize

                $srv.Configuration.Properties | 
                select DisplayName, Description, RunValue, ConfigValue |
                sort -Property DisplayName |
                ft -AutoSize

                $srv.Settings.Properties | 
                select Name, Value |
                ft -AutoSize

                $srv.UserOptions.Properties | 
                select Name, Value |
                ft -AutoSize
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

} ## END FUNCTION Get-SQLProperties

# --------------------------------------------------------------------------------------------------------

function Get-SQLSessions
{

<#
.SYNOPSIS
Returns a list of current SQL Sessions on a server.
   
.DESCRIPTION
Get-SQLSessions returns a list of the current SQL Server sessions that exist on one, or more,
servers input by the user.  The output inclueds: the login name, session ID, status, connection
time, and others.

The output may be directed to the screen or to a GUI Grid View where the user can sort each 
column return, and perform additional search options.

.PARAMETER computername
Mandatory parameter that is used to identify the SQL Server server[s].  Several server names may
be entered, each separated by a comma.

.EXAMPLE
Get-SQLSessions -computername AUSDSQLGAGL09A [, ...]

Returns a list of sessions and session information to the user screen

.PARAMETER GridView
Optional parameter that directs the output to a GUI based Grid View

.EXAMPLE
Get-SQLSessions -computername AUSDSQLGAGL09A [, ...] -GridView

Returns a list of sessions and session information to a Grid View

#>


[CmdletBinding()]

param
(
       [Parameter (Mandatory = $True, ValueFromPipeline = $True )] [string[]] $computername,
       [switch] $GridView
)


BEGIN
{
$SQLQuery = @"
SELECT dec.client_net_address ,
des.program_name ,
des.host_name ,
des.login_name ,
dec.session_id,
des.status,
dec.connect_time,
des.last_request_start_time,
des.last_request_end_time
FROM sys.dm_exec_sessions AS des
INNER JOIN sys.dm_exec_connections AS dec
ON des.session_id = dec.session_id
GROUP BY dec.client_net_address ,
des.program_name ,
des.host_name, 
des.login_name,
dec.session_id,
dec.connect_time,
des.status,
des.last_request_start_time,
des.last_request_end_time
ORDER BY dec.session_id 
       , dec.connect_time desc
       , des.program_name
       , dec.client_net_address;
"@

Import-Module SQLPS -DisableNameChecking | Out-Null

}


PROCESS
{
    foreach ($computer in $computername)
    {
        try
        {
            $canPing = Test-Connection -ComputerName $computer -Count 1 -Quiet

            if ($canPing)
            {

                $SRV = New-Object microsoft.sqlserver.management.smo.server -ArgumentList $computer -ErrorAction Stop

                if ($GridView) 
                {
                    Invoke-Sqlcmd -Query $SQLQuery -ServerInstance $SRV -ErrorAction Stop | Out-GridView -Title "SQL Sessions for Server: $computer"
                }
                else 
                { 
                    Write-Output "Server: $computer"
                    Invoke-Sqlcmd -Query $SQLQuery -ServerInstance $SRV -ErrorAction Stop | ft -AutoSize 
                }

            }
            else
            {
                throw "Unable to Ping Server: $computer"
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


} ## END FUNCTION: Get-SQLSessions

# --------------------------------------------------------------------------------------------------------

function Get-OsWaitStats
{

<#

.Synopsis
Get-OsWaitStats returns values for all wait statistics on the database server.  These
are cumulative statistics, values shown are given since the last server restart.

.DESCRIPTION

.PARAMETER computername
Mandatory parameter, value used to connect to the database server.  Only a single server
may be queried at a time.

.PARAMETER InstanceName
Optional parameter, used if there is a specific instance to be used.

.PARAMETER To_Output_File
Optional Boolean parameter, if included, the output of the command will be directed to 
an output file vs. a GUI output screen.

.PARAMETER Out_Filename
Optional parameter, if used along with to_output_file, the filename given is used to
hold the result set. *Note: if the user does not include a filename path, the default
filepath/filename will be used: C:\temp\OsWaitStats.csv

.EXAMPLE
   Get-OSWaitStats -computername AUSDSQLGAGL13A 

   This example will query server: AUSDSQLGAGL13A and return a list of wait statistics to
   a GUI based grid report.  The user may sort or eliminate the waits returned.

.EXAMPLE
   Get-OSWaitStats -computername AUSDSQLGAGL13A -InstanceName someInstance -To_Output_file

   Wait statistics are queried from the server: AUSDSQLGAGL13A, Instance: someInstance and 
   returned to the default output filename: C:\temp\OsWaitStats.csv

#>

    [CmdletBinding()]

    Param
    (
        [Parameter(Mandatory = $true,  ValueFromPipeline = $true)] [ValidateNotNullOrEmpty()] [String] $computername,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)] [String] $InstanceName,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)] [switch] $To_Output_File,

        [Parameter(Mandatory = $false, ValueFromPipeline = $true)] [String] $Out_Filename
    )


BEGIN
{

Import-Module SQLPS -DisableNameChecking | Out-Null

$SQL = @"
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT
wait_type AS 'Wait Type',
waiting_tasks_count AS 'Waiting Tasks Count',
(wait_time_ms - signal_wait_time_ms) AS 'Resource Wait Time'
, signal_wait_time_ms AS 'Signal Wait Time'
, wait_time_ms AS 'Total Wait Time'
, COALESCE(wait_time_ms / NULLIF(waiting_tasks_count,0), 0) AS 'Average WaitTime'
FROM sys.dm_os_wait_stats;
"@

if( $Out_Filename.Length -eq 0) { $Out_Filename = "C:\temp\OsWaitStats.csv" } # Default filename

$QryTimeout = 10                                                              # Query Timeout for Invoke-SQLCMD

}


PROCESS
{
    try 
    {
        
        $test = Test-Connection -ComputerName $computername -Count 1 -Quiet  -ErrorAction Stop 

        if ( $test -eq $false )
        {
            throw "Unable to Ping Server: $computerName"
        }			


        $srv  = New-Object -typename microsoft.sqlserver.management.smo.server -argumentlist $computername  -ErrorAction Stop


        if ($srv -eq $null)
        {
            throw "Unable To Connect to Server: $computername"
        }

        # -- DEBUG ONLY --
        Write-Debug "computer: $computername"
        Write-Debug "instance: $InstanceName"
        Write-Debug "to file:  $To_Output_File"
        Write-Debug "output file name: $Out_Filename"
        
        
    
    }
    catch 
    {
        Write-Output "An Error Has Occurred!"
        Write-Output $_.exception.message
        return
    }
    

    try 
    {

        # Query instance based upon host and instance name - if given
        if ($InstanceName.Length -eq 0 -or $InstanceName.Contains("null"))
        {
            Write-Debug "In first sqlcmd statement"
            $results = Invoke-Sqlcmd -ServerInstance $computername -Query $SQL -QueryTimeout $QryTimeout -ErrorAction Stop 
        } 
        else
        {
            Write-Debug "In second sqlcmd statement"
            $results = Invoke-Sqlcmd -ServerInstance $InstanceName -HostName $computername -Query $SQL -QueryTimeout $QryTimeout -ErrorAction Stop 
        }


        # Display the results or write to output file
        if ( $To_Output_File -eq $true )
        {
            $results | Export-Csv -Path $Out_Filename -Append -NoTypeInformation -ErrorAction Stop

            if ( Test-Path -Path $Out_Filename ) 
            { 
                Write-Output "Output Written to File: $Out_Filename"
            }
            else 
            {
                Throw "Error Writing to File: $Out_Filename"
            }
        }
        else
        {
            $results | Out-GridView -Title "$computername OS Wait Statistics" 
        }

    }
    catch 
    {
        Write-Output "A SQL Error Has Occurred!"
        Write-Output $_.exception.message
        return
    }
     
}


END {}

} ## END Get-OsWaitStats

# --------------------------------------------------------------------------------------------------------

function Get-DBInfo
{

<#

.Synopsis
Get-DBInfo will return all database information based upon the server SMO class.  The user
has three options for use:
1. database name:  provide a string for a specific database or group of databases
2. version information only:  this option will only return the OS and DB versions of the 
   specific server
3. all DB information: this option will return all parameters for the database object, this
   is the most verbose output.  Eliminating this option will cause the program to return
   the following information for those databases found:

name 
createdate
CompatibilityLevel
isaccessible
recoverymodel
lastbackupdate 
lastdifferentialbackupdate
lastlogbackupdate
LogReuseWaitStatus


.DESCRIPTION

.PARAMETER computername
Mandatory parameter, value used to connect to the database server. Multiple servers may
be listed.

.PARAMETER databasename
Optional parameter, may be used to seek a specific database or group of databases.  The
Regex wildcard '*' may be used.

.PARAMETER versionInfoOnly
Optional parameter that, when used, will only return the server name, server OS version, 
and server DB version.

.PARAMETER AllDBInfo
Optional parameter that will return all database parameters found in the database SMO
class.  If used on a server with many databases, the output will be large.


.EXAMPLE
   Get-DBInfo -computername AUSDSQLGAGL13A 

   This example will query server: AUSDSQLGAGL13A and return information (see above) for 
   all available databases.  

.EXAMPLE
   Get-DBInfo -computername AUSDSQLGAGL13A, AUSDSQLGAGL09A -versionInfoOnly
   
   Both servers, AUSDSQLGAGL13A and AUSDSQLGAGL09A, will be queried for their OS and Database
   version[s] only.


   .EXAMPLE
   Get-DBInfo -computername AUSDSQLGAGL13A, AUSDSQLGAGL09A -databasename DIT* -allDBInfo
   
   Both servers, AUSDSQLGAGL13A and AUSDSQLGAGL09A, are queried for any databases with names
   that begin with DIT.  Of those return, all will have every database parameter returned
   based upon those found in the SMO database class.

#>

    [CmdletBinding()]

    param 
    (
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)] [ValidateCount(1,10)] [string[]] $computername,
        [string]   $databasename = $null,
        [switch]   $versionInfoOnly,
        [switch]   $AllDBInfo
    )

    BEGIN
    {
        Import-Module SQLPS -DisableNameChecking | Out-Null
    }

    PROCESS 
    {
        foreach ($computer in $computername)
        {   
            try 
            {
                Write-Verbose "Testing server connection: $computer"

                $canConnect = Test-Connection -ComputerName $computer -Count 1 -Quiet -ErrorAction Stop

                if ($canConnect)
                {
            
                    Write-Verbose "`$canConnect is true - $canConnect"

                    $server = New-Object -TypeName microsoft.sqlserver.management.smo.server -ArgumentList $computer -ErrorAction Stop

                    if ($versionInfoOnly)  # User may just want a quick glance at the versions, nothing else
                    {
                        "Server: " + $server.Name.ToString()
                        "Server OS Version: " + $server.OSVersion.ToString()
                        "Server DB Version: " + $server.VersionString.ToString()
                        continue
                    }

                    # Print out server name and version info
                    "Server: " + $server.Name.ToString()

                    "Server OS Version: " + $server.OSVersion.ToString()

                    "Server DB Version: " + $server.VersionString.ToString()


                    $databases = $server.databases.Where({ $_.IsAccessible }) # be sure the DB[s] are accessible


                    # databases found on server?
                    if($databases.Count -eq 0)
                    {
                        Write-Output "No Databases Found!"
                        continue
                    }
                    else 
                    {
                        "Database Count: " + $databases.Count.ToString()
                    }

                
                    # specific database name entered?
                    if ($databasename)  
                    { 
                        $databases = $databases.where({$_.name -like $databasename}) 
                        # be sure something exists, if not, tell the user
                        if ( $databases.count -lt 1  ) {
                            throw "No Databases Found For Input String: $databasename"
                        }
                    }
                    
                
                    # list DB's to user...
                    if ($AllDBInfo)
                    {
                        Write-Output "Gathering ALL Database Information - Please Stand By ..."
                        $databases |
                        select * |
                        sort |
                        fl
                    } 
                    else
                    {
                        $databases |
                        select name, createdate, CompatibilityLevel, isaccessible, recoverymodel,
                        lastbackupdate, lastdifferentialbackupdate, lastlogbackupdate,
                        LogReuseWaitStatus  |
                        ft -AutoSize
                    }
                }
                else
                {
                    Throw "Unable to Connect to Server: $computer"
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

END{}

} ## END Get-DBInfo


# --------------------------------------------------------------------------------------------------------
##                                     END MODULE: SQLTOOLS.psm1                                        ##
# --------------------------------------------------------------------------------------------------------
