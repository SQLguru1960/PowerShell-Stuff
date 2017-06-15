Import-Module SQLPS -DisableNameChecking | Out-Null

#current server name 

$servername = "WN7X64-1284N12\TEDS_INSTANCE"


$server = New-Object "Microsoft.SqlServer.Management.Smo.Server" $servername 

$result = @() 

$ErrorActionPreference = 'SilentlyContinue'

$server.Databases |
#Where-Object IsSystemObject -eq $ false | 
ForEach-Object { 
    $db = $_
    Write-Output "Working database: $db"
    $db.FileGroups | 
    ForEach-Object { 
                     $fg = $_
                     $fg.Files | 
       ForEach-Object { $file = $_
                        $object = [PSCustomObject] @{Database = $db.Name 
                        FileGroup = $fg.Name 
                        FileName  = $file.FileName |
         #Split-Path -Resolve 
         Write-Output 
         "Size(MB)" = "{0:N2}" -f ($file.Size/1024) 
         "UsedSpace(MB)" = "{0:N2}" -f ($file.UsedSpace/1MB) 
         } 
         
         $result += $object 
       } 
    } 
} 

$result | 
Format-Table -AutoSize
