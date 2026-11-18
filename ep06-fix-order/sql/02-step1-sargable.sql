/* EP6 - 02: ขั้นที่ 1 ทำให้ประมาณจำนวนแถวถูก (SARGable + ค่าที่ optimizer เห็น) */


SELECT p.Id, p.Title, p.Body, p.Score, p.CreationDate, u.DisplayName
FROM dbo.Posts AS p
JOIN dbo.Users AS u ON u.Id = p.OwnerUserId
WHERE p.CreationDate >= '2013-06-01'
  AND p.CreationDate <  '2013-07-01'
ORDER BY p.CreationDate;
GO
