#!/usr/bin/env python3
"""
修复MATLAB维修数据库中的措施数组问题
"""

import re

# 读取原文件
with open('/workspace/O2_Diagnosis_System_Final.m', 'r', encoding='utf-8') as f:
    content = f.read()

# 查找所有需要修复的模式
pattern = r"(db\.code_[^=]+= struct\([^)]+)'maintenance_measures', \{([^}]+)\}\);"

def fix_measures(match):
    """修复单个故障代码的措施定义"""
    prefix = match.group(1)
    measures_content = match.group(2)
    
    # 提取代码名称
    code_match = re.search(r'db\.(code_[^=]+)', prefix)
    if not code_match:
        return match.group(0)  # 返回原文本
    
    code_var = code_match.group(1)
    measures_var = f"measures_{code_var[5:]}"  # 去掉'code_'前缀
    
    # 解析措施
    measure_lines = []
    measures = re.findall(r"create_measure\([^)]+\)", measures_content)
    
    # 构建新的代码
    new_code = f"    % 创建措施数组\n    {measures_var} = [];\n"
    for i, measure in enumerate(measures, 1):
        new_code += f"    {measures_var}({i}) = {measure};\n"
    
    # 重构struct定义
    new_code += f"\n    {prefix}'maintenance_measures', {measures_var});"
    
    return new_code

# 执行替换
new_content = re.sub(pattern, fix_measures, content, flags=re.DOTALL)

# 写入新文件
with open('/workspace/O2_Diagnosis_System_Fixed_All.m', 'w', encoding='utf-8') as f:
    f.write(new_content)

print("修复完成！")
print("新文件已保存为: O2_Diagnosis_System_Fixed_All.m")