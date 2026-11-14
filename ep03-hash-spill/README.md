# EP3 – Hash spill (+ exchange spill สั้นๆ)

ความยาว 14 นาที · Database: StackOverflow2013 (ตาราง Users, Badges) · พื้นฐานที่ควรมี: [EP1](../ep01-memory-grant/)–[EP2](../ep02-sort-spill/), join operators (Nested Loops, Hash, Merge)

## EP นี้ผู้เรียนได้อะไร

- เข้าใจว่า Hash Match ทำงานยังไง ทั้งแบบ join และ aggregate
- รู้ว่าตอน memory ไม่พอ Hash แบ่งข้อมูลเป็น partition แล้ว spill ยังไง
- รู้จัก hash recursion และ hash bailout ซึ่งเป็นกรณีที่แย่ที่สุด
- อธิบายได้ว่าทำไม hash spill มักแพงกว่า sort spill
- สร้างและอ่าน hash spill ทั้งแบบ join และ GROUP BY ได้

## EP นี้แก้ปัญหาอะไร

| ปัญหาที่เจอ | EP นี้ช่วยยังไง |
|---|---|
| JOIN ตารางใหญ่ช้าผิดปกติ | หาว่าฝั่ง build ของ Hash Join ถูกประมาณต่ำจน spill |
| GROUP BY ช้าเมื่อจำนวนกลุ่มเยอะ | อธิบาย Hash Aggregate spill จากจำนวนกลุ่มที่ประมาณต่ำ |
| query ค้างนานจนเหมือนไม่จบ | รู้จัก hash recursion และ hash bailout ซึ่งเป็นกรณีที่แย่ที่สุด |
| มีทั้ง Sort spill และ Hash spill ไม่รู้จะแก้ตัวไหนก่อน | เข้าใจว่าทำไม hash spill มักแพงกว่า จึงควรดูก่อน |

## เนื้อหาพร้อมตัวอย่าง

### 1. Hash Match ทำงานยังไง

**Hash Join** มีสองขั้น

1. **Build**: อ่าน input ฝั่งบนใน plan (ปกติเป็นฝั่งที่ประมาณว่าเล็กกว่า) มาสร้าง hash table ใน memory
2. **Probe**: อ่าน input ฝั่งล่างทีละแถว แล้วหาคู่ใน hash table

**Hash Aggregate** สร้าง hash table ที่มีหนึ่งแถวต่อกลุ่ม อ่านแถวเข้ามาแล้วสะสมค่า (COUNT, SUM) ใส่กลุ่มที่ตรงกัน

| แบบ | memory ขึ้นกับอะไร | ประมาณพลาดตรงไหนแล้ว spill |
|---|---|---|
| Hash Join | จำนวนแถว × ขนาดแถวของฝั่ง build | ฝั่ง build ใหญ่กว่าที่ประมาณ |
| Hash Aggregate | จำนวนกลุ่ม × ขนาดแถวของกลุ่ม | จำนวนกลุ่มมากกว่าที่ประมาณ |

ข้อสังเกต: Hash Join ไม่เก็บฝั่ง probe ไว้ใน memory เลย ตัวกำหนด grant คือฝั่ง build ถ้าฝั่งที่คิดว่าเล็กจริงๆ ใหญ่ ก็จะ spill

### 2. Hash เมื่อ memory ไม่พอ: partition และ spill

อธิบายแบบภาพง่าย:

1. แบ่งแถวฝั่ง build เป็นหลาย partition ตามค่า hash
2. partition ที่ใส่ memory ไม่พอถูกเขียนลง tempdb
3. ตอน probe แถวฝั่ง probe ที่ตรงกับ partition ที่ spill ไปแล้ว ก็ถูกเขียนลง tempdb ด้วย
4. หลังจบรอบแรก อ่าน partition คู่ที่ spill กลับมาทำ join ทีละคู่

**Hash recursion**: ถ้า partition ที่อ่านกลับมายังใหญ่เกิน memory ต้องแบ่งซ้ำแล้ว spill อีกรอบ แต่ละรอบคือ spill level ที่เพิ่มขึ้น

**Hash bailout**: ถ้าแบ่งซ้ำหลายรอบจนถึงขีดจำกัดแล้วยังไม่พอ SQL Server จะเลิกแบ่ง แล้วเปลี่ยนไปใช้วิธีที่ช้ามากแต่รับประกันว่าจบได้ มักเกิดกับข้อมูลที่มีค่าซ้ำกันมากๆ จนแบ่งเท่าไหร่ก็ตกอยู่ partition เดียวกันอาจจะเกิด bailout ต้องระวัง

