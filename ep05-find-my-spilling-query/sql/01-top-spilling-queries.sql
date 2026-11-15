/* EP5 - 01: query ใน plan cache ที่ spill มากที่สุด
   อยากหาเฉพาะ query ของเรา: เอา comment ที่บรรทัด AND st.text LIKE ออก แล้วใส่ชื่อตารางหรือ procedure
   ต้องการ SQL Server 2016 SP2 / 2017 CU3 ขึ้นไป */

SELECT TOP (20)
    qs.execution_count,
    qs.total_spills,
    qs.total_spills / qs.execution_count            AS avg_spill_pages,
    qs.max_spills,
    qs.total_grant_kb / qs.execution_count          AS avg_grant_kb,
    qs.total_used_grant_kb / qs.execution_count     AS avg_used_grant_kb,
    qs.total_ideal_grant_kb / qs.execution_count    AS avg_ideal_grant_kb,
    SUBSTRING(st.text, qs.statement_start_offset / 2 + 1,
        (CASE qs.statement_end_offset WHEN -1 THEN DATALENGTH(st.text)
              ELSE qs.statement_end_offset END - qs.statement_start_offset) / 2 + 1) AS statement_text
FROM sys.dm_exec_query_stats AS qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
WHERE qs.total_spills > 0
  -- AND st.text LIKE N'%usp_ชื่อprocedureของเรา%'
ORDER BY qs.total_spills DESC;
