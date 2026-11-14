/* EP4 - 04: เรียงเฉพาะ key ก่อน แล้วค่อยดึงคอลัมน์กว้าง
   เทียบ Estimated Row Size และ grant ของสองแบบ */


-- แบบเดิม: Sort แบก AboutMe ไปด้วยทุกแถว
SELECT TOP (1000) Id, DisplayName, AboutMe
FROM dbo.Users
ORDER BY CreationDate DESC;
GO

-- แบบใหม่: เรียงแค่ Id กับ CreationDate แล้ว join กลับไปดึง AboutMe 1000 แถว
WITH k AS (
    SELECT TOP (1000) Id, CreationDate
    FROM dbo.Users
    ORDER BY CreationDate DESC
)
SELECT u.Id, u.DisplayName, u.AboutMe
FROM k
JOIN dbo.Users AS u ON u.Id = k.Id
ORDER BY k.CreationDate DESC;
GO
