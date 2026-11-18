/* EP6 - 04: ขั้นที่ 3 index ที่เรียงไว้แล้ว
   สร้างบน Posts ใช้เวลาหลายนาที ให้สร้างไว้ก่อนถ่าย
   แล้วรัน query ในไฟล์ 03 ซ้ำ: Sort ควรหายจาก plan */

USE StackOverflow2013;
GO
CREATE INDEX IX_Posts_CreationDate
ON dbo.Posts (CreationDate)
INCLUDE (OwnerUserId, Score, Title);
GO
