# EP1 – Memory grant: SQL Server จอง memory ยังไง

ความยาว 12–15 นาที · Database: StackOverflow2013 · พื้นฐานที่ควรมี: [EP0](../ep00-tempdb-and-spill/), histogram และ density ของ statistics

## EP นี้ผู้เรียนได้อะไร

- รู้ว่า operator ตัวไหนขอ memory และตัวไหนไม่ขอ
- อ่านค่าใน MemoryGrantInfo ได้ครบทุกตัว
- เห็นว่าประมาณจำนวนแถวผิดทำให้ grant ผิดตาม ทั้งจองน้อยไปจน spill และจองมากไปจนเปลือง memory

## EP นี้แก้ปัญหาอะไร

| ปัญหาที่เจอ | EP นี้ช่วยยังไง |
|---|---|
| query เดิมแค่เปลี่ยนค่าคงที่เป็นตัวแปร แล้วช้าลงมาก | แสดงว่าตัวแปร local ทำให้ประมาณจำนวนแถวผิด grant จึงผิดตาม |
| query ไม่ spill แต่ขอ memory เยอะ | ใช้คู่ Granted กับ MaxUsed บอกว่า query จองเกินจริง |
| ไม่รู้ว่า query ไหนขอ memory บ้าง และตอนนี้ใครถืออยู่ | รู้จัก operator ที่ขอ memory และดูสดด้วย `sys.dm_exec_query_memory_grants` |

## เนื้อหาพร้อมตัวอย่าง

### 1. Operator ที่ขอ memory

| Operator | ใช้ memory ทำอะไร | เจอเมื่อไหร่ |
|---|---|---|
| Sort | เก็บทุกแถวไว้เรียง | ORDER BY, Merge Join ที่ข้อมูลยังไม่เรียง, window function ที่ไม่มี index รองรับ |
| Hash Match (Join) | สร้าง hash table จากตารางฝั่ง build | JOIN ตารางใหญ่ที่ไม่มี index เหมาะๆ |
| Hash Match (Aggregate) | เก็บกลุ่มของ GROUP BY ใน hash table | GROUP BY, DISTINCT บนข้อมูลที่ยังไม่เรียง |

- Sort และ Hash ต้องเห็นข้อมูลทั้งหมด (หรือทั้งฝั่ง build) ก่อนจะทำงานต่อได้ จึงต้องมีที่พักข้อมูล
- Index Seek, Nested Loops, Stream Aggregate ส่งต่อทีละแถวได้ ไม่ต้องจอง memory พื้นที่ทำงาน
- ถ้า plan ไม่มี operator ที่ขอ memory เลย ที่ SELECT จะไม่มี MemoryGrantInfo

ตัวอย่าง: [`sql/01-operators-that-need-memory.sql`](sql/01-operators-that-need-memory.sql)

### 2. Memory grant จองทีละ query

- หนึ่ง query ได้ grant **ก้อนเดียว** แม้ plan จะมี Sort และ Hash หลายตัว SQL Server คำนวณรวมแล้วแบ่งให้ operator ข้างใน
- นับตาม **การรันแต่ละครั้ง** ถ้า 10 session รัน query เดียวกันพร้อมกัน = grant 10 ก้อน
- ใน store procedure จองทีละคำสั่ง
- จองก่อนเริ่มรัน **ถือไว้จนจบ** ระหว่างทางขอเพิ่มไม่ได้ และ query อื่นยืมไม่ได้

**grant คือที่จอง ไม่ใช่ที่ใช้** เหมือนจองโต๊ะร้านอาหาร 10 ที่แต่มาจริง 3 คน อีก 7 ที่ว่างแต่คนอื่นนั่งไม่ได้

| ค่า | เทียบกับการจองโต๊ะ |
|---|---|
| DesiredMemory | อยากจองกี่ที่ |
| GrantedMemory (memory grant) | ร้านให้จองได้จริงกี่ที่ |
| MaxUsedMemory | มานั่งจริงมากสุดกี่คน |

**เพดาน grant**

| เพดาน | ความหมาย | ดูได้ที่ |
|---|---|---|
| ต่อ query | ค่าเริ่มต้นไม่เกินราว 25% ของ memory ที่ workload group ใช้ได้ (`REQUEST_MAX_MEMORY_GRANT_PERCENT` ใน Resource Governor) | MaxQueryMemory ใน plan |
| รวมทั้ง instance | grant ของทุก query รวมกันเกินไม่ได้ ถ้าไม่พอ query ที่มาทีหลังต้องรอคิว เกิด wait `RESOURCE_SEMAPHORE` (เจาะใน EP9) | `sys.dm_exec_query_resource_semaphores` |

### 3. อ่าน MemoryGrantInfo

เปิด actual plan → คลิก SELECT ซ้ายสุด → F4 → ขยาย MemoryGrantInfo (หน่วย KB)

