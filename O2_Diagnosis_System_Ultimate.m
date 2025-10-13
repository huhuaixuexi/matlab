clear; clc; close all;

%% ========================================
%% 氧分析仪智能诊断维护系统 - 终极版
%% ========================================

fprintf('════════════════════════════════════════\n');
fprintf('   氧分析仪智能诊断维护系统 v6.0\n');
fprintf('      终极版（带滚动显示）\n');
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
     % 创建超大窗口，占满屏幕
     screenSize = get(0, 'ScreenSize');
     fig = figure('Name', '氧分析仪智能诊断维护系统 v6.0 - 终极版', ...
                 'Position', [10, 40, screenSize(3)-20, screenSize(4)-100], ...
                 'NumberTitle', 'off');
     
     % 创建标签页
     tgroup = uitabgroup('Parent', fig);
     
     % 第一个标签页 - 实时监控
     tab1 = uitab('Parent', tgroup, 'Title', '实时监控');
     
     % 实时数据显示窗口
     ax1 = subplot(2, 2, 1, 'Parent', tab1);
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
     ax2 = subplot(2, 2, 2, 'Parent', tab1);
     h_buffer = plot(NaN, NaN, 'b-', 'LineWidth', 1);
     xlabel('时间 (小时)');
     ylabel('氧浓度 (%)');
     title('1小时数据窗口');
     grid on;
     xlim([0, 1]);
     ylim([-0.5, 10.5]);
     
     % 统计信息面板
     ax3 = subplot(2, 2, 3, 'Parent', tab1);
     axis off;
     h_stats_text = text(0.05, 0.9, '', 'FontSize', 10, 'FontName', 'FixedWidth');
     title('实时统计信息');
     
     % 诊断日志面板
     ax4 = subplot(2, 2, 4, 'Parent', tab1);
     axis off;
     h_log_text = text(0.05, 0.95, '', 'FontSize', 9, 'FontName', 'FixedWidth', ...
                      'VerticalAlignment', 'top');
     title('诊断日志（最近10条）');
     
     % 第二个标签页 - 维修建议
     tab2 = uitab('Parent', tgroup, 'Title', '维修建议');
     
     % 创建滚动面板
     scroll_panel = uipanel('Parent', tab2, 'Position', [0.02 0.02 0.96 0.96]);
     
     % 维修建议文本（使用uitextarea以支持滚动）
     h_maintenance_textarea = uitextarea(scroll_panel, ...
         'Position', [10 10 scroll_panel.Position(3)*fig.Position(3)-20 scroll_panel.Position(4)*fig.Position(4)-20], ...
         'FontSize', 10, ...
         'FontName', 'FixedWidth', ...
         'Editable', 'off', ...
         'Value', {'等待故障诊断...'});
     
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
         
         % 更新日志显示（最近10条）
         all_logs = [alarm_log, log_entries];
         if ~isempty(all_logs)
             recent_logs = all_logs(max(1, end-9):end);
             log_text = strjoin(recent_logs, '\n');
             set(h_log_text, 'String', log_text);
         end
         
         % 更新维修建议显示（在文本区域中）
         if ~isempty(current_maintenance_advice) && isfield(current_maintenance_advice, 'all_suggestions') && ~isempty(current_maintenance_advice.all_suggestions)
             maint_text_lines = {};
             maint_text_lines{end+1} = '【当前故障维修建议汇总】';
             maint_text_lines{end+1} = sprintf('共有 %d 种可能的故障原因', length(current_maintenance_advice.all_suggestions));
             maint_text_lines{end+1} = '═══════════════════════════════════════════════════════════';
             maint_text_lines{end+1} = '';
             
             % 显示所有故障原因
             for k = 1:length(current_maintenance_advice.all_suggestions)
                 suggestion = current_maintenance_advice.all_suggestions{k};
                 
                 maint_text_lines{end+1} = sprintf('【故障%d】故障代码: %s - %s', ...
                                                k, suggestion.fault_code, suggestion.fault_name);
                 maint_text_lines{end+1} = sprintf('故障描述: %s', suggestion.description);
                 maint_text_lines{end+1} = sprintf('严重程度: %s | 优先级: %d', ...
                                                suggestion.severity, suggestion.priority);
                 maint_text_lines{end+1} = '维修措施:';
                 
                 % 显示所有步骤
                 if iscell(suggestion.measures)
                     for j = 1:length(suggestion.measures)
                         measure = suggestion.measures{j};
                         maint_text_lines{end+1} = sprintf('  步骤%d: %s', ...
                                                        measure.step, measure.action);
                         maint_text_lines{end+1} = sprintf('         耗时: %s | 工具: %s', ...
                                                        measure.time, measure.tools);
                     end
                 elseif isstruct(suggestion.measures)
                     for j = 1:length(suggestion.measures)
                         measure = suggestion.measures(j);
                         maint_text_lines{end+1} = sprintf('  步骤%d: %s', ...
                                                        measure.step, measure.action);
                         maint_text_lines{end+1} = sprintf('         耗时: %s | 工具: %s', ...
                                                        measure.time, measure.tools);
                     end
                 end
                 
                 if k < length(current_maintenance_advice.all_suggestions)
                     maint_text_lines{end+1} = '';
                     maint_text_lines{end+1} = '───────────────────────────────────────────────────────────';
                     maint_text_lines{end+1} = '';
                 end
             end
             
             maint_text_lines{end+1} = '';
             maint_text_lines{end+1} = '═══════════════════════════════════════════════════════════';
             
             set(h_maintenance_textarea, 'Value', maint_text_lines);
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
%% 生成最终报告（与之前相同）
%% ========================================

fprintf('\n════════════════════════════════════════\n');
fprintf('         监控模拟完成\n');
fprintf('════════════════════════════════════════\n\n');

% ... 报告生成代码与之前相同 ...

%% ========================================
%% 核心诊断函数定义（与之前相同）
%% ========================================

% 所有函数定义与O2_Diagnosis_System_Final.m相同
% 包括：
% - detect_data_hold
% - get_maintenance_advice
% - format_maintenance_advice
% - realtime_detection_enhanced
% - periodic_diagnosis_enhanced
% - check_periodic_alarm
% - iif
% - create_measure
% - init_maintenance_database

% [由于篇幅限制，这里省略了具体函数实现，实际使用时需要包含完整的函数定义]