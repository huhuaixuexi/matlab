#!/usr/bin/env python3
"""
创建修复后的完整程序
"""

# 读取原始文件
with open('/workspace/O2_Diagnosis_System_Final.m', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 查找并修复maintenance_measures定义
in_measures = False
measures_buffer = []
fixed_lines = []
skip_next = 0

for i, line in enumerate(lines):
    if skip_next > 0:
        skip_next -= 1
        continue
        
    # 检测到maintenance_measures的花括号定义
    if "'maintenance_measures', {" in line:
        # 开始收集measures
        measures_buffer = []
        j = i + 1
        brace_count = 1
        
        while j < len(lines) and brace_count > 0:
            if '{' in lines[j]:
                brace_count += 1
            if '}' in lines[j]:
                brace_count -= 1
                if brace_count == 0:
                    break
            measures_buffer.append(lines[j].strip())
            j += 1
        
        # 构建新的measures定义
        new_measures = "        'maintenance_measures', [\n"
        for measure_line in measures_buffer:
            if 'create_measure' in measure_line:
                # 移除末尾的分号
                measure_line = measure_line.rstrip(';')
                new_measures += "            " + measure_line + "\n"
        new_measures += "        ]);"
        
        # 替换原来的行
        fixed_lines.append(line.replace("'maintenance_measures', {", new_measures))
        skip_next = j - i
        
    else:
        fixed_lines.append(line)

# 写入新文件
with open('/workspace/O2_System_Final_Fixed.m', 'w', encoding='utf-8') as f:
    f.writelines(fixed_lines)

print("修复完成！新文件: O2_System_Final_Fixed.m")