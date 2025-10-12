% 测试所有维修建议显示功能

% 初始化维修数据库
maintenance_db = init_maintenance_database();

% 建立故障映射
fault_mapping = containers.Map();
fault_mapping('001') = {'344', '301'};                          % 满量程输出
fault_mapping('002') = {'345', '303', '302'};                   % 零位输出
fault_mapping('003') = {'101', '201-209', '300', '308', '318', '332-337', '338-339'}; % 数据缺失
fault_mapping('004') = {'301', '318', '300'};                   % 数据保持
fault_mapping('005') = {'312', 'EXT-01', 'EXT-02', '319'};      % 剧烈波动
fault_mapping('006.01') = {'302', '309-311'};                   % 小幅正向偏移

% 测试不同的诊断故障代码
test_codes = {'001', '002', '003', '004', '005', '006.01'};
test_names = {'满量程输出', '零位输出', '数据缺失', '数据保持', '剧烈波动', '小幅正向偏移'};

for i = 1:length(test_codes)
    fprintf('\n\n════════════════════════════════════════\n');
    fprintf('测试诊断代码: %s - %s\n', test_codes{i}, test_names{i});
    fprintf('════════════════════════════════════════\n');
    
    % 获取所有维修建议
    maintenance_advice = get_maintenance_advice(test_codes{i}, fault_mapping, maintenance_db);
    
    % 格式化并显示
    if ~isempty(maintenance_advice.all_suggestions)
        advice_text = format_maintenance_advice(maintenance_advice);
        fprintf('%s', advice_text);
    else
        fprintf('未找到对应的维修建议\n');
    end
end

% ========== 辅助函数 ==========

% 获取维修建议函数（增强版）
function maintenance_advice = get_maintenance_advice(fault_code, fault_mapping, maintenance_db)
    maintenance_advice = struct();
    maintenance_advice.all_suggestions = {};
    
    if ~isKey(fault_mapping, fault_code)
        return;
    end
    
    possible_codes = fault_mapping(fault_code);
    
    for i = 1:length(possible_codes)
        maint_code = possible_codes{i};
        field_name = ['code_' strrep(maint_code, '-', '_')];
        
        if isfield(maintenance_db, field_name)
            maint_info = maintenance_db.(field_name);
            
            single_advice = struct();
            single_advice.fault_code = maint_code;
            single_advice.fault_name = maint_info.fault_name;
            single_advice.measures = maint_info.maintenance_measures;
            single_advice.severity = maint_info.severity;
            single_advice.priority = maint_info.priority;
            single_advice.description = maint_info.description;
            
            maintenance_advice.all_suggestions{end+1} = single_advice;
        end
    end
    
    if ~isempty(maintenance_advice.all_suggestions)
        priorities = cellfun(@(x) x.priority, maintenance_advice.all_suggestions);
        [~, idx] = sort(priorities);
        maintenance_advice.all_suggestions = maintenance_advice.all_suggestions(idx);
    end
end

