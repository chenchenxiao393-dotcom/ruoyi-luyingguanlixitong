@echo off
chcp 65001 >nul
cd /d "e:\VS code项目\RuoYi-Vue-master"
echo 正在启动后端服务...
echo 日志将输出到 backend.log
java -jar ruoyi-admin/target/ruoyi-admin.jar > backend.log 2>&1
pause
