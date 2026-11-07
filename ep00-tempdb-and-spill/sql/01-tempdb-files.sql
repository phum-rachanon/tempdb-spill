/* EP0 - 01: ไฟล์และพื้นที่ของ tempdb */

-- ไฟล์ของ tempdb: ขนาด, autogrowth, ตำแหน่ง
SELECT name, type_desc,
       size * 8 / 1024 AS size_mb,
       physical_name
FROM tempdb.sys.database_files;

-- พื้นที่ใน tempdb ตอนนี้: ทั้งหมด / ใช้อยู่ / ว่าง
SELECT SUM(total_page_count)              * 8 / 1024 AS total_mb,
       SUM(allocated_extent_page_count)   * 8 / 1024 AS used_mb,
       SUM(unallocated_extent_page_count) * 8 / 1024 AS free_mb
FROM tempdb.sys.dm_db_file_space_usage;
