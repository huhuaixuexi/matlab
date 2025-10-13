function update_all_charts()
    % 读取原文件
    content = fileread('analyze_fault_records_v2.m');
    
    % 定义所有需要替换的模式
    replacements = {
        % 第2页剩余部分
        {'title\(''工作日vs周末故障分布''', 'title(''工作日vs周末故障分布饼图'''}
        {'title\(''故障发生时间分布热力图''', 'title(''故障发生时间分布热力图'''}
        {'xlabel\(''小时''\)', 'xlabel(''小时（0-23点）'', ''FontSize'', 12, ''FontWeight'', ''bold'')'}
        {'ylabel\(''星期''\)', 'ylabel(''星期'', ''FontSize'', 12, ''FontWeight'', ''bold'')'}
        
        % 第3页
        {'title\(''严重程度与平均维修时间''', 'title(''严重程度与平均维修时间条形图'''}
        {'xlabel\(''严重程度''\)', 'xlabel(''严重程度'', ''FontSize'', 12, ''FontWeight'', ''bold'')'}
        {'ylabel\(''平均时间\(分钟\)''\)', 'ylabel(''平均维修时间（分钟）'', ''FontSize'', 12, ''FontWeight'', ''bold'')'}
        
        {'title\(''最复杂故障TOP5\(按维修时间\)''', 'title(''最复杂故障TOP5横向条形图'''}
        {'xlabel\(''平均维修时间\(分钟\)''\)', 'xlabel(''平均维修时间（分钟）'', ''FontSize'', 12, ''FontWeight'', ''bold'')'}
        
        {'title\(''故障趋势与预测''', 'title(''故障趋势与预测折线图'''}
        {'xlabel\(''时间''\)', 'xlabel(''时间（年-月）'', ''FontSize'', 12, ''FontWeight'', ''bold'')'}
        {'ylabel\(''故障数量''\)', 'ylabel(''故障数量（次）'', ''FontSize'', 12, ''FontWeight'', ''bold'')'}
        
        {'title\(''备件更换统计''', 'title(''备件更换统计条形图'''}
        {'xlabel\(''备件类型''\)', 'xlabel(''备件类型'', ''FontSize'', 12, ''FontWeight'', ''bold'')'}
        {'ylabel\(''更换次数''\)', 'ylabel(''更换次数'', ''FontSize'', 12, ''FontWeight'', ''bold'')'}
        
        {'title\(''TOP 10 最快维修操作''', 'title(''TOP 10 最快维修操作横向条形图'''}
        {'xlabel\(''平均时间\(分钟\)''\)', 'xlabel(''平均维修时间（分钟）'', ''FontSize'', 12, ''FontWeight'', ''bold'')'}
    };
    
    % 执行替换
    for i = 1:length(replacements)
        content = strrep(content, replacements{i}{1}, replacements{i}{2});
    end
    
    % 写回文件
    fid = fopen('analyze_fault_records_v2_updated.m', 'w');
    fwrite(fid, content);
    fclose(fid);
    
    fprintf('更新完成！新文件: analyze_fault_records_v2_updated.m\n');
end