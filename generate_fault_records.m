%% 故障诊断维修记录生成器 - MATLAB版本
% 生成5年的模拟故障维修记录数据并导出为Excel文件
% 包含数据故障代码映射

function generate_fault_records()
    % 主函数
    fprintf('开始生成故障记录...\n');
    
    % 设置时间范围（5年）
    end_date = datetime('now');
    start_date = end_date - years(5);
    
    % 生成记录数量：固定60条
    num_records = 60;
    
    fprintf('时间范围: %s 至 %s\n', datestr(start_date, 'yyyy-mm-dd'), datestr(end_date, 'yyyy-mm-dd'));
    fprintf('预计生成记录数: %d\n', num_records);
    
    % 初始化故障数据库
    fault_db = initialize_fault_database();
    
    % 生成故障记录
    records = generate_records(fault_db, start_date, end_date, num_records);
    
    % 导出到Excel
    filename = sprintf('故障诊断维修记录_%s.xlsx', datestr(now, 'yyyymmdd_HHMMSS'));
    export_to_excel(records, filename);
    
    % 显示统计信息
    generate_statistics(records);
    
    fprintf('\n任务完成！文件保存为: %s\n', filename);
end

function measure = create_measure(id, operation, duration, tools)
    % 创建维修措施结构体
    measure = struct(...
        'id', id, ...
        'operation', operation, ...
        'duration', duration, ...
        'tools', tools);
end

