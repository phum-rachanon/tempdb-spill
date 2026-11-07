/* EP0 - 03: วัดจำนวนหน้าที่ query เขียนลง tempdb
   internal_objects_alloc_page_count = ตัวนับสะสมของ session (เหมือนเลขไมล์รถ)
   ต้องจดก่อนและหลัง แล้วเอามาลบกัน */

USE StackOverflow2013;
GO

SELECT internal_objects_alloc_page_count,
internal_objects_alloc_page_count * 8 / 1024 AS AllocMB
FROM sys.dm_db_session_space_usage
WHERE session_id = @@SPID;

SELECT Id, DisplayName, Location, Reputation
FROM dbo.Users
ORDER BY Location, DisplayName
OPTION (MAX_GRANT_PERCENT = 0.01);

SELECT internal_objects_alloc_page_count,
internal_objects_alloc_page_count * 8 / 1024 AS AllocMB
FROM sys.dm_db_session_space_usage
WHERE session_id = @@SPID;

GO
