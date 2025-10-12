% 测试维修建议格式化功能

% 创建维修措施结构体的函数
function measure = create_measure(step, action, time, tools)
    measure = struct();
    measure.step = step;
    measure.action = action;
    measure.time = time;
    measure.tools = tools;
end

% 测试数据
test_maintenance = struct();
test_maintenance.fault_code = '302';
test_maintenance.fault_name = '零点漂移超过允许范围50%';
test_maintenance.severity = '中等';
test_maintenance.priority = 2;

% 创建措施（这会创建一个结构体数组，而不是元胞数组）
measures = [
    create_measure(1, '检查传感器表面污染', '10分钟', '清洁布、酒精');
    create_measure(2, '检查采样管路冷凝水', '15分钟', '排水工具');
    create_measure(3, '执行零点校准程序', '30分钟', '标准气体')
];

test_maintenance.measures = measures;

% 测试访问
fprintf('测试结构体数组访问:\n');
fprintf('measures类型: %s\n', class(test_maintenance.measures));
fprintf('是否为cell: %d\n', iscell(test_maintenance.measures));
fprintf('是否为struct: %d\n', isstruct(test_maintenance.measures));
fprintf('长度: %d\n', length(test_maintenance.measures));

% 测试不同的访问方式
fprintf('\n测试访问第一个元素:\n');
try
    % 尝试用花括号访问（会报错）
    measure1 = test_maintenance.measures{1};
    fprintf('花括号访问成功\n');
catch ME
    fprintf('花括号访问失败: %s\n', ME.message);
end

try
    % 用圆括号访问（正确方式）
    measure1 = test_maintenance.measures(1);
    fprintf('圆括号访问成功: %s\n', measure1.action);
catch ME
    fprintf('圆括号访问失败: %s\n', ME.message);
end

% 格式化维修建议文本的简化版本
function advice_text = format_maintenance_advice_test(maintenance_advice)
    advice_text = sprintf('\n【维修建议】故障代码: %s - %s\n', ...
                         maintenance_advice.fault_code, ...
                         maintenance_advice.fault_name);
    advice_text = [advice_text sprintf('维修措施:\n')];
    
    % 获取measures的数量
    if iscell(maintenance_advice.measures)
        num_measures = length(maintenance_advice.measures);
    elseif isstruct(maintenance_advice.measures)
        num_measures = length(maintenance_advice.measures);
    else
        num_measures = 0;
    end
    
    % 遍历所有措施
    for i = 1:num_measures
        if iscell(maintenance_advice.measures)
            % 如果是元胞数组
            measure = maintenance_advice.measures{i};
        elseif isstruct(maintenance_advice.measures)
            % 如果是结构体数组
            measure = maintenance_advice.measures(i);
        end
        
        % 格式化输出
        advice_text = [advice_text sprintf('  %d. %s (耗时: %s, 工具: %s)\n', ...
                                          measure.step, measure.action, ...
                                          measure.time, measure.tools)];
    end
end

% 测试格式化函数
fprintf('\n测试格式化函数:\n');
result = format_maintenance_advice_test(test_maintenance);
fprintf('%s', result);