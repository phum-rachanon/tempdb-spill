/* EP0 - 02: query เดียวกัน แบบไม่ spill กับแบบ spill */

USE StackOverflow2013;
GO
SET STATISTICS TIME ON;
GO

-- แบบปกติ
SELECT Id, DisplayName, Location, Reputation
FROM dbo.Users
ORDER BY Location, DisplayName;
GO

-- แบบจำกัด memory เพื่อจำลอง spill (ใช้สาธิตเท่านั้น)
SELECT Id, DisplayName, Location, Reputation
FROM dbo.Users
ORDER BY Location, DisplayName
OPTION (MAX_GRANT_PERCENT = 0.01);
GO

/* ถ้าเครื่อง memory มากจนยังไม่ spill: เพิ่มคอลัมน์ AboutMe ใน SELECT */
