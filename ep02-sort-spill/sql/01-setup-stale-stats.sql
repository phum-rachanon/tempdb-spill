/* EP2 - 01: Setup ตาราง demo ที่ statistics เก่า (รันก่อนถ่าย ใช้เวลาหลายนาที)
   ใช้บนเครื่อง lab เท่านั้น */
GO
DROP TABLE IF EXISTS dbo.UsersDemo;

-- ข้อมูลชุดแรก: เฉพาะ user ที่ Reputation เกิน 1000
-- CONVERT ทำให้ Id ไม่ติด IDENTITY มาจาก dbo.Users
SELECT CONVERT(int, Id) AS Id, DisplayName, Location, Reputation, CreationDate
INTO dbo.UsersDemo
FROM dbo.Users
WHERE Reputation > 1000;

-- statistics ที่ไม่อัปเดตอัตโนมัติ (ใช้สาธิตเท่านั้น)
CREATE STATISTICS st_UsersDemo_Reputation
ON dbo.UsersDemo (Reputation) WITH FULLSCAN, NORECOMPUTE;

-- เติมข้อมูลชุดใหญ่ที่ statistics ไม่รู้จัก
INSERT dbo.UsersDemo (Id, DisplayName, Location, Reputation, CreationDate)
SELECT Id, DisplayName, Location, Reputation, CreationDate
FROM dbo.Users
WHERE Reputation = 1;
GO