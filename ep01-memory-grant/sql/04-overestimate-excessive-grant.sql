/* EP1 - 04: ประมาณสูง -> grant เกิน -> เปลือง memory
   ดู MemoryGrantInfo: Granted สูง แต่ MaxUsed ต่ำมาก
   และอาจมีคำเตือน Excessive Grant ที่ SELECT */

-- ตัวแปร + เครื่องหมาย > : SQL Server เดาคงที่ราว 30% ของตาราง
DECLARE @minRep int = 2000000;

SELECT Id, DisplayName, Location, Reputation
FROM dbo.Users
WHERE Reputation > @minRep
ORDER BY DisplayName;
GO
