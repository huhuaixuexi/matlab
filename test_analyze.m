%% 测试分析程序
% 用于调试表格读取问题

% 查找最新的Excel文件
excel_files = dir('故障诊断维修记录_*.xlsx');
if isempty(excel_files)
    error('未找到故障记录Excel文件！');
end

[~, idx] = max([excel_files.datenum]);
excel_file = excel_files(idx).name;

fprintf('测试文件: %s\n', excel_file);

% 方法1：使用默认设置读取
fprintf('\n方法1：默认读取\n');
try
    T1 = readtable(excel_file);
    fprintf('成功！列名如下:\n');
    disp(T1.Properties.VariableNames);
catch ME
    fprintf('失败: %s\n', ME.message);
end

% 方法2：保留原始变量名
fprintf('\n方法2：保留原始变量名\n');
try
    T2 = readtable(excel_file, 'VariableNamingRule', 'preserve');
    fprintf('成功！列名如下:\n');
    disp(T2.Properties.VariableNames);
catch ME
    fprintf('失败: %s\n', ME.message);
end

% 方法3：指定Sheet名称
fprintf('\n方法3：指定Sheet\n');
try
    T3 = readtable(excel_file, 'Sheet', '故障维修记录');
    fprintf('成功！列名如下:\n');
    disp(T3.Properties.VariableNames);
catch ME
    fprintf('失败: %s\n', ME.message);
end

% 显示前几行数据
fprintf('\n数据预览:\n');
if exist('T1', 'var')
    disp(T1(1:3, :));
elseif exist('T2', 'var')
    disp(T2(1:3, :));
elseif exist('T3', 'var')
    disp(T3(1:3, :));
end