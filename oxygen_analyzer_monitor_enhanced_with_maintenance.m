clear; clc; close all;

%% ========================================
%% 系统配置部分
%% ========================================

fprintf('════════════════════════════════════════\n');
fprintf('   MATLAB实时氧分析仪监控系统 v4.0\n');
fprintf('   (集成故障诊断与维修建议)\n');
fprintf('════════════════════════════════════════\n\n');

% 系统参数配置
config = struct();
config.data_file = '7_twohour.xlsx';                % 数据文件名
config.sheet_name = 'Sheet1';               % 工作表名
config.start_time = datetime(2025,10,8,0,0,0); % 起始时间
config.sample_interval = 1;                 % 采样间隔(秒)
config.diagnosis_interval = 3600;          % 诊断间隔(1小时=3600秒)
config.simulation_speed = 100;              % 模拟速度(1=实时,100=100倍速)
config.enable_visualization = true;         % 是否启用实时可视化
config.save_log = true;                     % 是否保存日志

% 诊断阈值配置
thresholds = struct();
thresholds.full_scale = 9.95;              % 满量程阈值(%)
thresholds.zero_scale = 0.05;              % 零位阈值(%)
thresholds.normal_mean = 5.0;              % 正常均值(%)
thresholds.small_offset = 0.5;             % 小幅偏移阈值(%)
thresholds.large_offset = 1.5;             % 大幅偏移阈值(%)
thresholds.normal_std = 0.1;               % 正常标准差(%)
thresholds.high_std = 0.5;                 % 剧烈波动标准差阈值(%)
thresholds.data_hold_threshold = 0.001;    % 数据保持阈值(%)
thresholds.data_hold_duration = 300;       % 数据保持持续时间(秒)

% 故障类型编号体系
fault_types = struct();
fault_types.full_scale = '001';            % 满量程输出
fault_types.zero_scale = '002';            % 零位输出
fault_types.data_missing = '003';          % 数据缺失
fault_types.data_hold = '004';             % 数据保持
fault_types.severe_fluctuation = '005';    % 剧烈波动异常
fault_types.data_offset = '006';           % 数据偏移

% 数据偏移子类型
offset_subtypes = struct();
offset_subtypes.small_positive = '006.01'; % 小幅正向偏移
offset_subtypes.small_negative = '006.02'; % 小幅负向偏移
offset_subtypes.large_positive = '006.03'; % 大幅正向偏移
offset_subtypes.large_negative = '006.04'; % 大幅负向偏移
offset_subtypes.severe_positive = '006.05';% 严重正向偏移
offset_subtypes.severe_negative = '006.06';% 严重负向偏移

fprintf('【系统配置】\n');
fprintf('  数据文件: %s\n', config.data_file);
fprintf('  起始时间: %s\n', datestr(config.start_time));
fprintf('  采样间隔: %d秒\n', config.sample_interval);
fprintf('  诊断周期: %d秒 (%.1f小时)\n', config.diagnosis_interval, config.diagnosis_interval/3600);
fprintf('  模拟速度: %dx\n', config.simulation_speed);
fprintf('\n');

%% ========================================
%% 初始化维修建议数据库
%% ========================================

fprintf('【维修建议数据库初始化】\n');

% 创建维修建议数据库
maintenance_db = initialize_maintenance_database();

fprintf('  ✓ 维修建议数据库加载完成，共%d条记录\n\n', length(maintenance_db));

%% ========================================
%% 加载数据
%% ========================================

fprintf('【数据加载】\n');

% 检查文件是否存在
if ~exist(config.data_file, 'file')
    error('错误：找不到数据文件 %s', config.data_file);
end

% 读取Excel数据
try
    raw_data = readtable(config.data_file, 'Sheet', config.sheet_name);
    fprintf('  ✓ 成功加载数据文件\n');
catch ME
    error('读取数据失败: %s', ME.message);
end

% 数据预处理
if width(raw_data) == 2
    % 两列数据：时间戳和氧浓度
    time_stamps = raw_data{:,1};
    oxygen_values = raw_data{:,2};
elseif width(raw_data) == 1
    % 单列数据：仅氧浓度，自动生成时间戳
    oxygen_values = raw_data{:,1};
    time_stamps = (0:length(oxygen_values)-1)' * config.sample_interval;
else
    % 多列数据，假设第二列是氧浓度
    oxygen_values = raw_data{:,2};
    time_stamps = (0:length(oxygen_values)-1)' * config.sample_interval;
end

total_samples = length(oxygen_values);
total_duration = total_samples * config.sample_interval;

fprintf('  数据点数: %d\n', total_samples);
fprintf('  数据时长: %.2f小时 (%.2f天)\n', total_duration/3600, total_duration/86400);
fprintf('  数据范围: [%.4f, %.4f]%%\n\n', min(oxygen_values(~isnan(oxygen_values))), ...
    max(oxygen_values(~isnan(oxygen_values))));

%% ========================================
%% 初始化监控系统
%% ========================================

fprintf('【系统初始化】\n');

% 初始化数据缓冲区
buffer_size = config.diagnosis_interval;
data_buffer = NaN(buffer_size, 1);         % 1小时数据缓冲
buffer_index = 0;                           % 缓冲区索引

% 初始化统计变量
stats = struct();
stats.total_alarms = 0;                    % 总报警次数
stats.fault_counts = containers.Map();     % 各故障类型计数
stats.diagnosis_count = 0;                 % 诊断次数

% 初始化故障类型计数
fault_type_names = {'001', '002', '003', '004', '005', '006.01', '006.02', '006.03', '006.04', '006.05', '006.06'};
for i = 1:length(fault_type_names)
    stats.fault_counts(fault_type_names{i}) = 0;
end

% 初始化日志
log_entries = {};
alarm_log = {};

% 初始化数据保持检测变量
data_hold_detector = struct();
data_hold_detector.last_value = NaN;
data_hold_detector.hold_start_time = NaN;
data_hold_detector.hold_duration = 0;
data_hold_detector.is_holding = false;

