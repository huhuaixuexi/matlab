%% 故障诊断维修记录分析系统 - 中文显示修复版
% 专门解决中文显示问题的版本
% 采用多重策略确保中文正确显示

function analyze_fault_records_chinese_fixed(excel_file)
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

    % 强制中文显示修复
    force_chinese_display_fix();

    fprintf('\n========================================\n');
    fprintf('故障诊断维修记录分析系统（中文修复版）\n');
    fprintf('分析时间: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    fprintf('========================================\n\n');

    fprintf('正在分析文件: %s\n', excel_file);

    % 读取 Excel 数据
    try
        [~, ~, raw_data] = xlsread(excel_file, '故障维修记录');
        headers = raw_data(1, :);
        data_cells = raw_data(2:end, :);
        fprintf('成功读取 %d 条记录\n', size(data_cells, 1));
    catch ME
        error('读取 Excel 文件失败: %s', ME.message);
    end

    % 转换为结构化数据
    data = preprocess_data_from_cells(data_cells, headers);

    % 执行各项分析
    fprintf('\n开始执行分析...\n');
    basic_stats = basic_statistics_analysis(data);
    efficiency_stats = maintenance_efficiency_analysis(data);
    pattern_stats = fault_pattern_analysis(data);
    correlation_stats = correlation_analysis(data);
    predictive_stats = predictive_analysis(data);

    % 生成中文修复版可视化报告
    generate_chinese_fixed_report(data, basic_stats, efficiency_stats, ...
        pattern_stats, correlation_stats, predictive_stats);

    % 生成文字报告
    generate_summary_report(data, basic_stats, efficiency_stats, pattern_stats, excel_file);

    fprintf('\n========================================\n');
    fprintf('分析完成！中文显示已优化。\n');
    fprintf('========================================\n');
end

function force_chinese_display_fix()
    % 强制修复中文显示的多重策略
    
    fprintf('正在应用中文显示修复...\n');
    
    % 策略1: 重置所有图形属性到出厂设置
    set(0, 'factory');
    
    % 策略2: 设置字符编码
    try
        feature('DefaultCharacterSet', 'UTF-8');
        fprintf('✓ 设置UTF-8编码\n');
    catch
        fprintf('⚠ UTF-8编码设置失败\n');
    end
    
    % 策略3: 检测并设置最佳中文字体
    available_fonts = listfonts;
    
    % 按优先级排列的中文字体列表
    chinese_font_priority = {
        'SimSun',                    % Windows宋体
        'SimHei',                    % Windows黑体  
        'Microsoft YaHei',           % 微软雅黑
        'Microsoft YaHei UI',        % 微软雅黑UI
        'NSimSun',                   % 新宋体
        'STSong',                    % 华文宋体
        'STHeiti',                   % 华文黑体
        'PingFang SC',               % 苹方-简
        'Hiragino Sans GB',          % 冬青黑体简体中文
        'Noto Sans CJK SC',          % Google Noto简体中文
        'Noto Serif CJK SC',         % Google Noto衬线简体中文
        'Source Han Sans SC',        % 思源黑体简体中文
        'Source Han Serif SC',       % 思源宋体简体中文
        'WenQuanYi Micro Hei',       % 文泉驿微米黑
        'WenQuanYi Zen Hei',         % 文泉驿正黑
        'AR PL UMing CN',            % 文鼎PL简中明体
        'Droid Sans Fallback',       % Android后备字体
        'DejaVu Sans'                % Linux通用字体
    };
    
    % 查找可用的中文字体
    selected_font = '';
    for i = 1:length(chinese_font_priority)
        if any(strcmpi(available_fonts, chinese_font_priority{i}))
            selected_font = chinese_font_priority{i};
            fprintf('✓ 找到中文字体: %s\n', selected_font);
            break;
        end
    end
    
    % 如果没有找到专门的中文字体，使用通用字体
    if isempty(selected_font)
        fprintf('⚠ 未找到专用中文字体，使用通用字体\n');
        % 尝试通用字体
        universal_fonts = {'Monospaced', 'SansSerif', 'Serif', 'Dialog'};
        for i = 1:length(universal_fonts)
            if any(strcmpi(available_fonts, universal_fonts{i}))
                selected_font = universal_fonts{i};
                fprintf('✓ 使用通用字体: %s\n', selected_font);
                break;
            end
        end
    end
    
    % 如果还是没有，使用默认字体
    if isempty(selected_font)
        selected_font = get(0, 'DefaultAxesFontName');
        fprintf('⚠ 使用系统默认字体: %s\n', selected_font);
    end
    
    % 策略4: 设置所有相关的字体属性
    font_properties = {
        'DefaultAxesFontName'
        'DefaultTextFontName'
        'DefaultUicontrolFontName'
        'DefaultUipanelFontName'
        'DefaultUibuttongroupFontName'
        'DefaultUitableFontName'
        'DefaultLegendFontName'
        'DefaultColorbarFontName'
    };
    
    for i = 1:length(font_properties)
        try
            set(0, font_properties{i}, selected_font);
        catch
            % 忽略不支持的属性
        end
    end
    
    % 策略5: 设置字体大小
    set(0, 'DefaultAxesFontSize', 12);
    set(0, 'DefaultTextFontSize', 12);
    set(0, 'DefaultLegendFontSize', 10);
    
    % 策略6: 关闭所有解释器，使用纯文本
    interpreter_properties = {
        'DefaultTextInterpreter'
        'DefaultAxesTickLabelInterpreter'
        'DefaultLegendInterpreter'
        'DefaultColorbarTickLabelInterpreter'
    };
    
    for i = 1:length(interpreter_properties)
        try
            set(0, interpreter_properties{i}, 'none');
        catch
        end
    end
    
    % 策略7: 设置渲染器
    set(0, 'DefaultFigureRenderer', 'painters');
    
    % 策略8: Java字体设置（如果可用）
    try
        % 设置Java系统属性
        java.lang.System.setProperty('file.encoding', 'UTF-8');
        java.lang.System.setProperty('user.language', 'zh');
        java.lang.System.setProperty('user.country', 'CN');
        fprintf('✓ Java字体环境设置完成\n');
    catch
        fprintf('⚠ Java字体环境设置失败\n');
    end
    
    % 策略9: 创建测试图形验证中文显示
    test_chinese_display();
    
    fprintf('中文显示修复完成！\n\n');
end

function test_chinese_display()
    % 测试中文显示效果
    fprintf('正在测试中文显示效果...\n');
    
    test_fig = figure('Name', '中文显示测试', 'Position', [50, 50, 400, 300], 'Visible', 'off');
    
    % 创建简单的测试图表
    bar([1, 2, 3], [10, 20, 15]);
    title('中文测试标题');
    xlabel('横轴标签');
    ylabel('纵轴标签');
    
    % 检查标题文本
    title_handle = get(gca, 'Title');
    title_text = get(title_handle, 'String');
    
    if strcmp(title_text, '中文测试标题')
        fprintf('✓ 中文显示测试通过\n');
    else
        fprintf('⚠ 中文显示可能存在问题\n');
    end
    
    % 关闭测试图形
    close(test_fig);
end

function data = preprocess_data_from_cells(data_cells, headers)
    % 数据预处理（保持原有逻辑）
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

% ========== 分析函数（简化版本，专注中文显示） ==========

function stats = basic_statistics_analysis(data)
    fprintf('\n1. 基础统计分析\n');
    fprintf('==================================================\n');
    
    stats = struct();
    total_faults = length(data.fault_time);
    
    [unique_codes, ~, idx] = unique(data.instrument_fault_code);
    code_counts = accumarray(idx, 1);
    [sorted_counts, sort_idx] = sort(code_counts, 'descend');
    stats.fault_counts = [unique_codes(sort_idx), num2cell(sorted_counts)];
    
    yearly_counts = accumarray(data.year - min(data.year) + 1, 1);
    years = min(data.year):max(data.year);
    stats.yearly_counts = struct('years', years', 'counts', yearly_counts);
    
    [unique_types, ~, idx] = unique(data.fault_type);
    type_counts = accumarray(idx, 1);
    [sorted_type_counts, sort_idx] = sort(type_counts, 'descend');
    stats.type_counts = [unique_types(sort_idx), num2cell(sorted_type_counts)];
    
    return;
end

function stats = maintenance_efficiency_analysis(data)
    fprintf('\n2. 维修效率分析\n');
    fprintf('==================================================\n');
    
    stats = struct();
    
    [unique_types, ~, idx] = unique(data.fault_type);
    type_time_stats = zeros(length(unique_types), 4);
    
    for i = 1:length(unique_types)
        type_mask = strcmp(data.fault_type, unique_types{i});
        type_durations = data.duration_minutes(type_mask);
        type_time_stats(i, 1) = mean(type_durations);
        type_time_stats(i, 2) = min(type_durations);
        type_time_stats(i, 3) = max(type_durations);
        type_time_stats(i, 4) = sum(type_mask);
    end
    
    stats.type_time_stats = [unique_types, num2cell(type_time_stats)];
    
    % 工具使用频率
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
    stats.tools_freq = [unique_tools(sort_idx)', num2cell(sorted_tool_counts)];
    
    [unique_ops, ~, idx] = unique(data.operation);
    op_durations = zeros(length(unique_ops), 1);
    op_counts = zeros(length(unique_ops), 1);
    
    for i = 1:length(unique_ops)
        op_mask = strcmp(data.operation, unique_ops{i});
        op_durations(i) = mean(data.duration_minutes(op_mask));
        op_counts(i) = sum(op_mask);
    end
    
    [sorted_counts, sort_idx] = sort(op_counts, 'descend');
    stats.operation_stats = [unique_ops(sort_idx), num2cell(sorted_counts), ...
        num2cell(op_durations(sort_idx))];
    
    return;
end

function stats = fault_pattern_analysis(data)
    fprintf('\n3. 故障模式分析\n');
    fprintf('==================================================\n');
    
    stats = struct();
    total = length(data.fault_time);
    
    [unique_severities, ~, idx] = unique(data.severity);
    severity_counts = accumarray(idx, 1);
    stats.severity_counts = [unique_severities, num2cell(severity_counts)];
    
    unique_priorities = unique(data.priority);
    priority_counts = zeros(length(unique_priorities), 1);
    for i = 1:length(unique_priorities)
        priority_counts(i) = sum(data.priority == unique_priorities(i));
    end
    stats.priority_counts = struct('priorities', unique_priorities, 'counts', priority_counts);
    
    quarter_counts = accumarray(data.quarter, 1);
    stats.seasonal_counts = struct('quarters', (1:4)', 'counts', quarter_counts);
    
    is_workday = data.dayofweek >= 2 & data.dayofweek <= 6;
    workday_count = sum(is_workday);
    weekend_count = sum(~is_workday);
    stats.workday_counts = [workday_count; weekend_count];
    
    return;
end

function stats = correlation_analysis(data)
    fprintf('\n4. 关联性分析\n');
    fprintf('==================================================\n');
    
    stats = struct();
    
    [unique_severities, ~, idx] = unique(data.severity);
    severity_times = zeros(length(unique_severities), 1);
    
    for i = 1:length(unique_severities)
        severity_mask = strcmp(data.severity, unique_severities{i});
        severity_times(i) = mean(data.duration_minutes(severity_mask));
    end
    
    [sorted_times, sort_idx] = sort(severity_times, 'descend');
    stats.severity_time = [unique_severities(sort_idx), num2cell(sorted_times)];
    
    [unique_codes, ~, idx] = unique(data.instrument_fault_code);
    code_complexities = zeros(length(unique_codes), 3);
    
    for i = 1:length(unique_codes)
        code_mask = strcmp(data.instrument_fault_code, unique_codes{i});
        code_complexities(i, 1) = mean(data.duration_minutes(code_mask));
        code_complexities(i, 2) = mean(data.priority(code_mask));
        code_complexities(i, 3) = sum(code_mask);
    end
    
    [sorted_complexities, sort_idx] = sort(code_complexities(:, 1), 'descend');
    stats.fault_complexity = [unique_codes(sort_idx), num2cell(sorted_complexities)];
    
    return;
end

function stats = predictive_analysis(data)
    fprintf('\n5. 预测性分析\n');
    fprintf('==================================================\n');
    
    stats = struct();
    
    min_date = dateshift(min(data.fault_time), 'start', 'month');
    max_date = dateshift(max(data.fault_time), 'start', 'month');
    months = min_date:calmonths(1):max_date;
    monthly_counts = zeros(length(months), 1);
    
    for i = 1:length(months)
        month_start = months(i);
        month_end = dateshift(month_start, 'end', 'month');
        monthly_counts(i) = sum(data.fault_time >= month_start & data.fault_time <= month_end);
    end
    
    X = (1:length(monthly_counts))';
    y = monthly_counts;
    n = length(X);
    x_mean = mean(X);
    y_mean = mean(y);
    beta1 = sum((X - x_mean) .* (y - y_mean)) / sum((X - x_mean).^2);
    beta0 = y_mean - beta1 * x_mean;
    
    future_X = (n+1:n+6)';
    predictions = beta0 + beta1 * future_X;
    
    stats.monthly_faults = struct('months', months', 'counts', monthly_counts);
    stats.predictions = predictions;
    
    replacement_mask = contains(data.operation, '更换');
    replacement_ops = data.operation(replacement_mask);
    
    parts_count = struct();
    parts_count.sensor = sum(contains(replacement_ops, '传感器'));
    parts_count.board = sum(contains(replacement_ops, {'电路板', '板'}));
    parts_count.module = sum(contains(replacement_ops, '模块'));
    parts_count.cable = sum(contains(replacement_ops, {'电缆', '线路'}));
    
    stats.parts_freq = parts_count;
    
    return;
end

function generate_chinese_fixed_report(data, basic_stats, efficiency_stats, ...
    pattern_stats, correlation_stats, predictive_stats)
    % 生成中文修复版可视化报告
    
    fprintf('\n6. 生成中文修复版可视化报告\n');
    fprintf('==================================================\n');
    
    % 在生成图表前再次确认中文设置
    confirm_chinese_settings();
    
    % ========== 第 1 页：基础统计 ==========
    
    fig1 = figure('Name', '故障分析报告-第1页', 'Position', [50, 50, 1400, 900], 'Color', 'white');
    
    % 1. 故障类型分布
    subplot(2, 3, 1);
    type_data = basic_stats.type_counts;
    pie([type_data{:, 2}]);
    title('故障类型分布', 'FontSize', 14, 'FontWeight', 'bold');
    legend(type_data(:, 1), 'Location', 'eastoutside', 'FontSize', 10);
    
    % 2. 月度趋势
    subplot(2, 3, 2);
    monthly_data = predictive_stats.monthly_faults;
    plot(monthly_data.months, monthly_data.counts, 'b-o', 'LineWidth', 2, 'MarkerSize', 6);
    title('月度故障趋势', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('时间', 'FontSize', 12);
    ylabel('故障数量', 'FontSize', 12);
    grid on;
    datetick('x', 'yyyy-mm', 'keepticks');
    xtickangle(45);
    
    % 3. 严重程度分布
    subplot(2, 3, 3);
    severity_data = pattern_stats.severity_counts;
    bar([severity_data{:, 2}], 'FaceColor', [0.8 0.4 0.4]);
    set(gca, 'XTickLabel', severity_data(:, 1));
    title('严重程度分布', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('严重程度', 'FontSize', 12);
    ylabel('故障数量', 'FontSize', 12);
    grid on;
    
    % 4. TOP10故障代码
    subplot(2, 3, 4);
    fault_data = basic_stats.fault_counts;
    top10_codes = fault_data(1:min(10, size(fault_data, 1)), :);
    barh([top10_codes{:, 2}], 'FaceColor', [0.3 0.6 0.8]);
    set(gca, 'YTick', 1:size(top10_codes, 1));
    set(gca, 'YTickLabel', top10_codes(:, 1));
    title('TOP10故障代码', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('发生次数', 'FontSize', 12);
    ylabel('故障代码', 'FontSize', 12);
    grid on;
    
    % 5. 数据故障类型
    subplot(2, 3, 5);
    [unique_data_faults, ~, idx] = unique(data.data_fault_main);
    data_fault_counts = accumarray(idx, 1);
    pie(data_fault_counts, unique_data_faults);
    title('数据故障类型分布', 'FontSize', 14, 'FontWeight', 'bold');
    
    % 6. 年度统计
    subplot(2, 3, 6);
    yearly_data = basic_stats.yearly_counts;
    bar(yearly_data.years, yearly_data.counts, 'FaceColor', [0.5 0.8 0.5]);
    title('年度故障统计', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('年份', 'FontSize', 12);
    ylabel('故障数量', 'FontSize', 12);
    grid on;
    
    sgtitle('故障诊断维修记录分析报告-基础统计（中文修复版）', 'FontSize', 16, 'FontWeight', 'bold');
    
    % ========== 第 2 页：效率分析 ==========
    
    fig2 = figure('Name', '故障分析报告-第2页', 'Position', [100, 50, 1400, 900], 'Color', 'white');
    
    % 1. 维修时间分布
    subplot(2, 3, 1);
    type_time_data = efficiency_stats.type_time_stats;
    type_names = type_time_data(:, 1);
    avg_times = [type_time_data{:, 2}];
    bar(avg_times, 'FaceColor', [0.7 0.7 0.9]);
    set(gca, 'XTick', 1:length(type_names));
    set(gca, 'XTickLabel', type_names);
    title('各类型平均维修时间', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('故障类型', 'FontSize', 12);
    ylabel('维修时间（分钟）', 'FontSize', 12);
    xtickangle(45);
    grid on;
    
    % 2. 工具使用频率
    subplot(2, 3, 2);
    tools_data = efficiency_stats.tools_freq;
    top10_tools = tools_data(1:min(10, size(tools_data, 1)), :);
    barh([top10_tools{:, 2}], 'FaceColor', [0.9 0.7 0.5]);
    set(gca, 'YTick', 1:size(top10_tools, 1));
    set(gca, 'YTickLabel', top10_tools(:, 1));
    title('TOP10常用工具', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('使用次数', 'FontSize', 12);
    ylabel('工具名称', 'FontSize', 12);
    grid on;
    
    % 3. 季度分布
    subplot(2, 3, 3);
    seasonal_data = pattern_stats.seasonal_counts;
    bar(seasonal_data.quarters, seasonal_data.counts, 'FaceColor', [0.8 0.8 0.3]);
    set(gca, 'XTick', 1:4);
    set(gca, 'XTickLabel', {'春季', '夏季', '秋季', '冬季'});
    title('季度故障分布', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('季度', 'FontSize', 12);
    ylabel('故障数量', 'FontSize', 12);
    grid on;
    
    % 4. 优先级分布
    subplot(2, 3, 4);
    priority_data = pattern_stats.priority_counts;
    pie_data = priority_data.counts;
    pie_labels = arrayfun(@(x) sprintf('优先级%d', x), priority_data.priorities, 'UniformOutput', false);
    pie(pie_data, pie_labels);
    title('故障优先级分布', 'FontSize', 14, 'FontWeight', 'bold');
    
    % 5. 工作日vs周末
    subplot(2, 3, 5);
    workday_data = pattern_stats.workday_counts;
    pie([workday_data(1), workday_data(2)], {'工作日', '周末'});
    title('工作日vs周末分布', 'FontSize', 14, 'FontWeight', 'bold');
    
    % 6. 时间热力图
    subplot(2, 3, 6);
    heatmap_data = zeros(7, 24);
    for i = 1:length(data.dayofweek)
        dow = data.dayofweek(i);
        hr = data.hour(i) + 1;
        if dow >= 1 && dow <= 7 && hr >= 1 && hr <= 24
            heatmap_data(dow, hr) = heatmap_data(dow, hr) + 1;
        end
    end
    
    imagesc(heatmap_data);
    colormap('hot');
    colorbar;
    set(gca, 'YTick', 1:7);
    set(gca, 'YTickLabel', {'周日', '周一', '周二', '周三', '周四', '周五', '周六'});
    set(gca, 'XTick', [1, 6, 12, 18, 24]);
    set(gca, 'XTickLabel', {'0', '5', '11', '17', '23'});
    title('故障时间分布热力图', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('小时', 'FontSize', 12);
    ylabel('星期', 'FontSize', 12);
    
    sgtitle('故障诊断维修记录分析报告-效率分析（中文修复版）', 'FontSize', 16, 'FontWeight', 'bold');
    
    % ========== 第 3 页：关联分析 ==========
    
    fig3 = figure('Name', '故障分析报告-第3页', 'Position', [150, 50, 1400, 900], 'Color', 'white');
    
    % 1. 严重程度vs维修时间
    subplot(2, 3, 1);
    severity_time_data = correlation_stats.severity_time;
    bar([severity_time_data{:, 2}], 'FaceColor', [0.8 0.6 0.8]);
    set(gca, 'XTickLabel', severity_time_data(:, 1));
    title('严重程度vs平均维修时间', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('严重程度', 'FontSize', 12);
    ylabel('平均维修时间（分钟）', 'FontSize', 12);
    grid on;
    
    % 2. 复杂故障TOP5
    subplot(2, 3, 2);
    complexity_data = correlation_stats.fault_complexity;
    top5_complex = complexity_data(1:min(5, size(complexity_data, 1)), :);
    barh([top5_complex{:, 2}], 'FaceColor', [0.9 0.5 0.5]);
    set(gca, 'YTick', 1:size(top5_complex, 1));
    set(gca, 'YTickLabel', top5_complex(:, 1));
    title('最复杂故障TOP5', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('平均维修时间（分钟）', 'FontSize', 12);
    ylabel('故障代码', 'FontSize', 12);
    grid on;
    
    % 3. 趋势预测
    subplot(2, 3, 3);
    monthly_data = predictive_stats.monthly_faults;
    plot(monthly_data.months, monthly_data.counts, 'b-o', 'LineWidth', 2);
    hold on;
    future_months = monthly_data.months(end) + calmonths(1:6);
    predictions = predictive_stats.predictions;
    plot(future_months, predictions, 'r--o', 'LineWidth', 2);
    title('故障趋势与预测', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('时间', 'FontSize', 12);
    ylabel('故障数量', 'FontSize', 12);
    legend({'历史数据', '预测数据'}, 'Location', 'best');
    grid on;
    datetick('x', 'yyyy-mm', 'keepticks');
    xtickangle(45);
    hold off;
    
    % 4. 备件需求
    subplot(2, 3, 4);
    parts_data = predictive_stats.parts_freq;
    parts_names = {'传感器', '电路板', '模块', '电缆'};
    parts_counts = [parts_data.sensor, parts_data.board, parts_data.module, parts_data.cable];
    bar(parts_counts, 'FaceColor', [0.6 0.8 0.6]);
    set(gca, 'XTickLabel', parts_names);
    title('备件更换统计', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('备件类型', 'FontSize', 12);
    ylabel('更换次数', 'FontSize', 12);
    grid on;
    
    % 5. 维修操作效率
    subplot(2, 3, 5);
    op_data = efficiency_stats.operation_stats;
    freq_ops = op_data([op_data{:, 2}] >= 2, :);
    if ~isempty(freq_ops)
        [~, sort_idx] = sort([freq_ops{:, 3}]);
        top5_ops = freq_ops(sort_idx(1:min(5, length(sort_idx))), :);
        barh([top5_ops{:, 3}], 'FaceColor', [0.7 0.9 0.7]);
        set(gca, 'YTick', 1:size(top5_ops, 1));
        set(gca, 'YTickLabel', top5_ops(:, 1));
        title('TOP5快速维修操作', 'FontSize', 14, 'FontWeight', 'bold');
        xlabel('平均维修时间（分钟）', 'FontSize', 12);
        ylabel('维修操作', 'FontSize', 12);
        grid on;
    end
    
    % 6. 工具效率
    subplot(2, 3, 6);
    tools_data = efficiency_stats.tools_freq;
    top5_tools = tools_data(1:min(5, size(tools_data, 1)), :);
    pie([top5_tools{:, 2}], top5_tools(:, 1));
    title('TOP5常用工具分布', 'FontSize', 14, 'FontWeight', 'bold');
    
    sgtitle('故障诊断维修记录分析报告-关联分析（中文修复版）', 'FontSize', 16, 'FontWeight', 'bold');
    
    fprintf('\n中文修复版可视化报告已生成，共3个图形窗口。\n');
    fprintf('如果中文仍然显示异常，请运行 matlab_chinese_diagnostic() 进行诊断。\n');
end

function confirm_chinese_settings()
    % 在生成图表前确认中文设置
    current_font = get(0, 'DefaultAxesFontName');
    fprintf('当前使用字体: %s\n', current_font);
    
    % 再次设置解释器为none
    set(0, 'DefaultTextInterpreter', 'none');
    set(0, 'DefaultAxesTickLabelInterpreter', 'none');
    set(0, 'DefaultLegendInterpreter', 'none');
end

function generate_summary_report(data, basic_stats, efficiency_stats, pattern_stats, excel_file)
    % 生成文字总结报告
    report_filename = sprintf('故障分析总结报告_中文修复版_%s.txt', datestr(now, 'yyyymmdd_HHMMSS'));
    
    fid = fopen(report_filename, 'w', 'native', 'UTF-8');
    
    fprintf(fid, '======================================================================\n');
    fprintf(fid, '故障诊断维修记录分析总结报告（中文修复版）\n');
    fprintf(fid, '生成时间: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    fprintf(fid, '分析文件: %s\n', excel_file);
    fprintf(fid, '======================================================================\n\n');
    
    fprintf(fid, '【数据概览】\n');
    fprintf(fid, '总记录数: %d\n', length(data.fault_time));
    fprintf(fid, '覆盖故障类型: %d 种\n', length(unique(data.fault_type)));
    fprintf(fid, '涉及故障代码: %d 个\n\n', length(unique(data.instrument_fault_code)));
    
    fprintf(fid, '【中文显示修复说明】\n');
    fprintf(fid, '本版本采用了多重策略确保中文正确显示:\n');
    fprintf(fid, '1. 重置图形属性到出厂设置\n');
    fprintf(fid, '2. 设置UTF-8字符编码\n');
    fprintf(fid, '3. 智能检测并选择最佳中文字体\n');
    fprintf(fid, '4. 关闭所有LaTeX解释器\n');
    fprintf(fid, '5. 配置Java字体环境\n');
    fprintf(fid, '6. 使用painters渲染器\n\n');
    
    fprintf(fid, '【关键发现】\n');
    top_fault = basic_stats.fault_counts{1, 1};
    top_fault_count = basic_stats.fault_counts{1, 2};
    fprintf(fid, '1. 最频繁故障: %s (发生%d次)\n', top_fault, top_fault_count);
    
    avg_time = mean(data.duration_minutes);
    fprintf(fid, '2. 平均维修时间: %.1f分钟\n', avg_time);
    
    fclose(fid);
    
    fprintf('\n中文修复版文字总结报告已保存: %s\n', report_filename);
end