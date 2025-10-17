% main_magnos206.m - Magnos206氧分析仪数据采集系统主程序
% 
% 功能描述：
%   - 支持多种数据源：网络(TCP/IP)、Excel文件、数据库
%   - 实时数据采集和显示
%   - 数据存储和导出
%   - 图形化用户界面
%
% 使用方法：
%   直接运行此脚本即可启动系统

%% 清理环境
clear all;
close all;
clc;

%% 添加路径
addpath(genpath('src'));
addpath(genpath('config'));

%% 加载配置
fprintf('正在加载配置...\n');
config = loadConfig();

%% 创建GUI显示
fprintf('正在创建显示界面...\n');
gui = RealTimeDataDisplay();

%% 创建数据采集器
fprintf('正在初始化数据采集器...\n');

% 1. 网络数据采集器
if config.collectors.network.enabled
    try
        networkCollector = NetworkDataCollector(...
            config.collectors.network.ipAddress, ...
            config.collectors.network.port);
        gui.addCollector(networkCollector, 'Magnos206网络接口');
        fprintf('✓ 网络数据采集器已添加\n');
    catch ME
        fprintf('✗ 网络数据采集器创建失败: %s\n', ME.message);
    end
end

% 2. Excel数据采集器
if config.collectors.excel.enabled && ~isempty(config.collectors.excel.defaultFile)
    try
        % 检查示例文件是否存在
        excelFile = config.collectors.excel.defaultFile;
        if ~exist(excelFile, 'file')
            % 创建示例Excel文件
            createSampleExcelFile(excelFile);
        end
        
        excelCollector = ExcelDataCollector(excelFile);
        gui.addCollector(excelCollector, 'Excel历史数据');
        fprintf('✓ Excel数据采集器已添加\n');
    catch ME
        fprintf('✗ Excel数据采集器创建失败: %s\n', ME.message);
    end
end

% 3. 数据库采集器
if config.collectors.database.enabled
    try
        dbCollector = DatabaseDataCollector(...
            config.collectors.database.type, ...
            config.collectors.database.connectionInfo);
        gui.addCollector(dbCollector, '数据库');
        fprintf('✓ 数据库采集器已添加\n');
    catch ME
        fprintf('✗ 数据库采集器创建失败: %s\n', ME.message);
    end
end

%% 显示启动信息
fprintf('\n');
fprintf('========================================\n');
fprintf('Magnos206 氧分析仪数据采集系统\n');
fprintf('========================================\n');
fprintf('系统已启动！\n\n');
fprintf('使用说明：\n');
fprintf('1. 从下拉菜单选择数据源\n');
fprintf('2. 点击"连接"按钮连接数据源\n');
fprintf('3. 点击"开始"按钮开始采集数据\n');
fprintf('4. 点击"导出"按钮保存数据\n');
fprintf('\n');

%% 辅助函数
function config = loadConfig()
    % 加载配置文件
    configFile = 'config/system_config.json';
    
    % 检查配置文件是否存在
    if exist(configFile, 'file')
        % 读取JSON配置文件
        fid = fopen(configFile, 'r');
        raw = fread(fid, inf);
        str = char(raw');
        fclose(fid);
        config = jsondecode(str);
    else
        % 使用默认配置
        config = getDefaultConfig();
        
        % 保存默认配置
        saveConfig(config, configFile);
    end
end

function config = getDefaultConfig()
    % 获取默认配置
    config = struct();
    
    % 系统配置
    config.system.updateInterval = 1.0;  % 更新间隔（秒）
    config.system.displayPoints = 100;   % 显示点数
    config.system.bufferSize = 1000;     % 缓冲区大小
    
    % 网络采集器配置
    config.collectors.network.enabled = true;
    config.collectors.network.ipAddress = '192.168.1.100';
    config.collectors.network.port = 5025;
    config.collectors.network.timeout = 5;
    
    % Excel采集器配置
    config.collectors.excel.enabled = true;
    config.collectors.excel.defaultFile = 'data/excel/sample_oxygen_data.xlsx';
    
    % 数据库采集器配置
    config.collectors.database.enabled = false;
    config.collectors.database.type = 'sqlite';
    config.collectors.database.connectionInfo.filename = 'data/oxygen_data.db';
end

function saveConfig(config, filename)
    % 保存配置到JSON文件
    
    % 确保目录存在
    [path, ~, ~] = fileparts(filename);
    if ~exist(path, 'dir')
        mkdir(path);
    end
    
    % 写入JSON文件
    jsonStr = jsonencode(config, 'PrettyPrint', true);
    fid = fopen(filename, 'w');
    fprintf(fid, '%s', jsonStr);
    fclose(fid);
end

function createSampleExcelFile(filename)
    % 创建示例Excel文件
    
    fprintf('正在创建示例Excel文件...\n');
    
    % 确保目录存在
    [path, ~, ~] = fileparts(filename);
    if ~exist(path, 'dir')
        mkdir(path);
    end
    
    % 生成示例数据
    n = 100;
    timestamps = datetime('now') - minutes(n-1:-1:0)';
    values = 20.9 + 0.5 * randn(n, 1);  % 正常氧浓度约20.9%
    units = repmat({'%'}, n, 1);
    qualities = repmat({'Good'}, n, 1);
    sources = repmat({'Magnos206'}, n, 1);
    
    % 创建表格
    T = table(timestamps, values, units, qualities, sources, ...
        'VariableNames', {'Timestamp', 'Value', 'Unit', 'Quality', 'Source'});
    
    % 写入Excel文件
    writetable(T, filename);
    
    fprintf('示例文件已创建: %s\n', filename);
end