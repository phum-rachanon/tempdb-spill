# EP2 – Sort spill

ความยาว 12–15 นาที · Database: StackOverflow2013 (สร้างตาราง `dbo.UsersDemo` แยกไว้) · พื้นฐานที่ควรมี: [EP0](../ep00-tempdb-and-spill/)–[EP1](../ep01-memory-grant/), statistics และ auto update

## EP นี้ผู้เรียนได้อะไร

- เข้าใจว่า Sort ทำงานต่างกันยังไงตอน memory พอและไม่พอ
- อ่านคำเตือน Sort spill ได้ครบทุกตัวเลข และรู้ว่า spill level บอกอะไร
- เห็นว่า statistics เก่าทำให้ Sort spill ได้ยังไง และตรวจได้ว่า statistics เก่าแค่ไหน
- รู้ว่าทำไม ORDER BY บนข้อมูลใหญ่ถึงเสี่ยง และทางลดความเสี่ยงเบื้องต้น

## EP นี้แก้ปัญหาอะไร

| ปัญหาที่เจอ | EP นี้ช่วยยังไง |
|---|---|
| ORDER BY บนข้อมูลเยอะช้าแบบไม่สม่ำเสมอ | อธิบายกลไก Sort spill และ spill level ให้รู้ว่าเวลาหายไปตรงไหน |
| query ช้าลงหลังโหลดข้อมูลชุดใหญ่ ทั้งที่ไม่ได้แก้โค้ด | ตรวจ statistics เก่าด้วย modification_counter และแก้ด้วย UPDATE STATISTICS |
| เห็นคำเตือน spill แต่ไม่รู้ว่าคุ้มแก้ไหม | อ่านจำนวนหน้าที่เขียน/อ่าน และ level เพื่อจัดลำดับความสำคัญ |
| หน้าจอแสดงแค่ไม่กี่แถว แต่ query เรียงข้อมูลทั้งชุด | ใช้ TOP ให้ได้ Top N Sort และลดคอลัมน์ที่ต้องเรียง |

## เนื้อหาพร้อมตัวอย่าง

### 1. Sort เมื่อ memory พอ

- อ่านทุกแถวเข้า memory → เรียงใน memory → ส่งแถวออกตามลำดับ ไม่แตะดิสก์
- Sort เป็น **blocking operator** ส่งแถวแรกไม่ได้จนกว่าจะอ่านแถวสุดท้ายเสร็จ เพราะแถวสุดท้ายอาจเป็นแถวที่ต้องอยู่บนสุด
- memory ที่ต้องใช้จึงโตตาม **จำนวนแถวทั้งหมด × ขนาดแถว** ไม่ใช่ทีละแถว

### 2. Sort เมื่อ memory ไม่พอ: แบ่งกองแล้วรวม

อธิบายแบบภาพง่าย (กลไกภายในจริงซับซ้อนกว่านี้):

1. อ่านแถวจน memory เต็ม แล้วเรียงชุดนั้น
2. เขียนกองที่เรียงแล้ว (sorted run) ลง tempdb
3. อ่านแถวชุดถัดไป ทำซ้ำจนหมด ได้หลายกองใน tempdb
4. อ่านทุกกองกลับมา หยิบแถวที่น้อยที่สุดจากหัวกองมารวมทีละแถว (merge)

- ผลลัพธ์ถูกต้องเหมือนเดิม แต่ข้อมูลถูกเขียนลงดิสก์และอ่านกลับอย่างน้อยหนึ่งรอบ
- ถ้ากองมีมากจนรวมรอบเดียวไม่ได้ ต้องรวมเป็นชั้นๆ เขียนอ่านซ้ำหลายรอบ = spill level สูงขึ้น
- งานอ่านเขียน tempdb นี้ไม่โผล่ใน logical reads ของตารางใน STATISTICS IO

### 3. อ่านคำเตือน Sort spill

ข้อความเตือนใน SSMS รุ่นใหม่มีหน้าตาประมาณนี้:

*Operator used tempdb to spill data during execution with spill level 1 and 1 spilled thread(s), Sort wrote X pages to and read Y pages from tempdb with granted memory A KB and used memory B KB*

| ส่วนของข้อความ | ความหมาย |
|---|---|
| spill level 1 | เขียนลง tempdb แล้วรวมกลับได้ในรอบเดียว |
| spill level 2 ขึ้นไป | ต้องรวมหลายชั้น อ่านเขียน tempdb ซ้ำ |
| spilled thread(s) | จำนวน thread ที่ spill ใน parallel plan อาจ spill หลาย thread |
| wrote X pages | จำนวนหน้าที่เขียนลง tempdb |
| read Y pages | จำนวนหน้าที่อ่านกลับ |
| granted / used memory | memory ที่ได้และที่ใช้จริงของการ sort นั้น|

หลักการตัดสินใจ: ดูจำนวนหน้าและ spill level มากกว่าดูแค่ว่ามีสามเหลี่ยม spill ไม่กี่สิบหน้าอาจไม่คุ้มแก้ หลักแสนหน้าหรือ level สูงกว่า 1 ควรไล่ต่อ

