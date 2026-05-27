@echo off
mysql -u root -p795876 --default-character-set=utf8mb4 ry-vue < "C:\Users\chen\Desktop\RuoYi-Vue-master\RuoYi-Vue-master\sql\ry_20260417.sql"
mysql -u root -p795876 --default-character-set=utf8mb4 ry-vue < "C:\Users\chen\Desktop\RuoYi-Vue-master\RuoYi-Vue-master\sql\quartz.sql"
echo Done.
