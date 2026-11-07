# EP0 – tempdb คืออะไร และ spill เกิดจากอะไร

ความยาว 10–12 นาที · Database: StackOverflow2013 · พื้นฐานที่ควรมี: อ่าน actual plan ได้, รู้จัก statistics

## EP นี้ผู้เรียนได้อะไร

- รู้ว่า tempdb คืออะไร และเก็บอะไรบ้าง
- เข้าใจว่า memory grant และ spill คืออะไรในภาพรวม
- หาคำเตือน spill ใน execution plan ได้ และอ่าน MemoryGrantInfo เบื้องต้นได้
- วัดจำนวนหน้าที่ query เขียนลง tempdb ด้วย DMV ได้
- รู้ว่าทำไม STATISTICS IO อย่างเดียวหา Sort spill ไม่เจอ

## EP นี้แก้ปัญหาอะไร

| ปัญหาที่เจอ | EP นี้ช่วยยังไง |
|---|---|
| query ช้าทั้งที่ logical reads ไม่สูง index ก็ดูดีแล้ว หาสาเหตุไม่เจอ | ชี้ว่าเวลาที่หายไปอาจอยู่ที่การเขียนอ่าน tempdb (spill) ซึ่ง STATISTICS IO ไม่แสดง |
| query เดิมบางวันเร็วบางวันช้า ทั้งที่ข้อมูลที่อ่านเท่าเดิม | ปูพื้นว่าความเร็วขึ้นกับ memory ที่ได้จอง ไม่ใช่แค่จำนวนหน้าที่อ่าน |
| เห็นสามเหลี่ยมเหลืองใน plan แต่ไม่รู้ว่าหมายถึงอะไร ร้ายแรงแค่ไหน | อ่านคำเตือน spill ได้ และวัดขนาดเป็นจำนวนหน้าและ MB ได้จริง |

## เนื้อหาพร้อมตัวอย่าง

### 1. tempdb คืออะไร

- system database ที่ทุก SQL Server มี เป็นพื้นที่ทำงานชั่วคราว
- **ทุก database บน instance ใช้ tempdb ตัวเดียวกันร่วมกัน**
- ถูกสร้างใหม่ทุกครั้งที่ restart SQL Server ไม่มีข้อมูลค้างจากรอบก่อน

| กลุ่ม | ตัวอย่าง | ใครสร้าง |
|---|---|---|
| User objects | temp table (`#t`, `##t`), table variable (`@t`) | เราเขียนโค้ดสร้าง |
| Internal objects | worktable, workfile, ข้อมูลที่ spill จาก Sort และ Hash | SQL Server สร้างเองระหว่างรัน query |

ตัวอย่าง: [`sql/01-tempdb-files.sql`](sql/01-tempdb-files.sql) ดูไฟล์และพื้นที่ของ tempdb บนเครื่อง

### 2. Memory grant และ spill คืออะไร

- operator ที่ต้องใช้ memory เป็นพื้นที่ทำงาน ตัวหลักคือ **Sort** และ **Hash Match**
- SQL Server จอง memory ให้ **ทีละ query ก่อนเริ่มรัน** เรียกว่า **memory grant** คำนวณจากจำนวนแถวและขนาดแถวที่ **ประมาณ** ไว้
- ระหว่างรัน **ขอเพิ่มไม่ได้**
- ข้อมูลจริงเกิน memory ที่ได้ → ส่วนเกินถูกเขียนลง tempdb แล้วอ่านกลับ = **spill**
- ผลลัพธ์ยังถูกต้อง แต่ช้าลงเพราะงานดิสก์ที่เพิ่มขึ้น

```
ประมาณจำนวนแถว → จอง memory grant → เริ่มทำงาน
    ├─ memory พอ   → ทำเสร็จใน memory
    └─ memory ไม่พอ → spill ลง tempdb แล้วอ่านกลับ
```

spill ไม่กี่หน้าเกิดได้เป็นเรื่องปกติ ตัวที่ควรสนใจคือ spill ใหญ่, spill level สูง หรือ spill ใน query ที่ถูกเรียกบ่อย

### 3. ตัวอย่าง: query เดียวกัน แบบไม่ spill กับแบบ spill

ไฟล์: [`sql/02-spill-demo.sql`](sql/02-spill-demo.sql)

ใช้ hint `MAX_GRANT_PERCENT` จำกัด memory เพื่อ **จำลอง** spill ต้นเหตุจริงในงานจริงจะเรียนใน EP1–EP4

### 4. ดู spill ใน execution plan

- เปิด actual plan (Ctrl+M) → ไอคอน Sort มีสามเหลี่ยมเหลือง → hover อ่านคำเตือน
- คำเตือน spill มีเฉพาะใน **actual plan**
- คลิก SELECT → F4 → **MemoryGrantInfo** (หน่วย KB)

