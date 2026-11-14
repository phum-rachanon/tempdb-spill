/* EP4 - 03: ข้อมูลยาวเกือบเต็มขนาดที่ประกาศ -> spill
   จำนวนแถวประมาณถูก แต่ขนาดแถวถูกประมาณราวครึ่งเดียว */


DROP TABLE IF EXISTS dbo.FullText100;
CREATE TABLE dbo.FullText100 (Id int PRIMARY KEY, Txt nvarchar(100));

-- ทุกแถวยาว 100 ตัวอักษรเต็มขนาดที่ประกาศ
INSERT dbo.FullText100 (Id, Txt)
SELECT Id, LEFT(CONCAT(DisplayName, REPLICATE(N'x', 100)), 100)
FROM dbo.Users;
GO

SELECT Id, Txt FROM dbo.FullText100 ORDER BY Txt;
GO
