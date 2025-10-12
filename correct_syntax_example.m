% 正确的语法示例

% 错误方式（导致只有1个措施）：
% 'maintenance_measures', {
%     create_measure(1, '步骤1', '10分钟', '工具1');
%     create_measure(2, '步骤2', '20分钟', '工具2');
%     create_measure(3, '步骤3', '30分钟', '工具3')
% }

% 正确方式（使用方括号创建结构体数组）：
% 'maintenance_measures', [
%     create_measure(1, '步骤1', '10分钟', '工具1')
%     create_measure(2, '步骤2', '20分钟', '工具2')
%     create_measure(3, '步骤3', '30分钟', '工具3')
% ]

% 注意：
% 1. 使用方括号 [] 而不是花括号 {}
% 2. 每行末尾不需要分号（除了最后一行）
% 3. MATLAB会自动将这些结构体组合成数组