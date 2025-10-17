% Magnos206磁力机械氧分析仪模拟数据生成器
% 生成10种类型数据（每种类型前半天正常+后半天异常），保存至Excel文件
% 包含数据保持功能：前半天最后一个数据在后半天保持不变

clear; clc;

%% 一、可调整参数设置
range_min = 0;              % 量程下限 (%)
range_max = 10;             % 量程上限 (%)
normal_mean = 5;            % 正常平均值 (%)
normal_fluctuation = 0.1;   % 正常波动幅度 (±10%)
base_offset = 1;            % 基准偏移量 (%)
small_offset_ratio = 0.75;  % 小幅度偏移比例 (75%)
large_offset_ratio = 1.5;   % 大幅度偏移比例 (150%)
severe_fluctuation = 0.2;   % 剧烈波动幅度 (±20%)

% 时间参数
points_per_hour = 3600;     % 每小时的秒数
hours_per_day = 24;         % 一天24小时
num_points = points_per_hour * hours_per_day;  % 一天的总秒数（86400）
points_per_half = num_points / 2;  % 每半天的秒数（43200）

% 生成时间戳（以小时为单位，从00:00开始）
time_stamps_seconds = (1:num_points)';  % 秒数时间戳
time_stamps_hours = (time_stamps_seconds - 1) / 3600;  % 转换为小时（从0开始）

% 生成时间字符串（HH:MM格式）
hours = floor(time_stamps_hours);
minutes = floor((time_stamps_hours - hours) * 60);
time_strings = arrayfun(@(h, m) sprintf('%02d:%02d', h, m), hours, minutes, 'UniformOutput', false);

%% 二、生成各类型数据

fprintf('========================================\n');
fprintf('开始生成Magnos206氧分析仪10种类型模拟数据\n');
fprintf('每种类型：前12小时正常 + 后12小时异常\n');
fprintf('========================================\n\n');

% 预设标准差
normal_std = normal_mean * normal_fluctuation / 3;
severe_std = normal_mean * severe_fluctuation / 3;

%% 新增数据保持功能
% 数据保持类型：前半天正常 + 后半天数据保持
fprintf('[1/10] 正在生成数据保持：前半天正常 + 后半天保持最后值...\n');
% 前半天正常数据
first_half_hold = normal_mean + normal_std * randn(points_per_half, 1);
first_half_hold = max(range_min, min(range_max, first_half_hold));

% 后半天：保持前半天最后一个数据值不变
last_value = first_half_hold(end);
second_half_hold = ones(points_per_half, 1) * last_value;

day_hold_data = [first_half_hold; second_half_hold];

%% 1. 全天正常
fprintf('[2/10] 正在生成全天正常数据...\n');
day1_data = normal_mean + normal_std * randn(num_points, 1);
day1_data = max(range_min, min(range_max, day1_data));

%% 2. 小幅度正向偏移 - 前半天正常 + 后半天小幅度正向偏移（逐渐偏移）
fprintf('[3/10] 正在生成小幅度正向偏移数据：前半天正常 + 后半天偏移...\n');
% 前半天正常数据
first_half = normal_mean + normal_std * randn(points_per_half, 1);
first_half = max(range_min, min(range_max, first_half));

% 后半天：在正常数据基础上逐渐增加偏移
second_half_base = normal_mean + normal_std * randn(points_per_half, 1);
small_positive_offset = base_offset * small_offset_ratio;  % 0.75%
linear_offset = linspace(0, small_positive_offset, points_per_half)';
second_half = second_half_base + linear_offset;
second_half = max(range_min, min(range_max, second_half));

% 确保连续性：调整后半天第一个数据点
second_half(1) = first_half(end);

day2_data = [first_half; second_half];

%% 3. 小幅度负向偏移 - 前半天正常 + 后半天小幅度负向偏移（逐渐偏移）
fprintf('[4/10] 正在生成小幅度负向偏移数据：前半天正常 + 后半天偏移...\n');
first_half = normal_mean + normal_std * randn(points_per_half, 1);
first_half = max(range_min, min(range_max, first_half));

