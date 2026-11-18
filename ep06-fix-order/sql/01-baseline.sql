/* EP6 - 01: Baseline
   ก่อนรัน: Discard results after execution, เปิด actual plan */

USE StackOverflow2013;
GO
SET STATISTICS TIME, IO ON;
GO
DECLARE @month char(7) = '2013-06';

SELECT p.Id, p.Title, p.Body, p.Score, p.CreationDate, u.DisplayName
FROM dbo.Posts AS p
JOIN dbo.Users AS u ON u.Id = p.OwnerUserId
WHERE CONVERT(char(7), p.CreationDate, 120) = @month
ORDER BY p.CreationDate;
GO
