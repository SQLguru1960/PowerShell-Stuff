 $Tables = Invoke-Sqlcmd -ServerInstance "WN7X64-1284N12\TEDS_INSTANCE" -Query "SELECT empid, yearlysalary, monthlysalary from jproco.dbo.payrates;"
 $Tables | ft -AutoSize