second_half_base = normal_mean + normal_std * randn(points_per_half, 1);
small_negative_offset = -base_offset * small_offset_ratio;  % -0.75%
linear_offset = linspace(0, small_negative_offset, points_per_half)';
second_half = second_half_base + linear_offset;
second_half = max(range_min, min(range_max, second_half));

second_half(1) = first_half(end);
day3_data = [first_half; second_half];

%% 4. 大幅度正向偏移 - 前半天正常 + 后半天大幅度正向偏移（逐渐偏移）
fprintf('[5/10] 正在生成大幅度正向偏移数据：前半天正常 + 后半天偏移...\n');
first_half = normal_mean + normal_std * randn(points_per_half, 1);
first_half = max(range_min, min(range_max, first_half));

second_half_base = normal_mean + normal_std * randn(points_per_half, 1);
large_positive_offset = base_offset * large_offset_ratio;  % 1.5%
linear_offset = linspace(0, large_positive_offset, points_per_half)';
second_half = second_half_base + linear_offset;
second_half = max(range_min, min(range_max, second_half));

second_half(1) = first_half(end);
day4_data = [first_half; second_half];

%% 5. 大幅度负向偏移 - 前半天正常 + 后半天大幅度负向偏移（逐渐偏移）
fprintf('[6/10] 正在生成大幅度负向偏移数据：前半天正常 + 后半天偏移...\n');
first_half = normal_mean + normal_std * randn(points_per_half, 1);
first_half = max(range_min, min(range_max, first_half));

second_half_base = normal_mean + normal_std * randn(points_per_half, 1);
large_negative_offset = -base_offset * large_offset_ratio;  % -1.5%
linear_offset = linspace(0, large_negative_offset, points_per_half)';
second_half = second_half_base + linear_offset;
second_half = max(range_min, min(range_max, second_half));

second_half(1) = first_half(end);
day5_data = [first_half; second_half];

%% 6. 剧烈波动异常 - 前半天正常 + 后半天剧烈波动（连续）
fprintf('[7/10] 正在生成剧烈波动异常数据：前半天正常 + 后半天波动...\n');
first_half = normal_mean + normal_std * randn(points_per_half, 1);
first_half = max(range_min, min(range_max, first_half));

second_half = normal_mean + severe_std * randn(points_per_half, 1);
second_half = max(range_min, min(range_max, second_half));

second_half(1) = first_half(end);
day6_data = [first_half; second_half];

%% 7. 满量程输出异常 - 前半天正常 + 后半天满量程输出（不连续）
fprintf('[8/10] 正在生成满量程输出异常数据：前半天正常 + 后半天满量程...\n');
first_half = normal_mean + normal_std * randn(points_per_half, 1);
first_half = max(range_min, min(range_max, first_half));

second_half = ones(points_per_half, 1) * range_max;  % 恒定10%

day7_data = [first_half; second_half];

%% 8. 零位输出异常 - 前半天正常 + 后半天零位输出（不连续）
fprintf('[9/10] 正在生成零位输出异常数据：前半天正常 + 后半天零位...\n');
first_half = normal_mean + normal_std * randn(points_per_half, 1);
first_half = max(range_min, min(range_max, first_half));

second_half = zeros(points_per_half, 1);  % 恒定0%

day8_data = [first_half; second_half];

%% 9. 信号丢失异常 - 前半天正常 + 后半天信号丢失（不连续）
fprintf('[10/10] 正在生成信号丢失异常数据：前半天正常 + 后半天信号丢失...\n');
first_half = normal_mean + normal_std * randn(points_per_half, 1);
first_half = max(range_min, min(range_max, first_half));

second_half = NaN(points_per_half, 1);  % 全部NaN

day9_data = [first_half; second_half];

fprintf('\n所有数据类型生成完成！\n\n');

%% 三、创建Excel文件并写入数据

filename = 'Magnos206_SimulationData_Optimized.xlsx';

sheet_names = {'数据保持', ...
               '全天正常', ...
               '小幅度正向偏移', '小幅度负向偏移', ...
               '大幅度正向偏移', '大幅度负向偏移', ...
               '剧烈波动异常', ...
               '满量程输出异常', '零位输出异常', '信号丢失异常'};

