% 测试维修建议显示完整性

% 初始化数据库和映射
maintenance_db = init_maintenance_database();
fault_mapping = containers.Map();
fault_mapping('003') = {'101', '201-209', '300', '308', '318', '332-337', '338-339'};

% 测试故障003的维修建议
fprintf('测试故障003（数据缺失）的维修建议显示：\n');
fprintf('════════════════════════════════════════\n\n');

maintenance_advice = get_maintenance_advice('003', fault_mapping, maintenance_db);
advice_text = format_maintenance_advice(maintenance_advice);
fprintf('%s', advice_text);

% 辅助函数定义
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
        
        if num_measures > 5
            advice_text = [advice_text sprintf('  ... (共%d个步骤)\n', num_measures)];
        end
        
        if j < length(maintenance_advice.all_suggestions)
            advice_text = [advice_text sprintf('\n────────────────────────────────────────\n')];
        end
    end
    
    advice_text = [advice_text sprintf('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n')];
end

% 创建measure的简化函数
function measure = create_measure(step, action, time, tools)
    measure = struct();
    measure.step = step;
    measure.action = action;
    measure.time = time;
    measure.tools = tools;
end

% 初始化简化的维修数据库（只包含003相关的）
function db = init_maintenance_database()
    db = struct();
    
    % 故障代码101
    db.code_101 = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '101', ...
        'fault_name', '系统控制器关停', ...
        'description', '主控制器停止工作', ...
        'severity', '紧急', ...
        'priority', 1, ...
        'maintenance_measures', {
            create_measure(1, '检查主电源保险丝', '5分钟', '万用表');
            create_measure(2, '检查24V电源输出', '10分钟', '万用表');
            create_measure(3, '重启控制器系统', '15分钟', '无');
            create_measure(4, '检查CPU和内存', '30分钟', '诊断软件');
            create_measure(5, '更换控制器主板', '2小时', '备用主板')
        });
    
    % 故障代码201-209
    db.code_201_209 = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '201-209', ...
        'fault_name', '系统总线连接中断', ...
        'description', '系统总线通讯中断', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', {
            create_measure(1, '检查总线电缆', '10分钟', '无');
            create_measure(2, '检查终端电阻', '15分钟', '万用表');
            create_measure(3, '更换总线电缆', '30分钟', '备用电缆');
            create_measure(4, '检查模块供电', '20分钟', '万用表');
            create_measure(5, '更换通讯模块', '1小时', '备用模块')
        });
    
    % 故障代码300
    db.code_300 = struct(...
        'fault_type', '数据传输中断型故障', ...
        'fault_code', '300', ...
        'fault_name', '模数转换器无输出', ...
        'description', 'ADC无新测量值', ...
        'severity', '严重', ...
        'priority', 1, ...
        'maintenance_measures', {
            create_measure(1, '检查ADC供电', '10分钟', '万用表');
            create_measure(2, '检查模拟输入', '15分钟', '示波器');
            create_measure(3, '重置ADC芯片', '20分钟', '复位工具');
            create_measure(4, '更换ADC芯片', '1小时', '备用芯片');
            create_measure(5, '更换采集卡', '1.5小时', '备用采集卡')
        });
end