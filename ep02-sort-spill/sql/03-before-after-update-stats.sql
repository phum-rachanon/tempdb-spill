/* EP2 - 03: Query ก่อนและหลังอัปเดต statistics
   ก่อนรัน: Discard results after execution, เปิด actual plan
   ดู Estimated vs Actual ที่ Sort, คำเตือน spill และ MemoryGrantInfo */


SET STATISTICS TIME ON;
GO

-- ก่อนอัปเดต: histogram ไม่มีค่า 1 -> ประมาณต่ำ -> spill
SELECT Id, DisplayName, Location, Reputation, CreationDate
FROM dbo.UsersDemo
WHERE Reputation = 1
ORDER BY DisplayName;
GO

UPDATE STATISTICS dbo.UsersDemo;
GO

-- หลังอัปเดต: ประมาณใกล้จริง -> ไม่ spill
SELECT Id, DisplayName, Location, Reputation, CreationDate
FROM dbo.UsersDemo
WHERE Reputation = 1
ORDER BY DisplayName
OPTION (RECOMPILE);
GO
