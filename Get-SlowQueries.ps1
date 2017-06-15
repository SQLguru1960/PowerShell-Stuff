[string] $computername = "AUSUWDDSDB02"

$sql = @"
SELECT  t.text,
        s.TotalExecutionCount,
        s.TotalElapsedTime,
        s.TotalLogicalReads,
        s.TotalPhysicalReads
FROM    (SELECT deqs.query_plan_hash,
                SUM(deqs.execution_count)    AS TotalExecutionCount,
                SUM(deqs.total_elapsed_time) AS TotalElapsedTime,
                SUM(deqs.total_logical_reads)  AS TotalLogicalReads,
                SUM(deqs.total_physical_reads) AS TotalPhysicalReads
         FROM   sys.dm_exec_query_stats AS deqs
         GROUP BY deqs.query_plan_hash
        ) AS s
        CROSS APPLY (SELECT plan_handle
                     FROM   sys.dm_exec_query_stats AS deqs
                     WHERE  s.query_plan_hash = deqs.query_plan_hash
                    ) AS p
        CROSS APPLY sys.dm_exec_sql_text(p.plan_handle) AS t
ORDER BY TotalLogicalReads DESC;
"@

$sql2 = @"
SELECT *
FROM SYS.DM_OS_WAITING_TASKS WT
ORDER BY WT.SESSION_ID ASC;
"@

$sql3 = @"
SELECT *
FROM SYS.DM_EXEC_SESSIONS ES
WHERE ES.IS_USER_PROCESS = 'TRUE';
"@

Invoke-Sqlcmd -ServerInstance $computername  -Query $sql3  -QueryTimeout 10 |
Out-GridView -Title "Slow Queries" 

