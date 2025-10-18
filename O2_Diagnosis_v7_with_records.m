clear; clc; close all;

%% ========================================
%% 氧分析仪智能诊断维护系统 - 美化版（含维护记录层）
%% ========================================

fprintf('════════════════════════════════════════\n');
fprintf('   氧分析仪智能诊断维护系统 v7.0\n');
fprintf('      专业美化界面版 + 维护记录层\n');
fprintf('════════════════════════════════════════\n\n');

%% ========================================
%% 系统配置部分
%% ========================================

% 系统参数配置
config = struct();
config.data_file = '2_twohour.xlsx';                % 数据文件名
config.sheet_name = 'Sheet1';                       % 工作表名
config.start_time = datetime(2025,10,8,0,0,0);      % 起始时间
config.sample_interval = 1;                         % 采样间隔(秒)
config.diagnosis_interval = 3600;                   % 诊断间隔(1小时=3600秒)
config.simulation_speed = 1500;                     % 模拟速度(1=实时,100=100倍速)
config.enable_visualization = true;                 % 是否启用实时可视化
config.save_log = true;                             % 是否保存日志
config.save_figure = false;                         % 是否保存图形（设为false可避免警告）
config.show_maintenance_advice = true;              % 是否显示维修建议
config.export_records_on_finish = true;             % 程序结束时导出维护记录
config.records_excel_name = '故障诊断维修记录.xlsx';    % 维护记录表名

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
     raw_data = readtable(config.data_file, 'Sheet', config.sheet_name, 'VariableNamingRule', 'preserve');
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
stats.total_alarms = 0;                             % 总报警次数
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