| ค่า | ความหมาย |
|---|---|
| RequiredMemory | ขั้นต่ำที่ต้องได้ถึงจะเริ่มรัน ถ้าไม่ได้ต้องรอ |
| DesiredMemory | จำนวนที่อยากได้ คิดจากค่าประมาณ |
| RequestedMemory | จำนวนที่ขอจริง คือ Desired ที่ถูกตัดด้วยเพดาน |
| GrantedMemory | จำนวนที่ได้จริง |
| MaxUsedMemory | ใช้จริงสูงสุดระหว่างรัน (มีเฉพาะ actual plan) |
| GrantWaitTime | รอคิว memory นานแค่ไหนก่อนได้เริ่ม |
| MaxQueryMemory | เพดานที่ query เดียวขอได้บนเครื่องนี้ ณ ตอนนั้น |
| SerialDesiredMemory / SerialRequiredMemory | ค่าเดียวกันถ้ารันแบบ thread เดียว |

วิธีอ่านเร็ว:

| สิ่งที่เห็น | แปลว่า |
|---|---|
| MaxUsed = Granted และมีคำเตือน spill | จองน้อยไป |
| MaxUsed น้อยกว่า Granted พอสมควร ไม่มี spill | จองพอดี |
| MaxUsed น้อยกว่า Granted มาก | จองเกิน (EP9) |
| Granted น้อยกว่า Desired | ถูกตัดด้วยเพดาน หรือเครื่องมี memory ไม่พอ |

ดู grant ของ query ที่กำลังรันอยู่: [`sql/02-memory-grants-live.sql`](sql/02-memory-grants-live.sql)

### 4. ตัวอย่าง: ประมาณต่ำ → grant น้อย → spill

ไฟล์: [`sql/03-underestimate-spill.sql`](sql/03-underestimate-spill.sql)

query สองตัวหาคน Reputation = 1 เหมือนกัน ต่างกันแค่ใช้ค่าคงที่กับตัวแปร local

- ตอน compile SQL Server ไม่รู้ค่าในตัวแปร เพราะทั้ง batch ถูก compile ก่อน DECLARE ทำงาน จึงใช้ density แทน histogram
- Reputation = 1 เป็นค่าที่มีคนมากที่สุดในตาราง ค่าเฉลี่ยจึงต่ำกว่าความจริงหลายเท่า
- ผลที่ควรเห็น: query ตัวแรก Estimated ใกล้ Actual ไม่ spill / query ตัวที่สอง Estimated ต่ำกว่า Actual มาก Granted เล็ก MaxUsed เต็ม และ Sort มีคำเตือน spill

### 5. ตัวอย่าง: ประมาณสูง → grant เกิน → เปลือง memory

ไฟล์: [`sql/04-overestimate-excessive-grant.sql`](sql/04-overestimate-excessive-grant.sql)

- ตัวแปรกับเครื่องหมายมากกว่า/น้อยกว่า SQL Server ไม่มีข้อมูลให้ใช้ จึงเดาคงที่ราว 30% ของตาราง
- จริงๆ แทบไม่มีใคร Reputation เกินสองล้าน จอง memory ไปมากแต่เกือบไม่ได้ใช้
- ไม่ spill แต่ memory ที่จองไว้ query อื่นใช้ไม่ได้ตลอดเวลาที่รัน ถ้าจองเกินมากพอ SSMS จะขึ้นคำเตือน Excessive Grant ที่ SELECT

### 6. ข้อควรระวังตอนทดลอง

- ถ้า database ตั้ง compatibility level 150 ขึ้นไป memory grant feedback จะปรับ grant เองเมื่อรัน query เดิมซ้ำ รอบสองอาจไม่ spill แล้ว ให้ดูผลรอบแรก หรือรัน `DBCC FREEPROCCACHE` บนเครื่อง lab (ห้ามรันบน production) รายละเอียดใน EP8
- ตัวเลข 25% และ 30% เป็นค่าเริ่มต้นที่เจอทั่วไป ค่าจริงบนเครื่องอาจต่างตามการตั้งค่าและรุ่นของ cardinality estimator

## สรุปตอนท้าย

- operator ที่ขอ memory ตัวหลักคือ Sort และ Hash Match เพราะต้องเห็นข้อมูลทั้งหมดก่อนส่งแถวออก
- grant จองทีละ query ก่อนเริ่มรัน ถือไว้จนจบ และเป็นที่จอง ไม่ใช่ที่ใช้
- grant ≈ จำนวนแถวที่ประมาณ × ขนาดแถวที่ประมาณ คิดตอน compile และมีเพดานต่อ query
- ใน MemoryGrantInfo ให้ดูคู่ Granted กับ MaxUsed ก่อนอย่างอื่น
- ประมาณต่ำ → spill / ประมาณสูง → เปลือง memory และทำให้ query อื่นรอ
- การแก้ spill เกือบทุกแบบจะวนกลับมาที่การทำให้ประมาณจำนวนแถวถูก

**ตอนถัดไป:** EP2 – Sort spill
