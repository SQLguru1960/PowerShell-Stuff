# check logins for a specific login
# Import-Module SQLPS -DisableNameChecking | Out-Null

# add an input for the server name
#              and the user/login to find
# piping info from a file is needed too:
#   get-content (filename) | Find-Login

Import-Module SQLPS -DisableNameChecking | Out-Null

$instanceName = "WN7X64-1284N12\TEDS_INSTANCE"

$server = New-Object -TypeName Microsoft.SqlServer.Management.Smo.server -ArgumentList $instanceName

$Databases = $server.Databases.Where({-not $_.IsSystemObject})

 foreach ($db in $Databases)
 {
     Write-Output ""
     Write-Output "DATABASE: $db "
     Write-Output ""

     foreach($user in $db.Users.Where({-not $_.IsSystemObject}))
     #foreach($user in  $db.Users)
     {
        if (($db.Users).Count -gt 0)
        {
            Write-Output "User: $user"
        
            $pList = $db.EnumDatabasePermissions($user.Name)
            $rList = $user.EnumRoles()
    
            if ($pList.Count -gt 0)
            {
                Write-Output "PERMISSIONS:"
                $pList |
                select Grantee, Grantor, PermissionState, PermissionType  |
                ft -AutoSize
            }

            if ($rList.Count -gt 0)
            {
                Write-Output "ROLES:"
                $rList |
                ft -AutoSize
            }
        }
        else 
        {
            Write-Output "No Users Found for Database: $db"
            Write-Output ""
        }

     }
 }

