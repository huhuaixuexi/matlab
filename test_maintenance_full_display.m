% 测试维修建议完整显示

% 创建测试数据
maintenance_advice = struct();
maintenance_advice.all_suggestions = {};

% 添加多个测试建议
for k = 1:3
    suggestion = struct();
    suggestion.fault_code = sprintf('30%d', k);
    suggestion.fault_name = sprintf('测试故障%d', k);
    suggestion.description = sprintf('这是第%d个测试故障', k);
    suggestion.severity = '严重';
    suggestion.priority = k;
    
    % 创建5个维修步骤
    measures = [];
    for m = 1:5
        measure = struct();
        measure.step = m;
        measure.action = sprintf('故障%d的步骤%d操作', k, m);
        measure.time = sprintf('%d分钟', m*10);
        measure.tools = sprintf('工具%d', m);
        measures = [measures, measure];
    end
    suggestion.measures = measures;
    
    maintenance_advice.all_suggestions{end+1} = suggestion;
end

% 测试格式化函数
fprintf('开始测试维修建议显示...\n\n');

% 测试原始的格式化函数
advice_text = format_maintenance_advice_test(maintenance_advice);
fprintf('格式化后的文本长度: %d 字符\n', length(advice_text));
fprintf('包含的换行符数量: %d\n\n', sum(advice_text == char(10)));
fprintf('完整输出:\n');
fprintf('%s', advice_text);

% 格式化函数
function advice_text = format_maintenance_advice_test(maintenance_advice)
    if ~isfield(maintenance_advice, 'all_suggestions') || isempty(maintenance_advice.all_suggestions)
        advice_text = '';
        return;
    end
    
    advice_text = sprintf('\n【维修建议汇总】共有 %d 种可能的故障原因\n', length(maintenance_advice.all_suggestions));
    advice_text = [advice_text sprintf('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n')];
    
    fprintf('调试：开始遍历 %d 个建议\n', length(maintenance_advice.all_suggestions));
    
    % 遍历所有可能的维修建议
    for j = 1:length(maintenance_advice.all_suggestions)
        suggestion = maintenance_advice.all_suggestions{j};
        
        fprintf('调试：处理第 %d 个建议\n', j);
        
        advice_text = [advice_text sprintf('\n【故障%d】故障代码: %s - %s\n', ...
                                         j, suggestion.fault_code, suggestion.fault_name)];
        advice_text = [advice_text sprintf('故障描述: %s\n', suggestion.description)];
        advice_text = [advice_text sprintf('严重程度: %s | 优先级: %d\n', ...
                                         suggestion.severity, suggestion.priority)];
        advice_text = [advice_text sprintf('维修措施:\n')];
        
        % 处理measures
        if isstruct(suggestion.measures)
            fprintf('调试：measures是结构体数组，长度=%d\n', length(suggestion.measures));
            for i = 1:length(suggestion.measures)
                measure = suggestion.measures(i);
                advice_text = [advice_text sprintf('  步骤%d: %s\n', measure.step, measure.action)];
                advice_text = [advice_text sprintf('         耗时: %s | 工具: %s\n', ...
                                                 measure.time, measure.tools)];
            end
        elseif iscell(suggestion.measures)
            fprintf('调试：measures是元胞数组，长度=%d\n', length(suggestion.measures));
            for i = 1:length(suggestion.measures)
                measure = suggestion.measures{i};
                advice_text = [advice_text sprintf('  步骤%d: %s\n', measure.step, measure.action)];
                advice_text = [advice_text sprintf('         耗时: %s | 工具: %s\n', ...
                                                 measure.time, measure.tools)];
            end
        else
            fprintf('调试：measures类型未知\n');
        end
        
        if j < length(maintenance_advice.all_suggestions)
            advice_text = [advice_text sprintf('\n────────────────────────────────────────\n')];
        end
    end
    
    advice_text = [advice_text sprintf('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n')];
    
    fprintf('调试：格式化完成\n\n');
end