function fault_db = initialize_fault_database()
    % 初始化故障数据库
    fault_db = struct();
    
    % ========== 数据偏差型故障 ==========
    
    % 故障代码302
    fault_db.code_302 = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '302', ...
        'fault_name', '零点漂移超过允许范围50%', ...
        'description', '偏差漂移超过了允许范围的一半（±0.75vol%O2）', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', [
            create_measure(1, '检查传感器表面污染', '10分钟', '清洁布、酒精')
            create_measure(2, '检查采样管路冷凝水', '15分钟', '排水工具')
            create_measure(3, '执行零点校准程序', '30分钟', '标准气体')
            create_measure(4, '检查传感器老化程度', '1小时', '测试设备')
            create_measure(5, '更换传感器模块', '2小时', '备用传感器')
        ]);
    
    % 故障代码303
    fault_db.code_303 = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '303', ...
        'fault_name', '零点漂移超出允许范围', ...
        'description', '偏差漂移超出允许范围（±1.5vol%O2）', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', [
            create_measure(1, '立即检查传感器状态灯', '5分钟', '无')
            create_measure(2, '检查供电电压24V DC', '10分钟', '万用表')
            create_measure(3, '紧急执行零点量程校准', '45分钟', '标准气体')
            create_measure(4, '检查传感器参比电极', '1.5小时', '专用检测仪')
            create_measure(5, '立即更换传感器', '2小时', '备用传感器')
        ]);
    
    % 故障代码304
    fault_db.code_304 = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '304', ...
        'fault_name', '灵敏度漂移超出50%', ...
        'description', '放大漂移超出允许范围的50%', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', [
            create_measure(1, '检查测量池窗片清洁度', '15分钟', '清洁工具')
            create_measure(2, '检查光源强度稳定性', '20分钟', '光强测试仪')
            create_measure(3, '执行量程标定', '40分钟', '量程气体')
            create_measure(4, '检查检测器响应曲线', '1小时', '测试设备')
            create_measure(5, '更换检测器组件', '2小时', '备用检测器')
        ]);
    
    % 故障代码305
    fault_db.code_305 = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '305', ...
        'fault_name', '灵敏度漂移超出允许范围', ...
        'description', '放大漂移超出允许范围', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', [
            create_measure(1, '停止测量检查报警', '5分钟', '无')
            create_measure(2, '清洁所有光学元件', '30分钟', '光学清洁套装')
            create_measure(3, '执行完整系统标定', '1小时', '多种标准气体')
            create_measure(4, '调整光路对准', '1.5小时', '光路调整工具')
            create_measure(5, '更换光源和检测器', '3小时', '备件')
        ]);
    
    % 故障代码319
    fault_db.code_319 = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '319', ...
        'fault_name', '磁力测量回路失衡', ...
        'description', '磁力式传感器测量回路信号失去平衡', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', [
            create_measure(1, '检查磁场线圈连接', '10分钟', '万用表')
            create_measure(2, '测量磁力传感器输出', '20分钟', '示波器')
            create_measure(3, '调节信号调理电路', '30分钟', '调试设备')
            create_measure(4, '更换磁力传感器', '1小时', '备用传感器')
            create_measure(5, '更换传感器电路板', '2小时', '备用电路板')
        ]);
    
    % 故障代码320
    fault_db.code_320 = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '320', ...
        'fault_name', '测定放大偏差过高', ...
        'description', '信号放大器偏差超出正常范围', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', [
            create_measure(1, '检查放大器供电', '10分钟', '万用表')
            create_measure(2, '调整放大器零点增益', '25分钟', '示波器')
            create_measure(3, '更换运放芯片', '45分钟', '备用芯片')
            create_measure(4, '检查信号链路', '1小时', '信号发生器')
            create_measure(5, '更换放大器板', '1.5小时', '备用电路板')
        ]);
    
    % 故障代码309-311
    fault_db.code_309_311 = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '309-311', ...
        'fault_name', '温度调节器失效', ...
        'description', '温度控制超出范围', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', [
            create_measure(1, '检查温度传感器', '10分钟', '温度计')
            create_measure(2, '检查加热冷却器', '20分钟', '万用表')
            create_measure(3, '校准PID参数', '40分钟', '调试软件')
            create_measure(4, '更换温度传感器', '1小时', '备用传感器')
            create_measure(5, '更换温控模块', '2小时', '备用模块')
        ]);
    
    % ========== 数据传输中断型故障 ==========
    
    % 故障代码101
    fault_db.code_101 = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '101', ...
        'fault_name', '系统控制器关停', ...
        'description', '主控制器停止工作', ...
        'severity', '紧急', ...
        'priority', 1, ...
        'maintenance_measures', [
            create_measure(1, '检查主电源保险丝', '5分钟', '万用表')
            create_measure(2, '检查24V电源输出', '10分钟', '万用表')
            create_measure(3, '重启控制器系统', '15分钟', '无')
            create_measure(4, '检查CPU和内存', '30分钟', '诊断软件')
            create_measure(5, '更换控制器主板', '2小时', '备用主板')
        ]);
    
    % 故障代码116
    fault_db.code_116 = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '116', ...
        'fault_name', 'Profibus安装错误', ...
        'description', 'Profibus模块安装位置错误', ...
        'severity', '中等', ...
        'priority', 3, ...
        'maintenance_measures', [
            create_measure(1, '确认安装位置', '5分钟', '无')
            create_measure(2, '重装到X20/X21槽', '15分钟', '螺丝刀')
            create_measure(3, '重配通讯参数', '20分钟', '配置软件')
            create_measure(4, '测试通讯连接', '30分钟', 'Profibus测试仪')
            create_measure(5, '更换Profibus模块', '1小时', '备用模块')
        ]);
    
    % 故障代码201-209
    fault_db.code_201_209 = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '201-209', ...
        'fault_name', '系统总线连接中断', ...
        'description', '系统总线通讯中断', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', [
            create_measure(1, '检查总线电缆', '10分钟', '无')
            create_measure(2, '检查终端电阻', '15分钟', '万用表')
            create_measure(3, '更换总线电缆', '30分钟', '备用电缆')
            create_measure(4, '检查模块供电', '20分钟', '万用表')
            create_measure(5, '更换通讯模块', '1小时', '备用模块')
        ]);
    
    % 故障代码300
    fault_db.code_300 = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '300', ...
        'fault_name', '模数转换器无输出', ...
        'description', 'ADC无新测量值', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', [
            create_measure(1, '检查ADC供电', '10分钟', '万用表')
            create_measure(2, '检查模拟输入', '15分钟', '示波器')
            create_measure(3, '重置ADC芯片', '20分钟', '复位工具')
            create_measure(4, '更换ADC芯片', '1小时', '备用芯片')
            create_measure(5, '更换采集卡', '1.5小时', '备用采集卡')
        ]);
    
    % 故障代码308
    fault_db.code_308 = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '308', ...
        'fault_name', '测定值计算错误', ...
        'description', '计算过程错误', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', [
            create_measure(1, '重启处理程序', '5分钟', '无')
            create_measure(2, '检查CPU内存', '10分钟', '监控软件')
            create_measure(3, '清理系统缓存', '15分钟', '清理工具')
            create_measure(4, '重装固件程序', '45分钟', '固件包')
            create_measure(5, '更换处理器板', '2小时', '备用板')
        ]);
    
    % 故障代码318
    fault_db.code_318 = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '318', ...
        'fault_name', 'ADC无新测量', ...
        'description', 'ADC无新数据', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', [
            create_measure(1, '检查触发信号', '10分钟', '示波器')
            create_measure(2, '检查时钟信号', '15分钟', '示波器')
            create_measure(3, '重配采样参数', '20分钟', '配置软件')
            create_measure(4, '更换时钟芯片', '45分钟', '备用芯片')
            create_measure(5, '更换ADC模块', '1.5小时', '备用模块')
        ]);
    
    % 故障代码332-337
    fault_db.code_332_337 = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '332-337', ...
        'fault_name', 'I/O板故障', ...
        'description', 'I/O板硬件问题', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', [
            create_measure(1, '检查I/O板指示灯', '5分钟', '无')
            create_measure(2, '检查I/O配置', '15分钟', '配置软件')
            create_measure(3, '测试I/O通道', '30分钟', '万用表')
            create_measure(4, '初始化I/O板', '20分钟', '初始化工具')
            create_measure(5, '更换I/O板', '1小时', '备用板')
        ]);
    
    % 故障代码338-339
    fault_db.code_338_339 = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '338-339', ...
        'fault_name', '模拟线路故障', ...
        'description', '线路断裂或短路', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', [
            create_measure(1, '检查接线端子', '10分钟', '螺丝刀')
            create_measure(2, '测量线路通断', '15分钟', '万用表')
            create_measure(3, '检查屏蔽接地', '20分钟', '接地测试仪')
            create_measure(4, '更换信号电缆', '30分钟', '备用电缆')
            create_measure(5, '重新布线', '2小时', '布线工具')
        ]);
    
    % ========== 数据保持型故障 ==========
    
    % 故障代码301
    fault_db.code_301 = struct(...
        'fault_type', '数据保持型故障', ...
        'fault_code', '301', ...
        'fault_name', '超出ADC阈值', ...
        'description', '超出ADC范围', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', [
            create_measure(1, '确认实际浓度', '5分钟', '便携式分析仪')
            create_measure(2, '检查量程设置', '10分钟', '配置软件')
            create_measure(3, '调整信号衰减', '20分钟', '调节工具')
            create_measure(4, '重选测量量程', '30分钟', '配置软件')
            create_measure(5, '更换大量程传感器', '2小时', '备用传感器')
        ]);
    
    % 故障代码344
    fault_db.code_344 = struct(...
        'fault_type', '数据保持型故障', ...
        'fault_code', '344', ...
        'fault_name', '超上限130%', ...
        'description', '超过量程130%', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', [
            create_measure(1, '检查工艺异常', '5分钟', '工艺参数表')
            create_measure(2, '检查空气泄漏', '15分钟', '检漏仪')
            create_measure(3, '检查传感器饱和', '20分钟', '测试仪')
            create_measure(4, '切换高量程', '30分钟', '配置软件')
            create_measure(5, '更换高量程传感器', '2小时', '备用传感器')
        ]);
    
    % 故障代码345
    fault_db.code_345 = struct(...
        'fault_type', '数据保持型故障', ...
        'fault_code', '345', ...
        'fault_name', '低于下限-100%', ...
        'description', '低于量程-100%', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', [
            create_measure(1, '检查传感器接线', '10分钟', '接线图')
            create_measure(2, '检查信号电路', '20分钟', '万用表')
            create_measure(3, '验证零点设置', '30分钟', '零点气体')
            create_measure(4, '重新标定', '45分钟', '标准气体')
            create_measure(5, '更换传感器信号板', '2小时', '备件')
        ]);
    
    % ========== 数据波动型故障 ==========
    
    % 故障代码312
    fault_db.code_312 = struct(...
        'fault_type', '数据波动型故障', ...
        'fault_code', '312', ...
        'fault_name', '压力修正失效', ...
        'description', '压力测量错误', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', [
            create_measure(1, '检查压力传感器', '10分钟', '压力表')
            create_measure(2, '检查压力管路', '15分钟', '检漏仪')
            create_measure(3, '校准压力传感器', '30分钟', '标准压力源')
            create_measure(4, '检查补偿算法', '20分钟', '配置软件')
            create_measure(5, '更换压力传感器', '1小时', '备用传感器')
        ]);
    
    % 外部因素EXT-01
    fault_db.code_EXT_01 = struct(...
        'fault_type', '数据波动型故障', ...
        'fault_code', 'EXT-01', ...
        'fault_name', '管路污染堵塞', ...
        'description', '管道或过滤器问题', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', [
            create_measure(1, '检查过滤器压差', '5分钟', '压差表')
            create_measure(2, '更换过滤器', '20分钟', '备用滤芯')
            create_measure(3, '吹扫采样管路', '30分钟', '压缩空气')
            create_measure(4, '检查管路泄漏', '45分钟', '检漏仪')
            create_measure(5, '更换采样管路', '2小时', '备用管路')
        ]);
    
    % 外部因素EXT-02
    fault_db.code_EXT_02 = struct(...
        'fault_type', '数据波动型故障', ...
        'fault_code', 'EXT-02', ...
        'fault_name', '气路扭结泄漏', ...
        'description', '气路系统问题', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', [
            create_measure(1, '检查管路扭结', '5分钟', '手电筒')
            create_measure(2, '检查流量', '10分钟', '流量计')
            create_measure(3, '逐段检漏', '30分钟', '检漏仪')
            create_measure(4, '紧固接头', '20分钟', '扳手')
            create_measure(5, '重装气路', '3小时', '全套管路')
        ]);