ตัวอย่างค่าจริงจาก query แบบ spill:

| ค่า | ตัวเลข | อ่านว่า |
|---|---|---|
| DesiredMemory | จำนวนที่อยากได้ คิดจากค่าประมาณ |
| GrantedMemory | จำนวนที่ได้จริง |
| MaxUsedMemory | ใช้จริงสูงสุดระหว่างรัน (มีเฉพาะ actual plan) |

> อยากได้เกือบ 600 MB แต่ได้แค่ 7 MB และใช้จนหมด ที่เหลือจึง spill ลง tempdb

เทียบกับ query แบบปกติ: GrantedMemory ใกล้ DesiredMemory และ MaxUsedMemory น้อยกว่า GrantedMemory = ไม่ spill

### 5. วัดหน้าที่เขียนลง tempdb ด้วย DMV

ไฟล์: [`sql/03-measure-tempdb-pages.sql`](sql/03-measure-tempdb-pages.sql)

`internal_objects_alloc_page_count` ใน `sys.dm_db_session_space_usage` คือ **ตัวนับสะสม** ของหน้าที่ session นี้เคยจองใน tempdb ตั้งแต่เปิดหน้าต่าง query เพิ่มขึ้นอย่างเดียว เหมือน **เลขไมล์รถ** จึงต้องจดก่อนและหลังแล้วเอามาลบกัน

| | page count | AllocMB |
|---|---|---|
| ก่อนรัน | 15,552 | 121 |
| หลังรัน | 31,200 | 243 |
| **ผลต่าง** | **15,548 หน้า** | **≈ 121 MB** |

- หน่วยเป็นหน้า หน้าละ 8 KB เหมือน logical reads
- `AllocMB` เป็นคอลัมน์ที่คำนวณเอง (`page * 8 / 1024`) หารแบบจำนวนเต็มจึงตัดเศษ ใช้ `/ 1024.0` ถ้าต้องการทศนิยม
- ค่าก่อนรันไม่จำเป็นต้องเป็น 0 (เป็นของ query ก่อนหน้าใน session เดียวกัน) เปิดหน้าต่างใหม่ถ้าอยากให้เริ่มใกล้ 0
- ถ้าเปิด Discard results after execution ผล DMV จะถูกทิ้งด้วย ไฟล์นี้จึงใช้ `PRINT` แสดงผลต่างในแท็บ Messages

### 6. STATISTICS IO ไม่บอก Sort spill

ไฟล์: [`sql/04-statistics-io.sql`](sql/05-statistics-io.sql)

- logical reads ของตาราง Users เท่ากันทั้งแบบ spill และไม่ spill
- ดูแค่ STATISTICS IO จะพลาดปัญหานี้ ต้องดู actual plan หรือ DMV ประกอบเสมอ

### 7. spill กระทบ query อื่นยังไง

- **แย่งดิสก์ tempdb:** ทุก database ใช้ tempdb ร่วมกัน spill หนักทำให้งานอื่นที่ใช้ tempdb ช้าตาม
- **กินพื้นที่ tempdb:** spill กับ temp table (`#`) ใช้พื้นที่ก้อนเดียวกัน ถ้า tempdb เต็มและไฟล์โตต่อไม่ได้ การสร้างหรือ insert `#temp` / `@table` ของทุก session จะ error 1105
- **รันนานขึ้น:** query ที่ spill ถือ CPU, worker thread และ lock นานขึ้น
- spill ไม่ได้แย่ง memory grant จากคนอื่น ตัวที่ทำแบบนั้นคือ query ที่จองเกิน (EP9)

## สรุปตอนท้าย

- tempdb คือพื้นที่ทำงานชั่วคราวที่ทุก database บน instance ใช้ร่วมกัน และ SQL Server ใช้เองระหว่างรัน query
- Sort และ Hash ต้องจอง memory ทีละ query ก่อนเริ่มรันจากค่าประมาณ และขอเพิ่มทีหลังไม่ได้
- ข้อมูลจริงเกินที่จอง → spill ลง tempdb ผลถูกเหมือนเดิมแต่ช้าลง
- หา spill จากสามเหลี่ยมเหลืองใน actual plan อ่าน Desired / Granted / MaxUsed และวัดขนาดด้วยผลต่างของ `sys.dm_db_session_space_usage`
- พื้นที่ spill ถูกคืนทันทีที่ query จบ แต่ระหว่างรันแย่งพื้นที่และดิสก์ tempdb กับทุกคน
- STATISTICS IO อย่างเดียวไม่พอ เพราะไม่แสดง Sort spill

**ตอนถัดไป:** EP1 – Memory grant: SQL Server คิดตัวเลขการจอง memory จากอะไร
