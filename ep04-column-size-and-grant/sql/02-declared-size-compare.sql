/* EP4 - 02: ข้อมูลเดียวกัน ประกาศขนาดต่างกัน
   เทียบ Estimated Row Size, Granted และคำเตือน Excessive Grant */

DROP TABLE IF EXISTS dbo.NameSmall, dbo.NameBig;
CREATE TABLE dbo.NameSmall (Id int PRIMARY KEY, DisplayName nvarchar(40));
CREATE TABLE dbo.NameBig   (Id int PRIMARY KEY, DisplayName nvarchar(4000));

INSERT dbo.NameSmall (Id, DisplayName) SELECT Id, DisplayName FROM dbo.Users;
INSERT dbo.NameBig   (Id, DisplayName) SELECT Id, DisplayName FROM dbo.Users;
GO

SELECT Id, DisplayName FROM dbo.NameSmall ORDER BY DisplayName;
SELECT Id, DisplayName FROM dbo.NameBig   ORDER BY DisplayName;
GO
