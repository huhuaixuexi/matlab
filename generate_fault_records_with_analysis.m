%% 故障诊断维修记录生成与分析系统 - MATLAB版本
% 生成5年的模拟故障维修记录数据并导出为Excel文件
% 包含数据故障代码映射和全面的故障分析功能

function generate_fault_records_with_analysis()
    % 主函数
    fprintf('========================================\n');
    fprintf('故障诊断维修记录生成与分析系统\n');
    fprintf('MATLAB版本: %s\n', version);
    fprintf('========================================\n\n');
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
    
    % 执行故障分析
    fprintf('\n开始执行故障分析...\n');
    perform_fault_analysis(records);
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

%% ==================== 故障分析功能 ====================

function perform_fault_analysis(records)
    % 执行完整的故障分析
    
    % 转换记录为结构化数据
    data = preprocess_data(records);
    
    % 1. 基础统计分析
    basic_stats = basic_statistics_analysis(data);
    
    % 2. 维修效率分析
    efficiency_stats = maintenance_efficiency_analysis(data);
    
    % 3. 故障模式分析
    pattern_stats = fault_pattern_analysis(data);
    
    % 4. 关联性分析
    correlation_stats = correlation_analysis(data);
    
    % 5. 预测性分析
    predictive_stats = predictive_analysis(data);
    
    % 6. 生成可视化报告
    generate_visualizations(data, basic_stats, efficiency_stats, pattern_stats);
    
    % 7. 生成文字报告
    generate_summary_report(data, basic_stats, efficiency_stats, pattern_stats);
    
    fprintf('\n分析完成！\n');
end

