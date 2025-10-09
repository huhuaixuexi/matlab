%% 测试FaultKnowledgeBase语法
% 简单的语法检查脚本

try
    fprintf('开始语法检查...\n');
    
    % 尝试创建类实例
    kb = FaultKnowledgeBase();
    fprintf('类实例创建成功\n');
    
    % 测试基本功能
    [fault_info, measures] = kb.getFaultInfo('数据偏差型故障', '302');
    fprintf('基本查询功能正常\n');
    
    % 测试维护日志记录
    kb.logMaintenance('302', '测试维护', '成功', now);
    fprintf('维护日志记录功能正常\n');
    
    % 测试统计报告
    report = kb.generateStatisticsReport();
    fprintf('统计报告生成功能正常\n');
    
    fprintf('所有语法检查通过！\n');
    
catch ME
    fprintf('语法错误: %s\n', ME.message);
    fprintf('错误位置: %s (第%d行)\n', ME.stack(1).file, ME.stack(1).line);
    fprintf('错误标识符: %s\n', ME.identifier);
end