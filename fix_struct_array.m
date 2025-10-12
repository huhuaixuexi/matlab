% 测试和修复结构体数组创建问题

% 方法1：使用struct数组（推荐）
function test_method1()
    fprintf('方法1：使用struct数组\n');
    
    % 先定义空的结构体数组，指定所有字段
    measures = struct('step', {}, 'action', {}, 'time', {}, 'tools', {});
    
    % 然后添加元素
    measures(1) = struct('step', 1, 'action', '检查传感器', 'time', '10分钟', 'tools', '万用表');
    measures(2) = struct('step', 2, 'action', '清洁传感器', 'time', '20分钟', 'tools', '清洁布');
    measures(3) = struct('step', 3, 'action', '校准传感器', 'time', '30分钟', 'tools', '标准气体');
    
    fprintf('创建成功！数量: %d\n', length(measures));
    for i = 1:length(measures)
        fprintf('  步骤%d: %s\n', measures(i).step, measures(i).action);
    end
end

% 方法2：使用元胞数组
function test_method2()
    fprintf('\n方法2：使用元胞数组\n');
    
    measures = cell(3, 1);
    measures{1} = create_measure(1, '检查传感器', '10分钟', '万用表');
    measures{2} = create_measure(2, '清洁传感器', '20分钟', '清洁布');
    measures{3} = create_measure(3, '校准传感器', '30分钟', '标准气体');
    
    fprintf('创建成功！数量: %d\n', length(measures));
    for i = 1:length(measures)
        fprintf('  步骤%d: %s\n', measures{i}.step, measures{i}.action);
    end
end

% 方法3：直接创建完整数组（最简单）
function test_method3()
    fprintf('\n方法3：直接创建完整数组\n');
    
    measures = [
        create_measure(1, '检查传感器', '10分钟', '万用表')
        create_measure(2, '清洁传感器', '20分钟', '清洁布')
        create_measure(3, '校准传感器', '30分钟', '标准气体')
    ];
    
    fprintf('创建成功！数量: %d\n', length(measures));
    for i = 1:length(measures)
        fprintf('  步骤%d: %s\n', measures(i).step, measures(i).action);
    end
end

function measure = create_measure(step, action, time, tools)
    measure = struct();
    measure.step = step;
    measure.action = action;
    measure.time = time;
    measure.tools = tools;
end

% 运行测试
test_method1();
test_method2();
test_method3();