% 初始化周期性报警控制
periodic_alarm_control = struct();
periodic_alarm_control.last_alarm_time = containers.Map();
periodic_alarm_control.alarm_interval = 600; % 10分钟 = 600秒

% 初始化可视化
if config.enable_visualization
    fig = figure('Name', '实时氧分析仪监控系统 v4.0', ...
                'Position', [50, 50, 1400, 800], ...
                'NumberTitle', 'off');
    
    % 实时数据显示窗口
    ax1 = subplot(2, 2, 1);
    h_line = plot(NaN, NaN, 'b-', 'LineWidth', 1.5);
    hold on;
    h_alarm_points = plot(NaN, NaN, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    h_current = plot(NaN, NaN, 'go', 'MarkerSize', 10, 'MarkerFaceColor', 'g');
    yline(thresholds.full_scale, 'r--', '满量程', 'LineWidth', 1.5);
    yline(thresholds.zero_scale, 'r--', '零位', 'LineWidth', 1.5);
    yline(thresholds.normal_mean, 'g--', '正常值', 'LineWidth', 1.5);
    hold off;
    xlabel('时间 (秒)');
    ylabel('氧浓度 (%)');
    title('实时氧浓度监控');
    grid on;
    xlim([0, 1000]);
    ylim([-0.5, 10.5]);
    legend('实时数据', '异常点', '当前值', 'Location', 'best');
    
    % 1小时数据窗口
    ax2 = subplot(2, 2, 2);
    h_buffer = plot(NaN, NaN, 'b-', 'LineWidth', 1);
    xlabel('时间 (小时)');
    ylabel('氧浓度 (%)');
    title('1小时数据窗口');
    grid on;
    xlim([0, 1]);
    ylim([-0.5, 10.5]);
    
    % 统计信息面板
    ax3 = subplot(2, 2, 3);
    axis off;
    h_stats_text = text(0.05, 0.85, '', 'FontSize', 10, 'FontName', 'FixedWidth', ...
                       'VerticalAlignment', 'top');
    title('实时统计信息');
    
    % 诊断日志面板
    ax4 = subplot(2, 2, 4);
    axis off;
    h_log_text = text(0.05, 0.88, '', 'FontSize', 9, 'FontName', 'FixedWidth', ...
                     'VerticalAlignment', 'top');
    title('诊断日志（最近10条）');
    
    drawnow;
end

fprintf('  ✓ 系统初始化完成\n\n');

%% ========================================
%% 主监控循环
%% ========================================

fprintf('════════════════════════════════════════\n');
fprintf('         开始实时监控模拟\n');
fprintf('════════════════════════════════════════\n\n');

% 初始化变量
sample_count = 0;
last_diagnosis_time = 0;
alarm_times = [];
alarm_values = [];

% 主循环
for i = 1:total_samples
    sample_count = sample_count + 1;
    
    % 获取当前数据
    current_value = oxygen_values(i);
    current_time = config.start_time + seconds((i-1) * config.sample_interval);
    
    % 更新数据缓冲区
    buffer_index = mod(sample_count - 1, buffer_size) + 1;
    data_buffer(buffer_index) = current_value;
    
    % ====== 实时异常检测 ======
    [is_alarm, fault_code, alarm_msg] = realtime_detection(current_value, current_time, thresholds, ...
                                                          fault_types, offset_subtypes, ...
                                                          data_hold_detector, config.sample_interval);
    
    if is_alarm
        % 检查是否应该报警（周期性控制）
        should_alarm = check_periodic_alarm(fault_code, current_time, periodic_alarm_control);
        
        if should_alarm
            stats.total_alarms = stats.total_alarms + 1;
            
            % 统计各类报警
            if isKey(stats.fault_counts, fault_code)
                stats.fault_counts(fault_code) = stats.fault_counts(fault_code) + 1;
            end
            
            % 获取维修建议
            maintenance_advice = get_maintenance_advice(fault_code, maintenance_db);
            
            % 记录报警（包含维修建议）
            full_alarm_msg = sprintf('%s\n%s', alarm_msg, maintenance_advice);
            alarm_log{end+1} = full_alarm_msg;
            alarm_times(end+1) = (i-1) * config.sample_interval;
            alarm_values(end+1) = current_value;
            
            % 显示报警
            fprintf('\a'); % 蜂鸣器
            fprintf('%s\n', full_alarm_msg);
            fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n');
        end
    end
    
    % ====== 定期综合诊断 ======
    if sample_count >= config.diagnosis_interval && ...
       mod(sample_count, config.diagnosis_interval) == 0
        
        stats.diagnosis_count = stats.diagnosis_count + 1;
        
        % 执行诊断
        [fault_code, diagnosis_msg] = periodic_diagnosis(data_buffer, current_time, thresholds, ...
                                                        fault_types, offset_subtypes);
        
        % 获取维修建议
        if ~strcmp(fault_code, 'NORMAL')
            maintenance_advice = get_maintenance_advice(fault_code, maintenance_db);
            full_diagnosis_msg = sprintf('%s\n%s', diagnosis_msg, maintenance_advice);
        else
            full_diagnosis_msg = diagnosis_msg;
        end
        
        % 记录诊断
        log_entries{end+1} = full_diagnosis_msg;
        
        % 显示诊断结果
        fprintf('\n%s\n', full_diagnosis_msg);
        fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n');
    end
    
    % ====== 更新可视化 ======
    if config.enable_visualization && mod(i, 10) == 0  % 每10个点更新一次图形
        % 更新实时数据图
        window_size = min(1000, i);
        window_start = max(1, i - window_size + 1);
        window_data = oxygen_values(window_start:i);
        window_time = (window_start-1:i-1) * config.sample_interval;
        
        set(h_line, 'XData', window_time, 'YData', window_data);
        set(h_current, 'XData', window_time(end), 'YData', window_data(end));
        
        % 更新异常点
        if ~isempty(alarm_times)
            recent_alarms = alarm_times >= window_time(1);
            set(h_alarm_points, 'XData', alarm_times(recent_alarms), ...
                              'YData', alarm_values(recent_alarms));
        end
        
        xlim(ax1, [window_time(1), window_time(end)+100]);
        
        % 更新1小时窗口
        buffer_time = (0:buffer_size-1) / 3600;  % 转换为小时
        set(h_buffer, 'XData', buffer_time, 'YData', data_buffer);
        
        % 更新统计信息
        stats_text = sprintf(['\n\n监控时长: %.2f小时\n' ...
                            '处理样本: %d/%d\n' ...
                            '━━━━━━━━━━━━━━━━\n' ...
                            '总报警数: %d\n' ...
                            '  001-满量程: %d\n' ...
                            '  002-零位: %d\n' ...
                            '  003-数据缺失: %d\n' ...
                            '  004-数据保持: %d\n' ...
                            '  005-剧烈波动: %d\n' ...
                            '  006-数据偏移: %d\n' ...
                            '━━━━━━━━━━━━━━━━\n' ...
                            '诊断次数: %d\n' ...
                            '当前值: %.4f%%\n' ...
                            '当前时间: %s'], ...
                            sample_count/3600, sample_count, total_samples, ...
                            stats.total_alarms, ...
                            stats.fault_counts('001'), ...
                            stats.fault_counts('002'), ...
                            stats.fault_counts('003'), ...
                            stats.fault_counts('004'), ...
                            stats.fault_counts('005'), ...
                            stats.fault_counts('006.01') + stats.fault_counts('006.02') + ...
                            stats.fault_counts('006.03') + stats.fault_counts('006.04') + ...
                            stats.fault_counts('006.05') + stats.fault_counts('006.06'), ...
                            stats.diagnosis_count, ...
                            current_value, ...
                            datestr(current_time, 'HH:MM:SS'));
        set(h_stats_text, 'String', stats_text);
        
        % 更新日志显示（最近10条）
        all_logs = [alarm_log, log_entries];
        if ~isempty(all_logs)
            recent_logs = all_logs(max(1, end-9):end);
            log_text = sprintf('\n\n%s', strjoin(recent_logs, '\n'));
            set(h_log_text, 'String', log_text);
        end
        
        drawnow;
    end
    
    % 模拟延时（根据模拟速度调整）
    if config.simulation_speed < 1000  % 速度太快时不暂停
        pause(config.sample_interval / config.simulation_speed);
    end
    
    % 每小时显示进度
    if mod(sample_count, 3600) == 0
        fprintf('【进度】已处理 %.1f 小时数据 (%.1f%%)\n', ...
              sample_count/3600, sample_count/total_samples*100);
    end
end

%% ========================================
%% 生成最终报告
%% ========================================

fprintf('\n════════════════════════════════════════\n');
fprintf('         监控模拟完成\n');
fprintf('════════════════════════════════════════\n\n');

fprintf('【监控统计总结】\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('监控时长: %.2f小时 (%.2f天)\n', total_duration/3600, total_duration/86400);
fprintf('处理样本数: %d\n', total_samples);
fprintf('诊断次数: %d\n\n', stats.diagnosis_count);

fprintf('【故障统计】\n');
fprintf('总报警次数: %d\n', stats.total_alarms);
fprintf('  001-满量程输出: %d次 (%.2f%%)\n', stats.fault_counts('001'), ...
      stats.fault_counts('001')/total_samples*100);
fprintf('  002-零位输出: %d次 (%.2f%%)\n', stats.fault_counts('002'), ...
      stats.fault_counts('002')/total_samples*100);
fprintf('  003-数据缺失: %d次 (%.2f%%)\n', stats.fault_counts('003'), ...
      stats.fault_counts('003')/total_samples*100);
fprintf('  004-数据保持: %d次 (%.2f%%)\n', stats.fault_counts('004'), ...
      stats.fault_counts('004')/total_samples*100);
fprintf('  005-剧烈波动异常: %d次 (%.2f%%)\n', stats.fault_counts('005'), ...
      stats.fault_counts('005')/total_samples*100);
fprintf('  006-数据偏移: %d次 (%.2f%%)\n', ...
      stats.fault_counts('006.01') + stats.fault_counts('006.02') + ...
      stats.fault_counts('006.03') + stats.fault_counts('006.04') + ...
      stats.fault_counts('006.05') + stats.fault_counts('006.06'), ...
      (stats.fault_counts('006.01') + stats.fault_counts('006.02') + ...
       stats.fault_counts('006.03') + stats.fault_counts('006.04') + ...
       stats.fault_counts('006.05') + stats.fault_counts('006.06'))/total_samples*100);

fprintf('    006.01-小幅正向偏移: %d次\n', stats.fault_counts('006.01'));
fprintf('    006.02-小幅负向偏移: %d次\n', stats.fault_counts('006.02'));
fprintf('    006.03-大幅正向偏移: %d次\n', stats.fault_counts('006.03'));
fprintf('    006.04-大幅负向偏移: %d次\n', stats.fault_counts('006.04'));
fprintf('    006.05-严重正向偏移: %d次\n', stats.fault_counts('006.05'));
fprintf('    006.06-严重负向偏移: %d次\n', stats.fault_counts('006.06'));
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n');

% 保存报告到文件
if config.save_log
    % 生成报告文件名
    report_filename = sprintf('O2_Monitor_Enhanced_Report_%s.txt', ...
                            datestr(now, 'yyyymmdd_HHMMSS'));
    
    fid = fopen(report_filename, 'w', 'n', 'UTF-8');
    
    fprintf(fid, '════════════════════════════════════════\n');
    fprintf(fid, '   氧分析仪实时监控系统报告 v4.0\n');
    fprintf(fid, '   (集成故障诊断与维修建议)\n');
    fprintf(fid, '════════════════════════════════════════\n\n');
    fprintf(fid, '生成时间: %s\n', datestr(now));
    fprintf(fid, '数据文件: %s\n', config.data_file);
    fprintf(fid, '起始时间: %s\n', datestr(config.start_time));
    fprintf(fid, '监控时长: %.2f小时\n\n', total_duration/3600);
    
    fprintf(fid, '【监控统计】\n');
    fprintf(fid, '处理样本数: %d\n', total_samples);
    fprintf(fid, '诊断次数: %d\n', stats.diagnosis_count);
    fprintf(fid, '总报警次数: %d\n\n', stats.total_alarms);
    
    fprintf(fid, '【故障统计详情】\n');
    fprintf(fid, '001-满量程输出: %d次\n', stats.fault_counts('001'));
    fprintf(fid, '002-零位输出: %d次\n', stats.fault_counts('002'));
    fprintf(fid, '003-数据缺失: %d次\n', stats.fault_counts('003'));
    fprintf(fid, '004-数据保持: %d次\n', stats.fault_counts('004'));
    fprintf(fid, '005-剧烈波动异常: %d次\n', stats.fault_counts('005'));
    fprintf(fid, '006-数据偏移: %d次\n', ...
            stats.fault_counts('006.01') + stats.fault_counts('006.02') + ...
            stats.fault_counts('006.03') + stats.fault_counts('006.04') + ...
            stats.fault_counts('006.05') + stats.fault_counts('006.06'));
    fprintf(fid, '  006.01-小幅正向偏移: %d次\n', stats.fault_counts('006.01'));
    fprintf(fid, '  006.02-小幅负向偏移: %d次\n', stats.fault_counts('006.02'));
    fprintf(fid, '  006.03-大幅正向偏移: %d次\n', stats.fault_counts('006.03'));
    fprintf(fid, '  006.04-大幅负向偏移: %d次\n', stats.fault_counts('006.04'));
    fprintf(fid, '  006.05-严重正向偏移: %d次\n', stats.fault_counts('006.05'));
    fprintf(fid, '  006.06-严重负向偏移: %d次\n', stats.fault_counts('006.06'));
    fprintf(fid, '\n');
    
    fprintf(fid, '【实时报警记录】\n');
    fprintf(fid, '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    for j = 1:length(alarm_log)
        fprintf(fid, '%s\n', alarm_log{j});
        fprintf(fid, '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    end
    fprintf(fid, '\n');
    
    fprintf(fid, '【定期诊断记录】\n');
    fprintf(fid, '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    for j = 1:length(log_entries)
        fprintf(fid, '%s\n', log_entries{j});
        fprintf(fid, '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    end
    
    fclose(fid);
    fprintf('监控报告已保存至: %s\n', report_filename);
    
    % 保存报警数据到Excel
    if stats.total_alarms > 0
        alarm_excel = sprintf('O2_Alarms_Enhanced_%s.xlsx', datestr(now, 'yyyymmdd_HHMMSS'));
        
        % 转换时间戳
        alarm_datetimes = config.start_time + seconds(alarm_times);
        
        % 创建表格
        alarm_table = table(alarm_datetimes', alarm_values', ...
                          'VariableNames', {'时间', '氧浓度_%'});
        
        % 写入Excel
        writetable(alarm_table, alarm_excel);
        fprintf('报警数据已保存至: %s\n', alarm_excel);
    end
end

% 保存最终图形
if config.enable_visualization
    fig_filename = sprintf('O2_Monitor_Enhanced_Final_%s.png', ...
                         datestr(now, 'yyyymmdd_HHMMSS'));
    saveas(fig, fig_filename);
    fprintf('监控图表已保存至: %s\n', fig_filename);
end

fprintf('\n【系统提示】\n');
if stats.total_alarms > 10
    fprintf('⚠ 警告：检测到大量异常报警，建议立即检查设备！\n');
elseif stats.total_alarms > 0
    fprintf('⚠ 注意：监控期间出现了%d次异常，请关注设备状态。\n', stats.total_alarms);
else
    fprintf('✓ 监控期间设备运行正常，无异常报警。\n');
end

fprintf('\n【新增功能说明 v4.0】\n');
fprintf('✓ 集成完整维修建议数据库\n');
fprintf('✓ 实时显示故障对应的维修措施\n');
fprintf('✓ 支持多级维修建议（按优先级排序）\n');
fprintf('✓ 详细的维修时间和所需工具信息\n');
fprintf('✓ 维修建议记录保存到报告文件\n');

fprintf('\n════════════════════════════════════════\n');
fprintf('         程序执行完成\n');
fprintf('════════════════════════════════════════\n');

%% ========================================
%% 辅助函数定义
%% ========================================

% 数据保持检测函数
function [is_hold, hold_duration] = detect_data_hold(current_value, detector, thresholds, sample_interval)
    is_hold = false;
    hold_duration = 0;
    
    if isnan(current_value)
        detector.is_holding = false;
        detector.hold_duration = 0;
        return;
    end
    
    if isnan(detector.last_value)
        detector.last_value = current_value;
        detector.hold_duration = 0;
        detector.is_holding = false;
        return;
    end
    
    % 检查数值变化是否小于阈值
    value_change = abs(current_value - detector.last_value);
    
    if value_change <= thresholds.data_hold_threshold
        if ~detector.is_holding
            detector.is_holding = true;
            detector.hold_start_time = now;
            detector.hold_duration = sample_interval;
        else
            detector.hold_duration = detector.hold_duration + sample_interval;
        end
        
        % 检查是否达到保持持续时间阈值
        if detector.hold_duration >= thresholds.data_hold_duration
            is_hold = true;
            hold_duration = detector.hold_duration;
        end
    else
        detector.is_holding = false;
        detector.hold_duration = 0;
    end
    
    detector.last_value = current_value;
end

% 实时异常检测函数
function [is_alarm, fault_code, alarm_msg] = realtime_detection(value, timestamp, thresholds, fault_types, offset_subtypes, detector, sample_interval)
    is_alarm = false;
    fault_code = '';
    alarm_msg = '';
    
    if isnan(value)
        is_alarm = true;
        fault_code = fault_types.data_missing;
        alarm_msg = sprintf('【%s】%s - 数据缺失！检测到NaN值', ...
                          fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'));
    elseif value >= thresholds.full_scale
        is_alarm = true;
        fault_code = fault_types.full_scale;
        alarm_msg = sprintf('【%s】%s - 满量程输出！当前值: %.4f%%', ...
                          fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), value);
    elseif value <= thresholds.zero_scale
        is_alarm = true;
        fault_code = fault_types.zero_scale;
        alarm_msg = sprintf('【%s】%s - 零位输出！当前值: %.4f%%', ...
                          fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), value);
    else
        % 检测数据保持
        [is_hold, hold_duration] = detect_data_hold(value, detector, thresholds, sample_interval);
        if is_hold
            is_alarm = true;
            fault_code = fault_types.data_hold;
            alarm_msg = sprintf('【%s】%s - 数据保持！当前值: %.4f%%, 保持时长: %.1f秒', ...
                              fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), ...
                              value, hold_duration);
        end
    end
end

% 定期综合诊断函数
function [fault_code, diagnosis_msg] = periodic_diagnosis(data, timestamp, thresholds, fault_types, offset_subtypes)
    % 去除NaN进行统计
    valid_data = data(~isnan(data));
    
    if isempty(valid_data)
        fault_code = fault_types.data_missing;
        diagnosis_msg = sprintf('【%s】%s - 过去1小时数据全部缺失', ...
                              fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'));
        return;
    end
    
    % 计算统计特征
    data_mean = mean(valid_data);
    data_std = std(valid_data);
    offset = abs(data_mean - thresholds.normal_mean);
    
    % 诊断逻辑
    if data_std > thresholds.high_std
        fault_code = fault_types.severe_fluctuation;
        diagnosis_msg = sprintf('【%s】%s - 剧烈波动异常！标准差: %.4f%% (阈值: %.4f%%)', ...
                              fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), ...
                              data_std, thresholds.high_std);
    elseif data_mean > thresholds.normal_mean
        if offset <= thresholds.small_offset
            fault_code = offset_subtypes.small_positive;
            diagnosis_msg = sprintf('【%s】%s - 小幅正向偏移！均值: %.4f%% (偏移: +%.4f%%)', ...
                                  fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), ...
                                  data_mean, offset);
        elseif offset <= thresholds.large_offset
            fault_code = offset_subtypes.large_positive;
            diagnosis_msg = sprintf('【%s】%s - 大幅正向偏移！均值: %.4f%% (偏移: +%.4f%%)', ...
                                  fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), ...
                                  data_mean, offset);
        else
            fault_code = offset_subtypes.severe_positive;
            diagnosis_msg = sprintf('【%s】%s - 严重正向偏移！均值: %.4f%% (偏移: +%.4f%%)', ...
                                  fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), ...
                                  data_mean, offset);
        end
    elseif data_mean < thresholds.normal_mean
        if offset <= thresholds.small_offset
            fault_code = offset_subtypes.small_negative;
            diagnosis_msg = sprintf('【%s】%s - 小幅负向偏移！均值: %.4f%% (偏移: -%.4f%%)', ...
                                  fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), ...
                                  data_mean, offset);
        elseif offset <= thresholds.large_offset
            fault_code = offset_subtypes.large_negative;
            diagnosis_msg = sprintf('【%s】%s - 大幅负向偏移！均值: %.4f%% (偏移: -%.4f%%)', ...
                                  fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), ...
                                  data_mean, offset);
        else
            fault_code = offset_subtypes.severe_negative;
            diagnosis_msg = sprintf('【%s】%s - 严重负向偏移！均值: %.4f%% (偏移: -%.4f%%)', ...
                                  fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), ...
                                  data_mean, offset);
        end
    else
        fault_code = 'NORMAL';
        diagnosis_msg = sprintf('【正常】%s - 正常工况！均值: %.4f%%, 标准差: %.4f%%', ...
                              datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), ...
                              data_mean, data_std);
    end
    
    % 附加统计信息
    diagnosis_msg = sprintf('%s\n    数据统计: 有效点数=%d, 最大=%.4f%%, 最小=%.4f%%', ...
                          diagnosis_msg, length(valid_data), ...
                          max(valid_data), min(valid_data));
