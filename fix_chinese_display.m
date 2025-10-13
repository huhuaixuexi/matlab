function fix_chinese_display()
    % 修复MATLAB中文显示问题的函数
    
    fprintf('正在修复中文显示问题...\n');
    
    % 1. 设置默认字体为支持中文的字体
    set(0, 'DefaultAxesFontName', 'SimHei');  % 黑体
    set(0, 'DefaultTextFontName', 'SimHei');
    set(0, 'DefaultAxesTitleFontName', 'SimHei');
    set(0, 'DefaultAxesXLabelFontName', 'SimHei');
    set(0, 'DefaultAxesYLabelFontName', 'SimHei');
    set(0, 'DefaultLegendFontName', 'SimHei');
    
    % 2. 设置字符编码
    feature('DefaultCharacterSet', 'UTF-8');
    
    % 3. 尝试其他可用的中文字体
    available_fonts = listfonts;
    chinese_fonts = {'SimHei', 'SimSun', 'Microsoft YaHei', 'KaiTi', 'FangSong', ...
                     'Arial Unicode MS', 'Noto Sans CJK SC', 'WenQuanYi Micro Hei', ...
                     'Droid Sans Fallback', 'DejaVu Sans'};
    
    found_font = '';
    for i = 1:length(chinese_fonts)
        if any(strcmpi(available_fonts, chinese_fonts{i}))
            found_font = chinese_fonts{i};
            fprintf('找到可用中文字体: %s\n', found_font);
            break;
        end
    end
    
    if isempty(found_font)
        fprintf('警告：未找到标准中文字体，尝试使用系统默认字体...\n');
        % 在Linux系统上，尝试使用更通用的字体
        found_font = 'Monospaced';
    end
    
    % 更新默认字体
    set(0, 'DefaultAxesFontName', found_font);
    set(0, 'DefaultTextFontName', found_font);
    
    fprintf('已设置字体为: %s\n', found_font);
    fprintf('中文显示修复完成！\n');
end