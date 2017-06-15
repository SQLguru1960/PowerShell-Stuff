function get-logins
{

param
(
    [string[]] $instanceName,
    [string]   $login
)

foreach ($computer in $instanceName)
{


 $server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.server -ArgumentList $computer -ErrorAction Stop


 Write-Output "Server:  $computer"

$LoginList = $server.Logins.Where({$_.name -like $login})

if ($LoginList.count -gt 0)
{ 
   Write-Output $LoginList | ft -AutoSize
}
else
{
    Write-Output "No logins found that match: $login"
}

}
}
 
get-logins -instanceName AUSDVSQLFRMDB05, AUSDVSQLGRDCL15, AUSDVSQLGRDCL11  -login *mauricio*









<#

 $logins = $server.Logins  

 Write-Host "Logins:"

 $logins | sort | fl 

 foreach ($db in $server.Databases)
 {
    Write-Host "Database: $db"
     foreach($user in  $db.Users)
     {
        Write-Host "  $user"
     }
 }
 #>