### 4. ตัวอย่าง: statistics เก่าทำให้ Sort spill

**Setup** (รันไว้ล่วงหน้า ใช้เวลาหลายนาที): [`sql/01-setup-stale-stats.sql`](sql/01-setup-stale-stats.sql)
สร้างตารางจาก user ที่ Reputation เกิน 1000 สร้าง statistics แบบ NORECOMPUTE แล้วเติม user ที่ Reputation = 1 จำนวนมากทีหลัง

**ตรวจว่า statistics เก่าแค่ไหน**: [`sql/02-check-stats-age.sql`](sql/02-check-stats-age.sql)

- `rows` = จำนวนแถวตอนสร้าง statistics, `modification_counter` = จำนวนแถวที่เปลี่ยนหลังจากนั้น
- modification_counter สูงเทียบกับ rows = statistics เก่ามาก

**Query ก่อนและหลังอัปเดต statistics**: [`sql/03-before-after-update-stats.sql`](sql/03-before-after-update-stats.sql)

ผลที่ควรเห็น:

| | ก่อนอัปเดต | หลังอัปเดต |
|---|---|---|
| Estimated rows | ต่ำมาก (histogram ไม่มีค่า 1) | ใกล้ Actual |
| GrantedMemory | เล็ก | พอกับข้อมูล |
| Sort | มีคำเตือน spill | ไม่มีคำเตือน |
| เวลา | นานกว่า | เร็วกว่า |

- หลัง UPDATE STATISTICS แผนเดิมถูก recompile อัตโนมัติตอนรันครั้งถัดไป
- ในงานจริงไม่ต้องปิด auto update ก็เจอได้ เช่น ตารางที่เพิ่งโหลดข้อมูลแต่ยังไม่ถึงเกณฑ์ auto update หรือการค้นข้อมูลใหม่ล่าสุดที่ยังไม่อยู่ใน histogram (ascending key)

### 5. ทำไม ORDER BY บนข้อมูลใหญ่ถึงเสี่ยง

- Sort ต้องเก็บทุกแถว memory ที่ต้องการโตตามจำนวนแถว
- ทุกคอลัมน์ใน SELECT ถูกเก็บไปด้วย ไม่ใช่แค่คอลัมน์ที่ใช้เรียง (SELECT * และคอลัมน์ข้อความยาวทำให้แถวใหญ่)
- ทุกอย่างพึ่งค่าประมาณ ประมาณพลาดก็จองพลาด

ทางลดความเสี่ยง (ลำดับการแก้เต็มอยู่ใน EP6):

- ต้องการแค่ไม่กี่แถวแรก ใส่ TOP → plan ใช้ **Top N Sort** เก็บแค่ N แถว ใช้ memory น้อยมาก
- มี index ที่เรียงตามลำดับที่ต้องการแล้ว → Sort หายจาก plan
.- เลือกเฉพาะคอลัมน์ที่ใช้จริง

ตัวอย่าง: [`sql/04-top-n-sort.sql`](sql/04-top-n-sort.sql)

### 6. ข้อควรระวังตอนทดลอง

- อยากทดลองซ้ำต้องรัน setup ใหม่ทั้งหมด เพราะ statistics ถูกอัปเดตไปแล้ว ([`sql/05-cleanup.sql`](sql/05-cleanup.sql))
- compatibility level 150 ขึ้นไป: memory grant feedback อาจปรับ grant เองเมื่อรันซ้ำ ให้ดูผลรอบแรก
- ค่าประมาณของค่าที่ไม่อยู่ใน histogram ขึ้นกับรุ่น cardinality estimator อาจได้ 1 แถวหรือค่าเฉลี่ยจาก density แต่ทั้งสองแบบต่ำกว่าจริงมาก
- ถ้า plan เป็น parallel แล้วดูยาก ใส่ `OPTION (MAXDOP 1)` ตอนทดลอง

## สรุปตอนท้าย

- Sort เป็น blocking operator ต้องเก็บทุกแถวก่อนส่งแถวแรก memory ที่ต้องการโตตามข้อมูล
- memory ไม่พอ → เรียงทีละกอง เขียนลง tempdb แล้ว merge กลับ ผลถูกเหมือนเดิมแต่มีงานดิสก์เพิ่ม
- คำเตือนบอก spill level, หน้าที่เขียน/อ่าน และ memory ใช้ตัวเลขเหล่านี้ตัดสินว่าคุ้มแก้ไหม
- statistics เก่าเป็นต้นเหตุ Sort spill ที่เจอบ่อย ตรวจด้วย `sys.dm_db_stats_properties` และบางครั้งแก้ได้ด้วย UPDATE STATISTICS
- TOP, index ที่เรียงไว้แล้ว และการเลือกคอลัมน์เท่าที่ใช้ ลดความเสี่ยง Sort spill ได้

**ตอนถัดไป:** EP3 – Hash spill
