/* EP4 - 01: เพิ่มคอลัมน์ nvarchar(max) เข้า SELECT
   เทียบ Estimated Row Size ที่ Sort และ Desired/Granted/MaxUsed ที่ SELECT */

-- ไม่มี AboutMe
SELECT Id, DisplayName, Location
FROM dbo.Users
ORDER BY CreationDate;
GO

-- มี AboutMe (nvarchar(max))
SELECT Id, DisplayName, Location, AboutMe
FROM dbo.Users
ORDER BY CreationDate;
GO