function data = preprocess_data(records)
    % 数据预处理
    data = struct();
    
    % 基本字段
    data.data_fault_code = records(:, 1);
    data.fault_time = datetime(records(:, 2), 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
    data.instrument_fault_code = records(:, 3);
    data.fault_name = records(:, 4);
    data.fault_type = records(:, 5);
    data.severity = records(:, 6);
    data.priority = cell2mat(records(:, 7));
    data.operation = records(:, 8);
    data.duration = records(:, 9);
    data.tools = records(:, 10);
    
    % 时间相关字段
    data.year = year(data.fault_time);
    data.month = month(data.fault_time);
    data.quarter = quarter(data.fault_time);
    data.dayofweek = weekday(data.fault_time);
    data.hour = hour(data.fault_time);
    
    % 数据故障主类型
    data_fault_main = cellfun(@(x) strsplit(x, ' '), data.data_fault_code, 'UniformOutput', false);
    data_fault_main = cellfun(@(x) strsplit(x{1}, '.'), data_fault_main, 'UniformOutput', false);
    data.data_fault_main = cellfun(@(x) x{1}, data_fault_main, 'UniformOutput', false);
    
    % 耗时分钟数
    data.duration_minutes = parse_duration(data.duration);
end

function minutes = parse_duration(duration_cell)
    % 解析耗时字符串为分钟数
    minutes = zeros(length(duration_cell), 1);
    for i = 1:length(duration_cell)
        dur_str = duration_cell{i};
        if contains(dur_str, '小时')
            hours = str2double(strrep(dur_str, '小时', ''));
            minutes(i) = hours * 60;
        elseif contains(dur_str, '分钟')
            minutes(i) = str2double(strrep(dur_str, '分钟', ''));
        end
    end
end

function stats = basic_statistics_analysis(data)
    % 1. 基础统计分析
    fprintf('\n');
    fprintf('==================================================\n');
    fprintf('1. 基础统计分析\n');
    fprintf('==================================================\n');
    
    stats = struct();
    total_faults = length(data.fault_time);
    
    % 故障频率分析
    fprintf('\n【故障频率分析】\n');
    fprintf('总故障数: %d\n', total_faults);
    
    [unique_codes, ~, idx] = unique(data.instrument_fault_code);
    code_counts = accumarray(idx, 1);
    [sorted_counts, sort_idx] = sort(code_counts, 'descend');
    
    fprintf('\n各故障代码发生次数及占比:\n');
    for i = 1:min(10, length(sorted_counts))
        code = unique_codes{sort_idx(i)};
        count = sorted_counts(i);
        percentage = (count / total_faults) * 100;
        fprintf('%s: %d次 (%.1f%%)\n', code, count, percentage);
    end
    
    stats.fault_counts = [unique_codes(sort_idx), num2cell(sorted_counts)];
    
    % 时间分布分析
    fprintf('\n【时间分布分析】\n');
    
    % 年度分布
    yearly_counts = accumarray(data.year - min(data.year) + 1, 1);
    years = min(data.year):max(data.year);
    fprintf('\n年度故障分布:\n');
    for i = 1:length(years)
        fprintf('%d年: %d次\n', years(i), yearly_counts(i));
    end
    
    stats.yearly_counts = struct('years', years', 'counts', yearly_counts);
    
    % 故障类型分布
    fprintf('\n【故障类型分布】\n');
    [unique_types, ~, idx] = unique(data.fault_type);
    type_counts = accumarray(idx, 1);
    [sorted_type_counts, sort_idx] = sort(type_counts, 'descend');
    
    for i = 1:length(sorted_type_counts)
        type = unique_types{sort_idx(i)};
        count = sorted_type_counts(i);
        percentage = (count / total_faults) * 100;
        fprintf('%s: %d次 (%.1f%%)\n', type, count, percentage);
    end
    
    stats.type_counts = [unique_types(sort_idx), num2cell(sorted_type_counts)];
    
    return;
end

function stats = maintenance_efficiency_analysis(data)
    % 2. 维修效率分析
    fprintf('\n');
    fprintf('==================================================\n');
    fprintf('2. 维修效率分析\n');
    fprintf('==================================================\n');
    
    stats = struct();
    
    % 平均维修时间
    fprintf('\n【平均维修时间分析】\n');
    fprintf('\n各故障类型维修时间统计(分钟):\n');
    
    [unique_types, ~, idx] = unique(data.fault_type);
    for i = 1:length(unique_types)
        type_mask = strcmp(data.fault_type, unique_types{i});
        type_durations = data.duration_minutes(type_mask);
        
        avg_time = mean(type_durations);
        min_time = min(type_durations);
        max_time = max(type_durations);
        count = sum(type_mask);
        
        fprintf('%s:\n', unique_types{i});
        fprintf('  平均: %.1f, 最短: %.0f, 最长: %.0f, 次数: %d\n', ...
            avg_time, min_time, max_time, count);
    end
    
    % 工具使用频率
    fprintf('\n【工具使用频率分析】\n');
    tools_list = {};
    for i = 1:length(data.tools)
        if ~strcmp(data.tools{i}, '无')
            tools = strsplit(data.tools{i}, '、');
            tools_list = [tools_list, tools];
        end
    end
    
    [unique_tools, ~, idx] = unique(tools_list);
    tool_counts = accumarray(idx, 1);
    [sorted_tool_counts, sort_idx] = sort(tool_counts, 'descend');
    
    fprintf('\n最常用工具TOP10:\n');
    for i = 1:min(10, length(sorted_tool_counts))
        tool = unique_tools{sort_idx(i)};
        count = sorted_tool_counts(i);
        fprintf('%s: %d次\n', tool, count);
    end
    
    stats.tools_freq = [unique_tools(sort_idx)', num2cell(sorted_tool_counts)];
    
    % 维修操作效果
    fprintf('\n【维修操作效果分析】\n');
    [unique_ops, ~, idx] = unique(data.operation);
    op_durations = zeros(length(unique_ops), 1);
    op_counts = zeros(length(unique_ops), 1);
    
    for i = 1:length(unique_ops)
        op_mask = strcmp(data.operation, unique_ops{i});
        op_durations(i) = mean(data.duration_minutes(op_mask));
        op_counts(i) = sum(op_mask);
    end
    
    [sorted_counts, sort_idx] = sort(op_counts, 'descend');
    
    fprintf('\n最常见维修操作及平均耗时:\n');
    for i = 1:min(10, length(sorted_counts))
        if sorted_counts(i) > 0
            op = unique_ops{sort_idx(i)};
            count = sorted_counts(i);
            avg_time = op_durations(sort_idx(i));
            fprintf('%s: %d次, 平均%.1f分钟\n', op, count, avg_time);
        end
    end
    
    stats.operation_stats = [unique_ops(sort_idx), num2cell(sorted_counts), ...
        num2cell(op_durations(sort_idx))];
    
    return;
end

function stats = fault_pattern_analysis(data)
    % 3. 故障模式分析
    fprintf('\n');
    fprintf('==================================================\n');
    fprintf('3. 故障模式分析\n');
    fprintf('==================================================\n');
    
    stats = struct();
    total = length(data.fault_time);
    
    % 故障严重程度分布
    fprintf('\n【故障严重程度分布】\n');
    [unique_severities, ~, idx] = unique(data.severity);
    severity_counts = accumarray(idx, 1);
    
    for i = 1:length(unique_severities)
        severity = unique_severities{i};
        count = severity_counts(i);
        percentage = (count / total) * 100;
        fprintf('%s: %d次 (%.1f%%)\n', severity, count, percentage);
    end
    
    stats.severity_counts = [unique_severities, num2cell(severity_counts)];
    
    % 优先级分析
    fprintf('\n【优先级分析】\n');
    unique_priorities = unique(data.priority);
    priority_counts = zeros(length(unique_priorities), 1);
    
    for i = 1:length(unique_priorities)
        priority_counts(i) = sum(data.priority == unique_priorities(i));
        percentage = (priority_counts(i) / total) * 100;
        fprintf('优先级%d: %d次 (%.1f%%)\n', unique_priorities(i), priority_counts(i), percentage);
    end
    
    stats.priority_counts = struct('priorities', unique_priorities, 'counts', priority_counts);
    
    % 高优先级故障详情
    high_priority_mask = data.priority == 1;
    if any(high_priority_mask)
        fprintf('\n高优先级(1级)故障主要类型:\n');
        hp_codes = data.instrument_fault_code(high_priority_mask);
        hp_names = data.fault_name(high_priority_mask);
        
        [unique_hp_codes, ~, idx] = unique(hp_codes);
        hp_code_counts = accumarray(idx, 1);
        [sorted_hp_counts, sort_idx] = sort(hp_code_counts, 'descend');
        
        for i = 1:min(5, length(sorted_hp_counts))
            code = unique_hp_codes{sort_idx(i)};
            count = sorted_hp_counts(i);
            name_idx = find(strcmp(hp_codes, code), 1);
            name = hp_names{name_idx};
            fprintf('%s - %s: %d次\n', code, name, count);
        end
    end
    
    % 季节性模式
    fprintf('\n【季节性模式分析】\n');
    quarter_counts = accumarray(data.quarter, 1);
    season_names = {'春季', '夏季', '秋季', '冬季'};
    
    fprintf('\n各季度故障分布:\n');
    for i = 1:4
        if i <= length(quarter_counts)
            count = quarter_counts(i);
            avg_monthly = count / (length(unique(data.year)) * 3);
            fprintf('%s(Q%d): %d次, 平均每月%.1f次\n', ...
                season_names{i}, i, count, avg_monthly);
        end
    end
    
    stats.seasonal_counts = struct('quarters', (1:4)', 'counts', quarter_counts);
    
    % 工作日vs周末分析
    is_workday = data.dayofweek >= 2 & data.dayofweek <= 6;
    workday_count = sum(is_workday);
    weekend_count = sum(~is_workday);
    
    fprintf('\n工作日vs周末故障分布:\n');
    fprintf('工作日: %d次 (%.1f%%)\n', workday_count, (workday_count/total)*100);
    fprintf('周末: %d次 (%.1f%%)\n', weekend_count, (weekend_count/total)*100);
    
    stats.workday_counts = [workday_count; weekend_count];
    
    return;
end

function stats = correlation_analysis(data)
    % 4. 关联性分析
    fprintf('\n');
    fprintf('==================================================\n');
    fprintf('4. 关联性分析\n');
    fprintf('==================================================\n');
    
    stats = struct();
    
    % 故障代码关联分析
    fprintf('\n【故障代码关联分析】\n');
    
    % 分析同一天发生的故障
    dates = dateshift(data.fault_time, 'start', 'day');
    unique_dates = unique(dates);
    co_occurrence = containers.Map();
    
    for i = 1:length(unique_dates)
        day_mask = dates == unique_dates(i);
        day_codes = data.instrument_fault_code(day_mask);
        
        if length(day_codes) > 1
            for j = 1:length(day_codes)-1
                for k = j+1:length(day_codes)
                    pair = sort({day_codes{j}, day_codes{k}});
                    pair_key = sprintf('%s-%s', pair{1}, pair{2});
                    
                    if isKey(co_occurrence, pair_key)
                        co_occurrence(pair_key) = co_occurrence(pair_key) + 1;
                    else
                        co_occurrence(pair_key) = 1;
                    end
                end
            end
        end
    end
    
    if length(keys(co_occurrence)) > 0
        fprintf('\n同日发生的故障对:\n');
        all_keys = keys(co_occurrence);
        all_values = cell2mat(values(co_occurrence));
        [sorted_values, sort_idx] = sort(all_values, 'descend');
        
        for i = 1:min(5, length(sorted_values))
            if sorted_values(i) > 0
                fprintf('%s: %d次\n', all_keys{sort_idx(i)}, sorted_values(i));
            end
        end
    end
    
    % 维修操作与耗时关系
    fprintf('\n【维修操作与耗时关系】\n');
    
    % 按严重程度分组分析平均耗时
    [unique_severities, ~, idx] = unique(data.severity);
    severity_times = zeros(length(unique_severities), 1);
    
    for i = 1:length(unique_severities)
        severity_mask = strcmp(data.severity, unique_severities{i});
        severity_times(i) = mean(data.duration_minutes(severity_mask));
    end
    
    [sorted_times, sort_idx] = sort(severity_times, 'descend');
    
    fprintf('\n不同严重程度的平均维修时间:\n');
    for i = 1:length(sorted_times)
        severity = unique_severities{sort_idx(i)};
        avg_time = sorted_times(i);
        fprintf('%s: %.1f分钟\n', severity, avg_time);
    end
    
    stats.severity_time = [unique_severities(sort_idx), num2cell(sorted_times)];
    
    % 故障复杂度分析
    fprintf('\n【故障复杂度分析】\n');
    
    [unique_codes, ~, idx] = unique(data.instrument_fault_code);
    code_complexities = zeros(length(unique_codes), 3);
    
    for i = 1:length(unique_codes)
        code_mask = strcmp(data.instrument_fault_code, unique_codes{i});
        code_complexities(i, 1) = mean(data.duration_minutes(code_mask));
        code_complexities(i, 2) = mean(data.priority(code_mask));
        code_complexities(i, 3) = sum(code_mask);
    end
    
    [sorted_complexities, sort_idx] = sort(code_complexities(:, 1), 'descend');
    
    fprintf('\n最复杂故障TOP5(按平均维修时间):\n');
    for i = 1:min(5, length(sorted_complexities))
        code = unique_codes{sort_idx(i)};
        name_idx = find(strcmp(data.instrument_fault_code, code), 1);
        name = data.fault_name{name_idx};
        avg_time = sorted_complexities(i);
        fprintf('%s - %s: 平均%.1f分钟\n', code, name, avg_time);
    end
    
    stats.fault_complexity = [unique_codes(sort_idx), num2cell(sorted_complexities)];
    
    return;
end

function stats = predictive_analysis(data)
    % 5. 预测性分析
    fprintf('\n');
    fprintf('==================================================\n');
    fprintf('5. 预测性分析\n');
    fprintf('==================================================\n');
    
    stats = struct();
    
    % 故障趋势预测
    fprintf('\n【故障趋势预测】\n');
    
    % 按月统计故障数
    min_date = dateshift(min(data.fault_time), 'start', 'month');
    max_date = dateshift(max(data.fault_time), 'start', 'month');
    months = min_date:calmonths(1):max_date;
    monthly_counts = zeros(length(months), 1);
    
    for i = 1:length(months)
        month_start = months(i);
        month_end = dateshift(month_start, 'end', 'month');
        monthly_counts(i) = sum(data.fault_time >= month_start & data.fault_time <= month_end);
    end
    
    % 简单线性回归预测
    X = (1:length(monthly_counts))';
    y = monthly_counts;
    
    % 计算线性回归参数
    n = length(X);
    x_mean = mean(X);
    y_mean = mean(y);
    
    beta1 = sum((X - x_mean) .* (y - y_mean)) / sum((X - x_mean).^2);
    beta0 = y_mean - beta1 * x_mean;
    
    % 预测未来6个月
    future_X = (n+1:n+6)';
    predictions = beta0 + beta1 * future_X;
    
    fprintf('\n未来6个月故障预测:\n');
    for i = 1:6
        future_month = months(end) + calmonths(i);
        pred_count = max(0, round(predictions(i)));
        fprintf('%s: 预计%d次故障\n', datestr(future_month, 'yyyy-mm'), pred_count);
    end
    
    % 保存为结构体而不是数组拼接
    stats.monthly_faults = struct('months', months', 'counts', monthly_counts);
    stats.predictions = predictions;
    
    % 备件需求预测
    fprintf('\n【备件需求预测】\n');
    
    % 统计各类更换操作
    replacement_mask = contains(data.operation, '更换');
    replacement_ops = data.operation(replacement_mask);
    
    parts_count = struct();
    parts_count.sensor = sum(contains(replacement_ops, '传感器'));
    parts_count.board = sum(contains(replacement_ops, {'电路板', '板'}));
    parts_count.module = sum(contains(replacement_ops, '模块'));
    parts_count.cable = sum(contains(replacement_ops, {'电缆', '线路'}));
    
    years = length(unique(data.year));
    
    fprintf('\n基于历史数据的年度备件需求预测:\n');
    parts_names = fieldnames(parts_count);
    for i = 1:length(parts_names)
        part = parts_names{i};
        count = parts_count.(part);
        annual_need = count / years;
        suggested_stock = ceil(annual_need * 1.5);
        
        part_name_cn = '';
        switch part
            case 'sensor'
                part_name_cn = '传感器';
            case 'board'
                part_name_cn = '电路板';
            case 'module'
                part_name_cn = '模块';
            case 'cable'
                part_name_cn = '电缆';
        end
        
        fprintf('%s: 年均需求%.1f个, 建议库存%d个\n', part_name_cn, annual_need, suggested_stock);
    end
    
    stats.parts_freq = parts_count;
    
    % 预防性维护计划
    fprintf('\n【预防性维护计划建议】\n');
    
    % 分析高频故障的平均间隔时间
    [unique_codes, ~, idx] = unique(data.instrument_fault_code);
    code_counts = accumarray(idx, 1);
    [sorted_counts, sort_idx] = sort(code_counts, 'descend');
    
    fprintf('\n基于故障间隔的维护周期建议:\n');
    for i = 1:min(5, length(sorted_counts))
        if sorted_counts(i) > 1
            code = unique_codes{sort_idx(i)};
            code_mask = strcmp(data.instrument_fault_code, code);
            fault_dates = sort(data.fault_time(code_mask));
            
            if length(fault_dates) > 1
                intervals = days(diff(fault_dates));
                avg_interval = mean(intervals);
                suggested_interval = round(avg_interval * 0.8);
                
                name_idx = find(code_mask, 1);
                name = data.fault_name{name_idx};
                
                fprintf('%s - %s:\n', code, name);
                fprintf('  平均故障间隔: %.0f天\n', avg_interval);
                fprintf('  建议维护周期: %d天\n', suggested_interval);
            end
        end
    end
    
    return;
end

function generate_visualizations(data, basic_stats, efficiency_stats, pattern_stats)
    % 生成可视化图表
    fprintf('\n');
    fprintf('==================================================\n');
    fprintf('6. 生成可视化报告\n');
    fprintf('==================================================\n');
    
    % 创建图形窗口
    fig = figure('Position', [100, 100, 1600, 1200]);
    
    % 1. 故障类型分布饼图
    subplot(4, 3, 1);
    type_data = basic_stats.type_counts;
    pie([type_data{:, 2}]);
    legend(type_data(:, 1), 'Location', 'eastoutside');
    title('故障类型分布');
    
    % 2. 月度故障趋势图
    subplot(4, 3, 2);
    % 创建年月组合统计
    year_month = data.year * 100 + data.month;
    unique_ym = unique(year_month);
    ym_counts = zeros(length(unique_ym), 1);
    for i = 1:length(unique_ym)
        ym_counts(i) = sum(year_month == unique_ym(i));
    end
    plot(1:length(unique_ym), ym_counts, '-o');
    title('月度故障趋势');
    xlabel('时间序号');
    ylabel('故障数');
    grid on;
    
    % 3. 严重程度分布条形图
    subplot(4, 3, 3);
    severity_data = pattern_stats.severity_counts;
    bar([severity_data{:, 2}]);
    set(gca, 'XTickLabel', severity_data(:, 1));
    title('故障严重程度分布');
    xlabel('严重程度');
    ylabel('数量');
    
    % 4. TOP10故障代码
    subplot(4, 3, 4);
    fault_data = basic_stats.fault_counts;
    top10_codes = fault_data(1:min(10, size(fault_data, 1)), :);
    barh([top10_codes{:, 2}]);
    set(gca, 'YTickLabel', top10_codes(:, 1));
    title('TOP 10 故障代码');
    xlabel('数量');
    
    % 5. 维修时间分布图（使用条形图代替箱线图）
    subplot(4, 3, 5);
    [unique_types, ~, idx] = unique(data.fault_type);
    % 计算每种故障类型的平均值、最小值、最大值
    type_stats = zeros(length(unique_types), 3); % 平均值、最小值、最大值
    for i = 1:length(unique_types)
        type_mask = strcmp(data.fault_type, unique_types{i});
        type_durations = data.duration_minutes(type_mask);
        type_stats(i, 1) = mean(type_durations);
        type_stats(i, 2) = min(type_durations);
        type_stats(i, 3) = max(type_durations);
    end
    
    % 绘制分组条形图
    bar_data = type_stats(:, 1); % 只显示平均值
    bar(bar_data);
    hold on;
    % 添加误差线表示范围
    errorbar(1:length(unique_types), type_stats(:, 1), ...
        type_stats(:, 1) - type_stats(:, 2), ...
        type_stats(:, 3) - type_stats(:, 1), 'k.', 'LineWidth', 1);
    hold off;
    
    set(gca, 'XTick', 1:length(unique_types));
    set(gca, 'XTickLabel', unique_types);
    title('各故障类型维修时间分布');
    xlabel('故障类型');
    ylabel('平均时间(分钟)');
    xtickangle(45);
    
    % 6. 季度故障分布
    subplot(4, 3, 6);
    seasonal_data = pattern_stats.seasonal_counts;
    bar(seasonal_data.counts);
    set(gca, 'XTickLabel', {'Q1', 'Q2', 'Q3', 'Q4'});
    title('季度故障分布');
    xlabel('季度');
    ylabel('数量');
    
    % 7. 优先级分布
    subplot(4, 3, 7);
    priority_data = pattern_stats.priority_counts;
    bar(priority_data.counts);
    set(gca, 'XTickLabel', arrayfun(@num2str, priority_data.priorities, 'UniformOutput', false));
    title('优先级分布');
    xlabel('优先级');
    ylabel('数量');
    
    % 8. 数据故障类型分布饼图
    subplot(4, 3, 8);
    [unique_data_faults, ~, idx] = unique(data.data_fault_main);
    data_fault_counts = accumarray(idx, 1);
    pie(data_fault_counts);
    
    % 创建标签
    data_fault_names = {'满量程', '零位', '缺失', '保持', '波动', '偏移'};
    data_fault_labels = cell(length(unique_data_faults), 1);
    for i = 1:length(unique_data_faults)
        switch unique_data_faults{i}
            case '001'
                data_fault_labels{i} = data_fault_names{1};
            case '002'
                data_fault_labels{i} = data_fault_names{2};
            case '003'
                data_fault_labels{i} = data_fault_names{3};
            case '004'
                data_fault_labels{i} = data_fault_names{4};
            case '005'
                data_fault_labels{i} = data_fault_names{5};
            case '006'
                data_fault_labels{i} = data_fault_names{6};
            otherwise
                data_fault_labels{i} = unique_data_faults{i};
        end
    end
    
    legend(data_fault_labels, 'Location', 'eastoutside');
    title('数据故障类型分布');
    
    % 9. 工具使用频率TOP10
    subplot(4, 3, 9);
    tools_data = efficiency_stats.tools_freq;
    top10_tools = tools_data(1:min(10, size(tools_data, 1)), :);
    barh([top10_tools{:, 2}]);
    set(gca, 'YTickLabel', top10_tools(:, 1));
    title('TOP 10 常用工具');
    xlabel('使用次数');
    
    % 10. 故障热力图（按星期和小时）
    subplot(4, 3, 10);
    heatmap_data = zeros(7, 24);
    for i = 1:length(data.dayofweek)
        dow = data.dayofweek(i);
        hr = data.hour(i) + 1;
        if dow >= 1 && dow <= 7 && hr >= 1 && hr <= 24
            heatmap_data(dow, hr) = heatmap_data(dow, hr) + 1;
        end
    end
    imagesc(heatmap_data);
    colorbar;
    set(gca, 'YTick', 1:7);
    set(gca, 'YTickLabel', {'日', '一', '二', '三', '四', '五', '六'});
    set(gca, 'XTick', 1:4:24);
    set(gca, 'XTickLabel', 0:4:20);
    xlabel('小时');
    ylabel('星期');
    title('故障时间热力图');
    
    % 11. 年度故障趋势
    subplot(4, 3, 11);
    yearly_data = basic_stats.yearly_counts;
    bar(yearly_data.years, yearly_data.counts);
    title('年度故障趋势');
    xlabel('年份');
    ylabel('故障数');
    
    % 12. 维修操作效率TOP10
    subplot(4, 3, 12);
    op_data = efficiency_stats.operation_stats;
    % 筛选出现2次以上的操作
    freq_ops = op_data([op_data{:, 2}] >= 2, :);
    if ~isempty(freq_ops)
        % 按平均时间排序
        [~, sort_idx] = sort([freq_ops{:, 3}]);
        top10_ops = freq_ops(sort_idx(1:min(10, length(sort_idx))), :);
        barh([top10_ops{:, 3}]);
        set(gca, 'YTickLabel', top10_ops(:, 1));
        title('TOP 10 最快维修操作');
        xlabel('平均时间(分钟)');
    end
    
    % 保存图形
    report_filename = sprintf('故障分析报告_%s.png', datestr(now, 'yyyymmdd_HHMMSS'));
    saveas(fig, report_filename);
    fprintf('\n可视化报告已保存: %s\n', report_filename);
    
    close(fig);
end

function generate_summary_report(data, basic_stats, efficiency_stats, pattern_stats)
    % 生成文字总结报告
    report_filename = sprintf('故障分析总结报告_%s.txt', datestr(now, 'yyyymmdd_HHMMSS'));
    
    fid = fopen(report_filename, 'w', 'native', 'UTF-8');
    
    fprintf(fid, '======================================================================\n');
    fprintf(fid, '故障诊断维修记录分析总结报告\n');
    fprintf(fid, '生成时间: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    fprintf(fid, '======================================================================\n\n');
    
    % 概览
    fprintf(fid, '【数据概览】\n');
    fprintf(fid, '分析时间范围: %s 至 %s\n', ...
        datestr(min(data.fault_time), 'yyyy-mm-dd'), ...
        datestr(max(data.fault_time), 'yyyy-mm-dd'));
    fprintf(fid, '总记录数: %d\n', length(data.fault_time));
    fprintf(fid, '覆盖故障类型: %d种\n', length(unique(data.fault_type)));
    fprintf(fid, '涉及故障代码: %d个\n\n', length(unique(data.instrument_fault_code)));
    
    % 关键发现
    fprintf(fid, '【关键发现】\n');
    
    % 最频繁故障
    top_fault = basic_stats.fault_counts{1, 1};
    top_fault_count = basic_stats.fault_counts{1, 2};
    top_fault_idx = find(strcmp(data.instrument_fault_code, top_fault), 1);
    top_fault_name = data.fault_name{top_fault_idx};
    fprintf(fid, '1. 最频繁故障: %s - %s (发生%d次)\n', top_fault, top_fault_name, top_fault_count);
    
    % 平均维修时间
    avg_time = mean(data.duration_minutes);
    fprintf(fid, '2. 平均维修时间: %.1f分钟\n', avg_time);
    
    % 严重故障占比
    severe_count = sum(strcmp(data.severity, '严重'));
    severe_ratio = (severe_count / length(data.severity)) * 100;
    fprintf(fid, '3. 严重故障占比: %.1f%%\n', severe_ratio);
    
    % 高优先级故障
    high_priority_count = sum(data.priority == 1);
    high_priority_ratio = (high_priority_count / length(data.priority)) * 100;
    fprintf(fid, '4. 高优先级故障占比: %.1f%%\n\n', high_priority_ratio);
    
    % 建议
    fprintf(fid, '【改进建议】\n');
    fprintf(fid, '1. 重点关注高频故障的预防性维护\n');
    fprintf(fid, '2. 优化备件库存管理，确保常用配件充足\n');
    fprintf(fid, '3. 加强季节性维护，特别是故障高发季节\n');
    fprintf(fid, '4. 定期培训维修人员，提高维修效率\n');
    fprintf(fid, '5. 建立故障预警机制，提前发现潜在问题\n');
    
    fclose(fid);
    
    fprintf('\n文字总结报告已保存: %s\n', report_filename);
end