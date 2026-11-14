/* EP3 - 02: Hash Aggregate spill จากจำนวนกลุ่มที่ประมาณต่ำ
   ดู Estimated vs Actual ของ output ที่ Hash Match (Aggregate) */

USE StackOverflow2013;
GO

-- ค่าคงที่: SQL Server รู้จาก histogram ว่าเกือบทุกแถวผ่านเงื่อนไข
SELECT b.UserId, COUNT(*) AS BadgeCount
FROM dbo.Badges AS b
WHERE b.Date > '2008-01-01'
GROUP BY b.UserId;
GO

-- ตัวแปร local กับเครื่องหมาย > : เดาคงที่ราว 30%
DECLARE @date datetime = '2008-01-01';

SELECT b.UserId, COUNT(*) AS BadgeCount
FROM dbo.Badges AS b
WHERE b.Date > @date
GROUP BY b.UserId;
GO

/* ถ้ายังไม่ spill: เติม OPTION (MAX_GRANT_PERCENT = 1) เพื่อจำลอง */
