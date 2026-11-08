/* EP1 - 03: ประมาณต่ำ -> grant น้อย -> spill
   ก่อนรัน: เปิด actual plan
   เทียบ Estimated vs Actual Number of Rows ที่ Sort และ MemoryGrantInfo ที่ SELECT */

SET STATISTICS TIME ON;
GO

-- ค่าคงที่: ใช้ histogram ประมาณใกล้จริง
SELECT Id, DisplayName, Location, Reputation
FROM dbo.Users
WHERE Reputation = 1
ORDER BY DisplayName;
GO

-- ตัวแปร local: ใช้ density (ค่าเฉลี่ย) ประมาณต่ำกว่าจริงมาก
DECLARE @rep int = 1;

SELECT Id, DisplayName, Location, Reputation
FROM dbo.Users
WHERE Reputation = @rep
ORDER BY DisplayName;
GO
