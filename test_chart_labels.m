%% 测试图表标签修复效果
% 此脚本用于验证analyze_fault_records_v2.m中的图表标签是否正确显示

function test_chart_labels()
    fprintf('\n========================================\n');
    fprintf('测试图表标签修复效果\n');
    fprintf('========================================\n\n');
    
    % 检查是否有故障记录文件
    excel_files = dir('故障诊断维修记录_*.xlsx');
    if isempty(excel_files)
        fprintf('未找到故障记录文件，正在生成...\n');
        run('generate_fault_records_only.m');
        excel_files = dir('故障诊断维修记录_*.xlsx');
    end
    
    % 获取最新的文件
    [~, idx] = max([excel_files.datenum]);
    excel_file = excel_files(idx).name;
    
    fprintf('使用文件: %s\n', excel_file);
    fprintf('开始运行分析...\n\n');
    
    % 运行分析
    analyze_fault_records_v2(excel_file);
    
    fprintf('\n========================================\n');
    fprintf('测试完成！\n');
    fprintf('请检查生成的3个图形窗口：\n');
    fprintf('1. 每个图表是否都有清晰的标题\n');
    fprintf('2. 条形图和折线图是否都有横坐标和纵坐标标签\n');
    fprintf('3. 坐标轴标签是否包含单位信息\n');
    fprintf('4. 字体是否清晰可读\n');
    fprintf('========================================\n');
end