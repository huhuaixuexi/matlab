clear; clc; close all;

%% ========================================
%% 氧分析仪智能诊断维护系统 - 修复版
%% ========================================

fprintf('════════════════════════════════════════\n');
fprintf('   氧分析仪智能诊断维护系统 v5.1\n');
fprintf('      完整集成版（修复版）\n');
fprintf('════════════════════════════════════════\n\n');

%% ========================================
%% 系统配置部分
%% ========================================

% 系统参数配置
config = struct();
config.data_file = '7_twohour.xlsx';                % 数据文件名
config.sheet_name = 'Sheet1';                       % 工作表名
config.start_time = datetime(2025,10,8,0,0,0);      % 起始时间
config.sample_interval = 1;                         % 采样间隔(秒)
config.diagnosis_interval = 3600;                   % 诊断间隔(1小时=3600秒)
config.simulation_speed = 100;                      % 模拟速度(1=实时,100=100倍速)
config.enable_visualization = true;                 % 是否启用实时可视化
config.save_log = true;                             % 是否保存日志
config.show_maintenance_advice = true;              % 是否显示维修建议

% 诊断阈值配置
thresholds = struct();
thresholds.full_scale = 9.95;                       % 满量程阈值(%)
thresholds.zero_scale = 0.05;                       % 零位阈值(%)
thresholds.normal_mean = 5.0;                       % 正常均值(%)
thresholds.small_offset = 0.5;                      % 小幅偏移阈值(%)
thresholds.large_offset = 1.5;                      % 大幅偏移阈值(%)
thresholds.normal_std = 0.1;                        % 正常标准差(%)
thresholds.high_std = 0.5;                          % 剧烈波动标准差阈值(%)
thresholds.data_hold_threshold = 0.001;             % 数据保持阈值(%)
thresholds.data_hold_duration = 300;                % 数据保持持续时间(秒)

% 故障类型编号体系
fault_types = struct();
fault_types.full_scale = '001';                     % 满量程输出
fault_types.zero_scale = '002';                     % 零位输出
fault_types.data_missing = '003';                   % 数据缺失
fault_types.data_hold = '004';                      % 数据保持
fault_types.severe_fluctuation = '005';             % 剧烈波动异常
fault_types.data_offset = '006';                    % 数据偏移

% 数据偏移子类型
offset_subtypes = struct();
offset_subtypes.small_positive = '006.01';          % 小幅正向偏移
offset_subtypes.small_negative = '006.02';          % 小幅负向偏移
offset_subtypes.large_positive = '006.03';          % 大幅正向偏移
offset_subtypes.large_negative = '006.04';          % 大幅负向偏移
offset_subtypes.severe_positive = '006.05';         % 严重正向偏移
offset_subtypes.severe_negative = '006.06';         % 严重负向偏移

%% ========================================
%% 维修建议数据库初始化
%% ========================================

% 初始化维修建议数据库
maintenance_db = init_maintenance_database();

% 建立诊断代码到维修建议代码的映射
fault_mapping = containers.Map();
fault_mapping('001') = {'344', '301'};                          % 满量程输出
fault_mapping('002') = {'345', '303', '302'};                   % 零位输出
fault_mapping('003') = {'101', '201-209', '300', '308', '318', '332-337', '338-339'}; % 数据缺失
fault_mapping('004') = {'301', '318', '300'};                   % 数据保持
fault_mapping('005') = {'312', 'EXT-01', 'EXT-02', '319'};      % 剧烈波动
fault_mapping('006.01') = {'302', '309-311'};                   % 小幅正向偏移
fault_mapping('006.02') = {'302', '309-311'};                   % 小幅负向偏移
fault_mapping('006.03') = {'303', '304', '320'};                % 大幅正向偏移
fault_mapping('006.04') = {'303', '304', '320'};                % 大幅负向偏移
fault_mapping('006.05') = {'305', '319'};                       % 严重正向偏移
fault_mapping('006.06') = {'305', '319'};                       % 严重负向偏移

fprintf('【系统配置】\n');
fprintf('  数据文件: %s\n', config.data_file);
fprintf('  起始时间: %s\n', datestr(config.start_time));
fprintf('  采样间隔: %d秒\n', config.sample_interval);
fprintf('  诊断周期: %d秒 (%.1f小时)\n', config.diagnosis_interval, config.diagnosis_interval/3600);
fprintf('  模拟速度: %dx\n', config.simulation_speed);
fprintf('  维修建议: %s\n', iif(config.show_maintenance_advice, '启用', '禁用'));
fprintf('  维修数据库: 已加载 %d 条故障记录\n\n', length(fieldnames(maintenance_db)));

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
data_buffer = NaN(buffer_size, 1);                  % 1小时数据缓冲
buffer_index = 0;                                   % 缓冲区索引

% 初始化统计变量
stats = struct();
stats.total_alarms = 0;                            % 总报警次数
stats.fault_counts = containers.Map();              % 各故障类型计数
stats.diagnosis_count = 0;                          % 诊断次数
stats.maintenance_suggestions = {};                 % 维修建议记录

