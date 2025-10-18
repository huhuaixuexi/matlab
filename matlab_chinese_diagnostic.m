%% MATLAB中文显示诊断脚本
% 用于诊断MATLAB中文显示问题的根本原因

function matlab_chinese_diagnostic()
    fprintf('========================================\n');
    fprintf('MATLAB中文显示环境诊断\n');
    fprintf('========================================\n\n');
    
    % 1. 基本系统信息
    fprintf('【1. 系统信息】\n');
    fprintf('MATLAB版本: %s\n', version);
    fprintf('操作系统: %s\n', computer);
    
    % 获取Java版本
    try
        java_version = char(java.lang.System.getProperty('java.version'));
        fprintf('Java版本: %s\n', java_version);
    catch
        fprintf('Java版本: 无法获取\n');
    end
    
    % 获取系统编码
    try
        system_encoding = get(0, 'DefaultCharacterSet');
        fprintf('系统字符编码: %s\n', system_encoding);
    catch
        fprintf('系统字符编码: 无法获取\n');
    end
    
    fprintf('\n');
    
    % 2. 检查可用字体
    fprintf('【2. 可用字体检查】\n');
    available_fonts = listfonts;
    
    % 检查中文字体
    chinese_fonts = {'SimSun', 'SimHei', 'Microsoft YaHei', 'NSimSun', 'STSong', ...
                     'AR PL UMing CN', 'Noto Sans CJK SC', 'Source Han Sans SC', ...
                     'WenQuanYi Micro Hei', 'WenQuanYi Zen Hei', 'Droid Sans Fallback'};
    
    fprintf('检查中文字体:\n');
    found_chinese_fonts = {};
    for i = 1:length(chinese_fonts)
        if any(strcmpi(available_fonts, chinese_fonts{i}))
            fprintf('  ✓ %s - 可用\n', chinese_fonts{i});
            found_chinese_fonts{end+1} = chinese_fonts{i};
        else
            fprintf('  ✗ %s - 不可用\n', chinese_fonts{i});
        end
    end
    
    % 检查英文字体
    english_fonts = {'Times New Roman', 'Times', 'Arial', 'Helvetica', ...
                     'Liberation Serif', 'DejaVu Serif'};
    
    fprintf('\n检查英文字体:\n');
    found_english_fonts = {};
    for i = 1:length(english_fonts)
        if any(strcmpi(available_fonts, english_fonts{i}))
            fprintf('  ✓ %s - 可用\n', english_fonts{i});
            found_english_fonts{end+1} = english_fonts{i};
        else
            fprintf('  ✗ %s - 不可用\n', english_fonts{i});
        end
    end
    
    fprintf('\n');
    
    % 3. 当前字体设置
    fprintf('【3. 当前字体设置】\n');
    try
        current_axes_font = get(0, 'DefaultAxesFontName');
        fprintf('当前坐标轴字体: %s\n', current_axes_font);
    catch
        fprintf('当前坐标轴字体: 无法获取\n');
    end
    
    try
        current_text_font = get(0, 'DefaultTextFontName');
        fprintf('当前文本字体: %s\n', current_text_font);
    catch
        fprintf('当前文本字体: 无法获取\n');
    end
    
    try
        current_interpreter = get(0, 'DefaultTextInterpreter');
        fprintf('当前文本解释器: %s\n', current_interpreter);
    catch
        fprintf('当前文本解释器: 无法获取\n');
    end
    
    fprintf('\n');
    
    % 4. 测试中文显示
    fprintf('【4. 中文显示测试】\n');
    
    % 创建测试图形
    test_fig = figure('Name', '中文显示测试', 'Position', [100, 100, 800, 600]);
    
    % 测试不同字体的中文显示
    test_fonts = [found_chinese_fonts, {'Monospaced', 'SansSerif', 'Serif'}];
    
    if isempty(test_fonts)
        test_fonts = {'default'};
    end
    
    subplot_rows = ceil(sqrt(length(test_fonts)));
    subplot_cols = ceil(length(test_fonts) / subplot_rows);
    
    for i = 1:length(test_fonts)
        subplot(subplot_rows, subplot_cols, i);
        
        % 设置字体
        if ~strcmp(test_fonts{i}, 'default')
            set(gca, 'FontName', test_fonts{i});
        end
        
        % 绘制测试图表
        bar([1, 2, 3], [10, 20, 15]);
        title(sprintf('字体测试: %s', test_fonts{i}));
        xlabel('测试X轴标签');
        ylabel('测试Y轴标签');
        
        % 添加中文文本
        text(2, 10, '中文测试文本', 'HorizontalAlignment', 'center');
        
        % 检查文本是否正确显示
        fprintf('测试字体 %s: ', test_fonts{i});
        if strcmp(test_fonts{i}, 'default')
            fprintf('使用默认字体\n');
        else
            fprintf('已应用\n');
        end
    end
    
    fprintf('\n');
    
    % 5. Java字体设置测试
    fprintf('【5. Java字体设置测试】\n');
    try
        % 获取Java字体信息
        ge = java.awt.GraphicsEnvironment.getLocalGraphicsEnvironment();
        font_names = ge.getAvailableFontFamilyNames();
        
        fprintf('Java可用字体数量: %d\n', length(font_names));
        
        % 检查Java中的中文字体
        java_chinese_fonts = {};
        for i = 1:length(font_names)
            font_name = char(font_names(i));
            if contains(font_name, {'Sim', 'Microsoft', 'Noto', 'Source Han', 'WenQuanYi'}) || ...
               any(strcmp(font_name, {'宋体', '黑体', '微软雅黑'}))
                java_chinese_fonts{end+1} = font_name;
            end
        end
        
        fprintf('Java中发现的中文字体:\n');
        for i = 1:length(java_chinese_fonts)
            fprintf('  - %s\n', java_chinese_fonts{i});
        end
        
    catch ME
        fprintf('Java字体检查失败: %s\n', ME.message);
    end
    
    fprintf('\n');
    
    % 6. 环境变量检查
    fprintf('【6. 环境变量检查】\n');
    
    % 检查LANG环境变量
    try
        if isunix
            [status, lang_var] = system('echo $LANG');
            if status == 0
                fprintf('LANG环境变量: %s', lang_var);
            else
                fprintf('LANG环境变量: 无法获取\n');
            end
            
            [status, lc_all] = system('echo $LC_ALL');
            if status == 0 && ~isempty(strtrim(lc_all))
                fprintf('LC_ALL环境变量: %s', lc_all);
            end
        else
            fprintf('Windows系统，跳过环境变量检查\n');
        end
    catch
        fprintf('环境变量检查失败\n');
    end
    
    fprintf('\n');
    
    % 7. 生成诊断报告
    fprintf('【7. 诊断结果和建议】\n');
    
    if isempty(found_chinese_fonts)
        fprintf('❌ 问题: 未找到任何中文字体\n');
        fprintf('💡 建议: 安装中文字体包\n');
        if isunix && ~ismac
            fprintf('   Linux: sudo apt-get install fonts-noto-cjk fonts-wqy-microhei\n');
        elseif ismac
            fprintf('   macOS: 通过Font Book安装中文字体\n');
        else
            fprintf('   Windows: 确保系统已安装宋体等中文字体\n');
        end
    else
        fprintf('✓ 找到 %d 个中文字体\n', length(found_chinese_fonts));
        fprintf('推荐使用: %s\n', found_chinese_fonts{1});
    end
    
    % 检查MATLAB版本兼容性
    matlab_ver = version('-release');
    matlab_year = str2double(matlab_ver(1:4));
    
    if matlab_year < 2014
        fprintf('⚠️  警告: MATLAB版本较老 (%s)，中文支持可能有限\n', matlab_ver);
        fprintf('💡 建议: 升级到R2014b或更高版本\n');
    else
        fprintf('✓ MATLAB版本 %s 支持中文显示\n', matlab_ver);
    end
    
    % 保存诊断报告
    report_file = sprintf('matlab_chinese_diagnostic_report_%s.txt', datestr(now, 'yyyymmdd_HHMMSS'));
    save_diagnostic_report(report_file, found_chinese_fonts, found_english_fonts, matlab_ver);
    
    fprintf('\n诊断报告已保存到: %s\n', report_file);
    fprintf('请查看测试图形窗口中的中文显示效果\n');
