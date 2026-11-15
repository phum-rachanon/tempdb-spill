# EP5 – หา query ของเราที่ spill

ความยาว 8 นาที · Database: StackOverflow2013 · พื้นฐานที่ควรมี: [EP0](../ep00-tempdb-and-spill/)–[EP4](../ep04-column-size-and-grant/), Query Store เบื้องต้น

## EP นี้ผู้เรียนได้อะไร

- หา query ของตัวเองที่ spill จาก plan cache ด้วย `sys.dm_exec_query_stats`
- ดูย้อนหลังว่า query ไหนใช้ tempdb และ memory มากจาก Query Store
- ดูสดว่า query ที่กำลังรันอยู่ถือ grant เท่าไหร่ และกิน tempdb อยู่เท่าไหร่

## EP นี้แก้ปัญหาอะไร

| ปัญหาที่เจอ | EP นี้ช่วยยังไง |
|---|---|
| ผู้ใช้แจ้งว่าหน้าจอช้า แต่บนเครื่อง dev รันแล้วเร็ว | หา plan และตัวเลข spill ของ query นั้นจากเครื่องจริง |
| ไม่รู้ว่า query ไหนใน procedure ของเราที่ spill | จัดอันดับด้วย `total_spills` และกรองด้วยชื่อ procedure หรือตาราง |
| ข้อมูลใน plan cache หายทุกครั้งที่ restart | ใช้ Query Store ที่เก็บการใช้ tempdb และ memory ย้อนหลังได้ |
| query กำลังค้างอยู่ ไม่รู้ว่ารอ memory หรือ spill อยู่ | ดูสดด้วย `dm_exec_query_memory_grants` และ `dm_db_task_space_usage` |

## เนื้อหาพร้อมตัวอย่าง

### 1. เครื่องมือในตอนนี้

| เครื่องมือ | ตอบคำถาม | ข้อมูลอยู่นานแค่ไหน |
|---|---|---|
| `sys.dm_exec_query_stats` | query ไหนใน plan cache spill รวมมากสุด | จน plan หลุดจาก cache หรือ restart |
| Query Store | query ไหนใช้ tempdb และ memory เยอะ ย้อนหลังเป็นวัน | ตามที่ตั้งค่าไว้ อยู่รอด restart |
| `sys.dm_exec_query_memory_grants` | ตอนนี้ใครถือ grant อยู่ ใครรอคิว | เฉพาะตอนที่ query กำลังรัน |
| `sys.dm_db_task_space_usage` | ตอนนี้ session ไหนกิน tempdb | เฉพาะตอนที่ task กำลังรัน |

สิทธิ์ที่ต้องมี: DMV ระดับ server ต้องใช้ `VIEW SERVER STATE` (SQL Server 2022 ขึ้นไปคือ `VIEW SERVER PERFORMANCE STATE`) ถ้ารันแล้วโดนปฏิเสธ ให้ขอสิทธิ์นี้จาก DBA บนเครื่อง test หรือ staging

### 2. sys.dm_exec_query_stats: query ไหน spill มากสุด

ไฟล์: [`sql/01-top-spilling-queries.sql`](sql/01-top-spilling-queries.sql)

มีคอลัมน์ spill (นับเป็นจำนวนหน้า 8 KB) และ grant ตั้งแต่ SQL Server 2016 SP2 / 2017 CU3 ขึ้นไป

ตัวอย่าง: รัน query ที่ spill จาก EP2 สักสองสามรอบ แล้วรันไฟล์นี้ จะเห็น query นั้นขึ้นมาพร้อม `total_spills`

อ่านผล:

- `avg_spill_pages` สูง + `execution_count` สูง = ควรแก้ก่อน
- `avg_ideal_grant_kb` มากกว่า `avg_grant_kb` = ได้น้อยกว่าที่ต้องการ
- `avg_used_grant_kb` น้อยกว่า `avg_grant_kb` มาก = จองเกิน (เจาะใน [EP8](../ep08-excessive-grant-and-concurrency/))
- หาเฉพาะของเรา: เปิดบรรทัด `AND st.text LIKE ...` แล้วใส่ชื่อ procedure หรือตาราง
- ข้อจำกัด: เห็นเฉพาะ plan ที่ยังอยู่ใน cache และหายหมดตอน restart

### 3. Query Store: ดูย้อนหลังว่าใครใช้ tempdb

ไฟล์: [`sql/02-query-store-tempdb.sql`](sql/02-query-store-tempdb.sql)

`sys.query_store_runtime_stats` มี `avg_tempdb_space_used` (SQL Server 2017 ขึ้นไป) และ `max_query_max_used_memory` หน่วยเป็นหน้า 8 KB ต้องเปิด Query Store ใน database ก่อน (ถ้ายังไม่เปิด ให้คุยกับ DBA)

- คำนวณค่าเฉลี่ยถ่วงน้ำหนักด้วยจำนวนครั้งที่รัน ไม่ใช่เฉลี่ยของเฉลี่ย
- ไม่อยากเขียน query: เปิดรายงาน Top Resource Consuming Queries ใน SSMS แล้วเลือก metric Temp DB Memory Used
- ข้อดีเหนือ DMV: ข้อมูลอยู่รอด restart และเทียบได้ว่า plan ไหนของ query เดียวกัน spill ซึ่งช่วยตอบคำถาม "เมื่อวานยังเร็วอยู่เลย"

### 4. ดูสด: query ที่กำลังรันถือ memory และ tempdb เท่าไหร่

ไฟล์: [`sql/03-live-grants-and-tempdb.sql`](sql/03-live-grants-and-tempdb.sql)

ตัวอย่าง: เปิดสองหน้าต่าง หน้าต่างแรกรัน query ที่ spill จาก EP2 อีกหน้าต่างรันไฟล์นี้ระหว่างที่ query แรกยังไม่จบ

- `granted_memory_kb` เป็น NULL = ยังรอคิว grant อยู่ (query ไม่ได้ช้าเพราะตัวมันเอง แต่รอคนอื่นคืน memory)
- `used_memory_kb` ชนเพดาน `granted_memory_kb` และ `internal_mb_now` เพิ่มขึ้นเรื่อยๆ = กำลัง spill
- internal = spill, worktable ฯ / user = temp table, table variable

### 5. ได้ข้อมูลแล้วทำอะไรต่อ

1. หา query ที่ spill หนักและรันบ่อยจากข้อ 2 หรือ 3
2. ดึง actual plan มาอ่าน MemoryGrantInfo และคำเตือน spill (ทวน [EP1](../ep01-memory-grant/))
3. หาต้นเหตุและแก้ตามลำดับใน [EP6](../ep06-fix-order/)

ข้อห้าม: อย่ารัน `DBCC FREEPROCCACHE` หรือ `sp_configure` บน production เพื่อ "ลองแก้" เพราะกระทบทุก query บน server

## สรุปตอนท้าย

- `sys.dm_exec_query_stats` มี `total_spills` และค่า grant ใช้หา query ที่ spill ใน cache กรองด้วยชื่อ procedure ได้
- Query Store เก็บการใช้ tempdb และ memory ต่อ plan ย้อนหลังและอยู่รอด restart
- `dm_exec_query_memory_grants` และ `dm_db_task_space_usage` ใช้ดูสดระหว่างที่ query กำลังรัน
- หา → อ่าน plan → แก้ ถ้าปัญหาเป็นระดับ server ให้ส่งต่อ DBA 

**ตอนถัดไป:** EP6 – ลำดับการแก้ spill