% 设置全局字体
set_global_font();

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
     title_text = uicontrol('Parent', header_panel, ...
              'Style', 'text', ...
              'String', '氧分析仪智能诊断维护系统', ...
              'Position', [20 10 400 40], ...
              'BackgroundColor', colors.primary, ...
              'ForegroundColor', colors.light, ...
              'FontSize', 20, ...
              'FontWeight', 'bold', ...
              'FontName', 'Microsoft YaHei', ...
              'HorizontalAlignment', 'left');
     
     % 确保字体正确设置
     try
         set(title_text, 'FontName', 'Microsoft YaHei');
     catch
         try
             set(title_text, 'FontName', 'SimHei');
         catch
             set(title_text, 'FontName', 'default');
         end
     end
     
     % 状态指示器
     status_lamp = uicontrol('Parent', header_panel, ...
                            'Style', 'text', ...
                            'String', '● 运行中', ...
                            'Position', [figWidth-310 15 130 30], ...
                            'BackgroundColor', colors.primary, ...
                            'ForegroundColor', colors.success, ...
                            'FontSize', 14, ...
                            'FontWeight', 'bold', ...
                            'FontName', 'Microsoft YaHei', ...
                            'HorizontalAlignment', 'right');
     
     % 打开维护记录按钮
     btn_record = uicontrol('Parent', header_panel, ...
                            'Style', 'pushbutton', ...
                            'String', '打开维护记录', ...
                            'Position', [figWidth-160 12 140 34], ...
                            'BackgroundColor', colors.light, ...
                            'ForegroundColor', colors.primary, ...
                            'FontSize', 12, ...
                            'FontWeight', 'bold', ...
                            'Callback', @(src,evt) open_record_window(fig, colors, maintenance_db));
     
     % 确保状态灯字体正确设置
     try
         set(status_lamp, 'FontName', 'Microsoft YaHei');
         set(btn_record, 'FontName', 'Microsoft YaHei');
     catch
         try
             set(status_lamp, 'FontName', 'SimHei');
             set(btn_record, 'FontName', 'SimHei');
         catch
             set(status_lamp, 'FontName', 'default');
             set(btn_record, 'FontName', 'default');
         end
     end
     
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
                            'FontName', 'Microsoft YaHei', ...
                            'ForegroundColor', colors.primary);
     
     try
         set(monitor_panel, 'FontName', 'Microsoft YaHei');
     catch
         try
             set(monitor_panel, 'FontName', 'SimHei');
         catch
             set(monitor_panel, 'FontName', 'default');
         end
     end
     
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
     
     xlabel('时间', 'FontSize', 10, 'FontWeight', 'bold');
     ylabel('氧浓度 (%)', 'FontSize', 10, 'FontWeight', 'bold');
     grid on; grid minor;
     ax1.GridColor = [0.8 0.8 0.8];
     ax1.MinorGridColor = [0.9 0.9 0.9];
     xlim(ax1, [0, 3600]);  % 初始显示1小时
     ylim([-0.5, 10.5]);
     
     % === 右侧数据窗口 ===
     buffer_panel = uipanel('Parent', main_panel, ...
                           'Position', [0.51 0.51 0.48 0.48], ...
                           'BackgroundColor', colors.light, ...
                           'Title', '1小时数据分析', ...
                           'TitlePosition', 'centertop', ...
                           'FontSize', 12, ...
                           'FontWeight', 'bold', ...
                           'FontName', 'Microsoft YaHei', ...
                           'ForegroundColor', colors.primary);
     try
         set(buffer_panel, 'FontName', 'Microsoft YaHei');
     catch
         try
             set(buffer_panel, 'FontName', 'SimHei');
         catch
             set(buffer_panel, 'FontName', 'default');
         end
     end
     
     ax2 = axes('Parent', buffer_panel, 'Position', [0.1 0.15 0.85 0.75]);
     h_buffer = plot(NaN, NaN, '-', 'LineWidth', 1.5, 'Color', colors.secondary);
     xlabel('时间 (小时)', 'FontSize', 10, 'FontWeight', 'bold');
     ylabel('氧浓度 (%)', 'FontSize', 10, 'FontWeight', 'bold');
     grid on; xlim([0, 1]); ylim([-0.5, 10.5]);
     
     % === 左下统计信息 ===
     stats_panel = uipanel('Parent', main_panel, ...
                          'Position', [0.01 0.26 0.48 0.24], ...
                          'BackgroundColor', colors.light, ...
                          'Title', '实时统计', ...
                          'TitlePosition', 'centertop', ...
                          'FontSize', 12, ...
                          'FontWeight', 'bold', ...
                          'FontName', 'Microsoft YaHei', ...
                          'ForegroundColor', colors.primary);
     try
         set(stats_panel, 'FontName', 'Microsoft YaHei');
     catch
         try
             set(stats_panel, 'FontName', 'SimHei');
         catch
             set(stats_panel, 'FontName', 'default');
         end
     end
     
     h_stats_text = uicontrol('Parent', stats_panel, ...
                             'Style', 'listbox', ...
                             'Position', [10 5 stats_panel.Position(3)*figWidth-20 stats_panel.Position(4)*figHeight-35], ...
                             'BackgroundColor', colors.light, ...
                             'ForegroundColor', colors.dark, ...
                             'FontSize', 9, ...
                             'FontName', 'Microsoft YaHei', ...
                             'String', {'系统初始化中...'}, ...
                             'Max', 2, 'Min', 0, 'Value', 1, 'ListboxTop', 1);
     try
         set(h_stats_text, 'FontName', 'Microsoft YaHei');
     catch
         try
             set(h_stats_text, 'FontName', 'SimHei');
         catch
             set(h_stats_text, 'FontName', 'Courier New');
         end
     end
     
     % === 右下诊断日志 ===
     log_panel = uipanel('Parent', main_panel, ...
                        'Position', [0.51 0.26 0.48 0.24], ...
                        'BackgroundColor', colors.light, ...
                        'Title', '诊断日志', ...
                        'TitlePosition', 'centertop', ...
                        'FontSize', 12, ...
                        'FontWeight', 'bold', ...
                        'FontName', 'Microsoft YaHei', ...
                        'ForegroundColor', colors.primary);
     try
         set(log_panel, 'FontName', 'Microsoft YaHei');
     catch
         try
             set(log_panel, 'FontName', 'SimHei');
         catch
             set(log_panel, 'FontName', 'default');
         end
     end
     
     h_log_text = uicontrol('Parent', log_panel, ...
                           'Style', 'listbox', ...
                           'Position', [10 5 log_panel.Position(3)*figWidth-20 log_panel.Position(4)*figHeight-35], ...
                           'BackgroundColor', colors.light, ...
                           'ForegroundColor', colors.dark, ...
                           'FontSize', 9, ...
                           'FontName', 'Microsoft YaHei', ...
                           'String', {'等待诊断日志...'}, ...
                           'Max', 2, 'Min', 0, 'Value', 1, 'ListboxTop', 1);
     try
         set(h_log_text, 'FontName', 'Microsoft YaHei');
     catch
         try
             set(h_log_text, 'FontName', 'SimHei');
         catch
             set(h_log_text, 'FontName', 'Courier New');
         end
     end
     
     % === 底部维修建议区域 ===
     maint_panel = uipanel('Parent', main_panel, ...
                          'Position', [0.01 0.01 0.98 0.24], ...
                          'BackgroundColor', colors.light, ...
                          'Title', '维修建议', ...
                          'TitlePosition', 'centertop', ...
                          'FontSize', 12, ...
                          'FontWeight', 'bold', ...
                          'FontName', 'Microsoft YaHei', ...
                          'ForegroundColor', colors.primary);
     try
         set(maint_panel, 'FontName', 'Microsoft YaHei');
     catch
         try
             set(maint_panel, 'FontName', 'SimHei');
         catch
             set(maint_panel, 'FontName', 'default');
         end
     end
     
     h_maintenance_text = uicontrol('Parent', maint_panel, ...
                                   'Style', 'listbox', ...
                                   'Position', [10 5 maint_panel.Position(3)*figWidth-20 maint_panel.Position(4)*figHeight-35], ...
                                   'BackgroundColor', colors.light, ...
                                   'ForegroundColor', colors.dark, ...
                                   'FontSize', 9, ...
                                   'FontName', 'Microsoft YaHei', ...
                                   'String', {'等待故障诊断...'}, ...
                                   'Max', 2, 'Min', 0, 'Value', 1, 'ListboxTop', 1);
     try
         set(h_maintenance_text, 'FontName', 'Microsoft YaHei');
     catch
         try
             set(h_maintenance_text, 'FontName', 'SimHei');
         catch
             set(h_maintenance_text, 'FontName', 'Courier New');
         end
     end
     
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
     
     % 初始化维护记录层的状态存储
     init_record_state(fig);
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
alarm_datetime = [];  % 存储报警的实际时间
current_maintenance_advice = struct();
current_maintenance_advice.all_suggestions = {};
stats_history = {};

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
             alarm_log{end+1} = alarm_msg; %#ok<SAGROW>
             alarm_times(end+1) = (i-1) * config.sample_interval; %#ok<SAGROW>
             alarm_values(end+1) = current_value; %#ok<SAGROW>
             alarm_datetime(end+1) = current_time; %#ok<SAGROW>
             
             % 显示报警
             fprintf('\a'); % 蜂鸣器
             fprintf('%s\n', alarm_msg);
             
             % 显示维修建议
             if config.show_maintenance_advice && isfield(maintenance_advice, 'all_suggestions') && ~isempty(maintenance_advice.all_suggestions)
                 advice_text = format_maintenance_advice(maintenance_advice);
                 fprintf('%s\n', advice_text);
                 maintenance_log{end+1} = [alarm_msg advice_text]; %#ok<SAGROW>
                 current_maintenance_advice = maintenance_advice;
             end
             
             % 将事件加入维护记录待处理池（默认带上最高优先级建议作为预填）
             if config.enable_visualization
                 record_add_event(fig, fault_code, current_time, current_value, maintenance_advice, maintenance_db, '实时');
             end
         end
     end
     
     % ====== 定期综合诊断 ======
     if sample_count >= config.diagnosis_interval && ...
        mod(sample_count, config.diagnosis_interval) == 0
         
         stats.diagnosis_count = stats.diagnosis_count + 1;
         
         % 执行诊断
         [fault_code_p, diagnosis_msg, maintenance_advice_p] = periodic_diagnosis_enhanced(...
             data_buffer, current_time, thresholds, fault_types, offset_subtypes, ...
             fault_mapping, maintenance_db);
         
         % 记录诊断
         log_entries{end+1} = diagnosis_msg; %#ok<SAGROW>
         
         % 显示诊断结果
         fprintf('\n%s\n', diagnosis_msg);
         
         % 统计定期诊断的故障（非正常状态）
         if ~strcmp(fault_code_p, 'NORMAL')
             stats.total_alarms = stats.total_alarms + 1;
             if isKey(stats.fault_counts, fault_code_p)
                 stats.fault_counts(fault_code_p) = stats.fault_counts(fault_code_p) + 1;
             else
                 stats.fault_counts(fault_code_p) = 1;
             end
             
             % 计算最近一小时均值，作为“数据”列的数值
             recent_data = data_buffer(~isnan(data_buffer));
             if isempty(recent_data)
                 recent_mean = NaN;
             else
                 recent_mean = mean(recent_data);
             end
             
             % 显示维修建议
             if config.show_maintenance_advice && isfield(maintenance_advice_p, 'all_suggestions') && ~isempty(maintenance_advice_p.all_suggestions)
                 advice_text = format_maintenance_advice(maintenance_advice_p);
                 fprintf('%s\n', advice_text);
                 maintenance_log{end+1} = [diagnosis_msg advice_text]; %#ok<SAGROW>
                 current_maintenance_advice = maintenance_advice_p;
             end
             
             % 将周期诊断事件加入维护记录池
             if config.enable_visualization
                 record_add_event(fig, fault_code_p, current_time, recent_mean, maintenance_advice_p, maintenance_db, '定期');
             end
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
         
         % 更新实时数据图 - 使用相对时间（秒）并配上实际时间标签
         window_size = min(3600, i);  % 显示最近1小时的数据
         window_start = max(1, i - window_size + 1);
         window_data = oxygen_values(window_start:i);
         window_time_seconds = (window_start-1:i-1) * config.sample_interval;
         current_time_seconds = (i-1) * config.sample_interval;
         
         set(h_line, 'XData', window_time_seconds, 'YData', window_data);
         set(h_current, 'XData', current_time_seconds, 'YData', window_data(end));
         
         % 更新异常点 - 使用相对时间
         if ~isempty(alarm_times)
             recent_mask = alarm_times >= window_time_seconds(1) & alarm_times <= window_time_seconds(end);
             if any(recent_mask)
                 set(h_alarm_points, 'XData', alarm_times(recent_mask), ...
                                   'YData', alarm_values(recent_mask));
             else
                 set(h_alarm_points, 'XData', NaN, 'YData', NaN);
             end
         end
         
         % 设置X轴范围 - 显示最近1小时
         xlim(ax1, [window_time_seconds(1), window_time_seconds(end) + 300]);  % 加5分钟缓冲
         
         % 设置时间轴刻度和标签 - 显示实际时间
         time_range_seconds = window_time_seconds(end) - window_time_seconds(1);
         if time_range_seconds <= 3600
             tick_interval = 900;      % 15分钟
         elseif time_range_seconds <= 21600
             tick_interval = 1800;     % 30分钟
         else
             tick_interval = 3600;     % 1小时
         end
         tick_start = ceil(window_time_seconds(1) / tick_interval) * tick_interval;
         tick_positions = tick_start:tick_interval:window_time_seconds(end);
         if ~isempty(tick_positions)
             tick_labels = cell(1, length(tick_positions));
             for k = 1:length(tick_positions)
                 tick_time = config.start_time + seconds(tick_positions(k));
                 tick_labels{k} = datestr(tick_time, 'HH:MM');
             end
             xticks(ax1, tick_positions);
             xticklabels(ax1, tick_labels);
         end
         
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
         stats_lines = {};
         stats_lines{end+1} = '';
         stats_lines{end+1} = '';
         stats_lines{end+1} = '【实时监控统计】';
         stats_lines{end+1} = '═══════════════════════════════════════════';
         stats_lines{end+1} = sprintf('监控时长: %.2f 小时', sample_count/3600);
         stats_lines{end+1} = sprintf('处理进度: %d/%d (%.1f%%)', sample_count, total_samples, sample_count/total_samples*100);
         stats_lines{end+1} = sprintf('当前时间: %s', datestr(current_time, 'yyyy-mm-dd HH:MM:SS'));
         stats_lines{end+1} = sprintf('当前值: %.4f%%', current_value);
         stats_lines{end+1} = '';
         stats_lines{end+1} = '【故障统计汇总】';
         stats_lines{end+1} = '───────────────────────────────────────────';
         stats_lines{end+1} = sprintf('总报警次数: %d', stats.total_alarms);
         stats_lines{end+1} = sprintf('诊断次数: %d', stats.diagnosis_count);
         stats_lines{end+1} = '';
         stats_lines{end+1} = '【各类故障详情】';
         stats_lines{end+1} = sprintf('001-满量程输出: %d 次', iif(isKey(stats.fault_counts,'001'), stats.fault_counts('001'), 0));
         stats_lines{end+1} = sprintf('002-零位输出: %d 次', iif(isKey(stats.fault_counts,'002'), stats.fault_counts('002'), 0));
         stats_lines{end+1} = sprintf('003-数据缺失: %d 次', iif(isKey(stats.fault_counts,'003'), stats.fault_counts('003'), 0));
         stats_lines{end+1} = sprintf('004-数据保持: %d 次', iif(isKey(stats.fault_counts,'004'), stats.fault_counts('004'), 0));
         stats_lines{end+1} = sprintf('005-剧烈波动: %d 次', iif(isKey(stats.fault_counts,'005'), stats.fault_counts('005'), 0));
         stats_lines{end+1} = sprintf('006-数据偏移: %d 次 (总计)', offset_total);
         
         for k = 1:length(offset_codes)
             code = offset_codes{k};
             if isKey(stats.fault_counts, code) && stats.fault_counts(code) > 0
                 switch code
                     case '006.01', sub_name = '小幅正向偏移';
                     case '006.02', sub_name = '小幅负向偏移';
                     case '006.03', sub_name = '大幅正向偏移';
                     case '006.04', sub_name = '大幅负向偏移';
                     case '006.05', sub_name = '严重正向偏移';
                     case '006.06', sub_name = '严重负向偏移';
                 end
                 stats_lines{end+1} = sprintf('  └─ %s-%s: %d 次', code, sub_name, stats.fault_counts(code));
             end
         end
         
         % 数据质量统计
         stats_lines{end+1} = '';
         stats_lines{end+1} = '【数据质量统计】';
         stats_lines{end+1} = '───────────────────────────────────────────';
         valid_count = sum(~isnan(oxygen_values(1:i)));
         stats_lines{end+1} = sprintf('有效数据点: %d (%.1f%%)', valid_count, valid_count/i*100);
         stats_lines{end+1} = sprintf('缺失数据点: %d (%.1f%%)', i-valid_count, (i-valid_count)/i*100);
         
         % 最近一小时统计
         if sample_count >= 3600
             recent_data = oxygen_values(max(1,i-3599):i);
             recent_valid = recent_data(~isnan(recent_data));
             if ~isempty(recent_valid)
                 stats_lines{end+1} = '';
                 stats_lines{end+1} = '【最近一小时统计】';
                 stats_lines{end+1} = '───────────────────────────────────────────';
                 stats_lines{end+1} = sprintf('平均值: %.4f%%', mean(recent_valid));
                 stats_lines{end+1} = sprintf('标准差: %.4f%%', std(recent_valid));
                 stats_lines{end+1} = sprintf('最大值: %.4f%%', max(recent_valid));
                 stats_lines{end+1} = sprintf('最小值: %.4f%%', min(recent_valid));
             end
         end
         stats_lines{end+1} = '═══════════════════════════════════════════';
         set(h_stats_text, 'String', stats_lines, 'Value', length(stats_lines));
         
         % 更新日志显示
         all_logs = [alarm_log, log_entries];
         if ~isempty(all_logs)
             logs_with_padding = [{'', ''}, all_logs];
             set(h_log_text, 'String', logs_with_padding', 'Value', length(logs_with_padding));
         else
             set(h_log_text, 'String', {''; ''; '等待诊断日志...'}, 'Value', 1);
         end
         
         % 更新维修建议显示
         if ~isempty(current_maintenance_advice) && isfield(current_maintenance_advice, 'all_suggestions') && ~isempty(current_maintenance_advice.all_suggestions)
             maint_lines = {};
             maint_lines{end+1} = '';
             maint_lines{end+1} = '';
             maint_lines{end+1} = sprintf('【当前故障维修建议汇总】共有 %d 种可能的故障原因', length(current_maintenance_advice.all_suggestions));
             maint_lines{end+1} = '═══════════════════════════════════════════════════════════════════';
             for k = 1:length(current_maintenance_advice.all_suggestions)
                 suggestion = current_maintenance_advice.all_suggestions{k};
                 maint_lines{end+1} = '';
                 maint_lines{end+1} = sprintf('【故障%d】故障代码: %s - %s', k, suggestion.fault_code, suggestion.fault_name);
                 maint_lines{end+1} = sprintf('故障描述: %s', suggestion.description);
                 maint_lines{end+1} = sprintf('严重程度: %s | 优先级: %d', suggestion.severity, suggestion.priority);
                 maint_lines{end+1} = '维修措施:';
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
     
     % 模拟延时
     if config.simulation_speed < 1000
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
fprintf('诊断次数: %d\n', stats.diagnosis_count);

% 计算006总数
offset_total = 0;
offset_codes = {'006.01', '006.02', '006.03', '006.04', '006.05', '006.06'};
for i = 1:length(offset_codes)
    if isKey(stats.fault_counts, offset_codes{i})
        offset_total = offset_total + stats.fault_counts(offset_codes{i});
    end
end

% 故障统计
fprintf('\n【故障统计】\n');
fprintf('总报警次数: %d\n', stats.total_alarms);

fprintf('001-满量程输出: %d次 (%.2f%%)\n', ...
    iif(isKey(stats.fault_counts,'001'), stats.fault_counts('001'), 0), ...
    iif(isKey(stats.fault_counts,'001'), stats.fault_counts('001')/total_samples*100, 0));
    
fprintf('002-零位输出: %d次 (%.2f%%)\n', ...
    iif(isKey(stats.fault_counts,'002'), stats.fault_counts('002'), 0), ...
    iif(isKey(stats.fault_counts,'002'), stats.fault_counts('002')/total_samples*100, 0));
    
fprintf('003-数据缺失: %d次 (%.2f%%)\n', ...
    iif(isKey(stats.fault_counts,'003'), stats.fault_counts('003'), 0), ...
    iif(isKey(stats.fault_counts,'003'), stats.fault_counts('003')/total_samples*100, 0));
    
fprintf('004-数据保持: %d次 (%.2f%%)\n', ...
    iif(isKey(stats.fault_counts,'004'), stats.fault_counts('004'), 0), ...
    iif(isKey(stats.fault_counts,'004'), stats.fault_counts('004')/total_samples*100, 0));
    
fprintf('005-剧烈波动异常: %d次 (%.2f%%)\n', ...
    iif(isKey(stats.fault_counts,'005'), stats.fault_counts('005'), 0), ...
    iif(isKey(stats.fault_counts,'005'), stats.fault_counts('005')/total_samples*100, 0));
    
fprintf('006-数据偏移: %d次 (%.2f%%)\n', offset_total, offset_total/total_samples*100);

for i = 1:length(offset_codes)
    code = offset_codes{i};
    if isKey(stats.fault_counts, code) && stats.fault_counts(code) > 0
        switch code
            case '006.01', sub_name = '小幅正向偏移';
            case '006.02', sub_name = '小幅负向偏移';
            case '006.03', sub_name = '大幅正向偏移';
            case '006.04', sub_name = '大幅负向偏移';
            case '006.05', sub_name = '严重正向偏移';
            case '006.06', sub_name = '严重负向偏移';
        end
        fprintf('  %s-%s: %d次\n', code, sub_name, stats.fault_counts(code));
    end
end

fprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

% 保存报告文件
if config.save_log
    report_file = sprintf('O2_Diagnosis_Report_%s.txt', datestr(now, 'yyyymmdd_HHMMSS'));
    fid = fopen(report_file, 'w', 'n', 'UTF-8');
    fprintf(fid, '氧分析仪诊断报告\n');
    fprintf(fid, '生成时间: %s\n\n', datestr(now));
    fprintf(fid, '监控时长: %.2f小时\n', total_duration/3600);
    fprintf(fid, '样本总数: %d\n', total_samples);
    fprintf(fid, '报警总数: %d\n\n', stats.total_alarms);
    fprintf(fid, '详细报警记录:\n');
    for i = 1:length(alarm_log)
        fprintf(fid, '%s\n', alarm_log{i});
    end
    fprintf(fid, '\n诊断记录:\n');
    for i = 1:length(log_entries)
        fprintf(fid, '%s\n', log_entries{i});
    end
    fclose(fid);
    fprintf('\n监控报告已保存至: %s\n', report_file);
    
    % 保存报警数据到Excel
    if stats.total_alarms > 0
        alarm_table = table();
        alarm_types = keys(stats.fault_counts);
        row = 0;
        for i = 1:length(alarm_types)
            if stats.fault_counts(alarm_types{i}) > 0
                row = row + 1;
                alarm_table.FaultCode{row,1} = alarm_types{i}; %#ok<AGROW>
                alarm_table.Count(row,1) = stats.fault_counts(alarm_types{i}); %#ok<AGROW>
                alarm_table.Percentage(row,1) = stats.fault_counts(alarm_types{i})/total_samples*100; %#ok<AGROW>
            end
        end
        excel_file = sprintf('O2_Alarms_%s.xlsx', datestr(now, 'yyyymmdd_HHMMSS'));
        if exist('alarm_table','var') && height(alarm_table) > 0
            writetable(alarm_table, excel_file);
            fprintf('报警数据已保存至: %s\n', excel_file);
        end
    end
    
    % 保存图形（可选）
    if exist('fig','var') && config.enable_visualization && config.save_figure
        figure_file = sprintf('O2_Diagnosis_Figure_%s.png', datestr(now, 'yyyymmdd_HHMMSS'));
        try
            exportgraphics(fig, figure_file, 'Resolution', 300);
            fprintf('监控图表已保存至: %s\n', figure_file);
        catch
            print(fig, '-dpng', '-r300', figure_file);
            fprintf('监控图表已保存至: %s\n', figure_file);
        end
    end
end

% 导出维护记录（单独Excel）
if exist('fig','var') && config.export_records_on_finish
    try
        export_records_to_excel(fig, config.records_excel_name);
    catch ME
        warning('导出维护记录失败: %s', ME.message);
    end
end

% 系统提示
fprintf('\n【系统提示】\n');
if stats.total_alarms > 0
    fprintf('⚠ 注意：监控期间出现了%d次异常，请关注设备状态。\n', stats.total_alarms);
else
    fprintf('✓ 监控期间设备运行正常，无异常报警。\n');
end

fprintf('\n【系统功能说明】\n');
fprintf('✓ 实时异常检测（001-004）\n');
fprintf('✓ 定期综合诊断（005-006）\n');
fprintf('✓ 数据保持型故障检测\n');
fprintf('✓ 智能维修建议匹配\n');
fprintf('✓ 维护记录层：记录真实维修措施并导出Excel\n');
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
     
     value_change = abs(current_value - detector.last_value);
     
     if value_change <= thresholds.data_hold_threshold
         if ~detector.is_holding
             detector.is_holding = true;
             detector.hold_start_time = now; %#ok<NASGU>
             detector.hold_duration = sample_interval;
         else
             detector.hold_duration = detector.hold_duration + sample_interval;
         end
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
    maintenance_advice.all_suggestions = {};
    
    if ~isKey(fault_mapping, fault_code)
        return;
    end
    
    possible_codes = fault_mapping(fault_code);
    
    % 调试输出（可按需注释）
    fprintf('\n调试：get_maintenance_advice - 故障代码: %s\n', fault_code);
    fprintf('调试：可能的维修代码: %s\n', strjoin(possible_codes, ', '));
    
    for i = 1:length(possible_codes)
        maint_code = possible_codes{i};
        field_name = ['code_' strrep(maint_code, '-', '_')];
        fprintf('调试：检查数据库字段: %s', field_name);
        if isfield(maintenance_db, field_name)
            fprintf(' - 找到!\n');
            maint_info = maintenance_db.(field_name);
            single_advice = struct();
            single_advice.fault_code = maint_code;
            single_advice.fault_name = maint_info.fault_name;
            single_advice.measures = maint_info.maintenance_measures;
            single_advice.severity = maint_info.severity;
            single_advice.priority = maint_info.priority;
            single_advice.description = maint_info.description;
            maintenance_advice.all_suggestions{end+1} = single_advice; %#ok<AGROW>
            fprintf('      措施数量: %d, 类型: %s\n', length(single_advice.measures), class(single_advice.measures));
        else
            fprintf(' - 未找到!\n');
        end
    end
    fprintf('调试：收集到的建议总数: %d\n', length(maintenance_advice.all_suggestions))
    
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
    
    fprintf('调试：format_维护建议 - 建议总数: %d\n', length(maintenance_advice.all_suggestions));
    
    for j = 1:length(maintenance_advice.all_suggestions)
        suggestion = maintenance_advice.all_suggestions{j};
        fprintf('调试：处理建议 %d - 故障代码: %s\n', j, suggestion.fault_code);
        advice_text = [advice_text sprintf('\n【故障%d】故障代码: %s - %s\n', j, suggestion.fault_code, suggestion.fault_name)];
        advice_text = [advice_text sprintf('故障描述: %s\n', suggestion.description)];
        advice_text = [advice_text sprintf('严重程度: %s | 优先级: %d\n', suggestion.severity, suggestion.priority)];
        advice_text = [advice_text sprintf('维修措施:\n')];
        if iscell(suggestion.measures)
            fprintf('调试：measures是元胞数组，长度: %d\n', length(suggestion.measures));
            for i = 1:length(suggestion.measures)
                measure = suggestion.measures{i}; %#ok<NASGU>
            end
        elseif isstruct(suggestion.measures)
            fprintf('调试：measures是结构体数组，长度: %d\n', length(suggestion.measures));
            for i = 1:length(suggestion.measures)
                measure = suggestion.measures(i);
                advice_text = [advice_text sprintf('  步骤%d: %s\n', measure.step, measure.action)]; %#ok<AGROW>
                advice_text = [advice_text sprintf('         耗时: %s | 工具: %s\n', measure.time, measure.tools)]; %#ok<AGROW>
            end
        else
            fprintf('调试：measures类型未知: %s\n', class(suggestion.measures));
            advice_text = [advice_text sprintf('  （无维修措施）\n')];
        end
        if j < length(maintenance_advice.all_suggestions)
            advice_text = [advice_text sprintf('\n────────────────────────────────────────\n')];
        end
    end
    fprintf('调试：format_维护建议 完成\n')
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
         [is_hold, hold_duration] = detect_data_hold(value, detector, thresholds, sample_interval);
         if is_hold
             is_alarm = true;
             fault_code = fault_types.data_hold;
             alarm_msg = sprintf('【%s】%s - 数据保持！当前值: %.4f%%, 保持时长: %.1f秒', ...
                               fault_code, datestr(timestamp, 'yyyy-mm-dd HH:MM:SS'), ...
                               value, hold_duration);
         end
     end
     
     if is_alarm
         maintenance_advice = get_maintenance_advice(fault_code, fault_mapping, maintenance_db);
     end
end

% 定期综合诊断函数（增强版）
function [fault_code, diagnosis_msg, maintenance_advice] = periodic_diagnosis_enhanced(data, timestamp, thresholds, fault_types, offset_subtypes, fault_mapping, maintenance_db)
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
     
     data_mean = mean(valid_data);
     data_std = std(valid_data);
     offset = abs(data_mean - thresholds.normal_mean);
     
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
     
     diagnosis_msg = sprintf('%s\n    数据统计: 有效点数=%d, 最大=%.4f%%, 最小=%.4f%%', ...
                           diagnosis_msg, length(valid_data), ...
                           max(valid_data), min(valid_data));
     
     if ~strcmp(fault_code, 'NORMAL')
         maintenance_advice = get_maintenance_advice(fault_code, fault_mapping, maintenance_db);
     end
end

% 周期性报警控制函数
function should_alarm = check_periodic_alarm(fault_code, current_time, alarm_control)
     should_alarm = false;
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
         should_alarm = true;
     end
end

%% ========================================
%% 维护记录层：状态、UI与导出
%% ========================================

% 初始化记录状态（存入主窗口fig的appdata）
function init_record_state(fig)
    state = struct();
    state.pending = [];              % 待记录事件（struct数组）
    state.saved = [];                % 已保存的维护记录（struct数组）
    state.nextId = 1;               % 自增事件ID
    state.win = [];                 % 记录窗口句柄
    state.ui = struct();            % 窗口内UI句柄
    setappdata(fig, 'record_state', state);
end

% 打开/构建记录窗口
function open_record_window(fig, colors, maintenance_db)
    if ~ishandle(fig)
        return;
    end
    state = getappdata(fig, 'record_state');
    if isempty(state)
        init_record_state(fig);
        state = getappdata(fig, 'record_state');
    end
    if isfield(state, 'win') && ~isempty(state.win) && ishghandle(state.win)
        figure(state.win);  % 聚焦
        return;
    end
    
    screenSize = get(0, 'ScreenSize');
    w = min(1200, screenSize(3)*0.8);
    h = min(700, screenSize(4)*0.75);
    win = figure('Name','维护记录层', 'NumberTitle','off', 'MenuBar','none', 'ToolBar','none', ...
                 'Color', colors.light, 'Position', [(screenSize(3)-w)/2, (screenSize(4)-h)/2, w, h]);
    
    % 待记录事件列表
    pnlPending = uipanel('Parent', win, 'Title','待记录事件', 'Position',[0.01 0.52 0.48 0.47], ...
                         'BackgroundColor', colors.light, 'ForegroundColor', colors.primary, 'FontWeight','bold');
    tblPending = uitable('Parent', pnlPending, 'Units','normalized', 'Position',[0.02 0.05 0.96 0.9]);
    set(tblPending,'CellSelectionCallback', @(src,evt) on_pending_selection(fig, src, evt));
    
    % 记录编辑表单
    pnlForm = uipanel('Parent', win, 'Title','记录编辑', 'Position',[0.51 0.52 0.48 0.47], ...
                      'BackgroundColor', colors.light, 'ForegroundColor', colors.primary, 'FontWeight','bold');
    
    % 静态与编辑控件（使用归一化布局）
    y = 0.85; dy = 0.08; labelW = 0.28; editW = 0.65;
    mkLabel = @(str, yy) uicontrol('Parent', pnlForm, 'Style','text','Units','normalized','Position',[0.03 yy labelW 0.07], ...
        'BackgroundColor', colors.light, 'HorizontalAlignment','left', 'String', str, 'FontWeight','bold');
    mkEdit  = @(yy) uicontrol('Parent', pnlForm, 'Style','edit','Units','normalized','Position',[0.33 yy editW 0.07], 'BackgroundColor', colors.light);
    
    mkLabel('数据故障代码:', y);           txtDataCode = mkEdit(y); set(txtDataCode,'Enable','inactive'); y = y-dy;
    mkLabel('故障时间:', y);               txtTime = mkEdit(y); set(txtTime,'Enable','inactive'); y = y-dy;
    mkLabel('数据:', y);                   txtData = mkEdit(y); set(txtData,'Enable','inactive'); y = y-dy;
    mkLabel('仪表故障代码:', y);           txtInstrCode = mkEdit(y); y = y-dy;
    mkLabel('故障描述/名称:', y);         txtFaultName = mkEdit(y); set(txtFaultName,'Enable','inactive'); y = y-dy;
    mkLabel('故障类型:', y);               txtFaultType = mkEdit(y); set(txtFaultType,'Enable','inactive'); y = y-dy;
    mkLabel('严重程度:', y);               txtSeverity = mkEdit(y); set(txtSeverity,'Enable','inactive'); y = y-dy;
    mkLabel('优先级:', y);                 txtPriority = mkEdit(y); set(txtPriority,'Enable','inactive'); y = y-dy;
    mkLabel('维修操作:', y);               txtAction = mkEdit(y); y = y-dy;
    mkLabel('耗时:', y);                   txtDuration = mkEdit(y); y = y-dy;
    mkLabel('工具:', y);                   txtTools = mkEdit(y); y = y-dy;
    
    % 操作按钮
    btnSave = uicontrol('Parent', pnlForm, 'Style','pushbutton', 'Units','normalized', 'Position',[0.33 0.02 0.3 0.08], ...
                        'String','保存记录', 'BackgroundColor', colors.secondary, 'Callback', @(s,e) on_save_record(fig));
    btnExport = uicontrol('Parent', pnlForm, 'Style','pushbutton', 'Units','normalized', 'Position',[0.65 0.02 0.3 0.08], ...
                        'String','导出Excel', 'BackgroundColor', colors.secondary, 'Callback', @(s,e) on_export_records(fig));
    
    % 已保存记录
    pnlSaved = uipanel('Parent', win, 'Title','已保存记录', 'Position',[0.01 0.02 0.98 0.48], ...
                       'BackgroundColor', colors.light, 'ForegroundColor', colors.primary, 'FontWeight','bold');
    tblSaved = uitable('Parent', pnlSaved, 'Units','normalized', 'Position',[0.02 0.05 0.96 0.9]);
    
    % 保存句柄
    state.win = win;
    state.ui.tblPending = tblPending;
    state.ui.tblSaved = tblSaved;
    state.ui.txtDataCode = txtDataCode;
    state.ui.txtTime = txtTime;
    state.ui.txtData = txtData;
    state.ui.txtInstrCode = txtInstrCode;
    state.ui.txtFaultName = txtFaultName;
    state.ui.txtFaultType = txtFaultType;
    state.ui.txtSeverity = txtSeverity;
    state.ui.txtPriority = txtPriority;
    state.ui.txtAction = txtAction;
    state.ui.txtDuration = txtDuration;
    state.ui.txtTools = txtTools;
    state.maintenance_db = maintenance_db; % 缓存db以便查元数据
    setappdata(fig, 'record_state', state);
    
    % 初始化表头
    refresh_record_tables(fig);
end

% 将事件加入待记录池
function record_add_event(fig, data_fault_code, fault_time, data_value, maintenance_advice, maintenance_db, source)
    if ~ishandle(fig), return; end
    state = getappdata(fig, 'record_state');
    if isempty(state)
        init_record_state(fig);
        state = getappdata(fig, 'record_state');
    end
    
    % 预选建议中的优先项
    instr_code = '';
    instr_name = '';
    severity = '';
    priority = NaN;
    fault_type = '';
    if isstruct(maintenance_advice) && isfield(maintenance_advice,'all_suggestions') && ~isempty(maintenance_advice.all_suggestions)
        s = maintenance_advice.all_suggestions{1};
        instr_code = s.fault_code;
        instr_name = s.fault_name;
        severity = s.severity;
        priority = s.priority;
        % 从db查故障类型
        info = lookup_maintenance_info_by_code(instr_code, maintenance_db);
        if ~isempty(info)
            fault_type = info.fault_type;
        end
    end
    
    % 数据故障名称
    data_fault_name = get_data_fault_label_by_code(data_fault_code);
    
    ev = struct();
    ev.id = state.nextId;
    ev.source = source; % '实时'/'定期'
    ev.data_fault_code = data_fault_code;
    ev.data_fault_name = data_fault_name;
    ev.fault_time = fault_time;
    ev.data_value = data_value;
    ev.instr_fault_code = instr_code;
    ev.instr_fault_name = instr_name;
    ev.fault_type = fault_type;
    ev.severity = severity;
    ev.priority = priority;
    ev.action = '';
    ev.duration = '';
    ev.tools = '';
    
    if isempty(state.pending)
        state.pending = ev;
    else
        state.pending(end+1) = ev; %#ok<AGROW>
    end
    state.nextId = state.nextId + 1;
    setappdata(fig,'record_state', state);
    
    % 刷新窗口表格（若已打开）
    refresh_record_tables(fig);
end

% 刷新窗口中两张表
function refresh_record_tables(fig)
    if ~ishandle(fig), return; end
    state = getappdata(fig, 'record_state');
    if isempty(state) || ~isfield(state,'win') || isempty(state.win) || ~ishghandle(state.win)
        return; % 窗口未打开
    end
    
    % 待记录表
    headPending = {'事件ID','来源','数据故障代码','数据故障名称','故障时间','数据','默认仪表故障代码','默认名称','严重程度','优先级'};
    dataPending = {};
    if ~isempty(state.pending)
        for k = 1:numel(state.pending)
            ev = state.pending(k);
            dataPending(end+1, :) = {ev.id, ev.source, ev.data_fault_code, ev.data_fault_name, ...
                                      datestr(ev.fault_time,'yyyy-mm-dd HH:MM:SS'), ev.data_value, ...
                                      ev.instr_fault_code, ev.instr_fault_name, ev.severity, ev.priority}; %#ok<AGROW>
        end
    end
    set(state.ui.tblPending, 'Data', dataPending, 'ColumnName', headPending);
    
    % 已保存记录表
    headSaved = {'数据','故障代码','故障时间','仪表故障代码','故障描述/名称','故障类型','严重程度','优先级','维修操作','耗时','工具'};
    dataSaved = {};
    if ~isempty(state.saved)
        for k = 1:numel(state.saved)
            r = state.saved(k);
            dataSaved(end+1,:) = {r.data_value, r.data_fault_code, datestr(r.fault_time,'yyyy-mm-dd HH:MM:SS'), ...
                                  r.instr_fault_code, r.instr_fault_name, r.fault_type, r.severity, r.priority, ...
                                  r.action, r.duration, r.tools}; %#ok<AGROW>
        end
    end
    set(state.ui.tblSaved, 'Data', dataSaved, 'ColumnName', headSaved);
end

% 待记录选择 -> 填充右侧表单
function on_pending_selection(fig, src, evt)
    if ~ishandle(fig), return; end
    state = getappdata(fig, 'record_state');
    if isempty(state) || isempty(evt.Indices)
        return;
    end
    row = evt.Indices(1);
    if row < 1 || row > numel(state.pending)
        return;
    end
    ev = state.pending(row);
    setappdata(fig, 'record_current_index', row);
    set(state.ui.txtDataCode, 'String', ev.data_fault_code);
    set(state.ui.txtTime, 'String', datestr(ev.fault_time,'yyyy-mm-dd HH:MM:SS'));
    set(state.ui.txtData, 'String', num2str(ev.data_value));
    set(state.ui.txtInstrCode, 'String', ev.instr_fault_code);
    set(state.ui.txtFaultName, 'String', ev.instr_fault_name);
    set(state.ui.txtFaultType, 'String', ev.fault_type);
    set(state.ui.txtSeverity, 'String', ev.severity);
    set(state.ui.txtPriority, 'String', num2str(ev.priority));
    set(state.ui.txtAction, 'String', ev.action);
    set(state.ui.txtDuration, 'String', ev.duration);
    set(state.ui.txtTools, 'String', ev.tools);
end

% 保存当前选择的维护记录（一条事件一条实际措施）
function on_save_record(fig)
    if ~ishandle(fig), return; end
    state = getappdata(fig, 'record_state');
    if isempty(state), return; end
    if ~isfield(state,'ui') || ~ishghandle(state.ui.tblPending)
        return;
    end
    row = getappdata(fig, 'record_current_index');
    if isempty(row) || row < 1 || row > numel(state.pending)
        warndlg('请先在“待记录事件”中选择一条事件。','提示');
        return;
    end
    ev = state.pending(row);
    
    % 读取表单可编辑字段
    instrCode = strtrim(get(state.ui.txtInstrCode,'String'));
    action = strtrim(get(state.ui.txtAction,'String'));
    duration = strtrim(get(state.ui.txtDuration,'String'));
    tools = strtrim(get(state.ui.txtTools,'String'));
    
    % 自动补全仪表故障信息（若用户编辑了代码）
    if ~isempty(instrCode) && (~strcmp(instrCode, ev.instr_fault_code) || isempty(ev.instr_fault_name))
        info = lookup_maintenance_info_by_code(instrCode, state.maintenance_db);
        if ~isempty(info)
            ev.instr_fault_code = instrCode;
            ev.instr_fault_name = info.fault_name;
            ev.fault_type = info.fault_type;
            ev.severity = info.severity;
            ev.priority = info.priority;
        else
            % 未知代码则保留原信息
            ev.instr_fault_code = instrCode;
        end
    end
    
    ev.action = action;
    ev.duration = duration;
    ev.tools = tools;
    
    % 验证：必须有实际“维修操作”
    if isempty(ev.action)
        warndlg('请填写“维修操作”，该字段不能为空。','校验失败');
        return;
    end
    
    % 写入已保存列表
    rec = struct('data_value', ev.data_value, 'data_fault_code', ev.data_fault_code, 'fault_time', ev.fault_time, ...
                 'instr_fault_code', ev.instr_fault_code, 'instr_fault_name', ev.instr_fault_name, ...
                 'fault_type', ev.fault_type, 'severity', ev.severity, 'priority', ev.priority, ...
                 'action', ev.action, 'duration', ev.duration, 'tools', ev.tools);
    if isempty(state.saved)
        state.saved = rec;
    else
        state.saved(end+1) = rec; %#ok<AGROW>
    end
    
    % 从待记录中移除
    state.pending(row) = [];
    setappdata(fig,'record_state', state);
    rmappdata(fig, 'record_current_index');
    
    % 刷新显示
    refresh_record_tables(fig);
end

% 导出按钮回调
function on_export_records(fig)
    if ~ishandle(fig), return; end
    export_records_to_excel(fig, '故障诊断维修记录.xlsx');
end

% 导出Excel
function export_records_to_excel(fig, filename)
    if ~ishandle(fig), return; end
    state = getappdata(fig, 'record_state');
    if isempty(state) || isempty(state.saved)
        fprintf('维护记录为空，未导出。\n');
        return;
    end
    
    % 转换为table
    n = numel(state.saved);
    数据 = nan(n,1); %#ok<NASGU>
    故障代码 = strings(n,1); %#ok<NASGU>
    故障时间 = strings(n,1); %#ok<NASGU>
    仪表故障代码 = strings(n,1); %#ok<NASGU>
    故障描述_名称 = strings(n,1); %#ok<NASGU>
    故障类型 = strings(n,1); %#ok<NASGU>
    严重程度 = strings(n,1); %#ok<NASGU>
    优先级 = nan(n,1); %#ok<NASGU>
    维修操作 = strings(n,1); %#ok<NASGU>
    耗时 = strings(n,1); %#ok<NASGU>
    工具 = strings(n,1); %#ok<NASGU>
    
    for i = 1:n
        r = state.saved(i);
        数据(i,1) = r.data_value;
        故障代码(i,1) = string(r.data_fault_code);
        故障时间(i,1) = string(datestr(r.fault_time,'yyyy-mm-dd HH:MM:SS'));
        仪表故障代码(i,1) = string(r.instr_fault_code);
        故障描述_名称(i,1) = string(r.instr_fault_name);
        故障类型(i,1) = string(r.fault_type);
        严重程度(i,1) = string(r.severity);
        优先级(i,1) = r.priority;
        维修操作(i,1) = string(r.action);
        耗时(i,1) = string(r.duration);
        工具(i,1) = string(r.tools);
    end
    T = table(数据, 故障代码, 故障时间, 仪表故障代码, 故障描述_名称, 故障类型, 严重程度, 优先级, 维修操作, 耗时, 工具);
    writetable(T, filename);
    fprintf('维护记录已导出至: %s\n', filename);
end

% 依据数据故障代码返回中文名称
function name = get_data_fault_label_by_code(code)
    switch code
        case '001', name = '满量程输出';
        case '002', name = '零位输出';
        case '003', name = '数据缺失';
        case '004', name = '数据保持';
        case '005', name = '剧烈波动异常';
        case '006.01', name = '小幅正向偏移';
        case '006.02', name = '小幅负向偏移';
        case '006.03', name = '大幅正向偏移';
        case '006.04', name = '大幅负向偏移';
        case '006.05', name = '严重正向偏移';
        case '006.06', name = '严重负向偏移';
        otherwise, name = code;
    end
end

% 依据仪表故障代码查db条目
function info = lookup_maintenance_info_by_code(code, maintenance_db)
    info = [];
    if isempty(code)
        return;
    end
    field_name = ['code_' strrep(code,'-','_')];
    if isfield(maintenance_db, field_name)
        info = maintenance_db.(field_name);
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
    db.code_302 = struct('fault_type','数据偏差型故障','fault_code','302','fault_name','零点漂移超过允许范围50%', ...
        'description','偏差漂移超过了允许范围的一半（±0.75vol%O2）','severity','中等','priority',2, ...
        'maintenance_measures', [
            create_measure(1,'检查传感器表面污染','10分钟','清洁布、酒精')
            create_measure(2,'检查采样管路冷凝水','15分钟','排水工具')
            create_measure(3,'执行零点校准程序','30分钟','标准气体')
            create_measure(4,'检查传感器老化程度','1小时','测试设备')
            create_measure(5,'更换传感器模块','2小时','备用传感器')
        ]);
    db.code_303 = struct('fault_type','数据偏差型故障','fault_code','303','fault_name','零点漂移超出允许范围', ...
        'description','偏差漂移超出允许范围（±1.5vol%O2）','severity','严重','priority',1, ...
        'maintenance_measures', [
            create_measure(1,'立即检查传感器状态灯','5分钟','无')
            create_measure(2,'检查供电电压24V DC','10分钟','万用表')
            create_measure(3,'紧急执行零点量程校准','45分钟','标准气体')
            create_measure(4,'检查传感器参比电极','1.5小时','专用检测仪')
            create_measure(5,'立即更换传感器','2小时','备用传感器')
        ]);
    db.code_304 = struct('fault_type','数据偏差型故障','fault_code','304','fault_name','灵敏度漂移超出50%', ...
        'description','放大漂移超出允许范围的50%','severity','中等','priority',2, ...
        'maintenance_measures', [
            create_measure(1,'检查测量池窗片清洁度','15分钟','清洁工具')
            create_measure(2,'检查光源强度稳定性','20分钟','光强测试仪')
            create_measure(3,'执行量程标定','40分钟','量程气体')
            create_measure(4,'检查检测器响应曲线','1小时','测试设备')
            create_measure(5,'更换检测器组件','2小时','备用检测器')
        ]);
    db.code_305 = struct('fault_type','数据偏差型故障','fault_code','305','fault_name','灵敏度漂移超出允许范围', ...
        'description','放大漂移超出允许范围','severity','严重','priority',1, ...
        'maintenance_measures', [
            create_measure(1,'停止测量检查报警','5分钟','无')
            create_measure(2,'清洁所有光学元件','30分钟','光学清洁套装')
            create_measure(3,'执行完整系统标定','1小时','多种标准气体')
            create_measure(4,'调整光路对准','1.5小时','光路调整工具')
            create_measure(5,'更换光源和检测器','3小时','备件')
        ]);
    db.code_319 = struct('fault_type','数据偏差型故障','fault_code','319','fault_name','磁力测量回路失衡', ...
        'description','磁力式传感器测量回路信号失去平衡','severity','严重','priority',1, ...
        'maintenance_measures', [
            create_measure(1,'检查磁场线圈连接','10分钟','万用表')
            create_measure(2,'测量磁力传感器输出','20分钟','示波器')
            create_measure(3,'调节信号调理电路','30分钟','调试设备')
            create_measure(4,'更换磁力传感器','1小时','备用传感器')
            create_measure(5,'更换传感器电路板','2小时','备用电路板')
        ]);
    db.code_320 = struct('fault_type','数据偏差型故障','fault_code','320','fault_name','测定放大偏差过高', ...
        'description','信号放大器偏差超出正常范围','severity','中等','priority',2, ...
        'maintenance_measures', [
            create_measure(1,'检查放大器供电','10分钟','万用表')
            create_measure(2,'调整放大器零点增益','25分钟','示波器')
            create_measure(3,'更换运放芯片','45分钟','备用芯片')
            create_measure(4,'检查信号链路','1小时','信号发生器')
            create_measure(5,'更换放大器板','1.5小时','备用电路板')
        ]);
    db.code_309_311 = struct('fault_type','数据偏差型故障','fault_code','309-311','fault_name','温度调节器失效', ...
        'description','温度控制超出范围','severity','中等','priority',2, ...
        'maintenance_measures', [
            create_measure(1,'检查温度传感器','10分钟','温度计')
            create_measure(2,'检查加热冷却器','20分钟','万用表')
            create_measure(3,'校准PID参数','40分钟','调试软件')
            create_measure(4,'更换温度传感器','1小时','备用传感器')
            create_measure(5,'更换温控模块','2小时','备用模块')
        ]);

    % ========== 数据传输中断型故障 ==========
    db.code_101 = struct('fault_type','数据传输中断型故障','fault_code','101','fault_name','系统控制器关停', ...
        'description','主控制器停止工作','severity','紧急','priority',1, ...
        'maintenance_measures', [
            create_measure(1,'检查主电源保险丝','5分钟','万用表')
            create_measure(2,'检查24V电源输出','10分钟','万用表')
            create_measure(3,'重启控制器系统','15分钟','无')
            create_measure(4,'检查CPU和内存','30分钟','诊断软件')
            create_measure(5,'更换控制器主板','2小时','备用主板')
        ]);
    db.code_116 = struct('fault_type','数据传输中断型故障','fault_code','116','fault_name','Profibus安装错误', ...
        'description','Profibus模块安装位置错误','severity','中等','priority',3, ...
        'maintenance_measures', [
            create_measure(1,'确认安装位置','5分钟','无')
            create_measure(2,'重装到X20/X21槽','15分钟','螺丝刀')
            create_measure(3,'重配通讯参数','20分钟','配置软件')
            create_measure(4,'测试通讯连接','30分钟','Profibus测试仪')
            create_measure(5,'更换Profibus模块','1小时','备用模块')
        ]);
    db.code_201_209 = struct('fault_type','数据传输中断型故障','fault_code','201-209','fault_name','系统总线连接中断', ...
        'description','系统总线通讯中断','severity','严重','priority',1, ...
        'maintenance_measures', [
            create_measure(1,'检查总线电缆','10分钟','无')
            create_measure(2,'检查终端电阻','15分钟','万用表')
            create_measure(3,'更换总线电缆','30分钟','备用电缆')
            create_measure(4,'检查模块供电','20分钟','万用表')
            create_measure(5,'更换通讯模块','1小时','备用模块')
        ]);
    db.code_300 = struct('fault_type','数据传输中断型故障','fault_code','300','fault_name','模数转换器无输出', ...
        'description','ADC无新测量值','severity','严重','priority',1, ...
        'maintenance_measures', [
            create_measure(1,'检查ADC供电','10分钟','万用表')
            create_measure(2,'检查模拟输入','15分钟','示波器')
            create_measure(3,'重置ADC芯片','20分钟','复位工具')
            create_measure(4,'更换ADC芯片','1小时','备用芯片')
            create_measure(5,'更换采集卡','1.5小时','备用采集卡')
        ]);
    db.code_308 = struct('fault_type','数据传输中断型故障','fault_code','308','fault_name','测定值计算错误', ...
        'description','计算过程错误','severity','中等','priority',2, ...
        'maintenance_measures', [
            create_measure(1,'重启处理程序','5分钟','无')
            create_measure(2,'检查CPU内存','10分钟','监控软件')
            create_measure(3,'清理系统缓存','15分钟','清理工具')
            create_measure(4,'重装固件程序','45分钟','固件包')
            create_measure(5,'更换处理器板','2小时','备用板')
        ]);
    db.code_318 = struct('fault_type','数据传输中断型故障','fault_code','318','fault_name','ADC无新测量', ...
        'description','ADC无新数据','severity','严重','priority',1, ...
        'maintenance_measures', [
            create_measure(1,'检查触发信号','10分钟','示波器')
            create_measure(2,'检查时钟信号','15分钟','示波器')
            create_measure(3,'重配采样参数','20分钟','配置软件')
            create_measure(4,'更换时钟芯片','45分钟','备用芯片')
            create_measure(5,'更换ADC模块','1.5小时','备用模块')
        ]);
    db.code_332_337 = struct('fault_type','数据传输中断型故障','fault_code','332-337','fault_name','I/O板故障', ...
        'description','I/O板硬件问题','severity','中等','priority',2, ...
        'maintenance_measures', [
            create_measure(1,'检查I/O板指示灯','5分钟','无')
            create_measure(2,'检查I/O配置','15分钟','配置软件')
            create_measure(3,'测试I/O通道','30分钟','万用表')
            create_measure(4,'初始化I/O板','20分钟','初始化工具')
            create_measure(5,'更换I/O板','1小时','备用板')
        ]);
    db.code_338_339 = struct('fault_type','数据传输中断型故障','fault_code','338-339','fault_name','模拟线路故障', ...
        'description','线路断裂或短路','severity','严重','priority',1, ...
        'maintenance_measures', [
            create_measure(1,'检查接线端子','10分钟','螺丝刀')
            create_measure(2,'测量线路通断','15分钟','万用表')
            create_measure(3,'检查屏蔽接地','20分钟','接地测试仪')
            create_measure(4,'更换信号电缆','30分钟','备用电缆')
            create_measure(5,'重新布线','2小时','布线工具')
        ]);

    % ========== 数据保持型故障 ==========
    db.code_301 = struct('fault_type','数据保持型故障','fault_code','301','fault_name','超出ADC阈值', ...
        'description','超出ADC范围','severity','中等','priority',2, ...
        'maintenance_measures', [
            create_measure(1,'确认实际浓度','5分钟','便携式分析仪')
            create_measure(2,'检查量程设置','10分钟','配置软件')
            create_measure(3,'调整信号衰减','20分钟','调节工具')
            create_measure(4,'重选测量量程','30分钟','配置软件')
            create_measure(5,'更换大量程传感器','2小时','备用传感器')
        ]);
    db.code_344 = struct('fault_type','数据保持型故障','fault_code','344','fault_name','超上限130%', ...
        'description','超过量程130%','severity','严重','priority',1, ...
        'maintenance_measures', [
            create_measure(1,'检查工艺异常','5分钟','工艺参数表')
            create_measure(2,'检查空气泄漏','15分钟','检漏仪')
            create_measure(3,'检查传感器饱和','20分钟','测试仪')
            create_measure(4,'切换高量程','30分钟','配置软件')
            create_measure(5,'更换高量程传感器','2小时','备用传感器')
        ]);
    db.code_345 = struct('fault_type','数据保持型故障','fault_code','345','fault_name','低于下限-100%', ...
        'description','低于量程-100%','severity','严重','priority',1, ...
        'maintenance_measures', [
            create_measure(1,'检查传感器接线','10分钟','接线图')
            create_measure(2,'检查信号电路','20分钟','万用表')
            create_measure(3,'验证零点设置','30分钟','零点气体')
            create_measure(4,'重新标定','45分钟','标准气体')
            create_measure(5,'更换传感器信号板','2小时','备件')
        ]);

    % ========== 数据波动型故障 ==========
    db.code_312 = struct('fault_type','数据波动型故障','fault_code','312','fault_name','压力修正失效', ...
        'description','压力测量错误','severity','中等','priority',2, ...
        'maintenance_measures', [
            create_measure(1,'检查压力传感器','10分钟','压力表')
            create_measure(2,'检查压力管路','15分钟','检漏仪')
            create_measure(3,'校准压力传感器','30分钟','标准压力源')
            create_measure(4,'检查补偿算法','20分钟','配置软件')
            create_measure(5,'更换压力传感器','1小时','备用传感器')
        ]);
    db.code_EXT_01 = struct('fault_type','数据波动型故障','fault_code','EXT-01','fault_name','管路污染堵塞', ...
        'description','管道或过滤器问题','severity','中等','priority',2, ...
        'maintenance_measures', [
            create_measure(1,'检查过滤器压差','5分钟','压差表')
            create_measure(2,'更换过滤器','20分钟','备用滤芯')
            create_measure(3,'吹扫采样管路','30分钟','压缩空气')
            create_measure(4,'检查管路泄漏','45分钟','检漏仪')
            create_measure(5,'更换采样管路','2小时','备用管路')
        ]);
    db.code_EXT_02 = struct('fault_type','数据波动型故障','fault_code','EXT-02','fault_name','气路扭结泄漏', ...
        'description','气路系统问题','severity','中等','priority',2, ...
        'maintenance_measures', [
            create_measure(1,'检查管路扭结','5分钟','手电筒')
            create_measure(2,'检查流量','10分钟','流量计')
            create_measure(3,'逐段检漏','30分钟','检漏仪')
            create_measure(4,'紧固接头','20分钟','扳手')
            create_measure(5,'重装气路','3小时','全套管路')
        ]);
end

%% ========================================
%% 字体设置函数
%% ========================================

% 设置全局字体函数
function set_global_font()
    try
        set(0, 'DefaultUicontrolFontName', 'Microsoft YaHei');
        set(0, 'DefaultUipanelFontName', 'Microsoft YaHei');
        set(0, 'DefaultTextFontName', 'Microsoft YaHei');
        set(0, 'DefaultAxesFontName', 'Microsoft YaHei');
    catch
        try
            set(0, 'DefaultUicontrolFontName', 'SimHei');
            set(0, 'DefaultUipanelFontName', 'SimHei');
            set(0, 'DefaultTextFontName', 'SimHei');
            set(0, 'DefaultAxesFontName', 'SimHei');
        catch
            try
                set(0, 'DefaultUicontrolFontName', 'SimSun');
                set(0, 'DefaultUipanelFontName', 'SimSun');
                set(0, 'DefaultTextFontName', 'SimSun');
                set(0, 'DefaultAxesFontName', 'SimSun');
            catch
                warning('无法设置中文字体，使用系统默认字体');
            end
        end
    end
    try
        feature('DefaultCharacterSet', 'UTF-8');
    catch
        try
            feature('DefaultCharacterSet', 'GBK');
        catch
            warning('字符编码设置失败');
        end
    end
end
