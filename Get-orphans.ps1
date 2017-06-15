$srv = New-Object -TypeName microsoft.sqlserver.management.smo.server -ArgumentList ausdbsqlmaster3 -ErrorAction stop


foreach ($db in $srv.Databases)
{
 "Login Mappings for the database: "+ $db.Name
 

 $dt = $db.EnumLoginMappings()
 

 foreach($row in $dt.Rows)
     {
        foreach($col in $row.Table.Columns)
          {
            $col.ColumnName + "=" + $row[$col]
          }
 
     }
} 