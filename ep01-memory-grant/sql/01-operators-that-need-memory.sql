/* EP1 - 01: operator ไหนขอ memory
   เปิด Include Actual Execution Plan (Ctrl+M) แล้วคลิก SELECT > F4 ทุก query */

-- ไม่มี Sort/Hash: Clustered Index Seek อย่างเดียว -> ไม่มี MemoryGrantInfo
-- (เปลี่ยน Id เป็นค่าที่มีอยู่จริงบนเครื่องได้)
SELECT Id, DisplayName, Reputation
FROM dbo.Users
WHERE Id = 26837;
GO

-- มี Sort: ต้องเก็บทุกแถวไว้เรียง -> มี MemoryGrantInfo
SELECT TOP (1000) Id, DisplayName, Reputation
FROM dbo.Users
ORDER BY Reputation DESC;
GO

-- มี Hash Match (Aggregate): GROUP BY บนคอลัมน์ที่ไม่มี index -> มี MemoryGrantInfo
SELECT TOP(1000) 
   Location, 
   COUNT(*) AS Users
FROM dbo.Users
GROUP BY Location;
GO
