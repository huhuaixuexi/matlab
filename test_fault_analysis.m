% 测试故障分析系统
fprintf('开始测试故障分析系统...\n');

try
    % 运行主函数
    generate_fault_records_with_analysis();
    fprintf('\n测试成功！所有功能正常运行。\n');
catch ME
    fprintf('\n测试失败！\n');
    fprintf('错误信息: %s\n', ME.message);
    fprintf('错误位置: %s (第 %d 行)\n', ME.stack(1).name, ME.stack(1).line);
    
    % 显示详细的错误堆栈
    for i = 1:length(ME.stack)
        fprintf('  -> %s (第 %d 行)\n', ME.stack(i).name, ME.stack(i).line);
    end
end