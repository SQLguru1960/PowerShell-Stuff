$SQL1 = @'
SELECT COUNT(*) AS [TOTAL SINGLETON QUERY COUNT]
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(plan_handle)
WHERE cp.cacheobjtype = 'Compiled Plan'
AND cp.objtype = 'Adhoc'
AND cp.usecounts = 1 ;
'@



$SQL2 = @'
BEGIN TRAN
SELECT DTST.[session_id] ,
       DTST.[transaction_id] ,
       DTST.[is_user_transaction]
FROM sys.[dm_tran_session_transactions] AS DTST
--WHERE DTST.[session_id] = @@SPID
ORDER BY DTST.[transaction_id]
COMMIT
'@



# TABLE COUNTS
$SQL3 = @'
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



# UNUSED INDEXES
$SQL4 = @"
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



$SQL5 = @"
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
ORDER BY dec.connect_time desc
       , des.program_name
       , dec.client_net_address ;
"@


# ----------- PASSING VARIABLES ------------ #
# $MyArray = "MyVar1 = 'String1'", "MyVar2 = 'String2'"
# Invoke-Sqlcmd -Query "SELECT `$(MyVar1) AS Var1, `$(MyVar2) AS Var2;" -Variable $MyArray


$tablename = "dbo.users"

$QUERY = "exec sp_depends @objname = '$tablename';"

$instanceName = "AUSDSQLGAGL13A"

Import-Module SQLPS -DisableNameChecking | Out-Null

$SRV = New-Object microsoft.sqlserver.management.smo.server -ArgumentList $instanceName

Invoke-Sqlcmd -Query $SQL5 -ServerInstance $SRV | Ft -AutoSize 


