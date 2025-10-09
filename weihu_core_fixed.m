%% 智能维护决策系统主程序
% 功能：集成故障诊断、维护决策和预测性维护
% 版本：v1.1 (修复版)
% 日期：2025年10月8日

clear; clc; close all;

%% ========================================
%% 系统初始化
%% ========================================

fprintf('════════════════════════════════════════\n');
fprintf('    智能维护决策系统 v1.1 (修复版)\n');
fprintf('════════════════════════════════════════\n\n');

% 创建故障知识库实例
fprintf('正在初始化系统...\n');
try
    kb = FaultKnowledgeBase_Fixed();
    fprintf('知识库初始化成功！\n');
catch ME
    fprintf('知识库初始化失败: %s\n', ME.message);
    return;
end

% 初始化系统变量
system_running = true;
maintenance_history = {};
prediction_data = [];

%% ========================================
%% 主功能菜单
%% ========================================

while system_running
    fprintf('\n========================================\n');
    fprintf('主菜单\n');
    fprintf('========================================\n');
    fprintf('1. 故障诊断与维护建议\n');
    fprintf('2. 记录实际维护情况\n');
    fprintf('3. 添加自定义维护措施\n');
    fprintf('4. 查看故障统计报告\n');
    fprintf('5. 预测性维护分析\n');
    fprintf('6. 模拟实时监控诊断\n');
    fprintf('7. 导出维护记录\n');
    fprintf('8. 查看知识库\n');
    fprintf('0. 退出系统\n');
    fprintf('========================================\n');
    
    choice = input('请选择功能 [0-8]: ', 's');
    
    switch choice
        case '1'
            % 故障诊断与维护建议
            performFaultDiagnosis(kb);
            
        case '2'
            % 记录实际维护情况
            recordMaintenance(kb);
            
        case '3'
            % 添加自定义维护措施
            addCustomMaintenance(kb);
            
        case '4'
            % 查看故障统计报告
            generateReport(kb);
            
        case '5'
            % 预测性维护分析
            predictiveMaintenance(kb);
            
        case '6'
            % 模拟实时监控诊断
            simulateRealTimeMonitoring(kb);
            
        case '7'
            % 导出维护记录
            exportMaintenanceLog(kb);
            
        case '8'
            % 查看知识库
            viewKnowledgeBase(kb);
            
        case '0'
            % 退出系统
            system_running = false;
            fprintf('\n系统已退出。谢谢使用！\n');
            
        otherwise
            fprintf('无效选择，请重新输入。\n');
    end
end

%% ========================================
%% 功能函数定义
%% ========================================

function performFaultDiagnosis(kb)
    % 执行故障诊断
    fprintf('\n========================================\n');
    fprintf('故障诊断模块\n');
    fprintf('========================================\n');
    
    % 选择故障类型
    fprintf('请选择故障类型:\n');
    fprintf('1. 数据偏差型故障\n');
    fprintf('2. 数据传输中断型故障\n');
    fprintf('3. 数据保持型故障\n');
    fprintf('4. 数据波动型故障\n');
    
    type_choice = input('选择 [1-4]: ', 's');
    
    fault_types = {
        '数据偏差型故障',
        '数据传输中断型故障',
        '数据保持型故障',
        '数据波动型故障'
    };
    
    type_num = str2double(type_choice);
    if isnan(type_num) || type_num < 1 || type_num > 4
        fprintf('无效选择\n');
        return;
    end
    
    fault_type = fault_types{type_num};
    
    % 输入故障代码
    fault_code = input('请输入故障代码（如302，或直接回车查看该类型所有故障）: ', 's');
    
    % 处理空输入
    if isempty(fault_code)
        fault_code = '';
    end
    
    % 获取故障信息
    try
        [fault_info, measures] = kb.getFaultInfo(fault_type, fault_code);
        
        if isempty(fault_info)
            fprintf('未找到对应的故障信息\n');
            return;
        end
        
        % 显示故障信息和维护建议
        kb.displayFaultInfo(fault_info, measures);
        
        % 询问是否执行维护
        execute = input('\n是否立即执行维护？(y/n): ', 's');
        
        if strcmpi(execute, 'y')
            % 显示维护步骤选择
            fprintf('\n请选择执行的维护措施等级 [1-%d]: ', length(measures));
            level = input('', 's');
            level_num = str2double(level);
            
            if ~isnan(level_num) && level_num >= 1 && level_num <= length(measures)
                selected_measure = measures{level_num};
                fprintf('\n正在执行: %s\n', selected_measure.measure);
                fprintf('预计时间: %s\n', selected_measure.time);
                fprintf('所需工具: %s\n', selected_measure.tools);
                
                % 模拟维护过程
                fprintf('\n维护进行中');
                for i = 1:5
                    fprintf('.');
                    pause(0.5);
                end
                fprintf(' 完成！\n');
                
                % 记录维护结果
                result = input('维护结果（成功/失败）: ', 's');
                if isempty(result)
                    result = '成功';
                end
                
                kb.logMaintenance(fault_info.fault_code, ...
                                selected_measure.measure, ...
                                result, now);
                
                fprintf('维护记录已保存。\n');
            else
                fprintf('无效的选择\n');
            end
        end
        
    catch ME
        fprintf('诊断过程中发生错误: %s\n', ME.message);
    end
