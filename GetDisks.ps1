Get-WmiObject -Class win32_logicaldisk -ComputerName ausdbsqlmaster3 -Filter "drivetype = '3'" |
Export-Csv -path  "c:\temp\disksDemo.csv" 


 Get-WmiObject -Class win32_logicaldisk -ComputerName AUSSWCPARCDB01, AUSSWCPINTDB01  | 
 ft -AutoSize