end

% 周期性报警控制函数
function should_alarm = check_periodic_alarm(fault_code, current_time, alarm_control)
    should_alarm = false;
    
    % 对于001-004的实时监测类故障，检查周期性报警
    if strcmp(fault_code, '001') || strcmp(fault_code, '002') || ...
       strcmp(fault_code, '003') || strcmp(fault_code, '004')
        
        if ~isKey(alarm_control.last_alarm_time, fault_code)
            should_alarm = true;
            alarm_control.last_alarm_time(fault_code) = current_time;
        else
            time_since_last = etime(datevec(current_time), datevec(alarm_control.last_alarm_time(fault_code)));
            if time_since_last >= alarm_control.alarm_interval
                should_alarm = true;
                alarm_control.last_alarm_time(fault_code) = current_time;
            end
        end
    else
        % 其他故障类型维持实时报告
        should_alarm = true;
    end
end

% 维修建议数据库初始化函数
function db = initialize_maintenance_database()
    db = {};
    
    % ========== 数据偏差型故障 ==========
    
    % 故障代码302
    db{end+1} = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '302', ...
        'fault_name', '零点漂移超过允许范围50%', ...
        'description', '偏差漂移超过了允许范围的一半（±0.75vol%O2）', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', {{
            struct('step', 1, 'action', '检查传感器表面污染', 'time', '10分钟', 'tools', '清洁布、酒精');
            struct('step', 2, 'action', '检查采样管路冷凝水', 'time', '15分钟', 'tools', '排水工具');
            struct('step', 3, 'action', '执行零点校准程序', 'time', '30分钟', 'tools', '标准气体');
            struct('step', 4, 'action', '检查传感器老化程度', 'time', '1小时', 'tools', '测试设备');
            struct('step', 5, 'action', '更换传感器模块', 'time', '2小时', 'tools', '备用传感器')
        }});
    
    % 故障代码303
    db{end+1} = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '303', ...
        'fault_name', '零点漂移超出允许范围', ...
        'description', '偏差漂移超出允许范围（±1.5vol%O2）', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', {{
            struct('step', 1, 'action', '立即检查传感器状态灯', 'time', '5分钟', 'tools', '无');
            struct('step', 2, 'action', '检查供电电压24V DC', 'time', '10分钟', 'tools', '万用表');
            struct('step', 3, 'action', '紧急执行零点量程校准', 'time', '45分钟', 'tools', '标准气体');
            struct('step', 4, 'action', '检查传感器参比电极', 'time', '1.5小时', 'tools', '专用检测仪');
            struct('step', 5, 'action', '立即更换传感器', 'time', '2小时', 'tools', '备用传感器')
        }});
    
    % 故障代码304
    db{end+1} = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '304', ...
        'fault_name', '灵敏度漂移超出50%', ...
        'description', '放大漂移超出允许范围的50%', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', {{
            struct('step', 1, 'action', '检查测量池窗片清洁度', 'time', '15分钟', 'tools', '清洁工具');
            struct('step', 2, 'action', '检查光源强度稳定性', 'time', '20分钟', 'tools', '光强测试仪');
            struct('step', 3, 'action', '执行量程标定', 'time', '40分钟', 'tools', '量程气体');
            struct('step', 4, 'action', '检查检测器响应曲线', 'time', '1小时', 'tools', '测试设备');
            struct('step', 5, 'action', '更换检测器组件', 'time', '2小时', 'tools', '备用检测器')
        }});
    
    % 故障代码305
    db{end+1} = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '305', ...
        'fault_name', '灵敏度漂移超出允许范围', ...
        'description', '放大漂移超出允许范围', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', {{
            struct('step', 1, 'action', '停止测量检查报警', 'time', '5分钟', 'tools', '无');
            struct('step', 2, 'action', '清洁所有光学元件', 'time', '30分钟', 'tools', '光学清洁套装');
            struct('step', 3, 'action', '执行完整系统标定', 'time', '1小时', 'tools', '多种标准气体');
            struct('step', 4, 'action', '调整光路对准', 'time', '1.5小时', 'tools', '光路调整工具');
            struct('step', 5, 'action', '更换光源和检测器', 'time', '3小时', 'tools', '备件')
        }});
    
    % 故障代码319
    db{end+1} = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '319', ...
        'fault_name', '磁力测量回路失衡', ...
        'description', '磁力式传感器测量回路信号失去平衡', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', {{
            struct('step', 1, 'action', '检查磁场线圈连接', 'time', '10分钟', 'tools', '万用表');
            struct('step', 2, 'action', '测量磁力传感器输出', 'time', '20分钟', 'tools', '示波器');
            struct('step', 3, 'action', '调节信号调理电路', 'time', '30分钟', 'tools', '调试设备');
            struct('step', 4, 'action', '更换磁力传感器', 'time', '1小时', 'tools', '备用传感器');
            struct('step', 5, 'action', '更换传感器电路板', 'time', '2小时', 'tools', '备用电路板')
        }});
    
    % 故障代码320
    db{end+1} = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '320', ...
        'fault_name', '测定放大偏差过高', ...
        'description', '信号放大器偏差超出正常范围', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', {{
            struct('step', 1, 'action', '检查放大器供电', 'time', '10分钟', 'tools', '万用表');
            struct('step', 2, 'action', '调整放大器零点增益', 'time', '25分钟', 'tools', '示波器');
            struct('step', 3, 'action', '更换运放芯片', 'time', '45分钟', 'tools', '备用芯片');
            struct('step', 4, 'action', '检查信号链路', 'time', '1小时', 'tools', '信号发生器');
            struct('step', 5, 'action', '更换放大器板', 'time', '1.5小时', 'tools', '备用电路板')
        }});
    
    % 故障代码309-311
    db{end+1} = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '309-311', ...
        'fault_name', '温度调节器失效', ...
        'description', '温度控制超出范围', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', {{
            struct('step', 1, 'action', '检查温度传感器', 'time', '10分钟', 'tools', '温度计');
            struct('step', 2, 'action', '检查加热冷却器', 'time', '20分钟', 'tools', '万用表');
            struct('step', 3, 'action', '校准PID参数', 'time', '40分钟', 'tools', '调试软件');
            struct('step', 4, 'action', '更换温度传感器', 'time', '1小时', 'tools', '备用传感器');
            struct('step', 5, 'action', '更换温控模块', 'time', '2小时', 'tools', '备用模块')
        }});
    
    % ========== 数据传输中断型故障 ==========
    
    % 故障代码101
    db{end+1} = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '101', ...
        'fault_name', '系统控制器关停', ...
        'description', '主控制器停止工作', ...
        'severity', '紧急', ...
        'priority', 1, ...
        'maintenance_measures', {{
            struct('step', 1, 'action', '检查主电源保险丝', 'time', '5分钟', 'tools', '万用表');
            struct('step', 2, 'action', '检查24V电源输出', 'time', '10分钟', 'tools', '万用表');
            struct('step', 3, 'action', '重启控制器系统', 'time', '15分钟', 'tools', '无');
            struct('step', 4, 'action', '检查CPU和内存', 'time', '30分钟', 'tools', '诊断软件');
            struct('step', 5, 'action', '更换控制器主板', 'time', '2小时', 'tools', '备用主板')
        }});
    
    % 故障代码116
    db{end+1} = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '116', ...
        'fault_name', 'Profibus安装错误', ...
        'description', 'Profibus模块安装位置错误', ...
        'severity', '中等', ...
        'priority', 3, ...
        'maintenance_measures', {{
            struct('step', 1, 'action', '确认安装位置', 'time', '5分钟', 'tools', '无');
            struct('step', 2, 'action', '重装到X20/X21槽', 'time', '15分钟', 'tools', '螺丝刀');
            struct('step', 3, 'action', '重配通讯参数', 'time', '20分钟', 'tools', '配置软件');
            struct('step', 4, 'action', '测试通讯连接', 'time', '30分钟', 'tools', 'Profibus测试仪');
            struct('step', 5, 'action', '更换Profibus模块', 'time', '1小时', 'tools', '备用模块')
        }});
    
    % 故障代码201-209
    db{end+1} = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '201-209', ...
        'fault_name', '系统总线连接中断', ...
        'description', '系统总线通讯中断', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', {{
            struct('step', 1, 'action', '检查总线电缆', 'time', '10分钟', 'tools', '无');
            struct('step', 2, 'action', '检查终端电阻', 'time', '15分钟', 'tools', '万用表');
            struct('step', 3, 'action', '更换总线电缆', 'time', '30分钟', 'tools', '备用电缆');
            struct('step', 4, 'action', '检查模块供电', 'time', '20分钟', 'tools', '万用表');
            struct('step', 5, 'action', '更换通讯模块', 'time', '1小时', 'tools', '备用模块')
        }});
    
    % 故障代码300
    db{end+1} = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '300', ...
        'fault_name', '模数转换器无输出', ...
        'description', 'ADC无新测量值', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', {{
            struct('step', 1, 'action', '检查ADC供电', 'time', '10分钟', 'tools', '万用表');
            struct('step', 2, 'action', '检查模拟输入', 'time', '15分钟', 'tools', '示波器');
            struct('step', 3, 'action', '重置ADC芯片', 'time', '20分钟', 'tools', '复位工具');
            struct('step', 4, 'action', '更换ADC芯片', 'time', '1小时', 'tools', '备用芯片');
            struct('step', 5, 'action', '更换采集卡', 'time', '1.5小时', 'tools', '备用采集卡')
        }});
    
    % 故障代码308
    db{end+1} = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '308', ...
        'fault_name', '测定值计算错误', ...
        'description', '计算过程错误', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', {{
            struct('step', 1, 'action', '重启处理程序', 'time', '5分钟', 'tools', '无');
            struct('step', 2, 'action', '检查CPU内存', 'time', '10分钟', 'tools', '监控软件');
            struct('step', 3, 'action', '清理系统缓存', 'time', '15分钟', 'tools', '清理工具');
            struct('step', 4, 'action', '重装固件程序', 'time', '45分钟', 'tools', '固件包');
            struct('step', 5, 'action', '更换处理器板', 'time', '2小时', 'tools', '备用板')
        }});
    
    % 故障代码318
    db{end+1} = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '318', ...
        'fault_name', 'ADC无新测量', ...
        'description', 'ADC无新数据', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', {{
            struct('step', 1, 'action', '检查触发信号', 'time', '10分钟', 'tools', '示波器');
            struct('step', 2, 'action', '检查时钟信号', 'time', '15分钟', 'tools', '示波器');
            struct('step', 3, 'action', '重配采样参数', 'time', '20分钟', 'tools', '配置软件');
            struct('step', 4, 'action', '更换时钟芯片', 'time', '45分钟', 'tools', '备用芯片');
            struct('step', 5, 'action', '更换ADC模块', 'time', '1.5小时', 'tools', '备用模块')
        }});
    
    % 故障代码332-337
    db{end+1} = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '332-337', ...
        'fault_name', 'I/O板故障', ...
        'description', 'I/O板硬件问题', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', {{
            struct('step', 1, 'action', '检查I/O板指示灯', 'time', '5分钟', 'tools', '无');
            struct('step', 2, 'action', '检查I/O配置', 'time', '15分钟', 'tools', '配置软件');
            struct('step', 3, 'action', '测试I/O通道', 'time', '30分钟', 'tools', '万用表');
            struct('step', 4, 'action', '初始化I/O板', 'time', '20分钟', 'tools', '初始化工具');
            struct('step', 5, 'action', '更换I/O板', 'time', '1小时', 'tools', '备用板')
        }});
    
    % 故障代码338-339
    db{end+1} = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '338-339', ...
        'fault_name', '模拟线路故障', ...
        'description', '线路断裂或短路', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', {{
            struct('step', 1, 'action', '检查接线端子', 'time', '10分钟', 'tools', '螺丝刀');
            struct('step', 2, 'action', '测量线路通断', 'time', '15分钟', 'tools', '万用表');
            struct('step', 3, 'action', '检查屏蔽接地', 'time', '20分钟', 'tools', '接地测试仪');
            struct('step', 4, 'action', '更换信号电缆', 'time', '30分钟', 'tools', '备用电缆');
            struct('step', 5, 'action', '重新布线', 'time', '2小时', 'tools', '布线工具')
        }});
    
    % ========== 数据保持型故障 ==========
    
    % 故障代码301
    db{end+1} = struct(...
        'fault_type', '数据保持型故障', ...
        'fault_code', '301', ...
        'fault_name', '超出ADC阈值', ...
        'description', '超出ADC范围', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', {{
            struct('step', 1, 'action', '确认实际浓度', 'time', '5分钟', 'tools', '便携式分析仪');
            struct('step', 2, 'action', '检查量程设置', 'time', '10分钟', 'tools', '配置软件');
            struct('step', 3, 'action', '调整信号衰减', 'time', '20分钟', 'tools', '调节工具');
            struct('step', 4, 'action', '重选测量量程', 'time', '30分钟', 'tools', '配置软件');
            struct('step', 5, 'action', '更换大量程传感器', 'time', '2小时', 'tools', '备用传感器')
        }});
    
    % 故障代码344
    db{end+1} = struct(...
        'fault_type', '数据保持型故障', ...
        'fault_code', '344', ...
        'fault_name', '超上限130%', ...
        'description', '超过量程130%', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', {{
            struct('step', 1, 'action', '检查工艺异常', 'time', '5分钟', 'tools', '工艺参数表');
            struct('step', 2, 'action', '检查空气泄漏', 'time', '15分钟', 'tools', '检漏仪');
            struct('step', 3, 'action', '检查传感器饱和', 'time', '20分钟', 'tools', '测试仪');
            struct('step', 4, 'action', '切换高量程', 'time', '30分钟', 'tools', '配置软件');
            struct('step', 5, 'action', '更换高量程传感器', 'time', '2小时', 'tools', '备用传感器')
        }});
    
    % 故障代码345
    db{end+1} = struct(...
        'fault_type', '数据保持型故障', ...
        'fault_code', '345', ...
        'fault_name', '低于下限-100%', ...
        'description', '低于量程-100%', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', {{
            struct('step', 1, 'action', '检查传感器接线', 'time', '10分钟', 'tools', '接线图');
            struct('step', 2, 'action', '检查信号电路', 'time', '20分钟', 'tools', '万用表');
            struct('step', 3, 'action', '验证零点设置', 'time', '30分钟', 'tools', '零点气体');
            struct('step', 4, 'action', '重新标定', 'time', '45分钟', 'tools', '标准气体');
            struct('step', 5, 'action', '更换传感器信号板', 'time', '2小时', 'tools', '备件')
        }});
    
    % ========== 数据波动型故障 ==========
    
    % 故障代码312
    db{end+1} = struct(...
        'fault_type', '数据波动型故障', ...
        'fault_code', '312', ...
        'fault_name', '压力修正失效', ...
        'description', '压力测量错误', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', {{
            struct('step', 1, 'action', '检查压力传感器', 'time', '10分钟', 'tools', '压力表');
            struct('step', 2, 'action', '检查压力管路', 'time', '15分钟', 'tools', '检漏仪');
            struct('step', 3, 'action', '校准压力传感器', 'time', '30分钟', 'tools', '标准压力源');
            struct('step', 4, 'action', '检查补偿算法', 'time', '20分钟', 'tools', '配置软件');
            struct('step', 5, 'action', '更换压力传感器', 'time', '1小时', 'tools', '备用传感器')
        }});
    
    % 外部因素EXT-01
    db{end+1} = struct(...
        'fault_type', '数据波动型故障', ...
        'fault_code', 'EXT-01', ...
        'fault_name', '管路污染堵塞', ...
        'description', '管道或过滤器问题', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', {{
            struct('step', 1, 'action', '检查过滤器压差', 'time', '5分钟', 'tools', '压差表');
            struct('step', 2, 'action', '更换过滤器', 'time', '20分钟', 'tools', '备用滤芯');
            struct('step', 3, 'action', '吹扫采样管路', 'time', '30分钟', 'tools', '压缩空气');
            struct('step', 4, 'action', '检查管路泄漏', 'time', '45分钟', 'tools', '检漏仪');
            struct('step', 5, 'action', '更换采样管路', 'time', '2小时', 'tools', '备用管路')
        }});
    
    % 外部因素EXT-02
    db{end+1} = struct(...
        'fault_type', '数据波动型故障', ...
        'fault_code', 'EXT-02', ...
        'fault_name', '气路扭结泄漏', ...
        'description', '气路系统问题', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', {{
            struct('step', 1, 'action', '检查管路扭结', 'time', '5分钟', 'tools', '手电筒');
            struct('step', 2, 'action', '检查流量', 'time', '10分钟', 'tools', '流量计');
            struct('step', 3, 'action', '逐段检漏', 'time', '30分钟', 'tools', '检漏仪');
            struct('step', 4, 'action', '紧固接头', 'time', '20分钟', 'tools', '扳手');
            struct('step', 5, 'action', '重装气路', 'time', '3小时', 'tools', '全套管路')
        }});
