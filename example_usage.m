%% 氧分析仪故障诊断与维护建议知识库系统使用示例
% 演示如何使用FaultKnowledgeBase类

clear; clc;

%% 1. 初始化知识库系统
fprintf('=== 初始化故障知识库系统 ===\n');
kb = FaultKnowledgeBase();

%% 2. 查询特定故障信息
fprintf('\n=== 查询故障信息 ===\n');

% 查询故障代码302的信息
[fault_info, measures] = kb.getFaultInfo('数据偏差型故障', '302');
if ~isempty(fault_info)
    kb.displayFaultInfo(fault_info, measures);
end

%% 3. 直接通过故障代码查询
fprintf('\n=== 通过故障代码查询 ===\n');
fault_info = kb.getFaultByCode('101');
if ~isempty(fault_info)
    kb.displayFaultInfo(fault_info);
end

%% 4. 记录维护日志
fprintf('\n=== 记录维护日志 ===\n');

% 记录一些维护日志
kb.logMaintenance('302', '清洁传感器表面', '成功', now);
kb.logMaintenance('101', '更换主电源保险丝', '成功', now-1);
kb.logMaintenance('302', '执行零点校准', '成功', now-2);
kb.logMaintenance('300', '更换ADC芯片', '成功', now-3);
kb.logMaintenance('101', '重启控制器系统', '失败', now-4);

%% 5. 添加自定义维护措施
fprintf('\n=== 添加自定义维护措施 ===\n');
kb.addCustomMeasure('302', '使用超声波清洁传感器', '45分钟', '超声波清洁器');

%% 6. 搜索故障信息
fprintf('\n=== 搜索故障信息 ===\n');
kb.searchFaults('传感器');

%% 7. 列出所有故障
fprintf('\n=== 列出所有故障 ===\n');
kb.listAllFaults();

%% 8. 生成统计报告
fprintf('\n=== 生成统计报告 ===\n');
report = kb.generateStatisticsReport();

%% 9. 导出维护记录
fprintf('\n=== 导出维护记录 ===\n');
kb.exportToExcel('maintenance_log_example.xlsx');

%% 10. 备份数据
fprintf('\n=== 备份数据 ===\n');
kb.backupData('fault_kb_backup_example.mat');

%% 11. 演示错误处理
fprintf('\n=== 演示错误处理 ===\n');

try
    % 尝试查询不存在的故障代码
    fault_info = kb.getFaultByCode('999');
catch ME
    fprintf('捕获到错误: %s\n', ME.message);
end

try
    % 尝试添加不完整的自定义措施
    kb.addCustomMeasure('302', '', '30分钟', '工具');
catch ME
    fprintf('捕获到错误: %s\n', ME.message);
end

%% 12. 性能测试
fprintf('\n=== 性能测试 ===\n');

% 测试大量维护日志的性能
fprintf('添加1000条测试维护日志...\n');
tic;
for i = 1:1000
    fault_codes = {'302', '101', '300', '308', '312'};
    random_code = fault_codes{randi(length(fault_codes))};
    kb.logMaintenance(random_code, sprintf('测试维护措施%d', i), '成功', now);
end
elapsed_time = toc;
fprintf('添加1000条记录耗时: %.3f秒\n', elapsed_time);

% 测试统计报告生成性能
fprintf('生成统计报告...\n');
tic;
report = kb.generateStatisticsReport();
elapsed_time = toc;
fprintf('生成统计报告耗时: %.3f秒\n', elapsed_time);

fprintf('\n=== 示例运行完成 ===\n');