% 初始化故障类型计数（确保所有类型都初始化）
fault_type_names = {'001', '002', '003', '004', '005', '006.01', '006.02', '006.03', '006.04', '006.05', '006.06'};
for i = 1:length(fault_type_names)
     stats.fault_counts(fault_type_names{i}) = 0;
end

% 初始化日志
log_entries = {};
alarm_log = {};
maintenance_log = {};

% 初始化数据保持检测变量
data_hold_detector = struct();
data_hold_detector.last_value = NaN;
data_hold_detector.hold_start_time = NaN;
data_hold_detector.hold_duration = 0;
data_hold_detector.is_holding = false;

% 初始化周期性报警控制
periodic_alarm_control = struct();
periodic_alarm_control.last_alarm_time = containers.Map();
periodic_alarm_control.alarm_interval = 600;        % 10分钟 = 600秒

% 初始化可视化
if config.enable_visualization
     % 创建更大的窗口
     fig = figure('Name', '氧分析仪智能诊断维护系统 v5.1 - 修复版', ...
                 'Position', [30, 30, 1800, 1000], ...
                 'NumberTitle', 'off');
     
     % 创建两个主要面板
     % 左侧面板 - 数据显示
     panel_left = uipanel('Parent', fig, 'Position', [0.01 0.01 0.48 0.98]);
     
     % 右侧面板 - 维修建议
     panel_right = uipanel('Parent', fig, 'Position', [0.51 0.01 0.48 0.98]);
     
     % === 左侧面板内容 ===
     % 实时数据显示窗口
     ax1 = subplot(2, 2, 1, 'Parent', panel_left);
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
     ax2 = subplot(2, 2, 2, 'Parent', panel_left);
     h_buffer = plot(NaN, NaN, 'b-', 'LineWidth', 1);
     xlabel('时间 (小时)');
     ylabel('氧浓度 (%)');
     title('1小时数据窗口');
     grid on;
     xlim([0, 1]);
     ylim([-0.5, 10.5]);
     
     % 统计信息面板
     ax3 = subplot(2, 2, 3, 'Parent', panel_left);
     axis off;
     h_stats_text = text(0.05, 0.9, '', 'FontSize', 9, 'FontName', 'FixedWidth');
     title('实时统计信息');
     
     % 诊断日志面板
     ax4 = subplot(2, 2, 4, 'Parent', panel_left);
     axis off;
     h_log_text = text(0.05, 0.95, '', 'FontSize', 8, 'FontName', 'FixedWidth', ...
                      'VerticalAlignment', 'top');
     title('诊断日志（最近5条）');
     
     % === 右侧面板内容 - 维修建议 ===
     ax5 = axes('Parent', panel_right, 'Position', [0.05 0.05 0.9 0.9]);
     axis off;
     h_maintenance_text = text(0.02, 0.98, '', 'FontSize', 7, 'FontName', 'FixedWidth', ...
                              'VerticalAlignment', 'top', 'HorizontalAlignment', 'left');
     title('维修建议详情', 'FontSize', 12, 'FontWeight', 'bold');
     
     drawnow;
end