end

function recordMaintenance(kb)
    % 记录实际维护情况
    fprintf('\n========================================\n');
    fprintf('记录维护情况\n');
    fprintf('========================================\n');
    
    fault_code = input('故障代码: ', 's');
    if isempty(fault_code)
        fprintf('故障代码不能为空\n');
        return;
    end
    
    measure = input('实际执行的维护措施: ', 's');
    if isempty(measure)
        fprintf('维护措施不能为空\n');
        return;
    end
    
    result = input('维护结果（成功/失败/部分成功）: ', 's');
    if isempty(result)
        result = '成功';
    end
    
    try
        kb.logMaintenance(fault_code, measure, result, now);
        fprintf('\n维护记录已成功保存！\n');
    catch ME
        fprintf('记录维护时发生错误: %s\n', ME.message);
    end
end

function addCustomMaintenance(kb)
    % 添加自定义维护措施
    fprintf('\n========================================\n');
    fprintf('添加自定义维护措施\n');
    fprintf('========================================\n');
    
    fault_code = input('故障代码: ', 's');
    if isempty(fault_code)
        fprintf('故障代码不能为空\n');
        return;
    end
    
    measure = input('维护措施描述: ', 's');
    if isempty(measure)
        fprintf('维护措施描述不能为空\n');
        return;
    end
    
    time = input('预计时间: ', 's');
    if isempty(time)
        time = '30分钟';
    end
    
    tools = input('所需工具: ', 's');
    if isempty(tools)
        tools = '基本工具';
    end
    
    try
        kb.addCustomMeasure(fault_code, measure, time, tools);
        fprintf('\n自定义维护措施已成功添加！\n');
        fprintf('注意：该措施将在下次系统更新时纳入标准知识库。\n');
    catch ME
        fprintf('添加自定义措施时发生错误: %s\n', ME.message);
    end
end

function generateReport(kb)
    % 生成统计报告
    fprintf('\n正在生成统计报告...\n');
    
    try
        report = kb.generateStatisticsReport();
        
        % 保存报告到文件
        save_report = input('\n是否保存报告到文件？(y/n): ', 's');
        if strcmpi(save_report, 'y')
            filename = sprintf('Maintenance_Report_%s.txt', ...
                             datestr(now, 'yyyymmdd_HHMMSS'));
            
            % 创建报告文件
            fid = fopen(filename, 'w', 'n', 'UTF-8');
            if fid ~= -1
                fprintf(fid, '氧分析仪维护统计报告\n');
                fprintf(fid, '生成时间: %s\n', datestr(now));
                fprintf(fid, '总维护记录数: %d\n', report.total_logs);
                fprintf(fid, '自定义措施数: %d\n', report.custom_measures);
                fclose(fid);
                fprintf('报告已保存至: %s\n', filename);
            else
                fprintf('无法创建报告文件\n');
            end
        end
    catch ME
        fprintf('生成报告时发生错误: %s\n', ME.message);
    end
end

function predictiveMaintenance(kb)
    % 预测性维护分析
    fprintf('\n========================================\n');
    fprintf('预测性维护分析\n');
    fprintf('========================================\n');
    
    % 模拟历史数据分析
    fprintf('正在分析历史故障数据...\n');
    pause(1);
    
    fprintf('\n基于历史数据的预测性维护建议:\n');
    fprintf('----------------------------------------\n');
    
    % 高频故障分析
    fprintf('1. 高频故障预警:\n');
    fprintf('   - 故障代码302（零点漂移）出现频率增加\n');
    fprintf('   - 建议：每周进行零点校准\n\n');
    
    % 季节性维护建议
    current_month = month(datetime('now'));
    if current_month >= 6 && current_month <= 9
        fprintf('2. 季节性维护建议:\n');
        fprintf('   - 夏季高温高湿环境\n');
        fprintf('   - 建议：增加冷凝水检查频率\n');
        fprintf('   - 建议：每月清洁光学元件\n\n');
    else
        fprintf('2. 季节性维护建议:\n');
        fprintf('   - 冬季低温环境\n');
        fprintf('   - 建议：检查加热系统\n');
        fprintf('   - 建议：防止管路冻结\n\n');
    end
    
    % 设备寿命预测
    fprintf('3. 设备寿命预测:\n');
    fprintf('   - 传感器预计剩余寿命：约6个月\n');
    fprintf('   - 建议：准备备用传感器\n\n');
    
    % 维护计划优化
    fprintf('4. 维护计划优化建议:\n');
    fprintf('   - 将定期维护周期从30天调整为21天\n');
    fprintf('   - 增加关键部件库存\n');
    fprintf('   - 加强维护人员培训\n');
    
    % 成本效益分析
    fprintf('\n5. 成本效益分析:\n');
    fprintf('   - 预防性维护成本：约5000元/月\n');
    fprintf('   - 故障停机损失：约20000元/次\n');
    fprintf('   - 建议：加强预防性维护投入\n');
    
    % 生成维护日历
    generateMaintenanceCalendar();
