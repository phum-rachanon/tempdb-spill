# tempdb spill สำหรับ Developer: ทำไม query ช้าทั้งที่ index ดีแล้ว (DevHops)

เนื้อหาและ SQL ประกอบคลิป YouTube series **tempdb spill** ของ DevHops
เจาะเรื่อง tempdb, memory grant และ spill ใน SQL Server ในมุมของ developer: อ่าน plan, เขียน query และแก้ที่ code ของตัวเอง ตั้งแต่พื้นฐานจนไล่เคสจริง

เนื้อหาไม่ครอบคลุมงานดูแล server (การตั้งค่าไฟล์ tempdb, max server memory, Resource Governor, Extended Events ระดับ server) ส่วนนั้นให้ DBA ดูแล ใน series จะบอกว่าเมื่อไหร่ควรส่งต่อและควรแนบข้อมูลอะไร

- Database: **StackOverflow2013**
- ระดับ: กลาง–สูง ควรอ่าน execution plan และเข้าใจ statistics มาก่อน
- แต่ละ EP มีโฟลเดอร์ของตัวเอง ประกอบด้วย `README.md` (เนื้อหา) และโฟลเดอร์ `sql/` (สคริปต์ที่ใช้ในตอน)

## รายชื่อตอน

| EP | หัวข้อ | สถานะ |
|---|---|---|
| [EP0](ep00-tempdb-and-spill/) | tempdb คืออะไร และ spill เกิดจากอะไร | ✅ |
| [EP1](ep01-memory-grant/) | Memory grant: SQL Server จอง memory ยังไง | ✅ |
| [EP2](ep02-sort-spill/) | Sort spill | ✅ |
| [EP3](ep03-hash-spill/) | Hash spill (+ exchange spill สั้นๆ) | ✅ |
| [EP4](ep04-column-size-and-grant/) | ขนาดคอลัมน์และ data type ทำให้ grant เพี้ยน | ✅ |
| EP5 | หา query ของเราที่ spill | 🔜 |
| EP6 | ลำดับการแก้ spill | 🔜 |
| EP7 | ทำไมรันซ้ำแล้วไม่ spill (memory grant feedback) | 🔜 |
| EP8 | จองเกินก็เป็นปัญหา และเมื่อ 50 คนเรียกพร้อมกัน | 🔜 |
| EP9 | Capstone: ไล่เคส spill ตั้งแต่ต้นจนจบ | 🔜 |

## วิธีใช้

1. ดาวน์โหลดและ restore database StackOverflow2013 บนเครื่อง lab (ห้ามรันบน production) — แนะนำวิธีโหลดผ่าน BitTorrent จาก [Brent Ozar: How to Download the Stack Overflow Database via BitTorrent](https://www.brentozar.com/archive/2015/10/how-to-download-the-stack-overflow-database-via-bittorrent/)
2. เปิดโฟลเดอร์ของ EP ที่ต้องการ อ่าน `README.md`
3. รันไฟล์ใน `sql/` ตามลำดับเลขหน้าไฟล์ ใน SSMS

## ข้อควรระวัง

- สคริปต์บางตัวจงใจทำให้เกิด spill หรือแย่ง memory ใช้บนเครื่อง lab เท่านั้น
- ผลตัวเลขขึ้นกับ memory, compatibility level และรุ่น SQL Server ของแต่ละเครื่อง
- ถ้า compatibility level 150 ขึ้นไป memory grant feedback อาจทำให้รันรอบสองแล้วไม่ spill ให้ดูผลรอบแรก

## ติดต่อ DevHops

- Facebook: https://www.facebook.com/share/19ruKTdPCk/
- YouTube: https://www.youtube.com/@devhops
- Website: https://godevhops.com/
- TikTok: https://www.tiktok.com/@devhopsss
