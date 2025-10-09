%% MATLAB实时氧分析仪监控与诊断系统 v3.0
% 功能：模拟从DCS接收数据流，实现两级诊断机制
% 新增：统一故障编号体系、数据保持故障检测、优化报警机制
% 日期：2025年10月8日

clear; clc; close all;

%% ========================================
%% 系统配置部分
%% ========================================

fprintf('════════════════════════════════════════\n');
fprintf('   MATLAB实时氧分析仪监控系统 v3.0\n');
fprintf('════════════════════════════════════════\n\n');

% 系统参数配置
config = struct();
config.data_file = '1_twohour.xlsx';                % 数据文件名
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
thresholds.data_hold_threshold = 10;       % 数据保持检测阈值(连续相同值次数)

% 故障类型定义
fault_types = struct();
fault_types.full_scale = '001';            % 满量程输出
fault_types.zero_scale = '002';            % 零位输出
fault_types.data_loss = '003';             % 数据缺失
fault_types.data_hold = '004';             % 数据保持
fault_types.high_variance = '005';         % 剧烈波动异常
fault_types.data_offset = '006';           % 数据偏移

% 数据偏移子类型
offset_subtypes = struct();
offset_subtypes.small_positive = '006.01';  % 小幅正向偏移
offset_subtypes.small_negative = '006.02';  % 小幅负向偏移
offset_subtypes.large_positive = '006.03';  % 大幅正向偏移
offset_subtypes.large_negative = '006.04';  % 大幅负向偏移
offset_subtypes.severe_positive = '006.05'; % 严重正向偏移
offset_subtypes.severe_negative = '006.06'; % 严重负向偏移

fprintf('【系统配置】\n');
fprintf('  数据文件: %s\n', config.data_file);
fprintf('  起始时间: %s\n', datestr(config.start_time));
fprintf('  采样间隔: %d秒\n', config.sample_interval);
fprintf('  诊断周期: %d秒 (%.1f小时)\n', config.diagnosis_interval, config.diagnosis_interval/3600);
fprintf('  模拟速度: %dx\n', config.simulation_speed);
fprintf('\n');

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
stats.fault_counts(fault_types.full_scale) = 0;
stats.fault_counts(fault_types.zero_scale) = 0;
stats.fault_counts(fault_types.data_loss) = 0;
stats.fault_counts(fault_types.data_hold) = 0;
stats.fault_counts(fault_types.high_variance) = 0;
stats.fault_counts(fault_types.data_offset) = 0;
stats.diagnosis_count = 0;                 % 诊断次数

% 初始化数据保持检测变量
data_hold_count = 0;                       % 连续相同值计数
last_value = NaN;                          % 上一个值
data_hold_start_time = NaN;                % 数据保持开始时间

% 初始化报警状态跟踪
alarm_states = containers.Map();           % 各故障类型的报警状态
alarm_states(fault_types.full_scale) = false;
alarm_states(fault_types.zero_scale) = false;
alarm_states(fault_types.data_loss) = false;
alarm_states(fault_types.data_hold) = false;
last_alarm_times = containers.Map();       % 各故障类型最后报警时间

% 初始化日志
log_entries = {};
alarm_log = {};

% 初始化可视化
if config.enable_visualization
    fig = figure('Name', '实时氧分析仪监控系统 v3.0', ...
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
    h_stats_text = text(0.05, 0.9, '', 'FontSize', 10, 'FontName', 'FixedWidth');
    title('实时统计信息');
    
    % 诊断日志面板
    ax4 = subplot(2, 2, 4);
    axis off;
    h_log_text = text(0.05, 0.95, '', 'FontSize', 9, 'FontName', 'FixedWidth', ...
                     'VerticalAlignment', 'top');
    title('诊断日志（最近10条）');
    
    drawnow;
end

fprintf('  ✓ 系统初始化完成\n\n');

%% ========================================
%% 核心诊断函数
%% ========================================

% 实时异常检测函数
function [is_alarm, fault_code, alarm_msg] = realtime_detection(value, timestamp, thresholds, fault_types, data_hold_count, last_value)
    is_alarm = false;
    fault_code = '';
    alarm_msg = '';
    
    if isnan(value)
        is_alarm = true;
        fault_code = fault_types.data_loss;
        alarm_msg = sprintf('【故障%s】%s - 数据缺失！检测到NaN值', ...
                          fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'));
    elseif value >= thresholds.full_scale
        is_alarm = true;
        fault_code = fault_types.full_scale;
        alarm_msg = sprintf('【故障%s】%s - 满量程输出！当前值: %.4f%%', ...
                          fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), value);
    elseif value <= thresholds.zero_scale
        is_alarm = true;
        fault_code = fault_types.zero_scale;
        alarm_msg = sprintf('【故障%s】%s - 零位输出！当前值: %.4f%%', ...
                          fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), value);
    elseif ~isnan(last_value) && value == last_value && data_hold_count >= thresholds.data_hold_threshold
        is_alarm = true;
        fault_code = fault_types.data_hold;
        alarm_msg = sprintf('【故障%s】%s - 数据保持！值%.4f%%已保持%d次采样', ...
                          fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), ...
                          value, data_hold_count);
    end
