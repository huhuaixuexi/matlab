%% 完整测试故障分析系统
% 测试生成和分析功能

clc;
clear all;
close all;

fprintf('========================================\n');
fprintf('故障诊断维修记录系统 - 完整测试\n');
fprintf('========================================\n\n');

% 步骤1：生成故障记录
fprintf('步骤1：生成故障记录数据...\n');
try
    generate_fault_records_only();
    fprintf('✓ 故障记录生成成功！\n\n');
catch ME
    fprintf('✗ 故障记录生成失败！\n');
    fprintf('错误: %s\n', ME.message);
    return;
end

% 获取生成的文件
excel_files = dir('故障诊断维修记录_*.xlsx');
if isempty(excel_files)
    fprintf('错误：未找到生成的Excel文件！\n');
    return;
end

[~, idx] = max([excel_files.datenum]);
excel_file = excel_files(idx).name;
fprintf('生成的文件: %s\n\n', excel_file);

% 步骤2：分析故障记录
fprintf('步骤2：分析故障记录...\n');
fprintf('使用文件: %s\n\n', excel_file);

try
    % 尝试使用v2版本（更兼容）
    analyze_fault_records_v2(excel_file);
    fprintf('\n✓ 故障分析完成！\n');
catch ME
    fprintf('\n✗ 故障分析失败！\n');
    fprintf('错误: %s\n', ME.message);
    
    % 如果v2失败，尝试使用原始版本
    fprintf('\n尝试使用原始版本...\n');
    try
        analyze_fault_records(excel_file);
        fprintf('\n✓ 故障分析完成（使用原始版本）！\n');
    catch ME2
        fprintf('\n✗ 原始版本也失败！\n');
        fprintf('错误: %s\n', ME2.message);
    end
end

% 步骤3：检查生成的文件
fprintf('\n========================================\n');
fprintf('生成的文件列表：\n');
fprintf('========================================\n');

% Excel文件
excel_files = dir('故障诊断维修记录_*.xlsx');
if ~isempty(excel_files)
    fprintf('\nExcel数据文件:\n');
    for i = 1:length(excel_files)
        fprintf('  - %s (%.1f KB, %s)\n', ...
            excel_files(i).name, ...
            excel_files(i).bytes/1024, ...
            datestr(excel_files(i).datenum));
    end
end

% 文字报告
txt_files = dir('故障分析总结报告_*.txt');
if ~isempty(txt_files)
    fprintf('\n文字分析报告:\n');
    for i = 1:length(txt_files)
        fprintf('  - %s (%.1f KB, %s)\n', ...
            txt_files(i).name, ...
            txt_files(i).bytes/1024, ...
            datestr(txt_files(i).datenum));
    end
end

fprintf('\n========================================\n');
fprintf('测试完成！\n');
fprintf('========================================\n');

% 显示最新的文字报告内容（前20行）
if ~isempty(txt_files)
    [~, idx] = max([txt_files.datenum]);
    latest_report = txt_files(idx).name;
    
    fprintf('\n最新报告内容预览 (%s):\n', latest_report);
    fprintf('----------------------------------------\n');
    
    fid = fopen(latest_report, 'r', 'n', 'UTF-8');
    if fid > 0
        for i = 1:20
            line = fgetl(fid);
            if ~ischar(line)
                break;
            end
            fprintf('%s\n', line);
        end
        fclose(fid);
        fprintf('... (更多内容请查看完整报告)\n');
    end
end