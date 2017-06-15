Import-Module sqlps -DisableNameChecking | out-null

$server = New-Object -TypeName microsoft.sqlserver.management.smo.server -ArgumentList "WN7X64-1284N12\TEDS_INSTANCE"

$server.Configuration.Properties |
Out-File "C:\Temp\DB_Props.txt"

$server.Information.Properties |
Out-File "C:\Temp\DB_Props.txt" -Append

$db = $server.Databases

# List the $db var first to be sure the database
# you want is indeed at index "0"
$db["adventureworks2014"].Properties | Out-File "C:\Temp\AW2014_Props.txt"