end

% 定期综合诊断函数
function [diagnosis, fault_code, diagnosis_msg] = periodic_diagnosis(data, timestamp, thresholds, fault_types, offset_subtypes)
    % 去除NaN进行统计
    valid_data = data(~isnan(data));
    
    if isempty(valid_data)
        diagnosis = '数据缺失';
        fault_code = fault_types.data_loss;
        diagnosis_msg = sprintf('【故障%s】%s - 过去1小时数据全部缺失', ...
                              fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'));
        return;
    end
    
    % 计算统计特征
    data_mean = mean(valid_data);
    data_std = std(valid_data);
    offset = abs(data_mean - thresholds.normal_mean);
    
    % 诊断逻辑
    if data_std > thresholds.high_std
        diagnosis = '剧烈波动异常';
        fault_code = fault_types.high_variance;
        diagnosis_msg = sprintf('【故障%s】%s - 剧烈波动异常！标准差: %.4f%% (阈值: %.4f%%)', ...
                              fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), ...
                              data_std, thresholds.high_std);
    elseif data_mean > thresholds.normal_mean
        if offset <= thresholds.small_offset
            diagnosis = '小幅正向偏移';
            fault_code = offset_subtypes.small_positive;
            diagnosis_msg = sprintf('【故障%s】%s - 小幅正向偏移！均值: %.4f%% (偏移: +%.4f%%)', ...
                                  fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), ...
                                  data_mean, offset);
        elseif offset <= thresholds.large_offset
            diagnosis = '大幅正向偏移';
            fault_code = offset_subtypes.large_positive;
            diagnosis_msg = sprintf('【故障%s】%s - 大幅正向偏移！均值: %.4f%% (偏移: +%.4f%%)', ...
                                  fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), ...
                                  data_mean, offset);
        else
            diagnosis = '严重正向偏移';
            fault_code = offset_subtypes.severe_positive;
            diagnosis_msg = sprintf('【故障%s】%s - 严重正向偏移！均值: %.4f%% (偏移: +%.4f%%)', ...
                                  fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), ...
                                  data_mean, offset);
        end
    elseif data_mean < thresholds.normal_mean
        if offset <= thresholds.small_offset
            diagnosis = '小幅负向偏移';
            fault_code = offset_subtypes.small_negative;
            diagnosis_msg = sprintf('【故障%s】%s - 小幅负向偏移！均值: %.4f%% (偏移: -%.4f%%)', ...
                                  fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), ...
                                  data_mean, offset);
        elseif offset <= thresholds.large_offset
            diagnosis = '大幅负向偏移';
            fault_code = offset_subtypes.large_negative;
            diagnosis_msg = sprintf('【故障%s】%s - 大幅负向偏移！均值: %.4f%% (偏移: -%.4f%%)', ...
                                  fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), ...
                                  data_mean, offset);
        else
            diagnosis = '严重负向偏移';
            fault_code = offset_subtypes.severe_negative;
            diagnosis_msg = sprintf('【故障%s】%s - 严重负向偏移！均值: %.4f%% (偏移: -%.4f%%)', ...
                                  fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), ...
                                  data_mean, offset);
        end
    else
        diagnosis = '正常工况';
        fault_code = '000';
        diagnosis_msg = sprintf('【正常】%s - 正常工况！均值: %.4f%%, 标准差: %.4f%%', ...
                              datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), ...
                              data_mean, data_std);
    end
    
    % 附加统计信息
    diagnosis_msg = sprintf('%s\n    数据统计: 有效点数=%d, 最大=%.4f%%, 最小=%.4f%%', ...
                          diagnosis_msg, length(valid_data), ...
                          max(valid_data), min(valid_data));
end