fprintf('  ✓ 系统初始化完成\n');
fprintf('  ✓ 维修建议数据库加载完成\n\n');

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
current_maintenance_advice = struct();
current_maintenance_advice.all_suggestions = {};

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
     [is_alarm, fault_code, alarm_msg, maintenance_advice] = realtime_detection_enhanced(...
         current_value, current_time, thresholds, fault_types, offset_subtypes, ...
         data_hold_detector, config.sample_interval, fault_mapping, maintenance_db);
     
     if is_alarm
         % 检查是否应该报警（周期性控制）
         should_alarm = check_periodic_alarm(fault_code, current_time, periodic_alarm_control);
         
         if should_alarm
             stats.total_alarms = stats.total_alarms + 1;
             
             % 统计各类报警
             if isKey(stats.fault_counts, fault_code)
                 stats.fault_counts(fault_code) = stats.fault_counts(fault_code) + 1;
             else
                 stats.fault_counts(fault_code) = 1;
             end
             
             % 记录报警
             alarm_log{end+1} = alarm_msg;
             alarm_times(end+1) = (i-1) * config.sample_interval;
             alarm_values(end+1) = current_value;
             
             % 显示报警
             fprintf('\a'); % 蜂鸣器
             fprintf('%s\n', alarm_msg);
             
             % 显示维修建议
             if config.show_maintenance_advice && isfield(maintenance_advice, 'all_suggestions') && ~isempty(maintenance_advice.all_suggestions)
                 advice_text = format_maintenance_advice(maintenance_advice);
                 fprintf('%s\n', advice_text);
                 maintenance_log{end+1} = [alarm_msg advice_text];
                 current_maintenance_advice = maintenance_advice;
             end
         end
     end
     
     % ====== 定期综合诊断 ======
     if sample_count >= config.diagnosis_interval && ...
        mod(sample_count, config.diagnosis_interval) == 0
         
         stats.diagnosis_count = stats.diagnosis_count + 1;
         
         % 执行诊断
         [fault_code, diagnosis_msg, maintenance_advice] = periodic_diagnosis_enhanced(...
             data_buffer, current_time, thresholds, fault_types, offset_subtypes, ...
             fault_mapping, maintenance_db);
         
         % 记录诊断
         log_entries{end+1} = diagnosis_msg;
         
         % 显示诊断结果
         fprintf('\n%s\n', diagnosis_msg);
         
         % 统计定期诊断的故障（非正常状态）
         if ~strcmp(fault_code, 'NORMAL')
             stats.total_alarms = stats.total_alarms + 1;
             if isKey(stats.fault_counts, fault_code)
                 stats.fault_counts(fault_code) = stats.fault_counts(fault_code) + 1;
             else
                 stats.fault_counts(fault_code) = 1;
             end
         end
         
         % 显示维修建议
         if config.show_maintenance_advice && ~strcmp(fault_code, 'NORMAL') && isfield(maintenance_advice, 'all_suggestions') && ~isempty(maintenance_advice.all_suggestions)
             advice_text = format_maintenance_advice(maintenance_advice);
             fprintf('%s\n', advice_text);
             maintenance_log{end+1} = [diagnosis_msg advice_text];
             current_maintenance_advice = maintenance_advice;
         end
         
         fprintf('\n');
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
         
         % 计算006总数
         offset_total = 0;
         offset_codes = {'006.01', '006.02', '006.03', '006.04', '006.05', '006.06'};
         for k = 1:length(offset_codes)
             if isKey(stats.fault_counts, offset_codes{k})
                 offset_total = offset_total + stats.fault_counts(offset_codes{k});
             end
         end
         
         % 更新统计信息
         stats_text = sprintf(['监控时长: %.2f小时\n' ...
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
                             iif(isKey(stats.fault_counts,'001'), stats.fault_counts('001'), 0), ...
                             iif(isKey(stats.fault_counts,'002'), stats.fault_counts('002'), 0), ...
                             iif(isKey(stats.fault_counts,'003'), stats.fault_counts('003'), 0), ...
                             iif(isKey(stats.fault_counts,'004'), stats.fault_counts('004'), 0), ...
                             iif(isKey(stats.fault_counts,'005'), stats.fault_counts('005'), 0), ...
                             offset_total, ...
                             stats.diagnosis_count, ...
                             current_value, ...
                             datestr(current_time, 'HH:MM:SS'));
         set(h_stats_text, 'String', stats_text);
         
         % 更新日志显示（最近5条）
         all_logs = [alarm_log, log_entries];
         if ~isempty(all_logs)
             recent_logs = all_logs(max(1, end-4):end);
             log_text = strjoin(recent_logs, '\n');
             set(h_log_text, 'String', log_text);
         end
         
         % 更新维修建议显示（充分利用右侧面板空间）
         if ~isempty(current_maintenance_advice) && isfield(current_maintenance_advice, 'all_suggestions') && ~isempty(current_maintenance_advice.all_suggestions)
             maint_text = sprintf('【当前故障维修建议汇总】\n');
             maint_text = [maint_text sprintf('共有 %d 种可能的故障原因\n', length(current_maintenance_advice.all_suggestions))];
             maint_text = [maint_text sprintf('═══════════════════════════════════════════════════════════\n\n')];
             
             % 显示所有故障原因（右侧面板有足够空间）
             for k = 1:length(current_maintenance_advice.all_suggestions)
                 suggestion = current_maintenance_advice.all_suggestions{k};
                 
                 maint_text = [maint_text sprintf('【故障%d】故障代码: %s - %s\n', ...
                                                k, suggestion.fault_code, suggestion.fault_name)];
                 maint_text = [maint_text sprintf('故障描述: %s\n', suggestion.description)];
                 maint_text = [maint_text sprintf('严重程度: %s | 优先级: %d\n', ...
                                                suggestion.severity, suggestion.priority)];
                 maint_text = [maint_text sprintf('维修措施:\n')];
                 
                 % 显示所有步骤
                 if iscell(suggestion.measures)
                     for j = 1:length(suggestion.measures)
                         measure = suggestion.measures{j};
                         maint_text = [maint_text sprintf('  步骤%d: %s\n', ...
                                                        measure.step, measure.action)];
                         maint_text = [maint_text sprintf('         耗时: %s | 工具: %s\n', ...
                                                        measure.time, measure.tools)];
                     end
                 elseif isstruct(suggestion.measures)
                     for j = 1:length(suggestion.measures)
                         measure = suggestion.measures(j);
                         maint_text = [maint_text sprintf('  步骤%d: %s\n', ...
                                                        measure.step, measure.action)];
                         maint_text = [maint_text sprintf('         耗时: %s | 工具: %s\n', ...
                                                        measure.time, measure.tools)];
                     end
                 end
                 
                 if k < length(current_maintenance_advice.all_suggestions)
                     maint_text = [maint_text sprintf('\n───────────────────────────────────────────────────────────\n\n')];
                 end
             end
             
             maint_text = [maint_text sprintf('\n═══════════════════════════════════════════════════════════\n')];
             
             set(h_maintenance_text, 'String', maint_text);
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

% 计算006总数
offset_total = 0;
offset_codes = {'006.01', '006.02', '006.03', '006.04', '006.05', '006.06'};
for k = 1:length(offset_codes)
    if isKey(stats.fault_counts, offset_codes{k})
        offset_total = offset_total + stats.fault_counts(offset_codes{k});
    end
end

fprintf('【监控统计总结】\n');
fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
fprintf('监控时长: %.2f小时 (%.2f天)\n', total_duration/3600, total_duration/86400);
fprintf('处理样本数: %d\n', total_samples);
fprintf('诊断次数: %d\n\n', stats.diagnosis_count);

fprintf('【故障统计】\n');
fprintf('总报警次数: %d\n', stats.total_alarms);
fprintf('  001-满量程输出: %d次 (%.2f%%)\n', ...
       iif(isKey(stats.fault_counts,'001'), stats.fault_counts('001'), 0), ...
       iif(isKey(stats.fault_counts,'001'), stats.fault_counts('001'), 0)/total_samples*100);
fprintf('  002-零位输出: %d次 (%.2f%%)\n', ...
       iif(isKey(stats.fault_counts,'002'), stats.fault_counts('002'), 0), ...
       iif(isKey(stats.fault_counts,'002'), stats.fault_counts('002'), 0)/total_samples*100);
fprintf('  003-数据缺失: %d次 (%.2f%%)\n', ...
       iif(isKey(stats.fault_counts,'003'), stats.fault_counts('003'), 0), ...
       iif(isKey(stats.fault_counts,'003'), stats.fault_counts('003'), 0)/total_samples*100);
fprintf('  004-数据保持: %d次 (%.2f%%)\n', ...
       iif(isKey(stats.fault_counts,'004'), stats.fault_counts('004'), 0), ...
       iif(isKey(stats.fault_counts,'004'), stats.fault_counts('004'), 0)/total_samples*100);
fprintf('  005-剧烈波动异常: %d次 (%.2f%%)\n', ...
       iif(isKey(stats.fault_counts,'005'), stats.fault_counts('005'), 0), ...
       iif(isKey(stats.fault_counts,'005'), stats.fault_counts('005'), 0)/total_samples*100);
fprintf('  006-数据偏移: %d次 (%.2f%%)\n', offset_total, offset_total/total_samples*100);

for k = 1:length(offset_codes)
    code = offset_codes{k};
    if isKey(stats.fault_counts, code) && stats.fault_counts(code) > 0
        switch code
            case '006.01'
                name = '小幅正向偏移';
            case '006.02'
                name = '小幅负向偏移';
            case '006.03'
                name = '大幅正向偏移';
            case '006.04'
                name = '大幅负向偏移';
            case '006.05'
                name = '严重正向偏移';
            case '006.06'
                name = '严重负向偏移';
        end
        fprintf('    %s-%s: %d次\n', code, name, stats.fault_counts(code));
    end
end

fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n');

% 保存报告到文件
if config.save_log
     % 生成报告文件名
     report_filename = sprintf('O2_Diagnosis_Report_%s.txt', ...
                             datestr(now, 'yyyymmdd_HHMMSS'));
     
     fid = fopen(report_filename, 'w', 'n', 'UTF-8');
     
     fprintf(fid, '════════════════════════════════════════\n');
     fprintf(fid, '   氧分析仪智能诊断维护系统报告\n');
     fprintf(fid, '       完整集成版 v5.1\n');
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
     fprintf(fid, '001-满量程输出: %d次\n', iif(isKey(stats.fault_counts,'001'), stats.fault_counts('001'), 0));
     fprintf(fid, '002-零位输出: %d次\n', iif(isKey(stats.fault_counts,'002'), stats.fault_counts('002'), 0));
     fprintf(fid, '003-数据缺失: %d次\n', iif(isKey(stats.fault_counts,'003'), stats.fault_counts('003'), 0));
     fprintf(fid, '004-数据保持: %d次\n', iif(isKey(stats.fault_counts,'004'), stats.fault_counts('004'), 0));
     fprintf(fid, '005-剧烈波动异常: %d次\n', iif(isKey(stats.fault_counts,'005'), stats.fault_counts('005'), 0));
     fprintf(fid, '006-数据偏移: %d次\n', offset_total);
     
     for k = 1:length(offset_codes)
         code = offset_codes{k};
         if isKey(stats.fault_counts, code) && stats.fault_counts(code) > 0
             switch code
                 case '006.01'
                     name = '小幅正向偏移';
                 case '006.02'
                     name = '小幅负向偏移';
                 case '006.03'
                     name = '大幅正向偏移';
                 case '006.04'
                     name = '大幅负向偏移';
                 case '006.05'
                     name = '严重正向偏移';
                 case '006.06'
                     name = '严重负向偏移';
             end
             fprintf(fid, '  %s-%s: %d次\n', code, name, stats.fault_counts(code));
         end
     end
     fprintf(fid, '\n');
     
     fprintf(fid, '【实时报警记录（含维修建议）】\n');
     fprintf(fid, '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
     for j = 1:length(maintenance_log)
         fprintf(fid, '%s\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n', maintenance_log{j});
     end
     fprintf(fid, '\n');
     
     fprintf(fid, '【定期诊断记录】\n');
     fprintf(fid, '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
     for j = 1:length(log_entries)
         fprintf(fid, '%s\n', log_entries{j});
     end
     
     % 添加故障代码映射表
     fprintf(fid, '\n\n【故障代码映射表】\n');
     fprintf(fid, '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
     fprintf(fid, '诊断代码 | 可能的维修故障代码\n');
     fprintf(fid, '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
     
     keys_list = keys(fault_mapping);
     for k = 1:length(keys_list)
         key = keys_list{k};
         values = fault_mapping(key);
         fprintf(fid, '%s     | %s\n', key, strjoin(values, ', '));
     end
     
     fclose(fid);
     fprintf('监控报告已保存至: %s\n', report_filename);
     
     % 保存报警数据到Excel
     if stats.total_alarms > 0
         alarm_excel = sprintf('O2_Alarms_%s.xlsx', datestr(now, 'yyyymmdd_HHMMSS'));
         
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
     fig_filename = sprintf('O2_Diagnosis_Figure_%s.png', ...
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

fprintf('\n【系统功能说明】\n');
fprintf('✓ 实时异常检测（001-004）\n');
fprintf('✓ 定期综合诊断（005-006）\n');
fprintf('✓ 数据保持型故障检测\n');
fprintf('✓ 智能维修建议匹配\n');
fprintf('✓ 显示所有可能的故障原因\n');
fprintf('✓ 完整的故障统计分析\n');
fprintf('✓ 可视化监控界面\n');

fprintf('\n════════════════════════════════════════\n');
fprintf('         程序执行完成\n');
fprintf('════════════════════════════════════════\n');

%% ========================================
%% 核心诊断函数定义
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

% 获取维修建议函数（增强版 - 返回所有可能的维修建议）
function maintenance_advice = get_maintenance_advice(fault_code, fault_mapping, maintenance_db)
    maintenance_advice = struct();
    maintenance_advice.all_suggestions = {};  % 存储所有可能的维修建议
    
    if ~isKey(fault_mapping, fault_code)
        return;
    end
    
    % 获取可能的维修故障代码
    possible_codes = fault_mapping(fault_code);
    
    % 收集所有匹配的维修建议
    for i = 1:length(possible_codes)
        maint_code = possible_codes{i};
        field_name = ['code_' strrep(maint_code, '-', '_')];
        
        if isfield(maintenance_db, field_name)
            maint_info = maintenance_db.(field_name);
            
            % 创建单个建议结构
            single_advice = struct();
            single_advice.fault_code = maint_code;
            single_advice.fault_name = maint_info.fault_name;
            single_advice.measures = maint_info.maintenance_measures;
            single_advice.severity = maint_info.severity;
            single_advice.priority = maint_info.priority;
            single_advice.description = maint_info.description;
            
            % 添加到建议列表
            maintenance_advice.all_suggestions{end+1} = single_advice;
        end
    end
    
    % 按优先级排序（优先级1最高）
    if ~isempty(maintenance_advice.all_suggestions)
        priorities = cellfun(@(x) x.priority, maintenance_advice.all_suggestions);
        [~, idx] = sort(priorities);
        maintenance_advice.all_suggestions = maintenance_advice.all_suggestions(idx);
    end
end

% 格式化维修建议文本（增强版 - 显示所有可能的维修建议）
function advice_text = format_maintenance_advice(maintenance_advice)
    if ~isfield(maintenance_advice, 'all_suggestions') || isempty(maintenance_advice.all_suggestions)
        advice_text = '';
        return;
    end
    
    advice_text = sprintf('\n【维修建议汇总】共有 %d 种可能的故障原因\n', length(maintenance_advice.all_suggestions));
    advice_text = [advice_text sprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n')];
    
    % 遍历所有可能的维修建议
    for j = 1:length(maintenance_advice.all_suggestions)
        suggestion = maintenance_advice.all_suggestions{j};
        
        advice_text = [advice_text sprintf('\n【故障%d】故障代码: %s - %s\n', ...
                                         j, suggestion.fault_code, suggestion.fault_name)];
        advice_text = [advice_text sprintf('故障描述: %s\n', suggestion.description)];
        advice_text = [advice_text sprintf('严重程度: %s | 优先级: %d\n', ...
                                         suggestion.severity, suggestion.priority)];
        advice_text = [advice_text sprintf('维修措施:\n')];
        
        % 获取measures的数量
        if iscell(suggestion.measures)
            num_measures = length(suggestion.measures);
            % 显示所有措施
            for i = 1:num_measures
                measure = suggestion.measures{i};
                advice_text = [advice_text sprintf('  步骤%d: %s\n', measure.step, measure.action)];
                advice_text = [advice_text sprintf('         耗时: %s | 工具: %s\n', ...
                                                 measure.time, measure.tools)];
            end
        elseif isstruct(suggestion.measures)
            num_measures = length(suggestion.measures);
            % 显示所有措施
            for i = 1:num_measures
                measure = suggestion.measures(i);
                advice_text = [advice_text sprintf('  步骤%d: %s\n', measure.step, measure.action)];
                advice_text = [advice_text sprintf('         耗时: %s | 工具: %s\n', ...
                                                 measure.time, measure.tools)];
            end
        else
            num_measures = 0;
            advice_text = [advice_text sprintf('  （无维修措施）\n')];
        end
        
        if j < length(maintenance_advice.all_suggestions)
            advice_text = [advice_text sprintf('\n────────────────────────────────────────\n')];
        end
    end
    
    advice_text = [advice_text sprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n')];
end

% 实时异常检测函数（增强版）
function [is_alarm, fault_code, alarm_msg, maintenance_advice] = realtime_detection_enhanced(value, timestamp, thresholds, fault_types, offset_subtypes, detector, sample_interval, fault_mapping, maintenance_db)
     is_alarm = false;
     fault_code = '';
     alarm_msg = '';
     maintenance_advice = struct();
     maintenance_advice.all_suggestions = {};
     
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
     
     % 如果有报警，获取维修建议
     if is_alarm
         maintenance_advice = get_maintenance_advice(fault_code, fault_mapping, maintenance_db);
     end
end

% 定期综合诊断函数（增强版）
function [fault_code, diagnosis_msg, maintenance_advice] = periodic_diagnosis_enhanced(data, timestamp, thresholds, fault_types, offset_subtypes, fault_mapping, maintenance_db)
     % 去除NaN进行统计
     valid_data = data(~isnan(data));
     maintenance_advice = struct();
     maintenance_advice.all_suggestions = {};
     
     if isempty(valid_data)
         fault_code = fault_types.data_missing;
         diagnosis_msg = sprintf('【%s】%s - 过去1小时数据全部缺失', ...
                               fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'));
         maintenance_advice = get_maintenance_advice(fault_code, fault_mapping, maintenance_db);
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
     
     % 获取维修建议（正常情况除外）
     if ~strcmp(fault_code, 'NORMAL')
         maintenance_advice = get_maintenance_advice(fault_code, fault_mapping, maintenance_db);
     end
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

%% ========================================
%% 辅助函数定义
%% ========================================

% 条件判断函数（替代内联if）
function result = iif(condition, true_value, false_value)
    if condition
        result = true_value;
    else
        result = false_value;
    end
end

% 创建维修措施结构体
function measure = create_measure(step, action, time, tools)
    measure = struct();
    measure.step = step;
    measure.action = action;
    measure.time = time;
    measure.tools = tools;
end

% 初始化维修建议数据库
function db = init_maintenance_database()
    db = struct();
    
    % ========== 数据偏差型故障 ==========
    
    % 故障代码302
    db.code_302 = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '302', ...
        'fault_name', '零点漂移超过允许范围50%', ...
        'description', '偏差漂移超过了允许范围的一半（±0.75vol%O2）', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', {
            create_measure(1, '检查传感器表面污染', '10分钟', '清洁布、酒精');
            create_measure(2, '检查采样管路冷凝水', '15分钟', '排水工具');
            create_measure(3, '执行零点校准程序', '30分钟', '标准气体');
            create_measure(4, '检查传感器老化程度', '1小时', '测试设备');
            create_measure(5, '更换传感器模块', '2小时', '备用传感器')
        });
    
    % 故障代码303
    db.code_303 = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '303', ...
        'fault_name', '零点漂移超出允许范围', ...
        'description', '偏差漂移超出允许范围（±1.5vol%O2）', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', {
            create_measure(1, '立即检查传感器状态灯', '5分钟', '无');
            create_measure(2, '检查供电电压24V DC', '10分钟', '万用表');
            create_measure(3, '紧急执行零点量程校准', '45分钟', '标准气体');
            create_measure(4, '检查传感器参比电极', '1.5小时', '专用检测仪');
            create_measure(5, '立即更换传感器', '2小时', '备用传感器')
        });
    
    % 故障代码304
    db.code_304 = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '304', ...
        'fault_name', '灵敏度漂移超出50%', ...
        'description', '放大漂移超出允许范围的50%', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', {
            create_measure(1, '检查测量池窗片清洁度', '15分钟', '清洁工具');
            create_measure(2, '检查光源强度稳定性', '20分钟', '光强测试仪');
            create_measure(3, '执行量程标定', '40分钟', '量程气体');
            create_measure(4, '检查检测器响应曲线', '1小时', '测试设备');
            create_measure(5, '更换检测器组件', '2小时', '备用检测器')
        });
    
    % 故障代码305
    db.code_305 = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '305', ...
        'fault_name', '灵敏度漂移超出允许范围', ...
        'description', '放大漂移超出允许范围', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', {
            create_measure(1, '停止测量检查报警', '5分钟', '无');
            create_measure(2, '清洁所有光学元件', '30分钟', '光学清洁套装');
            create_measure(3, '执行完整系统标定', '1小时', '多种标准气体');
            create_measure(4, '调整光路对准', '1.5小时', '光路调整工具');
            create_measure(5, '更换光源和检测器', '3小时', '备件')
        });
    
    % 故障代码319
    db.code_319 = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '319', ...
        'fault_name', '磁力测量回路失衡', ...
        'description', '磁力式传感器测量回路信号失去平衡', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', {
           create_measure(1, '检查磁场线圈连接', '10分钟', '万用表');
           create_measure(2, '测量磁力传感器输出', '20分钟', '示波器');
           create_measure(3, '调节信号调理电路', '30分钟', '调试设备');
           create_measure(4, '更换磁力传感器', '1小时', '备用传感器');
           create_measure(5, '更换传感器电路板', '2小时', '备用电路板')
        });

    % 故障代码320
    db.code_320 = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '320', ...
        'fault_name', '测定放大偏差过高', ...
        'description', '信号放大器偏差超出正常范围', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', {
            create_measure(1, '检查放大器供电', '10分钟', '万用表');
            create_measure(2, '调整放大器零点增益', '25分钟', '示波器');
            create_measure(3, '更换运放芯片', '45分钟', '备用芯片');
            create_measure(4, '检查信号链路', '1小时', '信号发生器');
            create_measure(5, '更换放大器板', '1.5小时', '备用电路板')
        });
    
    % 故障代码309-311
    db.code_309_311 = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '309-311', ...
        'fault_name', '温度调节器失效', ...
        'description', '温度控制超出范围', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', {
            create_measure(1, '检查温度传感器', '10分钟', '温度计');
            create_measure(2, '检查加热冷却器', '20分钟', '万用表');
            create_measure(3, '校准PID参数', '40分钟', '调试软件');
            create_measure(4, '更换温度传感器', '1小时', '备用传感器');
            create_measure(5, '更换温控模块', '2小时', '备用模块')
        });
    
    % ========== 数据传输中断型故障 ==========
    
    % 故障代码101
    db.code_101 = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '101', ...
        'fault_name', '系统控制器关停', ...
        'description', '主控制器停止工作', ...
        'severity', '紧急', ...
        'priority', 1, ...
        'maintenance_measures', {
            create_measure(1, '检查主电源保险丝', '5分钟', '万用表');
            create_measure(2, '检查24V电源输出', '10分钟', '万用表');
            create_measure(3, '重启控制器系统', '15分钟', '无');
            create_measure(4, '检查CPU和内存', '30分钟', '诊断软件');
            create_measure(5, '更换控制器主板', '2小时', '备用主板')
        });
    
    % 故障代码116
    db.code_116 = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '116', ...
        'fault_name', 'Profibus安装错误', ...
        'description', 'Profibus模块安装位置错误', ...
        'severity', '中等', ...
        'priority', 3, ...
        'maintenance_measures', {
            create_measure(1, '确认安装位置', '5分钟', '无');
            create_measure(2, '重装到X20/X21槽', '15分钟', '螺丝刀');
            create_measure(3, '重配通讯参数', '20分钟', '配置软件');
            create_measure(4, '测试通讯连接', '30分钟', 'Profibus测试仪');
            create_measure(5, '更换Profibus模块', '1小时', '备用模块')
        });
    
    % 故障代码201-209
    db.code_201_209 = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '201-209', ...
        'fault_name', '系统总线连接中断', ...
        'description', '系统总线通讯中断', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', {
            create_measure(1, '检查总线电缆', '10分钟', '无');
            create_measure(2, '检查终端电阻', '15分钟', '万用表');
            create_measure(3, '更换总线电缆', '30分钟', '备用电缆');
            create_measure(4, '检查模块供电', '20分钟', '万用表');
            create_measure(5, '更换通讯模块', '1小时', '备用模块')
        });
    
    % 故障代码300
    db.code_300 = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '300', ...
        'fault_name', '模数转换器无输出', ...
        'description', 'ADC无新测量值', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', {
            create_measure(1, '检查ADC供电', '10分钟', '万用表');
            create_measure(2, '检查模拟输入', '15分钟', '示波器');
            create_measure(3, '重置ADC芯片', '20分钟', '复位工具');
            create_measure(4, '更换ADC芯片', '1小时', '备用芯片');
            create_measure(5, '更换采集卡', '1.5小时', '备用采集卡')
        });
    
    % 故障代码308
    db.code_308 = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '308', ...
        'fault_name', '测定值计算错误', ...
        'description', '计算过程错误', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', {
            create_measure(1, '重启处理程序', '5分钟', '无');
            create_measure(2, '检查CPU内存', '10分钟', '监控软件');
            create_measure(3, '清理系统缓存', '15分钟', '清理工具');
            create_measure(4, '重装固件程序', '45分钟', '固件包');
            create_measure(5, '更换处理器板', '2小时', '备用板')
        });
    
    % 故障代码318
    db.code_318 = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '318', ...
        'fault_name', 'ADC无新测量', ...
        'description', 'ADC无新数据', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', {
            create_measure(1, '检查触发信号', '10分钟', '示波器');
            create_measure(2, '检查时钟信号', '15分钟', '示波器');
            create_measure(3, '重配采样参数', '20分钟', '配置软件');
            create_measure(4, '更换时钟芯片', '45分钟', '备用芯片');
            create_measure(5, '更换ADC模块', '1.5小时', '备用模块')
        });
    
    % 故障代码332-337
    db.code_332_337 = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '332-337', ...
        'fault_name', 'I/O板故障', ...
        'description', 'I/O板硬件问题', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', {
            create_measure(1, '检查I/O板指示灯', '5分钟', '无');
            create_measure(2, '检查I/O配置', '15分钟', '配置软件');
            create_measure(3, '测试I/O通道', '30分钟', '万用表');
            create_measure(4, '初始化I/O板', '20分钟', '初始化工具');
            create_measure(5, '更换I/O板', '1小时', '备用板')
        });
    
    % 故障代码338-339
    db.code_338_339 = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '338-339', ...
        'fault_name', '模拟线路故障', ...
        'description', '线路断裂或短路', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', {
            create_measure(1, '检查接线端子', '10分钟', '螺丝刀');
            create_measure(2, '测量线路通断', '15分钟', '万用表');
            create_measure(3, '检查屏蔽接地', '20分钟', '接地测试仪');
            create_measure(4, '更换信号电缆', '30分钟', '备用电缆');
            create_measure(5, '重新布线', '2小时', '布线工具')
        });
    
    % ========== 数据保持型故障 ==========
    
    % 故障代码301
    db.code_301 = struct(...
        'fault_type', '数据保持型故障', ...
        'fault_code', '301', ...
        'fault_name', '超出ADC阈值', ...
        'description', '超出ADC范围', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', {
            create_measure(1, '确认实际浓度', '5分钟', '便携式分析仪');
            create_measure(2, '检查量程设置', '10分钟', '配置软件');
            create_measure(3, '调整信号衰减', '20分钟', '调节工具');
            create_measure(4, '重选测量量程', '30分钟', '配置软件');
            create_measure(5, '更换大量程传感器', '2小时', '备用传感器')
        });
    
    % 故障代码344
    db.code_344 = struct(...
        'fault_type', '数据保持型故障', ...
        'fault_code', '344', ...
        'fault_name', '超上限130%', ...
        'description', '超过量程130%', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', {
            create_measure(1, '检查工艺异常', '5分钟', '工艺参数表');
            create_measure(2, '检查空气泄漏', '15分钟', '检漏仪');
            create_measure(3, '检查传感器饱和', '20分钟', '测试仪');
            create_measure(4, '切换高量程', '30分钟', '配置软件');
            create_measure(5, '更换高量程传感器', '2小时', '备用传感器')
        });
    
    % 故障代码345
    db.code_345 = struct(...
        'fault_type', '数据保持型故障', ...
        'fault_code', '345', ...
        'fault_name', '低于下限-100%', ...
        'description', '低于量程-100%', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', {
            create_measure(1, '检查传感器接线', '10分钟', '接线图');
            create_measure(2, '检查信号电路', '20分钟', '万用表');
            create_measure(3, '验证零点设置', '30分钟', '零点气体');
            create_measure(4, '重新标定', '45分钟', '标准气体');
            create_measure(5, '更换传感器信号板', '2小时', '备件')
        });
    
    % ========== 数据波动型故障 ==========
    
    % 故障代码312
    db.code_312 = struct(...
        'fault_type', '数据波动型故障', ...
        'fault_code', '312', ...
        'fault_name', '压力修正失效', ...
        'description', '压力测量错误', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', {
            create_measure(1, '检查压力传感器', '10分钟', '压力表');
            create_measure(2, '检查压力管路', '15分钟', '检漏仪');
            create_measure(3, '校准压力传感器', '30分钟', '标准压力源');
            create_measure(4, '检查补偿算法', '20分钟', '配置软件');
            create_measure(5, '更换压力传感器', '1小时', '备用传感器')
        });
    
    % 外部因素EXT-01
    db.code_EXT_01 = struct(...
        'fault_type', '数据波动型故障', ...
        'fault_code', 'EXT-01', ...
        'fault_name', '管路污染堵塞', ...
        'description', '管道或过滤器问题', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', {
            create_measure(1, '检查过滤器压差', '5分钟', '压差表');
            create_measure(2, '更换过滤器', '20分钟', '备用滤芯');
            create_measure(3, '吹扫采样管路', '30分钟', '压缩空气');
            create_measure(4, '检查管路泄漏', '45分钟', '检漏仪');
            create_measure(5, '更换采样管路', '2小时', '备用管路')
        });
    
    % 外部因素EXT-02
    db.code_EXT_02 = struct(...
        'fault_type', '数据波动型故障', ...
        'fault_code', 'EXT-02', ...
        'fault_name', '气路扭结泄漏', ...
        'description', '气路系统问题', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', {
            create_measure(1, '检查管路扭结', '5分钟', '手电筒');
            create_measure(2, '检查流量', '10分钟', '流量计');
            create_measure(3, '逐段检漏', '30分钟', '检漏仪');
            create_measure(4, '紧固接头', '20分钟', '扳手');
            create_measure(5, '重装气路', '3小时', '全套管路')
        });
end