end

function data_fault_types = get_data_fault_types()
    % 定义数据故障类型
    data_fault_types = containers.Map();
    data_fault_types('001') = '满量程输出';
    data_fault_types('002') = '零位输出';
    data_fault_types('003') = '数据缺失';
    data_fault_types('004') = '数据保持';
    data_fault_types('005') = '剧烈波动异常';
    data_fault_types('006') = '数据偏移';
    data_fault_types('006.01') = '小幅正向偏移';
    data_fault_types('006.02') = '小幅负向偏移';
    data_fault_types('006.03') = '大幅正向偏移';
    data_fault_types('006.04') = '大幅负向偏移';
    data_fault_types('006.05') = '严重正向偏移';
    data_fault_types('006.06') = '严重负向偏移';
end

function fault_code_map = get_fault_code_mapping()
    % 定义仪表故障代码与数据故障类型的映射关系
    fault_code_map = containers.Map();
    
    % 数据偏差型故障
    fault_code_map('302') = {'006.01', '006.02'};
    fault_code_map('303') = {'006.03', '006.04'};
    fault_code_map('304') = {'006.01', '006.02'};
    fault_code_map('305') = {'006.05', '006.06'};
    fault_code_map('319') = {'001', '002'};
    fault_code_map('320') = {'006', '006.03'};
    fault_code_map('309-311') = {'005'};
    
    % 数据传输中断型故障
    fault_code_map('101') = {'003'};
    fault_code_map('116') = {'003', '004'};
    fault_code_map('201-209') = {'003'};
    fault_code_map('300') = {'003', '004'};
    fault_code_map('308') = {'005', '003'};
    fault_code_map('318') = {'003', '004'};
    fault_code_map('332-337') = {'003', '004'};
    fault_code_map('338-339') = {'003', '001', '002'};
    
    % 数据保持型故障
    fault_code_map('301') = {'001', '004'};
    fault_code_map('344') = {'001'};
    fault_code_map('345') = {'002'};
    
    % 数据波动型故障
    fault_code_map('312') = {'005', '006'};
    fault_code_map('EXT-01') = {'005', '004'};
    fault_code_map('EXT-02') = {'005', '003'};