% 检查是否需要周期性报警（每10分钟）
function should_report = should_periodic_report(fault_code, current_time, last_alarm_times)
    should_report = false;
    
    % 实时监测类故障（001-004）
    realtime_faults = {'001', '002', '003', '004'};
    
    if any(strcmp(fault_code, realtime_faults))
        if isKey(last_alarm_times, fault_code)
            last_time = last_alarm_times(fault_code);
            time_diff = etime(datevec(current_time), datevec(last_time));
            should_report = time_diff >= 600; % 10分钟 = 600秒
        else
            should_report = true; % 首次报警
        end
    else
        should_report = true; % 非实时监测类故障直接报告
    end
end

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
    
    % 更新数据保持检测
    if ~isnan(current_value) && ~isnan(last_value) && current_value == last_value
        data_hold_count = data_hold_count + 1;
    else
        data_hold_count = 1;
        if ~isnan(current_value)
            data_hold_start_time = current_time;
        end
    end
    
    % ====== 实时异常检测 ======
    [is_alarm, fault_code, alarm_msg] = realtime_detection(current_value, current_time, ...
                                                          thresholds, fault_types, ...
                                                          data_hold_count, last_value);
    
    if is_alarm
        % 检查是否需要报告
        if should_periodic_report(fault_code, current_time, last_alarm_times)
            stats.total_alarms = stats.total_alarms + 1;
            
            % 统计各类故障
            if isKey(stats.fault_counts, fault_code)
                stats.fault_counts(fault_code) = stats.fault_counts(fault_code) + 1;
            else
                stats.fault_counts(fault_code) = 1;
            end
            
            % 记录报警
            alarm_log{end+1} = alarm_msg;
            alarm_times(end+1) = (i-1) * config.sample_interval;
            alarm_values(end+1) = current_value;
            
            % 更新报警状态和时间
            alarm_states(fault_code) = true;
            last_alarm_times(fault_code) = current_time;
            
            % 显示报警
            fprintf('\a'); % 蜂鸣器
            fprintf('%s\n', alarm_msg);
        end
    else
        % 重置相关故障的报警状态
        if ~isnan(current_value)
            if current_value < thresholds.full_scale
                alarm_states(fault_types.full_scale) = false;
            end
            if current_value > thresholds.zero_scale
                alarm_states(fault_types.zero_scale) = false;
            end
            if current_value ~= last_value
                alarm_states(fault_types.data_hold) = false;
            end
        end
        if ~isnan(current_value)
            alarm_states(fault_types.data_loss) = false;
        end
    end
    
    % ====== 定期综合诊断 ======
    if sample_count >= config.diagnosis_interval && ...
       mod(sample_count, config.diagnosis_interval) == 0
        
        stats.diagnosis_count = stats.diagnosis_count + 1;
        
        % 执行诊断
        [diagnosis, fault_code, diagnosis_msg] = periodic_diagnosis(data_buffer, current_time, ...
                                                                   thresholds, fault_types, offset_subtypes);
        
        % 记录诊断
        log_entries{end+1} = diagnosis_msg;
        
        % 统计故障
        if ~strcmp(fault_code, '000')
            if isKey(stats.fault_counts, fault_code)
                stats.fault_counts(fault_code) = stats.fault_counts(fault_code) + 1;
            else
                stats.fault_counts(fault_code) = 1;
            end
        end
        
        % 显示诊断结果
        fprintf('\n%s\n\n', diagnosis_msg);
    end
    
    % 更新上一个值
    last_value = current_value;
    
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
        fault_summary = '';
        fault_keys = keys(stats.fault_counts);
        for k = 1:length(fault_keys)
            key = fault_keys{k};
            count = stats.fault_counts(key);
            if count > 0
                fault_summary = [fault_summary sprintf('  故障%s: %d\n', key, count)];
            end
        end
        
        stats_text = sprintf(['监控时长: %.2f小时\n' ...
                            '处理样本: %d/%d\n' ...
                            '━━━━━━━━━━━━━━━━\n' ...
                            '总报警数: %d\n' ...
                            '诊断次数: %d\n' ...
                            '━━━━━━━━━━━━━━━━\n' ...
                            '故障统计:\n%s' ...
                            '当前值: %.4f%%\n' ...
                            '当前时间: %s'], ...
                            sample_count/3600, sample_count, total_samples, ...
                            stats.total_alarms, stats.diagnosis_count, ...
                            fault_summary, current_value, ...
                            datestr(current_time, 'HH:MM:SS'));
        set(h_stats_text, 'String', stats_text);
        
        % 更新日志显示（最近10条）
        all_logs = [alarm_log, log_entries];
        if ~isempty(all_logs)
            recent_logs = all_logs(max(1, end-9):end);
            log_text = strjoin(recent_logs, '\n');
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
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