end

function save_diagnostic_report(filename, chinese_fonts, english_fonts, matlab_ver)
    % 保存诊断报告到文件
    fid = fopen(filename, 'w', 'native', 'UTF-8');
    
    fprintf(fid, 'MATLAB中文显示诊断报告\n');
    fprintf(fid, '生成时间: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    fprintf(fid, '==============================\n\n');
    
    fprintf(fid, 'MATLAB版本: %s\n', matlab_ver);
    fprintf(fid, '操作系统: %s\n\n', computer);
    
    fprintf(fid, '可用中文字体 (%d个):\n', length(chinese_fonts));
    for i = 1:length(chinese_fonts)
        fprintf(fid, '  %d. %s\n', i, chinese_fonts{i});
    end
    
    fprintf(fid, '\n可用英文字体 (%d个):\n', length(english_fonts));
    for i = 1:length(english_fonts)
        fprintf(fid, '  %d. %s\n', i, english_fonts{i});
    end
    
    fprintf(fid, '\n推荐解决方案:\n');
    if ~isempty(chinese_fonts)
        fprintf(fid, '1. 使用字体: %s\n', chinese_fonts{1});
        fprintf(fid, '2. 设置命令: set(0, ''DefaultAxesFontName'', ''%s'');\n', chinese_fonts{1});
    else
        fprintf(fid, '1. 安装中文字体包\n');
        fprintf(fid, '2. 重启MATLAB\n');
    end
    
    fclose(fid);
end