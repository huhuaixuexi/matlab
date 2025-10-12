% 测试修复维修措施数组问题

% 创建维修措施的函数
function measure = create_measure(step, action, time, tools)
    measure = struct();
    measure.step = step;
    measure.action = action;
    measure.time = time;
    measure.tools = tools;
end

% 测试不同的创建方式
fprintf('测试1：使用花括号创建\n');
test1 = struct(...
    'maintenance_measures', {
        create_measure(1, '步骤1', '10分钟', '工具1');
        create_measure(2, '步骤2', '20分钟', '工具2');
        create_measure(3, '步骤3', '30分钟', '工具3')
    });
fprintf('类型: %s, 长度: %d\n\n', class(test1.maintenance_measures), length(test1.maintenance_measures));

fprintf('测试2：先创建数组再赋值\n');
measures_array = [];
measures_array(1) = create_measure(1, '步骤1', '10分钟', '工具1');
measures_array(2) = create_measure(2, '步骤2', '20分钟', '工具2');
measures_array(3) = create_measure(3, '步骤3', '30分钟', '工具3');
test2 = struct('maintenance_measures', measures_array);
fprintf('类型: %s, 长度: %d\n\n', class(test2.maintenance_measures), length(test2.maintenance_measures));

fprintf('测试3：使用元胞数组包装\n');
measures_cell = cell(3, 1);
measures_cell{1} = create_measure(1, '步骤1', '10分钟', '工具1');
measures_cell{2} = create_measure(2, '步骤2', '20分钟', '工具2');
measures_cell{3} = create_measure(3, '步骤3', '30分钟', '工具3');
test3 = struct('maintenance_measures', {measures_cell});
fprintf('类型: %s, 长度: %d\n\n', class(test3.maintenance_measures), length(test3.maintenance_measures));

% 修复后的数据库初始化函数示例
function db = init_maintenance_database_fixed()
    db = struct();
    
    % 故障代码302 - 使用正确的方式创建措施数组
    measures_302 = [];
    measures_302(1) = create_measure(1, '检查传感器表面污染', '10分钟', '清洁布、酒精');
    measures_302(2) = create_measure(2, '检查采样管路冷凝水', '15分钟', '排水工具');
    measures_302(3) = create_measure(3, '执行零点校准程序', '30分钟', '标准气体');
    measures_302(4) = create_measure(4, '检查传感器老化程度', '1小时', '测试设备');
    measures_302(5) = create_measure(5, '更换传感器模块', '2小时', '备用传感器');
    
    db.code_302 = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '302', ...
        'fault_name', '零点漂移超过允许范围50%', ...
        'description', '偏差漂移超过了允许范围的一半（±0.75vol%O2）', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', measures_302);
    
    fprintf('故障302的措施数量: %d\n', length(db.code_302.maintenance_measures));
end

% 运行测试
db_test = init_maintenance_database_fixed();