/* EP0 - 05: STATISTICS IO ไม่แสดง Sort spill
   เทียบ logical reads ของ Users ในแท็บ Messages: เท่ากันทั้งสองแบบ */

USE StackOverflow2013;
GO
SET STATISTICS IO ON;
GO

SELECT Id, DisplayName, Location, Reputation
FROM dbo.Users
ORDER BY Location, DisplayName;
GO

SELECT Id, DisplayName, Location, Reputation
FROM dbo.Users
ORDER BY Location, DisplayName
OPTION (MAX_GRANT_PERCENT = 0.01);
GO