### 3. ทำไม hash spill มักแพงกว่า sort spill

| | Sort spill | Hash spill |
|---|---|---|
| ข้อมูลที่ถูกเขียนลง tempdb | input เดียว | ทั้งฝั่ง build และบางส่วนของฝั่ง probe |
| เมื่อแย่ลง | merge หลายชั้น | แบ่ง partition ซ้ำ (recursion) จนถึง bailout |
| ค่าซ้ำมากๆ | ไม่ค่อยกระทบ | ทำให้ partition ไม่สมดุล เสี่ยง bailout |

### 4. อ่านคำเตือน hash spill

ข้อความเตือนที่ Hash Match หน้าตาคล้าย Sort:

*Operator used tempdb to spill data during execution with spill level 2 and 12 spilled thread(s), Hash wrote X pages to and read Y pages from tempdb with granted memory A KB and used memory B KB*

- spill level ของ Hash คือจำนวนรอบที่แบ่ง partition ซ้ำ level สูง = recursion เยอะ
- อ่านคู่กับฝั่ง build: เทียบ Estimated กับ Actual Number of Rows ของ input ฝั่งบน จะเห็นต้นเหตุ
- ใน STATISTICS IO อาจเห็นบรรทัด Workfile หรือ Worktable ที่มี reads มากกว่า 0 แต่ไม่ควรพึ่งตัวเลขนี้อย่างเดียว ให้ดู plan เป็นหลัก

### 5. ตัวอย่าง: Hash Join spill จากฝั่ง build ที่ประมาณต่ำ

ไฟล์: [`sql/01-hash-join-spill.sql`](sql/01-hash-join-spill.sql)

ใช้เทคนิคตัวแปร local จาก EP1: ตัวแปรทำให้ประมาณ user ที่ Reputation = 1 ต่ำกว่าจริงมาก ฝั่ง Users จึงถูกเลือกเป็น build ด้วย grant เล็ก

ผลที่ควรเห็น:

- ทั้งสอง query ได้ Hash Match (Inner Join) โดย Users อยู่ฝั่งบน (build)
- query ที่สอง: Estimated rows ของ Users ต่ำกว่า Actual หลายเท่า Hash Match มีคำเตือน spill และอาจมี spill level มากกว่า 1
- ถ้า optimizer เลือก join แบบอื่น ให้ใส่ `OPTION (HASH JOIN)` ท้าย query เพื่อสาธิต

### 6. ตัวอย่าง: Hash Aggregate spill จากจำนวนกลุ่มที่ประมาณต่ำ

ไฟล์: [`sql/02-hash-aggregate-spill.sql`](sql/02-hash-aggregate-spill.sql)

- ค่าประมาณจำนวนแถวที่เข้า aggregate ต่ำลง จำนวนกลุ่มที่ประมาณก็ต่ำตาม
- ดูที่ Hash Match (Aggregate) เทียบ Estimated กับ Actual Number of Rows ของ output (= จำนวนกลุ่ม)
- ผลต่างของค่าประมาณในตัวอย่างนี้อาจน้อยกว่าตัวอย่าง join ถ้าเครื่องมี memory มากจนไม่ spill ให้เพิ่มคอลัมน์เข้า GROUP BY (เช่น b.Name) หรือใช้ `MAX_GRANT_PERCENT` ช่วยจำลอง

## สรุปตอนท้าย

- Hash Join ใช้ memory ตามฝั่ง build, Hash Aggregate ใช้ memory ตามจำนวนกลุ่ม ประมาณสองอย่างนี้ต่ำไป = spill
- memory ไม่พอ → แบ่ง partition, spill ทั้ง build และ probe บางส่วน แล้วกลับมาทำทีละคู่
- partition ยังใหญ่ → hash recursion (spill level สูงขึ้น) → ถึงขีดจำกัด → hash bailout ซึ่งช้าที่สุด
- hash spill มักแพงกว่า sort spill เพราะเขียนหลาย input และแบ่งซ้ำได้หลายรอบ
- เจอ hash spill ให้ดู Estimated vs Actual ของฝั่ง build หรือจำนวนกลุ่มก่อนเสมอ


**ตอนถัดไป:** EP4 – ขนาดคอลัมน์และ data type ทำให้ grant เพี้ยน
