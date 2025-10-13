%% 运行故障分析系统
% 这个脚本用于运行故障记录生成和分析系统

clear all;
close all;
clc;

fprintf('准备运行故障分析系统...\n\n');

% 检查MATLAB版本
v = version;
fprintf('当前MATLAB版本: %s\n', v);

% 检查是否有Statistics Toolbox
has_stats_toolbox = license('test', 'Statistics_Toolbox');
if has_stats_toolbox
    fprintf('检测到Statistics and Machine Learning Toolbox\n');
else
    fprintf('未检测到Statistics and Machine Learning Toolbox\n');
    fprintf('将使用基础绘图功能替代高级统计图表\n');
end

fprintf('\n按任意键继续...\n');
pause;

try
    % 运行主程序
    fprintf('\n开始执行分析...\n');
    generate_fault_records_with_analysis();
    
    fprintf('\n\n========================================\n');
    fprintf('程序执行成功！\n');
    fprintf('========================================\n');
    
    % 列出生成的文件
    fprintf('\n生成的文件:\n');
    excel_files = dir('故障诊断维修记录_*.xlsx');
    png_files = dir('故障分析报告_*.png');
    txt_files = dir('故障分析总结报告_*.txt');
    
    if ~isempty(excel_files)
        fprintf('- Excel文件: %s\n', excel_files(end).name);
    end
    if ~isempty(png_files)
        fprintf('- 图表报告: %s\n', png_files(end).name);
    end
    if ~isempty(txt_files)
        fprintf('- 文字报告: %s\n', txt_files(end).name);
    end
    
catch ME
    fprintf('\n\n========================================\n');
    fprintf('程序执行失败！\n');
    fprintf('========================================\n');
    fprintf('错误信息: %s\n', ME.message);
    fprintf('错误标识: %s\n', ME.identifier);
    
    if ~isempty(ME.stack)
        fprintf('\n错误位置:\n');
        for i = 1:min(3, length(ME.stack))
            fprintf('  文件: %s\n', ME.stack(i).file);
            fprintf('  函数: %s (第 %d 行)\n', ME.stack(i).name, ME.stack(i).line);
        end
    end
    
    fprintf('\n建议:\n');
    if contains(ME.message, 'boxplot')
        fprintf('- boxplot函数需要Statistics Toolbox，已使用条形图替代\n');
    end
    if contains(ME.message, 'datetime')
        fprintf('- 请确保使用MATLAB R2014b或更高版本\n');
    end
    if contains(ME.message, 'writetable')
        fprintf('- 请确保有写入文件的权限\n');
    end
end

fprintf('\n分析完成。\n');