end

% 获取维修建议函数
function advice = get_maintenance_advice(diag_code, maintenance_db)
    % 诊断代码到维修数据库代码的映射
    code_mapping = containers.Map();
    
    % 001 - 满量程输出
    code_mapping('001') = {'344', '301', '304', '305'};
    
    % 002 - 零位输出
    code_mapping('002') = {'345', '303', '302'};
    
    % 003 - 数据缺失
    code_mapping('003') = {'101', '116', '201-209', '300', '308', '318', '332-337', '338-339'};
    
    % 004 - 数据保持
    code_mapping('004') = {'301', '344', '345', '320'};
    
    % 005 - 剧烈波动
    code_mapping('005') = {'312', 'EXT-01', 'EXT-02', '319', '320'};
    
    % 006.01 - 小幅正向偏移
    code_mapping('006.01') = {'302', '320', '309-311'};
    
    % 006.02 - 小幅负向偏移
    code_mapping('006.02') = {'302', '320', '309-311'};
    
    % 006.03 - 大幅正向偏移
    code_mapping('006.03') = {'303', '304', '320', '319'};
    
    % 006.04 - 大幅负向偏移
    code_mapping('006.04') = {'303', '304', '320', '319'};
    
    % 006.05 - 严重正向偏移
    code_mapping('006.05') = {'303', '305', '319', '320'};
    
    % 006.06 - 严重负向偏移
    code_mapping('006.06') = {'303', '305', '319', '320'};
    
    % 获取对应的维修代码列表
    if isKey(code_mapping, diag_code)
        maint_codes = code_mapping(diag_code);
    else
        advice = '【维修建议】暂无对应的维修建议，请联系技术支持。';
        return;
    end
    
    % 构建维修建议文本
    advice = sprintf('\n【维修建议】');
    
    % 查找并显示所有相关的维修措施
    for i = 1:length(maint_codes)
        maint_code = maint_codes{i};
        
        % 在数据库中查找
        for j = 1:length(maintenance_db)
            if strcmp(maintenance_db{j}.fault_code, maint_code)
                fault_info = maintenance_db{j};
                
                advice = sprintf('%s\n  ┌─ 可能原因%d: %s (故障代码:%s)', ...
                    advice, i, fault_info.fault_name, fault_info.fault_code);
                advice = sprintf('%s\n  │  故障类型: %s', advice, fault_info.fault_type);
                advice = sprintf('%s\n  │  严重程度: %s', advice, fault_info.severity);
                advice = sprintf('%s\n  │  维修优先级: P%d', advice, fault_info.priority);
                advice = sprintf('%s\n  │', advice);
                advice = sprintf('%s\n  │  维修步骤:', advice);
                
                measures = fault_info.maintenance_measures{1};
                for k = 1:length(measures)
                    measure = measures{k};
                    advice = sprintf('%s\n  │    %d. %s', advice, measure.step, measure.action);
                    advice = sprintf('%s\n  │       预计时间: %s | 所需工具: %s', ...
                        advice, measure.time, measure.tools);
                end
                
                if i < length(maint_codes)
                    advice = sprintf('%s\n  │', advice);
                else
                    advice = sprintf('%s\n  └─────────────────────────────────────', advice);
                end
                
                break;
            end
        end
    end
    
    advice = sprintf('%s\n\n  ⚠ 建议：请按优先级从高到低依次检查上述可能原因', advice);
end
