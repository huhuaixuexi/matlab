function enhanced_chinese_fix()
    % 增强版中文显示修复方案
    
    fprintf('正在执行增强版中文显示修复...\n');
    
    % 1. 获取系统信息
    if isunix && ~ismac
        fprintf('检测到Linux系统\n');
        % Linux系统特殊处理
        
        % 尝试安装中文字体包
        fprintf('建议在终端运行以下命令安装中文字体：\n');
        fprintf('sudo apt-get install fonts-wqy-microhei fonts-wqy-zenhei\n');
        fprintf('sudo apt-get install fonts-noto-cjk\n');
        
        % 刷新字体缓存
        system('fc-cache -fv');
    end
    
    % 2. 检查并列出所有可用字体
    available_fonts = listfonts;
    fprintf('\n系统中可用的字体总数: %d\n', length(available_fonts));
    
    % 3. 查找包含中文支持的字体
    chinese_keywords = {'Chinese', 'CJK', 'CN', 'SC', 'Hei', 'Song', 'Kai', ...
                       'Ming', 'Yuan', 'Sans', 'Mono', 'WenQuanYi', 'Noto'};
    
    fprintf('\n可能支持中文的字体:\n');
    chinese_capable_fonts = {};
    for i = 1:length(available_fonts)
        font_name = available_fonts{i};
        for j = 1:length(chinese_keywords)
            if contains(font_name, chinese_keywords{j}, 'IgnoreCase', true)
                fprintf('  - %s\n', font_name);
                chinese_capable_fonts{end+1} = font_name;
                break;
            end
        end
    end
    
    % 4. 创建测试图形
    test_fig = figure('Name', '中文字体测试', 'Position', [100, 100, 800, 600]);
    
    % 5. 测试不同的字体
    test_fonts = {'SimHei', 'SimSun', 'Microsoft YaHei', 'Noto Sans CJK SC', ...
                  'WenQuanYi Micro Hei', 'DejaVu Sans', 'Liberation Sans', ...
                  'Droid Sans Fallback', 'Monospaced'};
    
    % 添加找到的中文字体
    if ~isempty(chinese_capable_fonts)
        test_fonts = [test_fonts, chinese_capable_fonts];
    end
    
    % 去重
    test_fonts = unique(test_fonts);
    
    % 6. 绘制测试文本
    num_fonts = min(length(test_fonts), 12);
    for i = 1:num_fonts
        subplot(4, 3, i);
        
        try
            % 设置当前字体
            font_name = test_fonts{i};
            if any(strcmpi(available_fonts, font_name))
                text(0.5, 0.5, sprintf('测试中文显示\n字体: %s', font_name), ...
                     'HorizontalAlignment', 'center', ...
                     'FontName', font_name, ...
                     'FontSize', 14);
                title(sprintf('字体 %d: %s', i, font_name), 'FontName', font_name);
            else
                text(0.5, 0.5, sprintf('字体不可用\n%s', font_name), ...
                     'HorizontalAlignment', 'center');
                title(sprintf('字体 %d: 不可用', i));
            end
        catch
            text(0.5, 0.5, '测试失败', 'HorizontalAlignment', 'center');
            title(sprintf('字体 %d: 错误', i));
        end
        
        axis([0 1 0 1]);
        axis off;
    end
    
    sgtitle('中文字体显示测试 - 请选择显示正确的字体');
    
    % 7. 推荐字体
    fprintf('\n推荐使用的字体设置代码:\n');
    fprintf('set(0, ''DefaultAxesFontName'', ''Monospaced'');\n');
    fprintf('set(0, ''DefaultTextFontName'', ''Monospaced'');\n');
    fprintf('set(0, ''DefaultTextInterpreter'', ''none'');\n');
    
    fprintf('\n如果仍有问题，请尝试:\n');
    fprintf('1. 更新MATLAB到最新版本\n');
    fprintf('2. 安装系统中文字体包\n');
    fprintf('3. 设置系统区域为中文\n');
    fprintf('4. 使用export_fig等第三方工具导出图形\n');
end