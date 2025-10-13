function fix_chinese_rendering()
    % 专门解决中文显示为方框的问题
    
    fprintf('执行中文渲染修复...\n');
    
    % 1. 重置所有图形默认设置
    reset(0);
    
    % 2. 设置MATLAB使用系统字体渲染
    if isunix
        % Linux系统下的特殊设置
        setenv('LANG', 'zh_CN.UTF-8');
        setenv('LC_ALL', 'zh_CN.UTF-8');
    end
    
    % 3. 获取并显示当前的字体设置
    current_font = get(0, 'DefaultAxesFontName');
    fprintf('当前默认字体: %s\n', current_font);
    
    % 4. 尝试不同的渲染器
    renderers = {'opengl', 'painters', 'zbuffer'};
    fprintf('\n测试不同的渲染器...\n');
    
    for i = 1:length(renderers)
        try
            set(0, 'DefaultFigureRenderer', renderers{i});
            fprintf('设置渲染器为: %s\n', renderers{i});
        catch
            fprintf('渲染器 %s 不可用\n', renderers{i});
        end
    end
    
    % 5. 设置字体抗锯齿
    try
        set(0, 'DefaultAxesFontSmoothing', 'on');
        set(0, 'DefaultTextFontSmoothing', 'on');
    catch
        fprintf('无法设置字体平滑\n');
    end
    
    % 6. 创建一个改进的字体设置函数
    setup_chinese_fonts();
    
    fprintf('\n中文渲染修复完成！\n');
    fprintf('如果问题仍然存在，请检查:\n');
    fprintf('1. MATLAB的Java堆内存是否足够\n');
    fprintf('2. 显卡驱动是否更新\n');
    fprintf('3. 系统是否安装了中文语言包\n');
end

function setup_chinese_fonts()
    % 设置中文字体的核心函数
    
    % 定义字体优先级列表
    font_list = {
        'Monospaced',          % 通用等宽字体
        'SansSerif',           % 通用无衬线字体
        'Dialog',              % Java对话框字体
        'DialogInput',         % Java对话框输入字体
        'Serif',               % 通用衬线字体
        'SimHei',              % 黑体
        'SimSun',              % 宋体
        'Microsoft YaHei',     % 微软雅黑
        'Arial Unicode MS',    % Arial Unicode
        'Noto Sans CJK SC',    % Google Noto字体
        'WenQuanYi Micro Hei', % 文泉驿微米黑
        'DejaVu Sans',         % DejaVu字体
        'Liberation Sans'      % Liberation字体
    };
    
    % 获取可用字体
    available = listfonts;
    
    % 查找第一个可用的字体
    selected_font = '';
    for i = 1:length(font_list)
        if any(strcmpi(available, font_list{i}))
            selected_font = font_list{i};
            break;
        end
    end
    
    % 如果没找到，使用默认
    if isempty(selected_font)
        selected_font = 'default';
    end
    
    % 应用字体设置
    fprintf('应用字体: %s\n', selected_font);
    
    % 设置所有可能的字体属性
    props = {
        'DefaultAxesFontName'
        'DefaultTextFontName'
        'DefaultUicontrolFontName'
        'DefaultUipanelFontName'
        'DefaultAxesXLabelFontName'
        'DefaultAxesYLabelFontName'
        'DefaultAxesZLabelFontName'
        'DefaultAxesTitleFontName'
        'DefaultTextarrowshapeFontName'
        'DefaultLegendFontName'
    };
    
    for i = 1:length(props)
        try
            set(0, props{i}, selected_font);
        catch
            % 某些属性可能在特定MATLAB版本中不存在
        end
    end
    
    % 关闭TeX解释器以避免问题
    set(0, 'DefaultTextInterpreter', 'none');
    set(0, 'DefaultAxesTickLabelInterpreter', 'none');
    set(0, 'DefaultLegendInterpreter', 'none');
    set(0, 'DefaultColorbarTickLabelInterpreter', 'none');
    
    % 设置字体大小
    set(0, 'DefaultAxesFontSize', 10);
    set(0, 'DefaultTextFontSize', 12);
end