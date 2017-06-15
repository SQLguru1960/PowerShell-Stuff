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

function Get-SQLLogin
{
	[CmdletBinding()]
	
	param 
	(
		[Parameter (Mandatory = $True,
		            ValueFromPipeline = $True,
					HelpMessage = "Server name or IP Address")]
		[ValidateCount (1,10)]
		[Alias ('hostname')]
		[string[]] $ComputerName,
		[string]   $ErrorLog = "C:\temp\SQLerrors.txt",
		[string]   $Login,	
		[switch]   $LogErrors
	)
	
	Begin 
	{
		Write-Verbose "Error Log: $ErrorLog"
		Write-Verbose "Value of `$LogErrors: $LogErrors"
		
		[regex] $LoginRX = $Login
	}
	
	Process 
	{
		Import-Module SQLPS -DisableNameChecking | Out-Null
		
		$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.Server -ArgumentList $ComputerName
		
		$server.Databases |
		ForEach-Object {
			$database = $_
			
			Write-Verbose "Working DB: $database"
			
			$users = $_.users
			
			$users |
			<#ForEach-Object {
				$LoginID = $LoginRX.Match($_.login).Success.Equals("True") |
				ft -AutoSize
			}#>
			
			Where-Object {-not ($_.IsSystemObject)} |
			Select @{n="Login"; e={$LoginRX.Match($_.login).Success.Equals("True")}} | ft -AutoSize
			Select @{N="Login"; E={$_.login}},
			       @{N="User"; E={$_.name}},
				   @{N="DatabaseName"; E={$database}},
				   @{N="DBRoles"; E={$_.EnumRoles()}},
				   @{N="ObjectPermissions"; E={$database.EnumObjectPermissions($_.name)}} |
			Format-Table -AutoSize
			
		}
		
	} # end Process block
	
	End {}

} # end function