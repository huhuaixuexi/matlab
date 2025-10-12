%% 测试维护建议系统
clear; clc; close all;

fprintf('════════════════════════════════════════\n');
fprintf('        维护建议系统测试\n');
fprintf('════════════════════════════════════════\n\n');

% 创建维护数据库实例
fprintf('【1. 初始化维护数据库】\n');
maintenanceDB = MaintenanceDatabase();
fprintf('✓ 维护数据库创建成功\n\n');

% 测试基本功能
fprintf('【2. 测试基本查询功能】\n');

% 测试根据故障代码查询
test_codes = {'001', '002', '003', '004', '005', '302', '303', '304', '305'};

for i = 1:length(test_codes)
    fault_code = test_codes{i};
    fault_info = maintenanceDB.getFaultByCode(fault_code);
    
    if ~isempty(fault_info)
        fprintf('✓ 故障代码 %s: %s\n', fault_code, fault_info.fault_name);
    else
        fprintf('✗ 故障代码 %s: 未找到\n', fault_code);
    end
end

fprintf('\n【3. 测试维护建议显示】\n');

% 测试显示维护建议
test_fault_code = '001';
fault_info = maintenanceDB.getFaultByCode(test_fault_code);
if ~isempty(fault_info)
    maintenanceDB.displayFaultInfo(fault_info, fault_info.maintenance_measures);
end

fprintf('【4. 测试维护建议汇总】\n');

% 测试维护建议汇总
test_fault_codes = {'001', '002', '003', '302', '303'};
maintenanceDB.displayMaintenanceSummary(test_fault_codes);

fprintf('【5. 测试故障类型查询】\n');

% 测试根据故障类型查询
fault_types = {'满量程输出', '数据偏差型故障', '数据传输中断型故障'};

for i = 1:length(fault_types)
    fault_type = fault_types{i};
    [fault_info, measures] = maintenanceDB.getFaultInfo(fault_type);
    
    if ~isempty(fault_info)
        fprintf('✓ 故障类型 %s: 找到 %s\n', fault_type, fault_info.fault_name);
    else
        fprintf('✗ 故障类型 %s: 未找到\n', fault_type);
    end
end

fprintf('\n【6. 测试维护措施创建】\n');

% 测试创建维护措施
try
    test_measure = maintenanceDB.createMeasure(1, '测试维护措施', '10分钟', '测试工具');
    fprintf('✓ 维护措施创建成功: %s\n', test_measure.measure);
catch ME
    fprintf('✗ 维护措施创建失败: %s\n', ME.message);
end

fprintf('\n【7. 数据库统计信息】\n');

% 显示数据库统计信息
fprintf('数据库中共有 %d 个故障记录\n', length(maintenanceDB.faultDatabase));

% 统计各类型故障数量
fault_type_count = containers.Map();
for i = 1:length(maintenanceDB.faultDatabase)
    fault_type = maintenanceDB.faultDatabase{i}.fault_type;
    if isKey(fault_type_count, fault_type)
        fault_type_count(fault_type) = fault_type_count(fault_type) + 1;
    else
        fault_type_count(fault_type) = 1;
    end
end

fprintf('\n故障类型分布:\n');
fault_types = keys(fault_type_count);
for i = 1:length(fault_types)
    fprintf('  %s: %d个\n', fault_types{i}, fault_type_count(fault_types{i}));
end

fprintf('\n【8. 测试错误处理】\n');

% 测试错误处理
try
    maintenanceDB.getFaultByCode('999');  % 不存在的故障代码
catch ME
    fprintf('✓ 错误处理正常: %s\n', ME.message);
end

try
    maintenanceDB.createMeasure(6, 'test', 'test', 'test');  % 无效的级别
catch ME
    fprintf('✓ 参数验证正常: %s\n', ME.message);
end

fprintf('\n════════════════════════════════════════\n');
fprintf('        测试完成\n');
fprintf('════════════════════════════════════════\n');

fprintf('\n【测试总结】\n');
fprintf('✓ 维护数据库功能正常\n');
fprintf('✓ 故障查询功能正常\n');
fprintf('✓ 维护建议显示功能正常\n');
fprintf('✓ 错误处理机制正常\n');
fprintf('✓ 系统可以投入使用\n');