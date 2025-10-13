%% 故障诊断维修记录系统 - 主运行脚本
% 这个脚本提供了使用故障记录系统的简单界面

function run_fault_system()
    clc;
    fprintf('========================================\n');
    fprintf('故障诊断维修记录系统\n');
    fprintf('========================================\n\n');
    
    fprintf('请选择操作:\n');
    fprintf('1. 生成新的故障记录数据库\n');
    fprintf('2. 分析现有故障记录\n');
    fprintf('3. 完整流程(生成+分析)\n');
    fprintf('0. 退出\n\n');
    
    choice = input('请输入选择(0-3): ');
    
    switch choice
        case 1
            % 生成故障记录
            fprintf('\n正在生成故障记录...\n');
            generate_fault_records_only();
            fprintf('\n生成完成！\n');
            
        case 2
            % 分析故障记录
            excel_files = dir('故障诊断维修记录_*.xlsx');
            if isempty(excel_files)
                fprintf('\n错误: 未找到故障记录文件！\n');
                fprintf('请先选择选项1生成故障记录。\n');
                return;
            end
            
            if length(excel_files) == 1
                excel_file = excel_files(1).name;
                fprintf('\n找到文件: %s\n', excel_file);
            else
                fprintf('\n找到多个故障记录文件:\n');
                for i = 1:length(excel_files)
                    fprintf('%d. %s\n', i, excel_files(i).name);
                end
                
                file_choice = input('\n请选择要分析的文件编号: ');
                if file_choice < 1 || file_choice > length(excel_files)
                    fprintf('无效的选择！\n');
                    return;
                end
                excel_file = excel_files(file_choice).name;
            end
            
            fprintf('\n正在分析: %s\n', excel_file);
            analyze_fault_records(excel_file);
            
        case 3
            % 完整流程
            fprintf('\n执行完整流程...\n');
            
            % 生成记录
            fprintf('\n步骤1: 生成故障记录\n');
            generate_fault_records_only();
            
            % 获取刚生成的文件
            excel_files = dir('故障诊断维修记录_*.xlsx');
            [~, idx] = max([excel_files.datenum]);
            excel_file = excel_files(idx).name;
            
            % 分析记录
            fprintf('\n步骤2: 分析故障记录\n');
            analyze_fault_records(excel_file);
            
            fprintf('\n完整流程执行完成！\n');
            
        case 0
            fprintf('\n退出系统。\n');
            return;
            
        otherwise
            fprintf('\n无效的选择！\n');
    end
    
    fprintf('\n========================================\n');
    fprintf('操作完成！\n');
    
    % 显示生成的文件
    fprintf('\n生成的文件列表:\n');
    
    % Excel文件
    excel_files = dir('故障诊断维修记录_*.xlsx');
    if ~isempty(excel_files)
        fprintf('\nExcel数据文件:\n');
        for i = 1:length(excel_files)
            fprintf('  - %s (%.1f KB)\n', excel_files(i).name, excel_files(i).bytes/1024);
        end
    end
    
    % 文字报告
    txt_files = dir('故障分析总结报告_*.txt');
    if ~isempty(txt_files)
        fprintf('\n文字分析报告:\n');
        for i = 1:length(txt_files)
            fprintf('  - %s (%.1f KB)\n', txt_files(i).name, txt_files(i).bytes/1024);
        end
    end
    
    fprintf('\n========================================\n');
end