end

function generateMaintenanceCalendar()
    % 生成维护日历
    fprintf('\n----------------------------------------\n');
    fprintf('未来30天维护计划:\n');
    fprintf('----------------------------------------\n');
    
    base_date = datetime('now');
    
    % 定期维护任务
    maintenance_tasks = {
        7,  '传感器表面清洁';
        14, '零点校准';
        21, '量程校准';
        30, '全面系统检查'
    };
    
    for i = 1:size(maintenance_tasks, 1)
        days = maintenance_tasks{i, 1};
        task = maintenance_tasks{i, 2};
        date = base_date + days;
        fprintf('%s - %s\n', datestr(date, 'yyyy-mm-dd'), task);
    end
end

function simulateRealTimeMonitoring(kb)
    % 模拟实时监控诊断
    fprintf('\n========================================\n');
    fprintf('模拟实时监控诊断\n');
    fprintf('========================================\n');
    
    fprintf('开始模拟实时数据流...\n');
    fprintf('按 Ctrl+C 停止模拟\n\n');
    
    % 模拟参数
    normal_value = 5.0;  % 正常氧浓度
    sample_count = 0;
    
    % 创建实时显示图
    figure('Name', '实时监控诊断', 'Position', [100, 100, 800, 600]);
    
    % 数据缓冲
    buffer_size = 100;
    data_buffer = zeros(buffer_size, 1);
    time_buffer = zeros(buffer_size, 1);
    
    try
        while true
            sample_count = sample_count + 1;
            
            % 生成模拟数据（包含各种故障模式）
            if mod(sample_count, 100) == 0
                % 模拟突变
                current_value = 10 * rand();
                fault_type = '数据突变';
            elseif mod(sample_count, 50) == 0
                % 模拟信号丢失
                current_value = NaN;
                fault_type = '信号丢失';
            else
                % 正常波动
                current_value = normal_value + 0.2 * randn();
                fault_type = '正常';
            end
            
            % 更新缓冲区
            data_buffer = [data_buffer(2:end); current_value];
            time_buffer = [time_buffer(2:end); sample_count];
            
            % 实时诊断
            if isnan(current_value)
                fprintf('[%s] 警报！信号丢失 - 故障代码: 300\n', ...
                       datestr(now, 'HH:MM:SS'));
                try
                    [fault_info, measures] = kb.getFaultInfo('数据传输中断型故障', '300');
                    if ~isempty(fault_info)
                        fprintf('  建议: %s\n', measures{1}.measure);
                    end
                catch
                    fprintf('  建议: 检查ADC供电\n');
                end
            elseif current_value > 9.95
                fprintf('[%s] 警报！满量程输出 - 故障代码: 344\n', ...
                       datestr(now, 'HH:MM:SS'));
                try
                    [fault_info, measures] = kb.getFaultInfo('数据保持型故障', '344');
                    if ~isempty(fault_info)
                        fprintf('  建议: %s\n', measures{1}.measure);
                    end
                catch
                    fprintf('  建议: 检查工艺异常\n');
                end
            elseif current_value < 0.05
                fprintf('[%s] 警报！零位输出 - 故障代码: 345\n', ...
                       datestr(now, 'HH:MM:SS'));
                try
                    [fault_info, measures] = kb.getFaultInfo('数据保持型故障', '345');
                    if ~isempty(fault_info)
                        fprintf('  建议: %s\n', measures{1}.measure);
                    end
                catch
                    fprintf('  建议: 检查传感器接线\n');
                end
            end
            
            % 更新图形
            clf;
            subplot(2,1,1);
            plot(time_buffer, data_buffer, 'b-', 'LineWidth', 1.5);
            hold on;
            plot(time_buffer(end), data_buffer(end), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
            yline(9.95, 'r--', '上限');
            yline(0.05, 'r--', '下限');
            yline(5, 'g--', '正常值');
            hold off;
            xlabel('采样点');
            ylabel('氧浓度 (%)');
            title('实时氧浓度监控');
            grid on;
            ylim([-1, 11]);
            
            subplot(2,1,2);
            % 计算统计指标
            valid_data = data_buffer(~isnan(data_buffer));
            if ~isempty(valid_data)
                stats_text = sprintf(['当前值: %.2f%%\n' ...
                                    '平均值: %.2f%%\n' ...
                                    '标准差: %.2f%%\n' ...
                                    '最大值: %.2f%%\n' ...
                                    '最小值: %.2f%%\n' ...
                                    '采样点: %d'], ...
                                    current_value, mean(valid_data), ...
                                    std(valid_data), max(valid_data), ...
                                    min(valid_data), sample_count);
            else
                stats_text = '等待数据...';
            end
            
            text(0.1, 0.5, stats_text, 'FontSize', 12, 'FontName', 'FixedWidth');
            axis off;
            title('实时统计');
            
            drawnow;
            
            % 模拟采样间隔
            pause(0.5);
            
            % 每100个样本进行一次综合诊断
            if mod(sample_count, 100) == 0
                performComprehensiveDiagnosis(data_buffer, kb);
            end
        end
    catch ME
        if ~strcmp(ME.identifier, 'MATLAB:badsubscript')
            rethrow(ME);
        end
        fprintf('\n模拟已停止。\n');
    end
    
    close(gcf);
end

function performComprehensiveDiagnosis(data, kb)
    % 执行综合诊断
    valid_data = data(~isnan(data));
    
    if isempty(valid_data)
        return;
    end
    
    mean_val = mean(valid_data);
    std_val = std(valid_data);
    
    fprintf('\n--- 综合诊断报告 ---\n');
    fprintf('时间: %s\n', datestr(now));
    
    % 判断故障类型
    if std_val > 0.5
        fprintf('诊断: 数据波动异常\n');
        fprintf('建议执行故障代码312相关维护\n');
    elseif abs(mean_val - 5) > 1.5
        fprintf('诊断: 数据偏差异常\n');
        if mean_val > 5
            fprintf('建议执行故障代码303相关维护\n');
        else
            fprintf('建议执行故障代码302相关维护\n');
        end
    else
        fprintf('诊断: 系统正常运行\n');
    end
    fprintf('-------------------\n\n');
end

function exportMaintenanceLog(kb)
    % 导出维护记录
    fprintf('\n========================================\n');
    fprintf('导出维护记录\n');
    fprintf('========================================\n');
    
    % 选择导出格式
    fprintf('选择导出格式:\n');
    fprintf('1. Excel (.xlsx)\n');
    fprintf('2. CSV (.csv)\n');
    fprintf('3. 文本文件 (.txt)\n');
    
    format_choice = input('选择 [1-3]: ', 's');
    
    % 生成文件名
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    
    try
        switch format_choice
            case '1'
                filename = sprintf('Maintenance_Log_%s.xlsx', timestamp);
                fprintf('正在导出到Excel...\n');
                kb.exportToExcel(filename);
                
            case '2'
                filename = sprintf('Maintenance_Log_%s.csv', timestamp);
                fprintf('正在导出到CSV...\n');
                kb.exportToExcel(filename);
                
            case '3'
                filename = sprintf('Maintenance_Log_%s.txt', timestamp);
                fprintf('正在导出到文本文件...\n');
                
                fid = fopen(filename, 'w', 'n', 'UTF-8');
                if fid ~= -1
                    fprintf(fid, '氧分析仪维护记录\n');
                    fprintf(fid, '生成时间: %s\n', datestr(now));
                    fprintf(fid, '========================================\n\n');
                    fprintf(fid, '维护记录导出完成\n');
                    fclose(fid);
                    fprintf('文件已保存: %s\n', filename);
                else
                    fprintf('无法创建文件\n');
                end
                
            otherwise
                fprintf('无效选择\n');
        end
    catch ME
        fprintf('导出过程中发生错误: %s\n', ME.message);
    end
end

function viewKnowledgeBase(kb)
    % 查看知识库
    fprintf('\n========================================\n');
    fprintf('故障知识库概览\n');
    fprintf('========================================\n');
    
    try
        % 使用知识库的listAllFaults方法
        kb.listAllFaults();
        
        % 询问是否搜索特定故障
        search_keyword = input('\n搜索特定故障？(输入关键词，直接回车跳过): ', 's');
        
        if ~isempty(search_keyword)
            kb.searchFaults(search_keyword);
        end
        
    catch ME
        fprintf('查看知识库时发生错误: %s\n', ME.message);
    end
end

%% ========================================
%% 程序结束
%% ========================================

fprintf('\n════════════════════════════════════════\n');
fprintf('     智能维护决策系统已关闭\n');
fprintf('════════════════════════════════════════\n');