# script to find logins/users/user mappings

Param ([string] $instance)

Import-Module sqlps -DisableNameChecking | Out-Null

$server = New-Object -TypeName microsoft.sqlserver.management.smo.server -ArgumentList $instance

# you can show just the logins:
# $server.logins
# or those specific windows logins given sql server access
# $server.enumWindowUserInfo()

$server.databases |
ForEach-Object {
    $database = $_

    #capture users in this database
    $users = $_.users

    $users |
    Where-Object {-not ($_.issystemobject)} |
    Select @{N="Login"; E={$_.login}},
           @{N="User"; E={$_.name}},
           @{N="Database Name"; E={$database.name}},
           @{N="Login Type"; E={$_.logintype}},
           @{N="User Type"; E={$_.usertype}}
} |
ft -AutoSize
