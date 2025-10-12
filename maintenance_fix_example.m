% 维修措施修复示例

% 正确的方式：先创建结构体数组，再赋值给maintenance_measures

function db = init_maintenance_database_example()
    db = struct();
    
    % ===== 故障代码302 =====
    % 先创建措施数组
    measures_302 = [];
    measures_302(1) = create_measure(1, '检查传感器表面污染', '10分钟', '清洁布、酒精');
    measures_302(2) = create_measure(2, '检查采样管路冷凝水', '15分钟', '排水工具');
    measures_302(3) = create_measure(3, '执行零点校准程序', '30分钟', '标准气体');
    measures_302(4) = create_measure(4, '检查传感器老化程度', '1小时', '测试设备');
    measures_302(5) = create_measure(5, '更换传感器模块', '2小时', '备用传感器');
    
    % 然后赋值给结构体
    db.code_302 = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '302', ...
        'fault_name', '零点漂移超过允许范围50%', ...
        'description', '偏差漂移超过了允许范围的一半（±0.75vol%O2）', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', measures_302);  % 这里不用花括号
    
    % ===== 故障代码309-311 =====
    measures_309_311 = [];
    measures_309_311(1) = create_measure(1, '检查温度传感器', '10分钟', '温度计');
    measures_309_311(2) = create_measure(2, '检查加热冷却器', '20分钟', '万用表');
    measures_309_311(3) = create_measure(3, '校准PID参数', '40分钟', '调试软件');
    measures_309_311(4) = create_measure(4, '更换温度传感器', '1小时', '备用传感器');
    measures_309_311(5) = create_measure(5, '更换温控模块', '2小时', '备用模块');
    
    db.code_309_311 = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '309-311', ...
        'fault_name', '温度调节器失效', ...
        'description', '温度控制超出范围', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', measures_309_311);
end

function measure = create_measure(step, action, time, tools)
    measure = struct();
    measure.step = step;
    measure.action = action;
    measure.time = time;
    measure.tools = tools;
end

% 测试
db = init_maintenance_database_example();
fprintf('故障302措施数量: %d\n', length(db.code_302.maintenance_measures));
fprintf('故障309-311措施数量: %d\n', length(db.code_309_311.maintenance_measures));

% 显示所有措施
fprintf('\n故障302的维修措施:\n');
for i = 1:length(db.code_302.maintenance_measures)
    m = db.code_302.maintenance_measures(i);
    fprintf('  步骤%d: %s (耗时: %s)\n', m.step, m.action, m.time);
end