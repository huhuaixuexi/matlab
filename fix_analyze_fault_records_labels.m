% 批量修复 analyze_fault_records.m 中的图表标签

% 读取文件
content = fileread('analyze_fault_records.m');

% 定义替换规则
replacements = {
    % 第1页
    {'title\(''故障类型分布''', 'title(''故障类型分布饼图'''}
    {'title\(''月度故障趋势''', 'title(''月度故障趋势图'''}
    {'xlabel\(''时间''\);', 'xlabel(''时间（年-月）'', ''FontSize'', 12, ''FontWeight'', ''bold'');'}
    {'ylabel\(''故障数量''\);', 'ylabel(''故障数量（次）'', ''FontSize'', 12, ''FontWeight'', ''bold'');'}
    
    {'title\(''故障严重程度分布''', 'title(''故障严重程度分布条形图'''}
    {'xlabel\(''严重程度''\);', 'xlabel(''严重程度等级'', ''FontSize'', 12, ''FontWeight'', ''bold'');'}
    {'ylabel\(''数量''\);', 'ylabel(''故障数量（次）'', ''FontSize'', 12, ''FontWeight'', ''bold'');'}
    
    {'title\(''TOP 10 故障代码''', 'title(''TOP 10 故障代码横向条形图'''}
    {'xlabel\(''发生次数''\);', 'xlabel(''故障发生次数'', ''FontSize'', 12, ''FontWeight'', ''bold'');'}
    
    {'title\(''数据故障类型分布''', 'title(''数据故障类型分布饼图'''}
    
    {'title\(''年度故障统计''', 'title(''年度故障统计条形图'''}
    {'xlabel\(''年份''\);', 'xlabel(''年份'', ''FontSize'', 12, ''FontWeight'', ''bold'');'}
    
    % 第2页
    {'title\(''各故障类型平均维修时间''', 'title(''各故障类型平均维修时间条形图'''}
    {'xlabel\(''故障类型''\);', 'xlabel(''故障类型'', ''FontSize'', 12, ''FontWeight'', ''bold'');'}
    {'ylabel\(''时间\(分钟\)''\);', 'ylabel(''维修时间（分钟）'', ''FontSize'', 12, ''FontWeight'', ''bold'');'}
    
    {'title\(''TOP 10 常用工具''', 'title(''TOP 10 常用工具横向条形图'''}
    {'xlabel\(''使用次数''\);', 'xlabel(''使用次数'', ''FontSize'', 12, ''FontWeight'', ''bold'');'}
    
    {'title\(''季度故障分布''', 'title(''季度故障分布条形图'''}
    {'xlabel\(''季度''\);', 'xlabel(''季度'', ''FontSize'', 12, ''FontWeight'', ''bold'');'}
    
    {'title\(''故障优先级分布''', 'title(''故障优先级分布饼图'''}
    
    {'title\(''工作日vs周末故障分布''', 'title(''工作日vs周末故障分布饼图'''}
    
    {'title\(''故障发生时间分布热力图''', 'title(''故障发生时间分布热力图'''}
    {'xlabel\(''小时''\);', 'xlabel(''小时（0-23点）'', ''FontSize'', 12, ''FontWeight'', ''bold'');'}
    {'ylabel\(''星期''\);', 'ylabel(''星期'', ''FontSize'', 12, ''FontWeight'', ''bold'');'}
    
    % 第3页
    {'title\(''严重程度与平均维修时间''', 'title(''严重程度与平均维修时间条形图'''}
    {'ylabel\(''平均时间\(分钟\)''\);', 'ylabel(''平均维修时间（分钟）'', ''FontSize'', 12, ''FontWeight'', ''bold'');'}
    
    {'title\(''最复杂故障TOP5\(按维修时间\)''', 'title(''最复杂故障TOP5横向条形图'''}
    {'xlabel\(''平均维修时间\(分钟\)''\);', 'xlabel(''平均维修时间（分钟）'', ''FontSize'', 12, ''FontWeight'', ''bold'');'}
    
    {'title\(''故障趋势与预测''', 'title(''故障趋势与预测折线图'''}
    
    {'title\(''备件更换统计''', 'title(''备件更换统计条形图'''}
    {'xlabel\(''备件类型''\);', 'xlabel(''备件类型'', ''FontSize'', 12, ''FontWeight'', ''bold'');'}
    {'ylabel\(''更换次数''\);', 'ylabel(''更换次数'', ''FontSize'', 12, ''FontWeight'', ''bold'');'}
    
    {'title\(''TOP 10 最快维修操作''', 'title(''TOP 10 最快维修操作横向条形图'''}
    {'xlabel\(''平均时间\(分钟\)''\);', 'xlabel(''平均维修时间（分钟）'', ''FontSize'', 12, ''FontWeight'', ''bold'');'}
};

% 执行替换
for i = 1:length(replacements)
    old_pattern = replacements{i}{1};
    new_pattern = replacements{i}{2};
    content = strrep(content, old_pattern, new_pattern);
end

% 添加 grid on 到需要的地方
grid_patterns = {
    'xtickangle(45);' % 在角度设置后添加grid
    'ylabel(''故障代码'', ''FontSize'', 12, ''FontWeight'', ''bold'');' % 在某些ylabel后添加
};

for i = 1:length(grid_patterns)
    pattern = grid_patterns{i};
    if contains(content, pattern) && ~contains(content, [pattern newline '    grid on;'])
        content = strrep(content, pattern, [pattern newline '    grid on;']);
    end
end

% 写回文件
fid = fopen('analyze_fault_records_fixed.m', 'w');
fwrite(fid, content);
fclose(fid);

% 覆盖原文件
movefile('analyze_fault_records_fixed.m', 'analyze_fault_records.m', 'f');

fprintf('analyze_fault_records.m 文件的图表标签已全部修复！\n');