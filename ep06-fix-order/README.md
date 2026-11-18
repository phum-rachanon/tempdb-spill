# EP6 – ลำดับการแก้ spill

ความยาว 15–18 นาที · Database: StackOverflow2013 (ตาราง Posts, Users) · พื้นฐานที่ควรมี: [EP1](../ep01-memory-grant/)–[EP5](../ep05-find-my-spilling-query/), SARGable predicate, covering index

## EP นี้ผู้เรียนได้อะไร

- มีลำดับขั้นการแก้ spill ที่ใช้ได้กับทุกเคส เริ่มจากต้นเหตุก่อน hint
- รู้ว่าแต่ละวิธีแก้ที่ตัวไหนของสูตร grant (จำนวนแถว, ขนาดแถว, การต้อง Sort/Hash เลย)
- วัดผลก่อนและหลังแก้ได้ครบทั้งเวลา หน้า tempdb และ grant
- รู้ว่าเมื่อไหร่ควรใช้ hint และใช้อย่างไรให้ปลอดภัย

## EP นี้แก้ปัญหาอะไร

| ปัญหาที่เจอ | EP นี้ช่วยยังไง |
|---|---|
| แก้ spill แบบลองผิดลองถูก ใส่ hint แล้วไม่นานก็กลับมาเป็นอีก | ให้ลำดับการแก้ที่เริ่มจากต้นเหตุ และใช้ hint เป็นทางสุดท้าย |
| แก้หลายอย่างพร้อมกัน ไม่รู้ว่าอย่างไหนได้ผลจริง | แก้ทีละขั้นและจดตัวเลขเดิมทุกขั้นในตารางก่อน-หลัง |
| รายงานรายเดือนช้าและ spill | ใช้ predicate แบบ SARGable, ลดคอลัมน์, index ที่เรียงไว้ และ keyset paging |
| แก้โค้ดไม่ได้ เช่น query จากโปรแกรมสำเร็จรูป | ใส่ hint ผ่าน Query Store (SQL Server 2022) หรือ plan guide |

## เนื้อหาพร้อมตัวอย่าง

### 1. ลำดับการแก้

| ลำดับ | วิธี | แก้ที่ |
|---|---|---|
| 1 | ทำให้ประมาณจำนวนแถวถูก (statistics, SARGable, เลิกใช้ตัวแปร local) | จำนวนแถวที่ประมาณ |
| 2 | ลดข้อมูลก่อนเรียง (กรองก่อน เลือกเฉพาะคอลัมน์ที่ต้องใช้) | จำนวนแถวจริงและขนาดแถว |
| 3 | index ที่เรียงข้อมูลไว้แล้ว จน Sort หายจาก plan | ไม่ต้องมี operator ที่ขอ memory |
| 4 | เขียน query ใหม่ (TOP, แบ่งหน้า, เรียง key ก่อนแล้วดึงคอลัมน์กว้าง) | ปริมาณงานทั้งหมด |
| 5 | hint `MIN_GRANT_PERCENT` / `MAX_GRANT_PERCENT` | บังคับตัวเลข grant ตรงๆ (ทางสุดท้าย) |

ทำไม hint อยู่ท้ายสุด:

- ข้อ 1–4 แก้ต้นเหตุ ผลดีต่อเนื่องแม้ข้อมูลโตขึ้น
- hint เป็นตัวเลขคงที่ที่เหมาะกับข้อมูลวันนี้ พอข้อมูลเปลี่ยนอาจกลายเป็นจองเกินหรือกลับมา spill
- การบังคับ grant ให้ใหญ่ขึ้นแก้ spill ได้ แต่ย้ายปัญหาไปเป็น RESOURCE_SEMAPHORE ของ query อื่น (EP8)

### 2. เคสตัวอย่าง: รายงานโพสต์ประจำเดือน

โจทย์: แสดงโพสต์เดือนมิถุนายน 2013 เรียงตามเวลา พร้อมชื่อเจ้าของโพสต์

**Baseline** (เปิด Discard results after execution ก่อนวัด): [`sql/01-baseline.sql`](sql/01-baseline.sql)

ปัญหาใน query นี้:

- ครอบฟังก์ชันที่คอลัมน์ (ไม่ SARGable) + ตัวแปร local → SQL Server ใช้ histogram ไม่ได้ ต้องเดา
- ดึง Body (nvarchar(max)) ไปเรียงด้วย ทั้งที่รายงานอาจไม่จำเป็น
- ไม่มี index บน CreationDate → ต้อง scan และ Sort

ตารางจดผล (กรอกจากเครื่องตัวเอง):

| ขั้น | เวลา (ms) | logical reads | หน้า tempdb | Granted / MaxUsed (KB) | Spill |
|---|---|---|---|---|---|
| Baseline | | | | | |
| 1. ประมาณถูก | | | | | |
| 2. ลดคอลัมน์ | | | | | |
| 3. index | | | | | |
| 4. เขียนใหม่ | | | | | |

### 3. ขั้นที่ 1: ทำให้ประมาณจำนวนแถวถูก

ไฟล์: [`sql/02-step1-sargable.sql`](sql/02-step1-sargable.sql)

เปลี่ยนเป็นช่วงวันที่บนคอลัมน์ตรงๆ (SARGable) และให้ SQL Server เห็นค่าจริง

