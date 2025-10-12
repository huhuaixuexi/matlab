clear; clc; close all;

%% ========================================
%% 氧分析仪智能诊断维护系统 - 美化版
%% ========================================

fprintf('════════════════════════════════════════\n');
fprintf('   氧分析仪智能诊断维护系统 v7.0\n');
fprintf('      专业美化界面版\n');
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

% 颜色方案定义
colors = struct();
colors.primary = [0.2, 0.4, 0.8];          % 主色调 - 深蓝色
colors.secondary = [0.1, 0.7, 0.9];        % 次要色 - 浅蓝色
colors.success = [0.2, 0.8, 0.4];          % 成功 - 绿色
colors.warning = [1, 0.7, 0.2];            % 警告 - 橙色
colors.danger = [0.9, 0.2, 0.2];           % 危险 - 红色
colors.background = [0.95, 0.95, 0.95];    % 背景 - 浅灰色
colors.dark = [0.2, 0.2, 0.2];             % 深色文字
colors.light = [1, 1, 1];                  % 浅色背景

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

% 初始化美化的可视化界面
if config.enable_visualization
     % 获取屏幕大小
     screenSize = get(0, 'ScreenSize');
     figWidth = min(1600, screenSize(3) * 0.9);
     figHeight = min(900, screenSize(4) * 0.85);
     
     % 创建主窗口
     fig = figure('Name', '氧分析仪智能诊断维护系统 - 专业版', ...
                 'Position', [(screenSize(3)-figWidth)/2, (screenSize(4)-figHeight)/2, figWidth, figHeight], ...
                 'NumberTitle', 'off', ...
                 'Color', colors.light, ...
                 'MenuBar', 'none', ...
                 'ToolBar', 'none', ...
                 'Resize', 'off');
     
     % 创建顶部标题栏
     header_panel = uipanel('Parent', fig, ...
                           'Position', [0 0.92 1 0.08], ...
                           'BackgroundColor', colors.primary, ...
                           'BorderType', 'none');
     
     % 标题文本
     uicontrol('Parent', header_panel, ...
              'Style', 'text', ...
              'String', '氧分析仪智能诊断维护系统', ...
              'Position', [20 10 400 40], ...
              'BackgroundColor', colors.primary, ...
              'ForegroundColor', colors.light, ...
              'FontSize', 20, ...
              'FontWeight', 'bold', ...
              'HorizontalAlignment', 'left');
     
     % 状态指示器
     status_lamp = uicontrol('Parent', header_panel, ...
                            'Style', 'text', ...
                            'String', '● 运行中', ...
                            'Position', [figWidth-150 15 130 30], ...
                            'BackgroundColor', colors.primary, ...
                            'ForegroundColor', colors.success, ...
                            'FontSize', 14, ...
                            'FontWeight', 'bold', ...
                            'HorizontalAlignment', 'right');
     
     % 创建主要内容区域
     main_panel = uipanel('Parent', fig, ...
                         'Position', [0.005 0.005 0.99 0.91], ...
                         'BackgroundColor', colors.background, ...
                         'BorderType', 'none');
     
     % === 左侧监控区域 ===
     monitor_panel = uipanel('Parent', main_panel, ...
                            'Position', [0.01 0.51 0.48 0.48], ...
                            'BackgroundColor', colors.light, ...
                            'Title', '实时监控', ...
                            'TitlePosition', 'centertop', ...
                            'FontSize', 12, ...
                            'FontWeight', 'bold', ...
                            'ForegroundColor', colors.primary);
     
     % 实时数据图
     ax1 = axes('Parent', monitor_panel, 'Position', [0.1 0.15 0.85 0.75]);
     h_line = plot(NaN, NaN, '-', 'LineWidth', 2, 'Color', colors.primary);
     hold on;
     h_alarm_points = plot(NaN, NaN, 'o', 'MarkerSize', 8, ...
                          'MarkerFaceColor', colors.danger, 'MarkerEdgeColor', colors.danger);
     h_current = plot(NaN, NaN, 'o', 'MarkerSize', 12, ...
                     'MarkerFaceColor', colors.success, 'MarkerEdgeColor', colors.dark, 'LineWidth', 2);
     
     % 添加阈值线
     yline(thresholds.full_scale, '--', '满量程', 'LineWidth', 1.5, 'Color', colors.danger, 'LabelHorizontalAlignment', 'left');
     yline(thresholds.zero_scale, '--', '零位', 'LineWidth', 1.5, 'Color', colors.danger, 'LabelHorizontalAlignment', 'left');
     yline(thresholds.normal_mean, '--', '正常值', 'LineWidth', 1.5, 'Color', colors.success, 'LabelHorizontalAlignment', 'left');
     hold off;
     
     xlabel('时间 (秒)', 'FontSize', 10, 'FontWeight', 'bold');
     ylabel('氧浓度 (%)', 'FontSize', 10, 'FontWeight', 'bold');
     grid on;
     grid minor;
     ax1.GridColor = [0.8 0.8 0.8];
     ax1.MinorGridColor = [0.9 0.9 0.9];
     xlim([0, 1000]);
     ylim([-0.5, 10.5]);
     
     % === 右侧数据窗口 ===
     buffer_panel = uipanel('Parent', main_panel, ...
                           'Position', [0.51 0.51 0.48 0.48], ...
                           'BackgroundColor', colors.light, ...
                           'Title', '1小时数据分析', ...
                           'TitlePosition', 'centertop', ...
                           'FontSize', 12, ...
                           'FontWeight', 'bold', ...
                           'ForegroundColor', colors.primary);
     
     ax2 = axes('Parent', buffer_panel, 'Position', [0.1 0.15 0.85 0.75]);
     h_buffer = plot(NaN, NaN, '-', 'LineWidth', 1.5, 'Color', colors.secondary);
     xlabel('时间 (小时)', 'FontSize', 10, 'FontWeight', 'bold');
     ylabel('氧浓度 (%)', 'FontSize', 10, 'FontWeight', 'bold');
     grid on;
     xlim([0, 1]);
     ylim([-0.5, 10.5]);
     
     % === 左下统计信息 ===
     stats_panel = uipanel('Parent', main_panel, ...
                          'Position', [0.01 0.26 0.48 0.24], ...
                          'BackgroundColor', colors.light, ...
                          'Title', '实时统计', ...
                          'TitlePosition', 'centertop', ...
                          'FontSize', 12, ...
                          'FontWeight', 'bold', ...
                          'ForegroundColor', colors.primary);
     
     h_stats_text = uicontrol('Parent', stats_panel, ...
                             'Style', 'text', ...
                             'Position', [10 10 stats_panel.Position(3)*figWidth-20 stats_panel.Position(4)*figHeight-40], ...
                             'BackgroundColor', colors.light, ...
                             'ForegroundColor', colors.dark, ...
                             'FontSize', 10, ...
                             'FontName', 'FixedWidth', ...
                             'HorizontalAlignment', 'left');
     
     % === 右下诊断日志 ===
     log_panel = uipanel('Parent', main_panel, ...
                        'Position', [0.51 0.26 0.48 0.24], ...
                        'BackgroundColor', colors.light, ...
                        'Title', '诊断日志', ...
                        'TitlePosition', 'centertop', ...
                        'FontSize', 12, ...
                        'FontWeight', 'bold', ...
                        'ForegroundColor', colors.primary);
     
     h_log_text = uicontrol('Parent', log_panel, ...
                           'Style', 'listbox', ...
                           'Position', [10 10 log_panel.Position(3)*figWidth-20 log_panel.Position(4)*figHeight-40], ...
                           'BackgroundColor', colors.light, ...
                           'ForegroundColor', colors.dark, ...
                           'FontSize', 9, ...
                           'FontName', 'FixedWidth');
     
     % === 底部维修建议区域 ===
     maint_panel = uipanel('Parent', main_panel, ...
                          'Position', [0.01 0.01 0.98 0.24], ...
                          'BackgroundColor', colors.light, ...
                          'Title', '维修建议', ...
                          'TitlePosition', 'centertop', ...
                          'FontSize', 12, ...
                          'FontWeight', 'bold', ...
                          'ForegroundColor', colors.primary);
     
     % 使用可滚动的文本区域
     h_maintenance_text = uicontrol('Parent', maint_panel, ...
                                   'Style', 'listbox', ...
                                   'Position', [10 10 maint_panel.Position(3)*figWidth-20 maint_panel.Position(4)*figHeight-40], ...
                                   'BackgroundColor', colors.light, ...
                                   'ForegroundColor', colors.dark, ...
                                   'FontSize', 9, ...
                                   'FontName', 'FixedWidth', ...
                                   'String', {'等待故障诊断...'});
     
     % 创建进度条
     progress_panel = uipanel('Parent', main_panel, ...
                             'Position', [0.01 0.505 0.98 0.005], ...
                             'BackgroundColor', colors.background, ...
                             'BorderType', 'none');
     
     progress_bar = uipanel('Parent', progress_panel, ...
                           'Position', [0 0 0.01 1], ...
                           'BackgroundColor', colors.secondary, ...
                           'BorderType', 'none');
     
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
         % 更新进度条
         progress_bar.Position(3) = i / total_samples;
         
         % 更新状态灯
         if stats.total_alarms > 0
             set(status_lamp, 'String', sprintf('● 异常 (%d)', stats.total_alarms), ...
                             'ForegroundColor', colors.warning);
         end
         
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
         
         % 更新统计信息（格式化）
         stats_lines = {};
         stats_lines{end+1} = sprintf('监控时长: %.2f 小时', sample_count/3600);
         stats_lines{end+1} = sprintf('处理进度: %d/%d (%.1f%%)', sample_count, total_samples, sample_count/total_samples*100);
         stats_lines{end+1} = '━━━━━━━━━━━━━━━━━━━━━━━━━━━';
         stats_lines{end+1} = sprintf('总报警数: %d', stats.total_alarms);
         stats_lines{end+1} = sprintf('  001-满量程: %d', iif(isKey(stats.fault_counts,'001'), stats.fault_counts('001'), 0));
         stats_lines{end+1} = sprintf('  002-零位: %d', iif(isKey(stats.fault_counts,'002'), stats.fault_counts('002'), 0));
         stats_lines{end+1} = sprintf('  003-数据缺失: %d', iif(isKey(stats.fault_counts,'003'), stats.fault_counts('003'), 0));
         stats_lines{end+1} = sprintf('  004-数据保持: %d', iif(isKey(stats.fault_counts,'004'), stats.fault_counts('004'), 0));
         stats_lines{end+1} = sprintf('  005-剧烈波动: %d', iif(isKey(stats.fault_counts,'005'), stats.fault_counts('005'), 0));
         stats_lines{end+1} = sprintf('  006-数据偏移: %d', offset_total);
         stats_lines{end+1} = '━━━━━━━━━━━━━━━━━━━━━━━━━━━';
         stats_lines{end+1} = sprintf('诊断次数: %d', stats.diagnosis_count);
         stats_lines{end+1} = sprintf('当前值: %.4f%%', current_value);
         stats_lines{end+1} = sprintf('时间: %s', datestr(current_time, 'HH:MM:SS'));
         
         stats_text = strjoin(stats_lines, '\n');
         set(h_stats_text, 'String', stats_text);
         
         % 更新日志显示（使用listbox）
         all_logs = [alarm_log, log_entries];
         if ~isempty(all_logs)
             recent_logs = all_logs(max(1, end-9):end);
             set(h_log_text, 'String', recent_logs, 'Value', length(recent_logs));
         end
         
         % 更新维修建议显示（格式化为listbox）
         if ~isempty(current_maintenance_advice) && isfield(current_maintenance_advice, 'all_suggestions') && ~isempty(current_maintenance_advice.all_suggestions)
             maint_lines = {};
             maint_lines{end+1} = sprintf('【当前故障维修建议汇总】共有 %d 种可能的故障原因', length(current_maintenance_advice.all_suggestions));
             maint_lines{end+1} = '═══════════════════════════════════════════════════════════════════';
             
             % 显示所有故障原因
             for k = 1:length(current_maintenance_advice.all_suggestions)
                 suggestion = current_maintenance_advice.all_suggestions{k};
                 
                 maint_lines{end+1} = '';
                 maint_lines{end+1} = sprintf('【故障%d】故障代码: %s - %s', k, suggestion.fault_code, suggestion.fault_name);
                 maint_lines{end+1} = sprintf('故障描述: %s', suggestion.description);
                 maint_lines{end+1} = sprintf('严重程度: %s | 优先级: %d', suggestion.severity, suggestion.priority);
                 maint_lines{end+1} = '维修措施:';
                 
                 % 显示所有步骤
                 if iscell(suggestion.measures)
                     for j = 1:length(suggestion.measures)
                         measure = suggestion.measures{j};
                         maint_lines{end+1} = sprintf('  步骤%d: %s', measure.step, measure.action);
                         maint_lines{end+1} = sprintf('         耗时: %s | 工具: %s', measure.time, measure.tools);
                     end
                 elseif isstruct(suggestion.measures)
                     for j = 1:length(suggestion.measures)
                         measure = suggestion.measures(j);
                         maint_lines{end+1} = sprintf('  步骤%d: %s', measure.step, measure.action);
                         maint_lines{end+1} = sprintf('         耗时: %s | 工具: %s', measure.time, measure.tools);
                     end
                 end
                 
                 if k < length(current_maintenance_advice.all_suggestions)
                     maint_lines{end+1} = '───────────────────────────────────────────────────────────────────';
                 end
             end
             
             set(h_maintenance_text, 'String', maint_lines, 'Value', 1);
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
%% 生成最终报告（与之前相同，省略）
%% ========================================

% ... 报告生成代码与O2_System_Final_Fixed.m相同 ...

%% ========================================
%% 核心诊断函数定义（与之前相同，省略）
%% ========================================

% 包含所有必要的函数定义...
% - detect_data_hold
% - get_maintenance_advice
% - format_maintenance_advice
% - realtime_detection_enhanced
% - periodic_diagnosis_enhanced
% - check_periodic_alarm
% - iif
% - create_measure
% - init_maintenance_database

% [完整函数实现请参考O2_System_Final_Fixed.m]