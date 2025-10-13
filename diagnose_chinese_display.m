%% 中文显示问题诊断工具
% 此脚本帮助诊断和解决MATLAB中文显示为方框的问题

function diagnose_chinese_display()
    fprintf('\n========================================\n');
    fprintf('MATLAB中文显示诊断工具\n');
    fprintf('========================================\n\n');
    
    % 1. 系统信息
    fprintf('1. 系统信息:\n');
    fprintf('   MATLAB版本: %s\n', version);
    fprintf('   操作系统: %s\n', computer);
    if isunix
        if ismac
            fprintf('   系统类型: macOS\n');
        else
            fprintf('   系统类型: Linux\n');
            [~, dist] = system('lsb_release -d 2>/dev/null');
            if ~isempty(dist)
                fprintf('   发行版: %s', dist);
            end
        end
    else
        fprintf('   系统类型: Windows\n');
    end
    
    % 2. 当前语言环境
    fprintf('\n2. 语言环境:\n');
    if isunix
        [~, lang] = system('echo $LANG');
        fprintf('   LANG: %s', lang);
        [~, lc_all] = system('echo $LC_ALL');
        fprintf('   LC_ALL: %s', lc_all);
    end
    
    % 3. Java信息
    fprintf('\n3. Java环境:\n');
    fprintf('   Java版本: %s\n', version('-java'));
    
    % 4. 可用字体统计
    fprintf('\n4. 字体信息:\n');
    all_fonts = listfonts;
    fprintf('   系统总字体数: %d\n', length(all_fonts));
    
    % 检查中文字体
    chinese_fonts = {'SimHei', 'SimSun', 'Microsoft YaHei', 'Noto Sans CJK SC', ...
                     'WenQuanYi Micro Hei', 'Arial Unicode MS'};
    found_chinese = {};
    for i = 1:length(chinese_fonts)
        if any(strcmpi(all_fonts, chinese_fonts{i}))
            found_chinese{end+1} = chinese_fonts{i};
        end
    end
    
    if ~isempty(found_chinese)
        fprintf('   找到的中文字体:\n');
        for i = 1:length(found_chinese)
            fprintf('     - %s\n', found_chinese{i});
        end
    else
        fprintf('   警告: 未找到常见中文字体!\n');
    end
    
    % 5. 当前默认设置
    fprintf('\n5. 当前MATLAB字体设置:\n');
    fprintf('   DefaultAxesFontName: %s\n', get(0, 'DefaultAxesFontName'));
    fprintf('   DefaultTextFontName: %s\n', get(0, 'DefaultTextFontName'));
    fprintf('   DefaultTextInterpreter: %s\n', get(0, 'DefaultTextInterpreter'));
    
    % 6. 创建测试图形
    fprintf('\n6. 创建测试图形...\n');
    test_fig = figure('Name', '中文显示测试', 'Position', [100, 100, 800, 600]);
    
    % 测试不同的显示方法
    subplot(2, 2, 1);
    text(0.5, 0.5, '测试中文显示', 'HorizontalAlignment', 'center', ...
         'FontSize', 16, 'FontWeight', 'bold');
    title('默认设置');
    axis([0 1 0 1]); axis off;
    
    subplot(2, 2, 2);
    text(0.5, 0.5, '测试中文显示', 'HorizontalAlignment', 'center', ...
         'FontSize', 16, 'FontName', 'Monospaced');
    title('Monospaced字体', 'FontName', 'Monospaced');
    axis([0 1 0 1]); axis off;
    
    subplot(2, 2, 3);
    text(0.5, 0.5, '测试中文显示', 'HorizontalAlignment', 'center', ...
         'FontSize', 16, 'Interpreter', 'none');
    title('关闭解释器', 'Interpreter', 'none');
    axis([0 1 0 1]); axis off;
    
    subplot(2, 2, 4);
    % 使用Unicode编码
    chinese_text = char([27979, 35797, 20013, 25991, 26174, 31034]); % "测试中文显示"
    text(0.5, 0.5, chinese_text, 'HorizontalAlignment', 'center', ...
         'FontSize', 16);
    title('Unicode编码');
    axis([0 1 0 1]); axis off;
    
    sgtitle('中文显示测试 - 检查哪种方法能正确显示');
    
    % 7. 解决方案
    fprintf('\n7. 推荐解决方案:\n');
    fprintf('   a) 安装中文字体（Linux）:\n');
    fprintf('      sudo apt-get update\n');
    fprintf('      sudo apt-get install fonts-noto-cjk\n');
    fprintf('      sudo apt-get install fonts-wqy-microhei fonts-wqy-zenhei\n');
    fprintf('      sudo fc-cache -fv\n');
    fprintf('\n   b) 设置环境变量（Linux）:\n');
    fprintf('      export LANG=zh_CN.UTF-8\n');
    fprintf('      export LC_ALL=zh_CN.UTF-8\n');
    fprintf('\n   c) MATLAB设置:\n');
    fprintf('      set(0, ''DefaultAxesFontName'', ''Monospaced'');\n');
    fprintf('      set(0, ''DefaultTextInterpreter'', ''none'');\n');
    fprintf('\n   d) 如果问题持续:\n');
    fprintf('      - 重启MATLAB\n');
    fprintf('      - 更新显卡驱动\n');
    fprintf('      - 尝试不同的渲染器: set(gcf, ''Renderer'', ''painters'');\n');
    
    % 8. 保存诊断报告
    report_file = sprintf('中文显示诊断报告_%s.txt', datestr(now, 'yyyymmdd_HHMMSS'));
    fid = fopen(report_file, 'w', 'native', 'UTF-8');
    fprintf(fid, 'MATLAB中文显示诊断报告\n');
    fprintf(fid, '生成时间: %s\n\n', datestr(now));
    fprintf(fid, 'MATLAB版本: %s\n', version);
    fprintf(fid, '操作系统: %s\n', computer);
    fprintf(fid, '找到的中文字体: %d个\n', length(found_chinese));
    for i = 1:length(found_chinese)
        fprintf(fid, '  - %s\n', found_chinese{i});
    end
    fclose(fid);
    
    fprintf('\n诊断完成！\n');
    fprintf('诊断报告已保存: %s\n', report_file);
    fprintf('\n请查看测试图形窗口，确认哪种方法能正确显示中文。\n');
end