% 格式化维修建议文本（增强版）
function advice_text = format_maintenance_advice(maintenance_advice)
    if ~isfield(maintenance_advice, 'all_suggestions') || isempty(maintenance_advice.all_suggestions)
        advice_text = '';
        return;
    end
    
    advice_text = sprintf('\n【维修建议汇总】共有 %d 种可能的故障原因\n', length(maintenance_advice.all_suggestions));
    advice_text = [advice_text sprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n')];
    
    for j = 1:length(maintenance_advice.all_suggestions)
        suggestion = maintenance_advice.all_suggestions{j};
        
        advice_text = [advice_text sprintf('\n【故障%d】故障代码: %s - %s\n', ...
                                         j, suggestion.fault_code, suggestion.fault_name)];
        advice_text = [advice_text sprintf('故障描述: %s\n', suggestion.description)];
        advice_text = [advice_text sprintf('严重程度: %s | 优先级: %d\n', ...
                                         suggestion.severity, suggestion.priority)];
        advice_text = [advice_text sprintf('维修措施:\n')];
        
        if iscell(suggestion.measures)
            num_measures = length(suggestion.measures);
        elseif isstruct(suggestion.measures)
            num_measures = length(suggestion.measures);
        else
            num_measures = 0;
        end
        
        for i = 1:num_measures
            if iscell(suggestion.measures)
                measure = suggestion.measures{i};
            elseif isstruct(suggestion.measures)
                measure = suggestion.measures(i);
            end
            
            advice_text = [advice_text sprintf('  步骤%d: %s\n', measure.step, measure.action)];
            advice_text = [advice_text sprintf('         耗时: %s | 工具: %s\n', ...
                                             measure.time, measure.tools)];
        end
        
        if j < length(maintenance_advice.all_suggestions)
            advice_text = [advice_text sprintf('────────────────────────────────────────\n')];
        end
    end
    
    advice_text = [advice_text sprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n')];
end

% 创建维修措施结构体
function measure = create_measure(step, action, time, tools)
    measure = struct();
    measure.step = step;
    measure.action = action;
    measure.time = time;
    measure.tools = tools;
end

% 初始化维修建议数据库（简化版，只包含部分）
function db = init_maintenance_database()
    db = struct();
    
    % 故障代码344
    db.code_344 = struct(...
        'fault_type', '数据保持型故障', ...
        'fault_code', '344', ...
        'fault_name', '超上限130%', ...
        'description', '超过量程130%', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', {
            create_measure(1, '检查工艺异常', '5分钟', '工艺参数表');
            create_measure(2, '检查空气泄漏', '15分钟', '检漏仪');
            create_measure(3, '检查传感器饱和', '20分钟', '测试仪');
            create_measure(4, '切换高量程', '30分钟', '配置软件');
            create_measure(5, '更换高量程传感器', '2小时', '备用传感器')
        });
    
    % 故障代码301
    db.code_301 = struct(...
        'fault_type', '数据保持型故障', ...
        'fault_code', '301', ...
        'fault_name', '超出ADC阈值', ...
        'description', '超出ADC范围', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', {
            create_measure(1, '确认实际浓度', '5分钟', '便携式分析仪');
            create_measure(2, '检查量程设置', '10分钟', '配置软件');
            create_measure(3, '调整信号衰减', '20分钟', '调节工具');
            create_measure(4, '重选测量量程', '30分钟', '配置软件');
            create_measure(5, '更换大量程传感器', '2小时', '备用传感器')
        });
    
    % 故障代码345
    db.code_345 = struct(...
        'fault_type', '数据保持型故障', ...
        'fault_code', '345', ...
        'fault_name', '低于下限-100%', ...
        'description', '低于量程-100%', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', {
            create_measure(1, '检查传感器接线', '10分钟', '接线图');
            create_measure(2, '检查信号电路', '20分钟', '万用表');
            create_measure(3, '验证零点设置', '30分钟', '零点气体');
            create_measure(4, '重新标定', '45分钟', '标准气体');
            create_measure(5, '更换传感器信号板', '2小时', '备件')
        });
    
    % 故障代码303
    db.code_303 = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '303', ...
        'fault_name', '零点漂移超出允许范围', ...
        'description', '偏差漂移超出允许范围（±1.5vol%O2）', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', {
            create_measure(1, '立即检查传感器状态灯', '5分钟', '无');
            create_measure(2, '检查供电电压24V DC', '10分钟', '万用表');
            create_measure(3, '紧急执行零点量程校准', '45分钟', '标准气体');
            create_measure(4, '检查传感器参比电极', '1.5小时', '专用检测仪');
            create_measure(5, '立即更换传感器', '2小时', '备用传感器')
        });
    
    % 故障代码302
    db.code_302 = struct(...
        'fault_type', '数据偏差型故障', ...
        'fault_code', '302', ...
        'fault_name', '零点漂移超过允许范围50%', ...
        'description', '偏差漂移超过了允许范围的一半（±0.75vol%O2）', ...
        'severity', '中等', ...
        'priority', 2, ...
        'maintenance_measures', {
            create_measure(1, '检查传感器表面污染', '10分钟', '清洁布、酒精');
            create_measure(2, '检查采样管路冷凝水', '15分钟', '排水工具');
            create_measure(3, '执行零点校准程序', '30分钟', '标准气体');
            create_measure(4, '检查传感器老化程度', '1小时', '测试设备');
            create_measure(5, '更换传感器模块', '2小时', '备用传感器')
        });
    
    % 其他故障代码...（这里只展示部分，实际代码中包含所有23种故障）
end