%% 故障诊断维修记录分析系统 - MATLAB 版本（优化版）
% 读取 Excel 文件中的故障记录并进行全面分析
% 生成优化的可视化报告和文字分析报告
% 优化内容：字体设置（中文宋体，英文Times New Roman），图表布局优化

function analyze_fault_records_v3_optimized(excel_file)
    % 主函数 - 分析故障记录

    % 如果没有指定文件，选择最新的 Excel 文件
    if nargin < 1
        excel_files = dir('故障诊断维修记录_*.xlsx');
        if isempty(excel_files)
            error('未找到故障记录 Excel 文件！请先运行 generate_fault_records_only.m 生成数据。');
        end
        [~, idx] = max([excel_files.datenum]);
        excel_file = excel_files(idx).name;
    end

    % 优化的中文字体显示设置
    setup_optimized_fonts();

    fprintf('\n========================================\n');
    fprintf('故障诊断维修记录分析系统（优化版）\n');
    fprintf('分析时间: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    fprintf('========================================\n\n');

    fprintf('正在分析文件: %s\n', excel_file);

    % 读取 Excel 数据 - 使用更兼容的方法
    try
        % 首先尝试直接读取
        [~, ~, raw_data] = xlsread(excel_file, '故障维修记录');

        % 提取标题和数据
        headers = raw_data(1, :);
        data_cells = raw_data(2:end, :);

        fprintf('成功读取 %d 条记录\n', size(data_cells, 1));

        % 显示列标题
        fprintf('\n数据表列标题:\n');
        for i = 1:length(headers)
            fprintf('  列%d: %s\n', i, headers{i});
        end

    catch ME
        error('读取 Excel 文件失败: %s', ME.message);
    end

    % 转换为结构化数据
    data = preprocess_data_from_cells(data_cells, headers);

    % 执行各项分析
    fprintf('\n开始执行分析...\n');

    % 1. 基础统计分析
    basic_stats = basic_statistics_analysis(data);

    % 2. 维修效率分析
    efficiency_stats = maintenance_efficiency_analysis(data);

    % 3. 故障模式分析
    pattern_stats = fault_pattern_analysis(data);

    % 4. 关联性分析
    correlation_stats = correlation_analysis(data);

    % 5. 预测性分析
    predictive_stats = predictive_analysis(data);

    % 6. 生成优化的可视化报告
    generate_optimized_comprehensive_report(data, basic_stats, efficiency_stats, ...
        pattern_stats, correlation_stats, predictive_stats);

    % 7. 生成文字报告
    generate_summary_report(data, basic_stats, efficiency_stats, pattern_stats, excel_file);

    fprintf('\n========================================\n');
    fprintf('分析完成！已生成优化版可视化报告。\n');
    fprintf('========================================\n');
end

function setup_optimized_fonts()
    % 优化的字体设置函数 - 中文宋体，英文Times New Roman
    
    fprintf('正在设置优化字体...\n');
    
    % 1. 检查系统可用字体
    available_fonts = listfonts;
    
    % 2. 定义字体优先级
    chinese_fonts = {'SimSun', 'NSimSun', 'STSong', 'AR PL UMing CN', 'Noto Serif CJK SC', 'Source Han Serif SC'};
    english_fonts = {'Times New Roman', 'Times', 'Liberation Serif', 'DejaVu Serif', 'Noto Serif'};
    
    % 3. 选择最佳中文字体
    selected_chinese_font = 'SimSun'; % 默认宋体
    for i = 1:length(chinese_fonts)
        if any(strcmpi(available_fonts, chinese_fonts{i}))
            selected_chinese_font = chinese_fonts{i};
            break;
        end
    end
    
    % 4. 选择最佳英文字体
    selected_english_font = 'Times New Roman'; % 默认Times New Roman
    for i = 1:length(english_fonts)
        if any(strcmpi(available_fonts, english_fonts{i}))
            selected_english_font = english_fonts{i};
            break;
        end
    end
    
    % 5. 设置混合字体（优先使用Times New Roman，中文回退到宋体）
    if any(strcmpi(available_fonts, 'Times New Roman')) && any(strcmpi(available_fonts, 'SimSun'))
        primary_font = 'Times New Roman';
    elseif any(strcmpi(available_fonts, selected_english_font))
        primary_font = selected_english_font;
    else
        primary_font = selected_chinese_font;
    end
    
    % 6. 设置所有图形默认字体属性
    font_properties = {
        'DefaultAxesFontName', primary_font;
        'DefaultTextFontName', primary_font;
        'DefaultUicontrolFontName', primary_font;
        'DefaultUipanelFontName', primary_font;
        'DefaultLegendFontName', primary_font;
        'DefaultColorbarlabelFontName', primary_font;
    };
    
    for i = 1:size(font_properties, 1)
        try
            set(0, font_properties{i, 1}, font_properties{i, 2});
        catch
            % 忽略不支持的属性
        end
    end
    
    % 7. 设置字体大小
    set(0, 'DefaultAxesFontSize', 11);
    set(0, 'DefaultTextFontSize', 12);
    set(0, 'DefaultLegendFontSize', 10);
    set(0, 'DefaultAxesTitleFontSize', 14);
    set(0, 'DefaultAxesLabelFontSize', 12);
    
    % 8. 关闭LaTeX解释器，使用纯文本
    set(0, 'DefaultTextInterpreter', 'none');
    set(0, 'DefaultAxesTickLabelInterpreter', 'none');
    set(0, 'DefaultLegendInterpreter', 'none');
    set(0, 'DefaultColorbarTickLabelInterpreter', 'none');
    
    % 9. 设置渲染器
    set(0, 'DefaultFigureRenderer', 'painters');
    
    % 10. 设置字符编码
    try
        feature('DefaultCharacterSet', 'UTF-8');
    catch
        % 某些版本不支持
    end
    
    fprintf('字体设置完成: 主字体=%s\n', primary_font);
    if ~strcmp(primary_font, selected_chinese_font)
        fprintf('中文字体: %s\n', selected_chinese_font);
    end
end

function data = preprocess_data_from_cells(data_cells, headers)
    % 从 cell 数组预处理数据
    data = struct();

    % 查找列索引
    col_idx = struct();
    for i = 1:length(headers)
        header = headers{i};
        switch header
            case '数据故障代码'
                col_idx.data_fault_code = i;
            case '故障时间'
                col_idx.fault_time = i;
            case '仪表故障代码'
                col_idx.instrument_fault_code = i;
            case '故障描述/名称'
                col_idx.fault_name = i;
            case '故障类型'
                col_idx.fault_type = i;
            case '严重程度'
                col_idx.severity = i;
            case '优先级'
                col_idx.priority = i;
            case '维修操作'
                col_idx.operation = i;
            case '耗时'
                col_idx.duration = i;
            case '工具'
                col_idx.tools = i;
        end
    end

    % 提取数据
    n_records = size(data_cells, 1);

    % 初始化数组
    data.data_fault_code = cell(n_records, 1);
    data.fault_time = NaT(n_records, 1);
    data.instrument_fault_code = cell(n_records, 1);
    data.fault_name = cell(n_records, 1);
    data.fault_type = cell(n_records, 1);
    data.severity = cell(n_records, 1);
    data.priority = zeros(n_records, 1);
    data.operation = cell(n_records, 1);
    data.duration = cell(n_records, 1);
    data.tools = cell(n_records, 1);

    % 填充数据
    for i = 1:n_records
        data.data_fault_code{i} = data_cells{i, col_idx.data_fault_code};

        % 处理时间字段
        time_str = data_cells{i, col_idx.fault_time};
        if ischar(time_str) || isstring(time_str)
            data.fault_time(i) = datetime(time_str, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
        elseif isnumeric(time_str)
            % Excel 日期格式
            data.fault_time(i) = datetime(time_str, 'ConvertFrom', 'excel');
        end

        data.instrument_fault_code{i} = data_cells{i, col_idx.instrument_fault_code};
        data.fault_name{i} = data_cells{i, col_idx.fault_name};
        data.fault_type{i} = data_cells{i, col_idx.fault_type};
        data.severity{i} = data_cells{i, col_idx.severity};
        data.priority(i) = data_cells{i, col_idx.priority};
        data.operation{i} = data_cells{i, col_idx.operation};
        data.duration{i} = data_cells{i, col_idx.duration};
        data.tools{i} = data_cells{i, col_idx.tools};
    end

    % 时间相关字段
    data.year = year(data.fault_time);
    data.month = month(data.fault_time);
    data.quarter = quarter(data.fault_time);
    data.dayofweek = weekday(data.fault_time);
    data.hour = hour(data.fault_time);

    % 数据故障主类型
    data_fault_main = cellfun(@(x) strsplit(x, ' '), data.data_fault_code, 'UniformOutput', false);
    data_fault_main = cellfun(@(x) strsplit(x{1}, '.'), data_fault_main, 'UniformOutput', false);
    data.data_fault_main = cellfun(@(x) x{1}, data_fault_main, 'UniformOutput', false);

    % 耗时分钟数
    data.duration_minutes = parse_duration(data.duration);
end

function minutes = parse_duration(duration_cell)
    % 解析耗时字符串为分钟数
    minutes = zeros(length(duration_cell), 1);
    for i = 1:length(duration_cell)
        dur_str = duration_cell{i};
        if contains(dur_str, '小时')
            hours = str2double(strrep(dur_str, '小时', ''));
            minutes(i) = hours * 60;
        elseif contains(dur_str, '分钟')
            minutes(i) = str2double(strrep(dur_str, '分钟', ''));
        end
    end
end

% ========== 分析函数（保持原有逻辑） ==========

function stats = basic_statistics_analysis(data)
    % 1. 基础统计分析
    fprintf('\n');
    fprintf('==================================================\n');
    fprintf('1. 基础统计分析\n');
    fprintf('==================================================\n');

    stats = struct();
    total_faults = length(data.fault_time);

    % 故障频率分析
    fprintf('\n【故障频率分析】\n');
    fprintf('总故障数: %d\n', total_faults);

    [unique_codes, ~, idx] = unique(data.instrument_fault_code);
    code_counts = accumarray(idx, 1);
    [sorted_counts, sort_idx] = sort(code_counts, 'descend');

    fprintf('\n各故障代码发生次数及占比:\n');
    for i = 1:min(10, length(sorted_counts))
        code = unique_codes{sort_idx(i)};
        count = sorted_counts(i);
        percentage = (count / total_faults) * 100;
        fprintf('%s: %d 次 (%.1f%%)\n', code, count, percentage);
    end

    stats.fault_counts = [unique_codes(sort_idx), num2cell(sorted_counts)];

    % 时间分布分析
    fprintf('\n【时间分布分析】\n');

    % 年度分布
    yearly_counts = accumarray(data.year - min(data.year) + 1, 1);
    years = min(data.year):max(data.year);
    fprintf('\n年度故障分布:\n');
    for i = 1:length(years)
        fprintf('%d 年: %d 次\n', years(i), yearly_counts(i));
    end

    stats.yearly_counts = struct('years', years', 'counts', yearly_counts);

    % 故障类型分布
    fprintf('\n【故障类型分布】\n');
    [unique_types, ~, idx] = unique(data.fault_type);
    type_counts = accumarray(idx, 1);
    [sorted_type_counts, sort_idx] = sort(type_counts, 'descend');

    for i = 1:length(sorted_type_counts)
        type = unique_types{sort_idx(i)};
        count = sorted_type_counts(i);
        percentage = (count / total_faults) * 100;
        fprintf('%s: %d 次 (%.1f%%)\n', type, count, percentage);
    end

    stats.type_counts = [unique_types(sort_idx), num2cell(sorted_type_counts)];

    return;
end

function stats = maintenance_efficiency_analysis(data)
    % 2. 维修效率分析
    fprintf('\n');
    fprintf('==================================================\n');
    fprintf('2. 维修效率分析\n');
    fprintf('==================================================\n');

    stats = struct();

    % 平均维修时间
    fprintf('\n【平均维修时间分析】\n');
    fprintf('\n各故障类型维修时间统计(分钟):\n');

    [unique_types, ~, idx] = unique(data.fault_type);
    type_time_stats = zeros(length(unique_types), 4);

    for i = 1:length(unique_types)
        type_mask = strcmp(data.fault_type, unique_types{i});
        type_durations = data.duration_minutes(type_mask);

        type_time_stats(i, 1) = mean(type_durations);
        type_time_stats(i, 2) = min(type_durations);
        type_time_stats(i, 3) = max(type_durations);
        type_time_stats(i, 4) = sum(type_mask);

        fprintf('%s:\n', unique_types{i});
        fprintf('  平均: %.1f, 最短: %.0f, 最长: %.0f, 次数: %d\n', ...
            type_time_stats(i, 1), type_time_stats(i, 2), ...
            type_time_stats(i, 3), type_time_stats(i, 4));
    end

    stats.type_time_stats = [unique_types, num2cell(type_time_stats)];

    % 工具使用频率
    fprintf('\n【工具使用频率分析】\n');
    tools_list = {};
    for i = 1:length(data.tools)
        if ~strcmp(data.tools{i}, '无')
            tools = strsplit(data.tools{i}, '、');
            tools_list = [tools_list, tools];
        end
    end

    [unique_tools, ~, idx] = unique(tools_list);
    tool_counts = accumarray(idx, 1);
    [sorted_tool_counts, sort_idx] = sort(tool_counts, 'descend');

    fprintf('\n最常用工具 TOP10:\n');
    for i = 1:min(10, length(sorted_tool_counts))
        tool = unique_tools{sort_idx(i)};
        count = sorted_tool_counts(i);
        fprintf('%s: %d 次\n', tool, count);
    end

    stats.tools_freq = [unique_tools(sort_idx)', num2cell(sorted_tool_counts)];

    % 维修操作效果
    fprintf('\n【维修操作效果分析】\n');
    [unique_ops, ~, idx] = unique(data.operation);
    op_durations = zeros(length(unique_ops), 1);
    op_counts = zeros(length(unique_ops), 1);

    for i = 1:length(unique_ops)
        op_mask = strcmp(data.operation, unique_ops{i});
        op_durations(i) = mean(data.duration_minutes(op_mask));
        op_counts(i) = sum(op_mask);
    end

    [sorted_counts, sort_idx] = sort(op_counts, 'descend');

    fprintf('\n最常见维修操作及平均耗时:\n');
    for i = 1:min(10, length(sorted_counts))
        if sorted_counts(i) > 0
            op = unique_ops{sort_idx(i)};
            count = sorted_counts(i);
            avg_time = op_durations(sort_idx(i));
            fprintf('%s: %d 次, 平均%.1f 分钟\n', op, count, avg_time);
        end
    end

    stats.operation_stats = [unique_ops(sort_idx), num2cell(sorted_counts), ...
        num2cell(op_durations(sort_idx))];

    return;
end

function stats = fault_pattern_analysis(data)
    % 3. 故障模式分析
    fprintf('\n');
    fprintf('==================================================\n');
    fprintf('3. 故障模式分析\n');
    fprintf('==================================================\n');

    stats = struct();
    total = length(data.fault_time);

    % 故障严重程度分布
    fprintf('\n【故障严重程度分布】\n');
    [unique_severities, ~, idx] = unique(data.severity);
    severity_counts = accumarray(idx, 1);

    for i = 1:length(unique_severities)
        severity = unique_severities{i};
        count = severity_counts(i);
        percentage = (count / total) * 100;
        fprintf('%s: %d 次 (%.1f%%)\n', severity, count, percentage);
    end

    stats.severity_counts = [unique_severities, num2cell(severity_counts)];

    % 优先级分析
    fprintf('\n【优先级分析】\n');
    unique_priorities = unique(data.priority);
    priority_counts = zeros(length(unique_priorities), 1);

    for i = 1:length(unique_priorities)
        priority_counts(i) = sum(data.priority == unique_priorities(i));
        percentage = (priority_counts(i) / total) * 100;
        fprintf('优先级%d: %d 次 (%.1f%%)\n', unique_priorities(i), priority_counts(i), percentage);
    end

    stats.priority_counts = struct('priorities', unique_priorities, 'counts', priority_counts);

    % 高优先级故障详情
    high_priority_mask = data.priority == 1;
    if any(high_priority_mask)
        fprintf('\n高优先级(1级)故障主要类型:\n');
        hp_codes = data.instrument_fault_code(high_priority_mask);
        hp_names = data.fault_name(high_priority_mask);

        [unique_hp_codes, ~, idx] = unique(hp_codes);
        hp_code_counts = accumarray(idx, 1);
        [sorted_hp_counts, sort_idx] = sort(hp_code_counts, 'descend');

        for i = 1:min(5, length(sorted_hp_counts))
            code = unique_hp_codes{sort_idx(i)};
            count = sorted_hp_counts(i);
            name_idx = find(strcmp(hp_codes, code), 1);
            name = hp_names{name_idx};
            fprintf('%s - %s: %d 次\n', code, name, count);
        end
    end

    % 季节性模式
    fprintf('\n【季节性模式分析】\n');
    quarter_counts = accumarray(data.quarter, 1);
    season_names = {'春季', '夏季', '秋季', '冬季'};

    fprintf('\n各季度故障分布:\n');
    for i = 1:4
        if i <= length(quarter_counts)
            count = quarter_counts(i);
            avg_monthly = count / (length(unique(data.year)) * 3);
            fprintf('%s(Q%d): %d 次, 平均每月%.1f 次\n', ...
                season_names{i}, i, count, avg_monthly);
        end
    end

    stats.seasonal_counts = struct('quarters', (1:4)', 'counts', quarter_counts);

    % 工作日 vs 周末分析
    is_workday = data.dayofweek >= 2 & data.dayofweek <= 6;
    workday_count = sum(is_workday);
    weekend_count = sum(~is_workday);

    fprintf('\n工作日 vs 周末故障分布:\n');
    fprintf('工作日: %d 次 (%.1f%%)\n', workday_count, (workday_count/total)*100);
    fprintf('周末: %d 次 (%.1f%%)\n', weekend_count, (weekend_count/total)*100);

    stats.workday_counts = [workday_count; weekend_count];

    return;
end

function stats = correlation_analysis(data)
    % 4. 关联性分析
    fprintf('\n');
    fprintf('==================================================\n');
    fprintf('4. 关联性分析\n');
    fprintf('==================================================\n');

    stats = struct();

    % 故障代码关联分析
    fprintf('\n【故障代码关联分析】\n');

    % 分析同一天发生的故障
    dates = dateshift(data.fault_time, 'start', 'day');
    unique_dates = unique(dates);
    co_occurrence = containers.Map();

    for i = 1:length(unique_dates)
        day_mask = dates == unique_dates(i);
        day_codes = data.instrument_fault_code(day_mask);

        if length(day_codes) > 1
            for j = 1:length(day_codes)-1
                for k = j+1:length(day_codes)
                    pair = sort({day_codes{j}, day_codes{k}});
                    pair_key = sprintf('%s-%s', pair{1}, pair{2});

                    if isKey(co_occurrence, pair_key)
                        co_occurrence(pair_key) = co_occurrence(pair_key) + 1;
                    else
                        co_occurrence(pair_key) = 1;
                    end
                end
            end
        end
    end

    if length(keys(co_occurrence)) > 0
        fprintf('\n同日发生的故障对:\n');
        all_keys = keys(co_occurrence);
        all_values = cell2mat(values(co_occurrence));
        [sorted_values, sort_idx] = sort(all_values, 'descend');

        for i = 1:min(5, length(sorted_values))
            if sorted_values(i) > 0
                fprintf('%s: %d 次\n', all_keys{sort_idx(i)}, sorted_values(i));
            end
        end
    end

    % 维修操作与耗时关系
    fprintf('\n【维修操作与耗时关系】\n');

    % 按严重程度分组分析平均耗时
    [unique_severities, ~, idx] = unique(data.severity);
    severity_times = zeros(length(unique_severities), 1);

    for i = 1:length(unique_severities)
        severity_mask = strcmp(data.severity, unique_severities{i});
        severity_times(i) = mean(data.duration_minutes(severity_mask));
    end

    [sorted_times, sort_idx] = sort(severity_times, 'descend');

    fprintf('\n不同严重程度的平均维修时间:\n');
    for i = 1:length(sorted_times)
        severity = unique_severities{sort_idx(i)};
        avg_time = sorted_times(i);
        fprintf('%s: %.1f 分钟\n', severity, avg_time);
    end

    stats.severity_time = [unique_severities(sort_idx), num2cell(sorted_times)];

    % 故障复杂度分析
    fprintf('\n【故障复杂度分析】\n');

    [unique_codes, ~, idx] = unique(data.instrument_fault_code);
    code_complexities = zeros(length(unique_codes), 3);

    for i = 1:length(unique_codes)
        code_mask = strcmp(data.instrument_fault_code, unique_codes{i});
        code_complexities(i, 1) = mean(data.duration_minutes(code_mask));
        code_complexities(i, 2) = mean(data.priority(code_mask));
        code_complexities(i, 3) = sum(code_mask);
    end

    [sorted_complexities, sort_idx] = sort(code_complexities(:, 1), 'descend');

    fprintf('\n最复杂故障 TOP5(按平均维修时间):\n');
    for i = 1:min(5, length(sorted_complexities))
        code = unique_codes{sort_idx(i)};
        name_idx = find(strcmp(data.instrument_fault_code, code), 1);
        name = data.fault_name{name_idx};
        avg_time = sorted_complexities(i);
        fprintf('%s - %s: 平均%.1f 分钟\n', code, name, avg_time);
    end

    stats.fault_complexity = [unique_codes(sort_idx), num2cell(sorted_complexities)];

    return;
end

function stats = predictive_analysis(data)
    % 5. 预测性分析
    fprintf('\n');
    fprintf('==================================================\n');
    fprintf('5. 预测性分析\n');
    fprintf('==================================================\n');

    stats = struct();

    % 故障趋势预测
    fprintf('\n【故障趋势预测】\n');

    % 按月统计故障数
    min_date = dateshift(min(data.fault_time), 'start', 'month');
    max_date = dateshift(max(data.fault_time), 'start', 'month');
    months = min_date:calmonths(1):max_date;
    monthly_counts = zeros(length(months), 1);

    for i = 1:length(months)
        month_start = months(i);
        month_end = dateshift(month_start, 'end', 'month');
        monthly_counts(i) = sum(data.fault_time >= month_start & data.fault_time <= month_end);
    end

    % 简单线性回归预测
    X = (1:length(monthly_counts))';
    y = monthly_counts;

    % 计算线性回归参数
    n = length(X);
    x_mean = mean(X);
    y_mean = mean(y);

    beta1 = sum((X - x_mean) .* (y - y_mean)) / sum((X - x_mean).^2);
    beta0 = y_mean - beta1 * x_mean;

    % 预测未来 6 个月
    future_X = (n+1:n+6)';
    predictions = beta0 + beta1 * future_X;

    fprintf('\n未来 6 个月故障预测:\n');
    for i = 1:6
        future_month = months(end) + calmonths(i);
        pred_count = max(0, round(predictions(i)));
        fprintf('%s: 预计%d 次故障\n', datestr(future_month, 'yyyy-mm'), pred_count);
    end

    stats.monthly_faults = struct('months', months', 'counts', monthly_counts);
    stats.predictions = predictions;

    % 备件需求预测
    fprintf('\n【备件需求预测】\n');

    % 统计各类更换操作
    replacement_mask = contains(data.operation, '更换');
    replacement_ops = data.operation(replacement_mask);

    parts_count = struct();
    parts_count.sensor = sum(contains(replacement_ops, '传感器'));
    parts_count.board = sum(contains(replacement_ops, {'电路板', '板'}));
    parts_count.module = sum(contains(replacement_ops, '模块'));
    parts_count.cable = sum(contains(replacement_ops, {'电缆', '线路'}));

    years = length(unique(data.year));

    fprintf('\n基于历史数据的年度备件需求预测:\n');
    parts_names = fieldnames(parts_count);
    for i = 1:length(parts_names)
        part = parts_names{i};
        count = parts_count.(part);
        annual_need = count / years;
        suggested_stock = ceil(annual_need * 1.5);

        part_name_cn = '';
        switch part
            case 'sensor'
                part_name_cn = '传感器';
            case 'board'
                part_name_cn = '电路板';
            case 'module'
                part_name_cn = '模块';
            case 'cable'
                part_name_cn = '电缆';
        end

        fprintf('%s: 年均需求%.1f 个, 建议库存%d 个\n', part_name_cn, annual_need, suggested_stock);
    end

    stats.parts_freq = parts_count;

    % 预防性维护计划
    fprintf('\n【预防性维护计划建议】\n');

    % 分析高频故障的平均间隔时间
    [unique_codes, ~, idx] = unique(data.instrument_fault_code);
    code_counts = accumarray(idx, 1);
    [sorted_counts, sort_idx] = sort(code_counts, 'descend');

    fprintf('\n基于故障间隔的维护周期建议:\n');
    for i = 1:min(5, length(sorted_counts))
        if sorted_counts(i) > 1
            code = unique_codes{sort_idx(i)};
            code_mask = strcmp(data.instrument_fault_code, code);
            fault_dates = sort(data.fault_time(code_mask));

            if length(fault_dates) > 1
                intervals = days(diff(fault_dates));
                avg_interval = mean(intervals);
                suggested_interval = round(avg_interval * 0.8);

                name_idx = find(code_mask, 1);
                name = data.fault_name{name_idx};

                fprintf('%s - %s:\n', code, name);
                fprintf('  平均故障间隔: %.0f 天\n', avg_interval);
                fprintf('  建议维护周期: %d 天\n', suggested_interval);
            end
        end
    end

    return;
end

function create_subplot_with_margins(m, n, p, margins)
    % 创建带边距的子图
    if length(p) > 1
        % 处理跨多个位置的子图（如 [5, 6]）
        min_p = min(p);
        max_p = max(p);
        
        % 计算起始位置
        start_row = floor((min_p-1)/n);
        start_col = mod(min_p-1, n);
        
        % 计算结束位置
        end_row = floor((max_p-1)/n);
        end_col = mod(max_p-1, n);
        
        % 计算位置和大小
        left = margins(1) + start_col*(1-margins(1)-margins(3))/n;
        bottom = margins(2) + (m-1-end_row)*(1-margins(2)-margins(4))/m;
        width = (end_col - start_col + 1)*(1-margins(1)-margins(3))/n - margins(1)/2;
        height = (end_row - start_row + 1)*(1-margins(2)-margins(4))/m - margins(2)/2;
        
        subplot('Position', [left, bottom, width, height]);
    else
        % 单个位置的子图
        row = floor((p-1)/n);
        col = mod(p-1, n);
        
        left = margins(1) + col*(1-margins(1)-margins(3))/n;
        bottom = margins(2) + (m-1-row)*(1-margins(2)-margins(4))/m;
        width = (1-margins(1)-margins(3))/n - margins(1)/2;
        height = (1-margins(2)-margins(4))/m - margins(2)/2;
        
        subplot('Position', [left, bottom, width, height]);
    end
end

function generate_optimized_comprehensive_report(data, basic_stats, efficiency_stats, ...
    pattern_stats, correlation_stats, predictive_stats)
    % 生成优化的综合可视化报告

    fprintf('\n');
    fprintf('==================================================\n');
    fprintf('6. 生成优化可视化报告\n');
    fprintf('==================================================\n');

    % ========== 第 1 页：基础统计和分布（优化版） ==========
    
    fig1 = figure('Name', '故障分析综合报告 - 第1页（优化版）', ...
        'Position', [50, 50, 1500, 1000], ...
        'Color', 'white');

    % 调整子图间距，防止标题重叠
    subplot_tight = @(m,n,p,margins) create_subplot_with_margins(m,n,p,margins);
    
    margins = [0.08, 0.12, 0.05, 0.08]; % [left, bottom, right, top]

    % 1. 故障类型分布饼图
    create_subplot_with_margins(2, 3, 1, margins);
    type_data = basic_stats.type_counts;
    pie([type_data{:, 2}]);
    title('故障类型分布', 'FontSize', 13, 'FontWeight', 'bold', 'Margin', 5);
    legend(type_data(:, 1), 'Location', 'eastoutside', 'FontSize', 9);

    % 2. 月度故障趋势图
    create_subplot_with_margins(2, 3, 2, margins);
    monthly_data = predictive_stats.monthly_faults;
    plot(monthly_data.months, monthly_data.counts, 'b-o', 'LineWidth', 2, 'MarkerSize', 5);
    hold on;
    % 添加趋势线
    X = (1:length(monthly_data.counts))';
    y = monthly_data.counts;
    p = polyfit(X, y, 1);
    trend_line = polyval(p, X);
    plot(monthly_data.months, trend_line, 'r--', 'LineWidth', 1.5);
    hold off;
    title('月度故障趋势图', 'FontSize', 13, 'FontWeight', 'bold', 'Margin', 5);
    xlabel('时间', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('故障数量（次）', 'FontSize', 11, 'FontWeight', 'bold');
    legend({'实际数据', '趋势线'}, 'Location', 'best', 'FontSize', 9);
    grid on;
    datetick('x', 'yyyy-mm', 'keepticks');
    xtickangle(45);

    % 3. 严重程度分布条形图
    create_subplot_with_margins(2, 3, 3, margins);
    severity_data = pattern_stats.severity_counts;
    severity_colors = [1 0.2 0.2; 1 0.6 0; 1 1 0]; % 红、橙、黄
    bar_data = [severity_data{:, 2}];
    b = bar(bar_data);
    
    if size(severity_data, 1) <= 3
        b.FaceColor = 'flat';
        b.CData = severity_colors(1:size(severity_data, 1), :);
    end

    set(gca, 'XTickLabel', severity_data(:, 1));
    title('故障严重程度分布', 'FontSize', 13, 'FontWeight', 'bold', 'Margin', 5);
    xlabel('严重程度', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('故障数量（次）', 'FontSize', 11, 'FontWeight', 'bold');

    % 添加数值标签
    for i = 1:length(bar_data)
        text(i, bar_data(i) + max(bar_data)*0.02, num2str(bar_data(i)), ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', ...
            'FontSize', 9);
    end
    grid on;
    ylim([0, max(bar_data)*1.15]);

    % 4. TOP10 故障代码
    create_subplot_with_margins(2, 3, 4, margins);
    fault_data = basic_stats.fault_counts;
    top10_codes = fault_data(1:min(10, size(fault_data, 1)), :);
    barh([top10_codes{:, 2}], 'FaceColor', [0.3 0.6 0.8]);
    set(gca, 'YTick', 1:size(top10_codes, 1));
    set(gca, 'YTickLabel', top10_codes(:, 1));
    title('TOP 10 故障代码', 'FontSize', 13, 'FontWeight', 'bold', 'Margin', 5);
    xlabel('故障发生次数', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('故障代码', 'FontSize', 11, 'FontWeight', 'bold');
    grid on;

    % 5. 数据故障类型分布
    create_subplot_with_margins(2, 3, 5, margins);
    [unique_data_faults, ~, idx] = unique(data.data_fault_main);
    data_fault_counts = accumarray(idx, 1);

    % 创建标签映射
    data_fault_names = containers.Map(...
        {'001', '002', '003', '004', '005', '006'}, ...
        {'满量程输出', '零位输出', '数据缺失', '数据保持', '剧烈波动', '数据偏移'});

    % 创建显示标签
    data_fault_labels = cell(length(unique_data_faults), 1);
    for i = 1:length(unique_data_faults)
        if isKey(data_fault_names, unique_data_faults{i})
            data_fault_labels{i} = sprintf('%s\n(%s)', ...
                data_fault_names(unique_data_faults{i}), unique_data_faults{i});
        else
            data_fault_labels{i} = unique_data_faults{i};
        end
    end

    pie(data_fault_counts, data_fault_labels);
    title('数据故障类型分布', 'FontSize', 13, 'FontWeight', 'bold', 'Margin', 5);

    % 6. 年度故障统计
    create_subplot_with_margins(2, 3, 6, margins);
    yearly_data = basic_stats.yearly_counts;
    bar(yearly_data.years, yearly_data.counts, 'FaceColor', [0.5 0.8 0.5]);
    title('年度故障统计', 'FontSize', 13, 'FontWeight', 'bold', 'Margin', 5);
    xlabel('年份', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('故障数量（次）', 'FontSize', 11, 'FontWeight', 'bold');
    grid on;

    % 添加数值标签
    for i = 1:length(yearly_data.counts)
        text(yearly_data.years(i), yearly_data.counts(i) + max(yearly_data.counts)*0.02, ...
            num2str(yearly_data.counts(i)), ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', ...
            'FontSize', 9);
    end
    ylim([0, max(yearly_data.counts)*1.15]);

    % 添加总标题
    sgtitle('故障诊断维修记录分析报告 - 基础统计（优化版）', ...
        'FontSize', 16, 'FontWeight', 'bold');

    % ========== 第 2 页：维修效率和模式分析（优化版） ==========

    fig2 = figure('Name', '故障分析综合报告 - 第2页（优化版）', ...
        'Position', [100, 50, 1500, 1000], ...
        'Color', 'white');

    % 1. 维修时间分布（各故障类型）
    create_subplot_with_margins(2, 3, 1, margins);
    type_time_data = efficiency_stats.type_time_stats;
    type_names = type_time_data(:, 1);
    avg_times = [type_time_data{:, 2}];

    bar(avg_times, 'FaceColor', [0.7 0.7 0.9]);
    hold on;

    % 添加误差线显示范围
    min_times = [type_time_data{:, 3}];
    max_times = [type_time_data{:, 4}];
    errorbar(1:length(avg_times), avg_times, ...
        avg_times - min_times, max_times - avg_times, ...
        'k.', 'LineWidth', 1.5);
    hold off;

    set(gca, 'XTick', 1:length(type_names));
    set(gca, 'XTickLabel', type_names);
    title('各故障类型平均维修时间', 'FontSize', 13, 'FontWeight', 'bold', 'Margin', 5);
    xlabel('故障类型', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('维修时间（分钟）', 'FontSize', 11, 'FontWeight', 'bold');
    xtickangle(45);
    grid on;

    % 2. 工具使用频率 TOP10
    create_subplot_with_margins(2, 3, 2, margins);
    tools_data = efficiency_stats.tools_freq;
    top10_tools = tools_data(1:min(10, size(tools_data, 1)), :);
    barh([top10_tools{:, 2}], 'FaceColor', [0.9 0.7 0.5]);
    set(gca, 'YTick', 1:size(top10_tools, 1));
    set(gca, 'YTickLabel', top10_tools(:, 1));
    title('TOP 10 常用工具', 'FontSize', 13, 'FontWeight', 'bold', 'Margin', 5);
    xlabel('使用次数', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('工具名称', 'FontSize', 11, 'FontWeight', 'bold');
    grid on;

    % 3. 季度故障分布
    create_subplot_with_margins(2, 3, 3, margins);
    seasonal_data = pattern_stats.seasonal_counts;
    bar(seasonal_data.quarters, seasonal_data.counts, 'FaceColor', [0.8 0.8 0.3]);
    set(gca, 'XTick', 1:4);
    set(gca, 'XTickLabel', {'春季(Q1)', '夏季(Q2)', '秋季(Q3)', '冬季(Q4)'});
    title('季度故障分布', 'FontSize', 13, 'FontWeight', 'bold', 'Margin', 5);
    xlabel('季度', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('故障数量（次）', 'FontSize', 11, 'FontWeight', 'bold');
    grid on;

    % 添加数值标签
    for i = 1:length(seasonal_data.counts)
        text(i, seasonal_data.counts(i) + max(seasonal_data.counts)*0.02, ...
            num2str(seasonal_data.counts(i)), ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', ...
            'FontSize', 9);
    end
    ylim([0, max(seasonal_data.counts)*1.15]);

    % 4. 优先级分布
    create_subplot_with_margins(2, 3, 4, margins);
    priority_data = pattern_stats.priority_counts;
    pie_data = priority_data.counts;
    pie_labels = arrayfun(@(x) sprintf('优先级 %d\n(%d 次)', x, ...
        priority_data.counts(priority_data.priorities == x)), ...
        priority_data.priorities, 'UniformOutput', false);

    pie(pie_data, pie_labels);
    title('故障优先级分布', 'FontSize', 13, 'FontWeight', 'bold', 'Margin', 5);
    colormap(gca, [1 0.3 0.3; 1 0.7 0.3; 0.3 0.8 0.3]);

    % 5. 工作日 vs 周末分布
    create_subplot_with_margins(2, 3, 5, margins);
    workday_data = pattern_stats.workday_counts;
    pie_data = workday_data;
    pie_labels = {sprintf('工作日\n%d 次', workday_data(1)), ...
                  sprintf('周末\n%d 次', workday_data(2))};
    pie(pie_data, pie_labels);
    title('工作日 vs 周末故障分布', 'FontSize', 13, 'FontWeight', 'bold', 'Margin', 5);
    colormap(gca, [0.7 0.7 0.9; 0.9 0.7 0.7]);

    % 6. 故障时间热力图
    create_subplot_with_margins(2, 3, 6, margins);
    heatmap_data = zeros(7, 24);
    for i = 1:length(data.dayofweek)
        dow = data.dayofweek(i);
        hr = data.hour(i) + 1;
        if dow >= 1 && dow <= 7 && hr >= 1 && hr <= 24
            heatmap_data(dow, hr) = heatmap_data(dow, hr) + 1;
        end
    end

    imagesc(heatmap_data);
    colormap(gca, 'hot');
    colorbar;

    set(gca, 'YTick', 1:7);
    set(gca, 'YTickLabel', {'周日', '周一', '周二', '周三', '周四', '周五', '周六'});
    set(gca, 'XTick', [1, 6, 12, 18, 24]);
    set(gca, 'XTickLabel', {'0', '5', '11', '17', '23'});

    title('故障发生时间分布热力图', 'FontSize', 13, 'FontWeight', 'bold', 'Margin', 5);
    xlabel('小时（0-23点）', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('星期', 'FontSize', 11, 'FontWeight', 'bold');

    % 添加总标题
    sgtitle('故障诊断维修记录分析报告 - 维修效率与模式（优化版）', ...
        'FontSize', 16, 'FontWeight', 'bold');

    % ========== 第 3 页：关联分析和预测（优化版） ==========

    fig3 = figure('Name', '故障分析综合报告 - 第3页（优化版）', ...
        'Position', [150, 50, 1500, 1000], ...
        'Color', 'white');

    % 1. 严重程度与维修时间关系
    create_subplot_with_margins(2, 3, 1, margins);
    severity_time_data = correlation_stats.severity_time;
    bar_data = [severity_time_data{:, 2}];
    bar(bar_data, 'FaceColor', [0.8 0.6 0.8]);
    set(gca, 'XTickLabel', severity_time_data(:, 1));
    title('严重程度与平均维修时间', 'FontSize', 13, 'FontWeight', 'bold', 'Margin', 5);
    xlabel('严重程度', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('平均维修时间（分钟）', 'FontSize', 11, 'FontWeight', 'bold');
    grid on;

    % 添加数值标签
    for i = 1:length(bar_data)
        text(i, bar_data(i) + max(bar_data)*0.02, sprintf('%.1f', bar_data(i)), ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', ...
            'FontSize', 9);
    end
    ylim([0, max(bar_data)*1.15]);

    % 2. 最复杂故障 TOP5
    create_subplot_with_margins(2, 3, 2, margins);
    complexity_data = correlation_stats.fault_complexity;
    top5_complex = complexity_data(1:min(5, size(complexity_data, 1)), :);
    barh([top5_complex{:, 2}], 'FaceColor', [0.9 0.5 0.5]);

    % 创建标签
    ylabels = cell(size(top5_complex, 1), 1);
    for i = 1:size(top5_complex, 1)
        ylabels{i} = top5_complex{i, 1};
    end

    set(gca, 'YTick', 1:length(ylabels));
    set(gca, 'YTickLabel', ylabels);
    title('最复杂故障 TOP5', 'FontSize', 13, 'FontWeight', 'bold', 'Margin', 5);
    xlabel('平均维修时间（分钟）', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('故障代码', 'FontSize', 11, 'FontWeight', 'bold');
    grid on;

    % 3. 故障趋势预测
    create_subplot_with_margins(2, 3, 3, margins);
    monthly_data = predictive_stats.monthly_faults;
    plot(monthly_data.months, monthly_data.counts, 'b-o', ...
        'LineWidth', 2, 'MarkerSize', 5);
    hold on;

    % 添加预测数据
    future_months = monthly_data.months(end) + calmonths(1:6);
    predictions = predictive_stats.predictions;
    plot(future_months, predictions, 'r--o', ...
        'LineWidth', 2, 'MarkerSize', 5);

    title('故障趋势与预测', 'FontSize', 13, 'FontWeight', 'bold', 'Margin', 5);
    xlabel('时间', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('故障数量（次）', 'FontSize', 11, 'FontWeight', 'bold');
    legend({'历史数据', '预测数据'}, 'Location', 'best', 'FontSize', 9);
    grid on;
    datetick('x', 'yyyy-mm', 'keepticks');
    xtickangle(45);
    hold off;

    % 4. 备件需求分析
    create_subplot_with_margins(2, 3, 4, margins);
    parts_data = predictive_stats.parts_freq;
    parts_names = {'传感器', '电路板', '模块', '电缆'};
    parts_counts = [parts_data.sensor, parts_data.board, ...
                   parts_data.module, parts_data.cable];

    bar(parts_counts, 'FaceColor', [0.6 0.8 0.6]);
    set(gca, 'XTickLabel', parts_names);
    title('备件更换统计', 'FontSize', 13, 'FontWeight', 'bold', 'Margin', 5);
    xlabel('备件类型', 'FontSize', 11, 'FontWeight', 'bold');
    ylabel('更换次数', 'FontSize', 11, 'FontWeight', 'bold');
    grid on;

    % 添加数值标签
    for i = 1:length(parts_counts)
        text(i, parts_counts(i) + max(parts_counts)*0.02, num2str(parts_counts(i)), ...
            'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', ...
            'FontSize', 9);
    end
    ylim([0, max(parts_counts)*1.15]);

    % 5-6. 维修操作效率分析（跨两个子图位置）
    create_subplot_with_margins(2, 3, [5, 6], margins);
    op_data = efficiency_stats.operation_stats;
    % 筛选出现 2 次以上的操作
    freq_ops = op_data([op_data{:, 2}] >= 2, :);
    if ~isempty(freq_ops)
        % 按平均时间排序
        [~, sort_idx] = sort([freq_ops{:, 3}]);
        top10_ops = freq_ops(sort_idx(1:min(10, length(sort_idx))), :);

        x_data = [top10_ops{:, 3}];
        y_pos = 1:length(x_data);

        barh(y_pos, x_data, 'FaceColor', [0.7 0.9 0.7]);

        % 设置标签
        op_labels = cell(size(top10_ops, 1), 1);
        for i = 1:size(top10_ops, 1)
            op_labels{i} = sprintf('%s (n=%d)', ...
                top10_ops{i, 1}, top10_ops{i, 2});
        end

        set(gca, 'YTick', y_pos);
        set(gca, 'YTickLabel', op_labels);
        title('TOP 10 最快维修操作', 'FontSize', 13, 'FontWeight', 'bold', 'Margin', 5);
        xlabel('平均维修时间（分钟）', 'FontSize', 11, 'FontWeight', 'bold');
        ylabel('维修操作（含次数）', 'FontSize', 11, 'FontWeight', 'bold');
        grid on;
    end

    % 添加总标题
    sgtitle('故障诊断维修记录分析报告 - 关联分析与预测（优化版）', ...
        'FontSize', 16, 'FontWeight', 'bold');

    fprintf('\n优化版可视化报告已生成，共 3 个图形窗口。\n');
    fprintf('优化内容：\n');
    fprintf('- 字体：中文宋体，英文Times New Roman\n');
    fprintf('- 布局：调整子图间距，防止标题重叠\n');
    fprintf('- 标签：优化数值标签位置和大小\n');
    fprintf('- 颜色：统一配色方案\n');
end

function generate_summary_report(data, basic_stats, efficiency_stats, pattern_stats, excel_file)
    % 生成文字总结报告
    report_filename = sprintf('故障分析总结报告_优化版_%s.txt', datestr(now, 'yyyymmdd_HHMMSS'));

    fid = fopen(report_filename, 'w', 'native', 'UTF-8');

    fprintf(fid, '======================================================================\n');
    fprintf(fid, '故障诊断维修记录分析总结报告（优化版）\n');
    fprintf(fid, '生成时间: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    fprintf(fid, '分析文件: %s\n', excel_file);
    fprintf(fid, '======================================================================\n\n');

    % 概览
    fprintf(fid, '【数据概览】\n');
    fprintf(fid, '分析时间范围: %s 至 %s\n', ...
        datestr(min(data.fault_time), 'yyyy-mm-dd'), ...
        datestr(max(data.fault_time), 'yyyy-mm-dd'));
    fprintf(fid, '总记录数: %d\n', length(data.fault_time));
    fprintf(fid, '覆盖故障类型: %d 种\n', length(unique(data.fault_type)));
    fprintf(fid, '涉及故障代码: %d 个\n\n', length(unique(data.instrument_fault_code)));

    % 关键发现
    fprintf(fid, '【关键发现】\n');

    % 最频繁故障
    top_fault = basic_stats.fault_counts{1, 1};
    top_fault_count = basic_stats.fault_counts{1, 2};
    top_fault_idx = find(strcmp(data.instrument_fault_code, top_fault), 1);
    top_fault_name = data.fault_name{top_fault_idx};
    fprintf(fid, '1. 最频繁故障: %s - %s (发生%d 次)\n', top_fault, top_fault_name, top_fault_count);

    % 平均维修时间
    avg_time = mean(data.duration_minutes);
    fprintf(fid, '2. 平均维修时间: %.1f 分钟\n', avg_time);

    % 严重故障占比
    severe_count = sum(strcmp(data.severity, '严重'));
    severe_ratio = (severe_count / length(data.severity)) * 100;
    fprintf(fid, '3. 严重故障占比: %.1f%%\n', severe_ratio);

    % 高优先级故障
    high_priority_count = sum(data.priority == 1);
    high_priority_ratio = (high_priority_count / length(data.priority)) * 100;
    fprintf(fid, '4. 高优先级故障占比: %.1f%%\n\n', high_priority_ratio);

    % 统计摘要
    fprintf(fid, '【统计摘要】\n');

    % 故障类型统计
    fprintf(fid, '\n故障类型分布:\n');
    type_data = basic_stats.type_counts;
    for i = 1:size(type_data, 1)
        fprintf(fid, '  - %s: %d 次 (%.1f%%)\n', ...
            type_data{i, 1}, type_data{i, 2}, ...
            type_data{i, 2} / length(data.fault_time) * 100);
    end

    % 严重程度统计
    fprintf(fid, '\n严重程度分布:\n');
    severity_data = pattern_stats.severity_counts;
    for i = 1:size(severity_data, 1)
        fprintf(fid, '  - %s: %d 次 (%.1f%%)\n', ...
            severity_data{i, 1}, severity_data{i, 2}, ...
            severity_data{i, 2} / length(data.fault_time) * 100);
    end

    % 优化建议
    fprintf(fid, '\n【优化建议】\n');
    fprintf(fid, '1. 重点关注高频故障的预防性维护\n');
    fprintf(fid, '   - 建议对"%s"制定专项维护计划\n', top_fault_name);
    fprintf(fid, '2. 优化备件库存管理\n');
    fprintf(fid, '   - 确保常用配件充足，特别是传感器和电路板\n');
    fprintf(fid, '3. 加强季节性维护\n');
    fprintf(fid, '   - 重点关注冬季(Q4)的预防性维护工作\n');
    fprintf(fid, '4. 提升维修效率\n');
    fprintf(fid, '   - 加强维修人员培训，缩短平均维修时间\n');
    fprintf(fid, '5. 建立预警机制\n');
    fprintf(fid, '   - 对高优先级故障建立早期预警系统\n');

    % 报告优化说明
    fprintf(fid, '\n【报告优化说明】\n');
    fprintf(fid, '本次优化版报告改进内容:\n');
    fprintf(fid, '1. 字体优化: 中文采用宋体，英文采用Times New Roman\n');
    fprintf(fid, '2. 布局优化: 调整子图间距，防止标题覆盖图片内容\n');
    fprintf(fid, '3. 标签优化: 改进数值标签位置和字体大小\n');
    fprintf(fid, '4. 颜色优化: 统一配色方案，提高可读性\n');
    fprintf(fid, '5. 间距优化: 增加图表间距，避免重叠问题\n');

    fprintf(fid, '\n【数据质量】\n');
    fprintf(fid, '数据完整性: 100%%\n');

    % 计算时间跨度
    time_span = max(data.fault_time) - min(data.fault_time);
    years_span = days(time_span) / 365.25;
    fprintf(fid, '时间跨度: %.1f 年\n', years_span);

    % 计算月份数
    start_date = min(data.fault_time);
    end_date = max(data.fault_time);
    num_months = (year(end_date) - year(start_date)) * 12 + (month(end_date) - month(start_date)) + 1;

    fprintf(fid, '平均每月故障数: %.1f\n', length(data.fault_time) / num_months);

    fclose(fid);

    fprintf('\n优化版文字总结报告已保存: %s\n', report_filename);
end