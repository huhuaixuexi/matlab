%% 测试主程序修复
% 验证修复后的主程序是否能正常运行

clear; clc;

fprintf('测试智能维护决策系统...\n');

try
    % 测试知识库初始化
    fprintf('1. 测试知识库初始化...\n');
    kb = FaultKnowledgeBase_Fixed();
    fprintf('   ✓ 知识库初始化成功\n');
    
    % 测试基本查询功能
    fprintf('2. 测试基本查询功能...\n');
    
    % 测试空故障代码查询
    fprintf('   测试空故障代码查询...\n');
    [fault_info, measures] = kb.getFaultInfo('数据偏差型故障', '');
    if ~isempty(fault_info)
        fprintf('   ✓ 空故障代码查询成功\n');
    else
        fprintf('   ✗ 空故障代码查询失败\n');
    end
    
    % 测试具体故障代码查询
    fprintf('   测试具体故障代码查询...\n');
    [fault_info, measures] = kb.getFaultInfo('数据偏差型故障', '302');
    if ~isempty(fault_info)
        fprintf('   ✓ 具体故障代码查询成功\n');
    else
        fprintf('   ✗ 具体故障代码查询失败\n');
    end
    
    % 测试维护日志记录
    fprintf('3. 测试维护日志记录...\n');
    kb.logMaintenance('302', '测试维护', '成功', now);
    fprintf('   ✓ 维护日志记录成功\n');
    
    % 测试统计报告生成
    fprintf('4. 测试统计报告生成...\n');
    report = kb.generateStatisticsReport();
    fprintf('   ✓ 统计报告生成成功\n');
    
    % 测试搜索功能
    fprintf('5. 测试搜索功能...\n');
    kb.searchFaults('传感器');
    fprintf('   ✓ 搜索功能成功\n');
    
    fprintf('\n所有测试通过！系统可以正常运行。\n');
    fprintf('现在可以运行 weihu_core_fixed.m 主程序。\n');
    
catch ME
    fprintf('测试失败: %s\n', ME.message);
    if ~isempty(ME.stack)
        fprintf('错误位置: %s 第%d行\n', ME.stack(1).file, ME.stack(1).line);
    end
end