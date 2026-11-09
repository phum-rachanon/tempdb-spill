/* EP2 - 02: statistics เก่าแค่ไหน
   modification_counter สูงเทียบกับ rows = statistics เก่ามาก */

SELECT s.name, sp.last_updated, sp.rows, sp.modification_counter
FROM sys.stats AS s
CROSS APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) AS sp
WHERE s.object_id = OBJECT_ID('dbo.UsersDemo');
