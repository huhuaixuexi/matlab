%% 测试简化版FaultKnowledgeBase
% 验证基本功能是否正常

try
    fprintf('开始测试简化版知识库...\n');
    
    % 创建简化版实例
    kb = FaultKnowledgeBase_Simple();
    fprintf('简化版类实例创建成功\n');
    
    % 测试基本查询
    fault_info = kb.getFaultByCode('302');
    if ~isempty(fault_info)
        fprintf('故障查询功能正常\n');
        kb.displayFaultInfo(fault_info);
    end
    
    % 测试维护日志记录
    kb.logMaintenance('302', '测试维护措施', '成功', now);
    fprintf('维护日志记录功能正常\n');
    
    % 测试统计报告
    report = kb.generateStatisticsReport();
    fprintf('统计报告生成功能正常\n');
    
    fprintf('简化版所有测试通过！\n');
    
catch ME
    fprintf('错误: %s\n', ME.message);
    if ~isempty(ME.stack)
        fprintf('错误位置: %s 第%d行\n', ME.stack(1).file, ME.stack(1).line);
    end
end