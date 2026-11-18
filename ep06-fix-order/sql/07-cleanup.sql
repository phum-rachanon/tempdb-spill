/* EP6 - 07: ล้าง index หลังถ่าย ถ้าไม่ต้องการเก็บไว้ */

DROP INDEX IF EXISTS IX_Posts_CreationDate ON dbo.Posts;
