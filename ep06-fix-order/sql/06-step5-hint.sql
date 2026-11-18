/* EP6 - 06: ขั้นที่ 5 hint เมื่อแก้ต้นเหตุไม่ได้
   MIN_GRANT_PERCENT = % ของเพดาน grant ต่อ query (ไม่ใช่ % ของ memory ทั้งเครื่อง) */

SELECT 
   p.Id, 
   p.Title, 
   p.Score, 
   p.CreationDate, 
   u.DisplayName
FROM dbo.Posts AS p
JOIN dbo.Users AS u ON u.Id = p.OwnerUserId
WHERE p.CreationDate >= '2013-06-01'
  AND p.CreationDate <  '2013-07-01'
ORDER BY p.CreationDate
OPTION (MIN_GRANT_PERCENT = 5);
GO

/* แก้โค้ดไม่ได้ (SQL Server 2022): ใส่ hint ผ่าน Query Store
   EXEC sys.sp_query_store_set_hints
        @query_id = <query_id จาก Query Store>,
        @query_hints = N'OPTION (MIN_GRANT_PERCENT = 5)';
*/
