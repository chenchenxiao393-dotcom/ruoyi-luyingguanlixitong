import pymysql
import os

# 数据库配置
db_config = {
    'host': 'localhost',
    'port': 3306,
    'user': 'root',
    'password': '795876',
    'database': 'ry-vue',
    'charset': 'utf8mb4'
}

# 读取 SQL 文件
sql_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'sql', 'refund_table.sql')
with open(sql_file, 'r', encoding='utf-8') as f:
    sql_content = f.read()

# 按分号分割 SQL 语句
statements = []
current_stmt = ''
for line in sql_content.split('\n'):
    # 跳过注释行
    stripped = line.strip()
    if stripped.startswith('--') or stripped.startswith('/*') or stripped == '':
        continue
    current_stmt += line + '\n'
    if stripped.endswith(';'):
        statements.append(current_stmt)
        current_stmt = ''

# 连接数据库并执行
conn = pymysql.connect(**db_config)
cursor = conn.cursor()

try:
    for stmt in statements:
        stmt = stmt.strip()
        if stmt:
            try:
                cursor.execute(stmt)
                print(f"✅ 执行成功: {stmt[:80]}...")
            except Exception as e:
                if 'Duplicate' in str(e) or 'already exists' in str(e):
                    print(f"⏭️ 已存在: {stmt[:80]}...")
                else:
                    print(f"❌ 执行失败: {str(e)[:100]}")
                    print(f"   SQL: {stmt[:100]}...")
    conn.commit()
    print("\n🎉 SQL 脚本执行完成！")
    
    # 验证菜单是否已添加
    cursor.execute("SELECT menu_id, menu_name, parent_id FROM sys_menu WHERE menu_id IN (2050, 2051, 2052) OR menu_name LIKE '%退款%'")
    results = cursor.fetchall()
    print("\n📋 退款菜单检查结果:")
    for row in results:
        print(f"   menu_id={row[0]}, menu_name={row[1]}, parent_id={row[2]}")
    
    if not results:
        print("   ⚠️ 未找到退款相关菜单，可能需要手动检查")
    
except Exception as e:
    print(f"❌ 错误: {e}")
    conn.rollback()
finally:
    cursor.close()
    conn.close()
