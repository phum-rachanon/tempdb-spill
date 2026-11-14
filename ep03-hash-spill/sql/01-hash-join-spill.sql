/* EP3 - 01: Hash Join spill จากฝั่ง build ที่ประมาณต่ำ
   ก่อนรัน: Discard results after execution, เปิด actual plan */

SET STATISTICS TIME, IO ON;
GO

-- ค่าคงที่: ประมาณใกล้จริง
SELECT u.Id, u.DisplayName, b.Name, b.Date
FROM dbo.Users AS u
JOIN dbo.Badges AS b ON b.UserId = u.Id
WHERE b.Date >= '2013-01-01' AND b.Date < '2014-01-01'
GO


-- ตัวแปร local: ฝั่ง build ถูกประมาณต่ำ
DECLARE @startDate DATE = '2013-01-01';
DECLARE @endDate DATE = '2014-01-01';

SELECT u.Id, u.DisplayName, b.Name, b.Date
FROM dbo.Users AS u
JOIN dbo.Badges AS b ON b.UserId = u.Id
WHERE b.Date >= @startDate AND b.Date < @endDate
-- ถ้าไม่ได้ Hash Match ให้เติม: OPTION (HASH JOIN)
GO