- ถ้าค่ามาจากตัวแปรหรือ parameter: ใช้ stored procedure (parameter ถูก sniff) หรือ `OPTION (RECOMPILE)` ให้ optimizer เห็นค่าตอน compile
- ตรวจว่า statistics ไม่เก่า ([EP2](../ep02-sort-spill/)) ถ้าเก่าให้ UPDATE STATISTICS
- ผลที่ควรเห็น: Estimated rows ใกล้ Actual grant พอดีกับข้อมูลมากขึ้น

### 4. ขั้นที่ 2: ลดข้อมูลก่อนเรียง

ไฟล์: [`sql/03-step2-fewer-columns.sql`](sql/03-step2-fewer-columns.sql)

- Estimated Row Size ที่ Sort ลดลงมาก → grant ลดลงตาม ([EP4](../ep04-column-size-and-grant/))
- กรองให้ได้เยอะที่สุดก่อนถึง Sort หรือ Hash เช่น เงื่อนไข PostTypeId ถ้าต้องการแค่คำถาม

### 5. ขั้นที่ 3: index ที่เรียงไว้แล้ว

ไฟล์: [`sql/04-step3-index.sql`](sql/04-step3-index.sql)

- Index Seek อ่านข้อมูลเรียงตาม CreationDate อยู่แล้ว Sort หายจาก plan
- ต้องดูต่อว่า join กับ Users กลายเป็นอะไร ถ้าเป็น Hash Match ก็ยังขอ memory อยู่ ถ้าเป็น Nested Loops บน PK ของ Users อาจไม่มี MemoryGrantInfo เลย
- ค่าใช้จ่าย: index เพิ่มพื้นที่และงานตอน INSERT/UPDATE ควรเป็น query สำคัญที่รันบ่อย

### 6. ขั้นที่ 4: เขียน query ใหม่

ไฟล์: [`sql/05-step4-keyset-paging.sql`](sql/05-step4-keyset-paging.sql)

ถ้าหน้าจอแสดงทีละ 100 แถว ไม่จำเป็นต้องเรียงทั้งเดือน

- แบ่งหน้าแบบ keyset จำค่าสุดท้ายของหน้าก่อน แทน OFFSET ที่ต้องอ่านและเรียงทุกแถวก่อนหน้านั้น
- ทางเลือกอื่น: เรียงแค่ key แล้วดึงคอลัมน์กว้างทีหลัง (EP4), สรุปผลเก็บไว้ล่วงหน้าสำหรับรายงานที่รันซ้ำ
- หน้าแรกให้ @lastDate เป็นค่าก่อนวันแรกของเดือนเล็กน้อย (เช่น '2013-05-31 23:59:59') หรือเขียน query หน้าแรกแยก ตัวอย่างนี้เน้นรูปแบบ

### 7. ขั้นที่ 5: hint เมื่อแก้ต้นเหตุไม่ได้

| Hint | ทำอะไร | ใช้ตอนไหน |
|---|---|---|
| `MIN_GRANT_PERCENT = n` | รับประกัน grant ขั้นต่ำ n% ของเพดาน | query ที่ spill เพราะประมาณต่ำและแก้ค่าประมาณไม่ได้ |
| `MAX_GRANT_PERCENT = n` | จำกัด grant ไม่เกิน n% ของเพดาน | query ที่จองเกินจนคนอื่นรอ (EP8) |

ไฟล์: [`sql/06-step5-hint.sql`](sql/06-step5-hint.sql)

- ค่า n คิดเป็น % ของเพดาน grant ต่อ query ไม่ใช่ของ memory ทั้งเครื่อง เครื่องที่ memory ต่างกันจะได้ KB ต่างกัน
- แก้โค้ดไม่ได้ (เช่น query จากโปรแกรมสำเร็จรูป): SQL Server 2022 ใส่ hint ผ่าน Query Store ได้ด้วย `sys.sp_query_store_set_hints` รุ่นก่อนหน้าใช้ plan guide
- ทุกครั้งที่ใส่ hint ให้จดเหตุผลไว้ และตามดูผลใน Query Store เป็นระยะ

ล้าง index หลังถ่าย: [`sql/07-cleanup.sql`](sql/07-cleanup.sql)

## สรุปตอนท้าย

- แก้ตามลำดับ: ประมาณถูก → ลดข้อมูล → index ที่เรียงไว้แล้ว → เขียนใหม่ → hint
- ทุกขั้นแก้ที่ส่วนหนึ่งของสูตร grant: จำนวนแถว, ขนาดแถว หรือการต้องมี Sort/Hash เลย
- วัดทุกขั้นด้วยตัวเลขชุดเดิม: เวลา, reads, หน้า tempdb, Granted/MaxUsed
- hint เป็นทางสุดท้าย เพราะตัวเลขคงที่ไม่ตามข้อมูล และอาจย้ายปัญหาไปที่ query อื่น

**นี่คือตอนสุดท้ายของซีรีส์ tempdb spill** ภาพรวมทั้งซีรีส์: เข้าใจ tempdb/spill ([EP0](../ep00-tempdb-and-spill/)) → memory grant ([EP1](../ep01-memory-grant/)) → สาเหตุหลัก Sort/Hash/column size ([EP2](../ep02-sort-spill/)–[EP4](../ep04-column-size-and-grant/)) → หา query ที่ spill จากระบบจริง ([EP5](../ep05-find-my-spilling-query/)) → ลำดับการแก้ที่ใช้ได้ทุกเคส (ตอนนี้)

ติดตามเนื้อหาอื่นของ DevHops ได้ที่ [ช่องทางติดต่อ](../README.md#ติดต่อ-devhops)