end

function data_fault_code = get_data_fault_code(instrument_fault_code)
    % 根据仪表故障代码获取对应的数据故障代码
    fault_code_map = get_fault_code_mapping();
    data_fault_types = get_data_fault_types();
    
    if isKey(fault_code_map, instrument_fault_code)
        data_fault_codes = fault_code_map(instrument_fault_code);
        selected_code = data_fault_codes{randi(length(data_fault_codes))};
        data_fault_code = sprintf('%s %s', selected_code, data_fault_types(selected_code));
    else
        data_fault_code = '006 数据偏移';
    end
end

function records = generate_records(fault_db, start_date, end_date, num_records)
    % 生成故障记录
    
    % 获取所有故障代码
    fault_fields = fieldnames(fault_db);
    num_faults = length(fault_fields);
    
    % 初始化记录数组
    records = cell(num_records, 10);
    
    % 计算时间范围（秒）
    time_range = seconds(end_date - start_date);
    
    for i = 1:num_records
        % 随机选择故障
        fault_idx = randi(num_faults);
        fault_field = fault_fields{fault_idx};
        fault_info = fault_db.(fault_field);
        
        % 随机选择维修措施
        measure_idx = randi(length(fault_info.maintenance_measures));
        measure = fault_info.maintenance_measures(measure_idx);
        
        % 生成随机时间
        random_seconds = rand() * time_range;
        fault_time = start_date + seconds(random_seconds);
        
        % 获取对应的数据故障代码
        data_fault_code = get_data_fault_code(fault_info.fault_code);
        
        % 创建记录
        records{i, 1} = data_fault_code;
        records{i, 2} = datestr(fault_time, 'yyyy-mm-dd HH:MM:SS');
        records{i, 3} = fault_info.fault_code;
        records{i, 4} = fault_info.fault_name;
        records{i, 5} = fault_info.fault_type;
        records{i, 6} = fault_info.severity;
        records{i, 7} = fault_info.priority;
        records{i, 8} = measure.operation;
        records{i, 9} = measure.duration;
        records{i, 10} = measure.tools;
    end
    
    % 按时间排序
    [~, sort_idx] = sort(records(:, 2));
    records = records(sort_idx, :);
