/* EP2 - 04: Top N Sort
   เทียบกับ query ในไฟล์ 03: operator เปลี่ยนเป็น Top N Sort และ grant เล็กลง */


SELECT TOP (100) Id, DisplayName, Location, Reputation, CreationDate
FROM dbo.UsersDemo
WHERE Reputation = 1
ORDER BY DisplayName;
GO
