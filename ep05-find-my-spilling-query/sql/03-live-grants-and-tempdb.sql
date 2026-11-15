/* EP5 - 03: ดูสดระหว่างที่ query ของเรากำลังรัน
   รันจากอีกหน้าต่างหนึ่ง ขณะที่ query ช้ายังไม่จบ */

--query test
SELECT Id, PostId, VoteTypeId, UserId, CreationDate
FROM dbo.Votes
ORDER BY UserId
OPTION (MAXDOP 1, MAX_GRANT_PERCENT = 1);

-- grant ที่กำลังใช้อยู่ และคนที่รอคิว (granted_memory_kb = NULL)
SELECT mg.session_id, mg.requested_memory_kb, mg.granted_memory_kb,
       mg.used_memory_kb, mg.ideal_memory_kb, mg.wait_time_ms,
       st.text AS sql_text
FROM sys.dm_exec_query_memory_grants AS mg
CROSS APPLY sys.dm_exec_sql_text(mg.sql_handle) AS st
ORDER BY mg.requested_memory_kb DESC;

-- tempdb ที่แต่ละ session ใช้อยู่ตอนนี้ (จอง - คืน)
-- internal = spill/worktable, user = temp table/table variable
SELECT session_id,
       SUM(internal_objects_alloc_page_count - internal_objects_dealloc_page_count) * 8 / 1024 AS internal_mb_now,
       SUM(user_objects_alloc_page_count - user_objects_dealloc_page_count) * 8 / 1024         AS user_mb_now
FROM sys.dm_db_task_space_usage
GROUP BY session_id
ORDER BY internal_mb_now DESC;