end

function export_to_excel(records, filename)
    % 导出记录到Excel文件
    
    % 创建表格
    column_names = {
        '数据故障代码', ...
        '故障时间', ...
        '仪表故障代码', ...
        '故障描述/名称', ...
        '故障类型', ...
        '严重程度', ...
        '优先级', ...
        '维修操作', ...
        '耗时', ...
        '工具'
    };
    
    % 转换为table
    T = cell2table(records, 'VariableNames', column_names);
    
    % 写入Excel
    writetable(T, filename, 'Sheet', '故障维修记录');
    
    fprintf('Excel文件已生成: %s\n', filename);
end

function generate_statistics(records)
    % 生成分布统计信息
    
    fprintf('\n=== 故障记录统计信息 ===\n');
    fprintf('总记录数: %d\n', size(records, 1));
    
    % 故障类型分布
    fault_types = records(:, 5);
    unique_types = unique(fault_types);
    fprintf('\n故障类型分布:\n');
    for i = 1:length(unique_types)
        count = sum(strcmp(fault_types, unique_types{i}));
        fprintf('%s: %d\n', unique_types{i}, count);
    end
    
    % 严重程度分布
    severities = records(:, 6);
    unique_severities = unique(severities);
    fprintf('\n严重程度分布:\n');
    for i = 1:length(unique_severities)
        count = sum(strcmp(severities, unique_severities{i}));
        fprintf('%s: %d\n', unique_severities{i}, count);
    end
    
    % 数据故障类型分布
    data_fault_codes = records(:, 1);
    data_fault_main = cellfun(@(x) strsplit(x, ' '), data_fault_codes, 'UniformOutput', false);
    data_fault_main = cellfun(@(x) strsplit(x{1}, '.'), data_fault_main, 'UniformOutput', false);
    data_fault_main = cellfun(@(x) x{1}, data_fault_main, 'UniformOutput', false);
    
    unique_data_faults = unique(data_fault_main);
    fprintf('\n数据故障类型分布:\n');
    for i = 1:length(unique_data_faults)
        count = sum(strcmp(data_fault_main, unique_data_faults{i}));
        fprintf('%s: %d\n', unique_data_faults{i}, count);
    end
    
    % 计算平均每月故障数
    fault_times = datetime(records(:, 2), 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
    months = unique(dateshift(fault_times, 'start', 'month'));
    avg_monthly = size(records, 1) / length(months);
    fprintf('\n平均每月故障数: %.1f\n', avg_monthly);
end