data_sets = {day_hold_data, day1_data, day2_data, day3_data, day4_data, day5_data, ...
             day6_data, day7_data, day8_data, day9_data};

if exist(filename, 'file')
    delete(filename);
    fprintf('已删除旧文件: %s\n\n', filename);
end

fprintf('========================================\n');
fprintf('开始写入Excel文件\n');
fprintf('========================================\n\n');

for i = 1:length(sheet_names)
    fprintf('[%d/%d] 正在写入工作表: %s\n', i, length(sheet_names), sheet_names{i});
    
    % 创建包含时间字符串、小时数和氧浓度的数据表
    data_table = table(time_strings, time_stamps_hours, data_sets{i}, ...
                      'VariableNames', {'时间_HH:MM', '时间_小时', '氧浓度_%'});
    
    writetable(data_table, filename, 'Sheet', i, 'WriteMode', 'overwritesheet');
    
    % 显示前后半天的统计信息
    first_half_data = data_sets{i}(1:points_per_half);
    second_half_data = data_sets{i}(points_per_half+1:end);
    
    fprintf('   前半天(00:00-11:59): 均值=%.4f%%, 标准差=%.4f%%\n', ...
            mean(first_half_data, 'omitnan'), std(first_half_data, 'omitnan'));
    
    if all(isnan(second_half_data))
        fprintf('   后半天(12:00-23:59): 信号丢失(NaN)\n');
    else
        fprintf('   后半天(12:00-23:59): 均值=%.4f%%, 标准差=%.4f%%\n', ...
                mean(second_half_data, 'omitnan'), std(second_half_data, 'omitnan'));
    end
    
    if i == 1  % 数据保持示例
        fprintf('   数据保持值: %.4f%% (从12:00开始保持)\n', last_value);
    end
    
    fprintf('   连续性检查: 前半天末值=%.4f%%, 后半天首值=%.4f%%\n\n', ...
            first_half_data(end), second_half_data(1));
end

%% 四、生成完成提示和汇总信息

fprintf('========================================\n');
fprintf('数据生成与写入完成！\n');
fprintf('========================================\n');
fprintf('文件名称: %s\n', filename);
fprintf('工作表数量: %d个\n', length(sheet_names));
fprintf('每个工作表数据点: %d个 (前12小时 + 后12小时)\n', num_points);
fprintf('数据总量: %d个数据点\n', num_points * length(sheet_names));
fprintf('文件大小: 约%.2f MB\n', num_points * length(sheet_names) * 8 / 1024 / 1024);
fprintf('数据类型: %d种（含数据保持、正常、各类异常）\n', length(sheet_names));
fprintf('========================================\n\n');

%% 五、数据可视化预览

fprintf('正在生成数据预览图...\n');

figure('Name', 'Magnos206数据预览（各故障类型）', 'Position', [50, 50, 1600, 1000]);