% 显示各故障类型统计
fault_keys = keys(stats.fault_counts);
fault_names = {'001-满量程输出', '002-零位输出', '003-数据缺失', '004-数据保持', ...
               '005-剧烈波动', '006-数据偏移'};

for k = 1:length(fault_keys)
    key = fault_keys{k};
    count = stats.fault_counts(key);
    if count > 0
        % 根据故障代码确定名称
        if strcmp(key, '001')
            name = '001-满量程输出';
        elseif strcmp(key, '002')
            name = '002-零位输出';
        elseif strcmp(key, '003')
            name = '003-数据缺失';
        elseif strcmp(key, '004')
            name = '004-数据保持';
        elseif strcmp(key, '005')
            name = '005-剧烈波动';
        elseif startsWith(key, '006')
            name = sprintf('006-数据偏移(%s)', key);
        else
            name = key;
        end
        
        fprintf('  %s: %d次 (%.2f%%)\n', name, count, count/total_samples*100);
    end
end

fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n');

% 保存报告到文件
if config.save_log
    % 生成报告文件名
    report_filename = sprintf('O2_Monitor_Report_v3_%s.txt', ...
                            datestr(now, 'yyyymmdd_HHMMSS'));
    
    fid = fopen(report_filename, 'w', 'n', 'UTF-8');
    
    fprintf(fid, '════════════════════════════════════════\n');
    fprintf(fid, '   氧分析仪实时监控系统报告 v3.0\n');
    fprintf(fid, '════════════════════════════════════════\n\n');
    fprintf(fid, '生成时间: %s\n', datestr(now));
    fprintf(fid, '数据文件: %s\n', config.data_file);
    fprintf(fid, '起始时间: %s\n', datestr(config.start_time));
    fprintf(fid, '监控时长: %.2f小时\n\n', total_duration/3600);
    
    fprintf(fid, '【监控统计】\n');
    fprintf(fid, '处理样本数: %d\n', total_samples);
    fprintf(fid, '诊断次数: %d\n', stats.diagnosis_count);
    fprintf(fid, '总报警次数: %d\n\n', stats.total_alarms);
    
    fprintf(fid, '【故障统计】\n');
    for k = 1:length(fault_keys)
        key = fault_keys{k};
        count = stats.fault_counts(key);
        if count > 0
            if strcmp(key, '001')
                name = '001-满量程输出';
            elseif strcmp(key, '002')
                name = '002-零位输出';
            elseif strcmp(key, '003')
                name = '003-数据缺失';
            elseif strcmp(key, '004')
                name = '004-数据保持';
            elseif strcmp(key, '005')
                name = '005-剧烈波动';
            elseif startsWith(key, '006')
                name = sprintf('006-数据偏移(%s)', key);
            else
                name = key;
            end
            fprintf(fid, '%s: %d次\n', name, count);
        end
    end
    fprintf(fid, '\n');
    
    fprintf(fid, '【实时报警记录】\n');
    fprintf(fid, '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    for j = 1:length(alarm_log)
        fprintf(fid, '%s\n', alarm_log{j});
    end
    fprintf(fid, '\n');
    
    fprintf(fid, '【定期诊断记录】\n');
    fprintf(fid, '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
    for j = 1:length(log_entries)
        fprintf(fid, '%s\n', log_entries{j});
    end
    
    fclose(fid);
    fprintf('监控报告已保存至: %s\n', report_filename);
    
    % 保存报警数据到Excel
    if stats.total_alarms > 0
        alarm_excel = sprintf('O2_Alarms_v3_%s.xlsx', datestr(now, 'yyyymmdd_HHMMSS'));
        
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
    fig_filename = sprintf('O2_Monitor_Final_v3_%s.png', ...
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

fprintf('\n【故障类型说明】\n');
fprintf('001-满量程输出: 氧浓度达到或超过满量程阈值\n');
fprintf('002-零位输出: 氧浓度达到或低于零位阈值\n');
fprintf('003-数据缺失: 检测到NaN值或数据丢失\n');
fprintf('004-数据保持: 数据值连续保持不变超过阈值\n');
fprintf('005-剧烈波动: 数据标准差超过正常范围\n');
fprintf('006-数据偏移: 数据均值偏离正常值\n');
fprintf('  006.01-小幅正向偏移  006.02-小幅负向偏移\n');
fprintf('  006.03-大幅正向偏移  006.04-大幅负向偏移\n');
fprintf('  006.05-严重正向偏移  006.06-严重负向偏移\n');

fprintf('\n════════════════════════════════════════\n');
fprintf('         程序执行完成\n');
fprintf('════════════════════════════════════════\n');