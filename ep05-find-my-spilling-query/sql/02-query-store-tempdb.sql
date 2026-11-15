/* EP5 - 02: query ที่ใช้ tempdb มากที่สุดจาก Query Store
   avg_tempdb_space_used และ max_query_max_used_memory มีหน่วยเป็นหน้า 8 KB
   ต้องเปิด Query Store ใน database ก่อน (SQL Server 2017 ขึ้นไป) */

--เปิด query store
ALTER DATABASE StackOverflow2013 SET QUERY_STORE = ON;

--check ว่าเปิดแล้ว
SELECT actual_state_desc, desired_state_desc, query_capture_mode_desc
FROM sys.database_query_store_options;

SELECT TOP (20)
    q.query_id,
    SUM(rs.count_executions)                                         AS execs,
    SUM(rs.avg_tempdb_space_used * rs.count_executions)
        / NULLIF(SUM(rs.count_executions), 0) * 8 / 1024.0          AS avg_tempdb_mb,
    MAX(rs.max_query_max_used_memory) * 8 / 1024.0                  AS max_used_memory_mb,
    MAX(qt.query_sql_text)                                           AS query_text
FROM sys.query_store_runtime_stats AS rs
JOIN sys.query_store_plan          AS p  ON p.plan_id = rs.plan_id
JOIN sys.query_store_query         AS q  ON q.query_id = p.query_id
JOIN sys.query_store_query_text    AS qt ON qt.query_text_id = q.query_text_id
-- WHERE qt.query_sql_text LIKE N'%ชื่อตารางหรือ procedure ของเรา%'
GROUP BY q.query_id
ORDER BY avg_tempdb_mb DESC;