% 绘制10个子图（包含数据保持示例）
for i = 1:length(sheet_names)
    if i <= 5
        subplot(4, 3, i);
    elseif i == 6
        subplot(4, 3, 7);
    else
        subplot(4, 3, i+1);
    end
    
    % 绘制完整的一天数据（使用小时作为横轴）
    if ~all(isnan(data_sets{i}))
        plot(time_stamps_hours, data_sets{i}, 'LineWidth', 1, 'Color', [0.2 0.4 0.8]);
        
        % 添加分界线标记前后半天（12小时处）
        hold on;
        plot([12, 12], [range_min-0.5, range_max+0.5], ...
             'r--', 'LineWidth', 1.5);
        
        % 如果是数据保持示例，添加特殊标记
        if i == 1
            plot(time_stamps_hours(points_per_half+1:end), ...
                 data_sets{i}(points_per_half+1:end), ...
                 'LineWidth', 2, 'Color', [0.8 0.2 0.2]);
            text(18, last_value + 0.3, sprintf('保持值: %.2f%%', last_value), ...
                 'FontSize', 8, 'Color', 'red', 'FontWeight', 'bold');
        end
        hold off;
        
        % 添加统计信息
        first_half_mean = mean(data_sets{i}(1:points_per_half), 'omitnan');
        second_half_mean = mean(data_sets{i}(points_per_half+1:end), 'omitnan');
        
        text_str = sprintf('前12h均值: %.2f%%\n后12h均值: %.2f%%', ...
                          first_half_mean, second_half_mean);
        text(15, range_max*0.85, text_str, 'FontSize', 7, ...
             'BackgroundColor', 'white', 'EdgeColor', 'black');
    else
        % 特殊处理全NaN情况
        plot(time_stamps_hours(1:points_per_half), data_sets{i}(1:points_per_half), ...
             'LineWidth', 1, 'Color', [0.2 0.4 0.8]);
        hold on;
        plot([12, 12], [range_min-0.5, range_max+0.5], ...
             'r--', 'LineWidth', 1.5);
        text(18, range_max/2, '信号丢失', 'FontSize', 10, ...
             'Color', 'red', 'FontWeight', 'bold');
        hold off;
    end
    
    title(sheet_names{i}, 'FontSize', 10, 'FontWeight', 'bold');
    xlabel('时间 (小时)', 'FontSize', 8);
    ylabel('氧浓度 (%)', 'FontSize', 8);
    grid on;
    ylim([range_min-0.5, range_max+0.5]);
    xlim([0, 24]);
    
    % 设置x轴刻度
    set(gca, 'XTick', 0:6:24);
    set(gca, 'XTickLabel', {'00:00', '06:00', '12:00', '18:00', '24:00'});
end

sgtitle('Magnos206氧分析仪 - 各类型数据预览（红色虚线为12:00分界线）', ...
        'FontSize', 14, 'FontWeight', 'bold');

preview_filename = 'Magnos206_DataPreview_AllTypes.png';
saveas(gcf, preview_filename);
fprintf('预览图已保存: %s\n\n', preview_filename);

%% 六、生成详细报告

fprintf('========================================\n');
fprintf('各类型数据详细信息汇总\n');
fprintf('========================================\n\n');

for i = 1:length(sheet_names)
    fprintf('【%s】\n', sheet_names{i});
    fprintf('----------------------------------------\n');
    fprintf('前半天(00:00-11:59): ');
    if i == 1
        fprintf('正常数据\n');
    else
        fprintf('正常数据\n');
    end
    fprintf('  均值: %.6f%%, 标准差: %.6f%%\n', ...
            mean(data_sets{i}(1:points_per_half), 'omitnan'), ...
            std(data_sets{i}(1:points_per_half), 'omitnan'));
    
    fprintf('后半天(12:00-23:59): ');
    if i == 1
        fprintf('数据保持（保持前半天最后值）\n');
        fprintf('  保持值: %.6f%%\n', last_value);
    elseif i == 2
        fprintf('正常数据\n');
    elseif i == 3
        fprintf('小幅度正向偏移(逐渐偏移)\n');
    elseif i == 4
        fprintf('小幅度负向偏移(逐渐偏移)\n');
    elseif i == 5
        fprintf('大幅度正向偏移(逐渐偏移)\n');
    elseif i == 6
        fprintf('大幅度负向偏移(逐渐偏移)\n');
    elseif i == 7
        fprintf('剧烈波动异常\n');
    elseif i == 8
        fprintf('满量程输出异常\n');
    elseif i == 9
        fprintf('零位输出异常\n');
    elseif i == 10
        fprintf('信号丢失异常\n');
    end
    
    if ~all(isnan(data_sets{i}(points_per_half+1:end)))
        fprintf('  均值: %.6f%%, 标准差: %.6f%%\n', ...
                mean(data_sets{i}(points_per_half+1:end), 'omitnan'), ...
                std(data_sets{i}(points_per_half+1:end), 'omitnan'));
    else
        fprintf('  所有数据为NaN\n');
    end
    
    fprintf('连续性: ');
    if i == 1 || (i >= 3 && i <= 7)
        fprintf('连续（前后半天数据点相连）\n');
    else
        fprintf('不连续（前后半天存在突变）\n');
    end
    fprintf('\n');
end

fprintf('========================================\n');
fprintf('程序执行完成！\n');
fprintf('========================================\n');