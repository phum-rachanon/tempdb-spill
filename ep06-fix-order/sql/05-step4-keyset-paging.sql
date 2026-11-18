/* EP6 - 05: ขั้นที่ 4 เขียน query ใหม่ด้วย keyset paging
   หน้าถัดไป: ใส่ CreationDate และ Id ของแถวสุดท้ายในหน้าก่อน */

DECLARE @lastDate datetime = '2013-05-31 23:59:59', @lastId int = 0;

SELECT TOP (100) p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
FROM dbo.Posts AS p
JOIN dbo.Users AS u ON u.Id = p.OwnerUserId
WHERE p.CreationDate <  '2013-07-01'
  AND (p.CreationDate > @lastDate
       OR (p.CreationDate = @lastDate AND p.Id > @lastId))
ORDER BY p.CreationDate, p.Id;
GO
