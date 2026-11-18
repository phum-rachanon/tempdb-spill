/* EP6 - 03: ขั้นที่ 2 ลดข้อมูลก่อนเรียง
   ตัด Body ออก ถ้ารายงานไม่ต้องแสดงเนื้อหาเต็ม */

SELECT p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
FROM dbo.Posts AS p
JOIN dbo.Users AS u ON u.Id = p.OwnerUserId
WHERE p.CreationDate >= '2013-06-01'
  AND p.CreationDate <  '2013-07-01'
ORDER BY p.CreationDate;
GO
