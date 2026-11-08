/* EP1 - 02: ดู grant ของ query ที่กำลังรันอยู่ทั้ง instance
   รันจากอีกหน้าต่าง ระหว่างที่ query ใหญ่กำลังทำงาน
   granted_memory_kb เป็น NULL = ยังรอคิว grant อยู่ */

SELECT  mg.session_id,
        mg.ideal_memory_kb       AS Desired_KB,     -- = DesiredMemory
        mg.required_memory_kb    AS Required_KB,    -- = RequiredMemory
        mg.requested_memory_kb   AS Requested_KB,   -- = RequestedMemory
        mg.granted_memory_kb     AS Granted_KB,     -- = GrantedMemory (NULL = ยังรอคิว)
        mg.used_memory_kb        AS UsedNow_KB,     -- ใช้อยู่ตอนนี้
        mg.max_used_memory_kb    AS MaxUsed_KB,     -- = MaxUsedMemory
        mg.wait_time_ms          AS GrantWait_sec,  -- = GrantWaitTime
        st.text                  AS sql_text
FROM sys.dm_exec_query_memory_grants AS mg
CROSS APPLY sys.dm_exec_sql_text(mg.sql_handle) AS st
ORDER BY mg.requested_memory_kb DESC;

-- เพดานรวมของ grant ทั้ง instance
SELECT  resource_semaphore_id, 
        pool_id,
        target_memory_kb, 
        available_memory_kb, 
        granted_memory_kb,
        grantee_count, waiter_count
FROM sys.dm_exec_query_resource_semaphores;

