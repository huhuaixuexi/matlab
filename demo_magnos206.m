% demo_magnos206.m - Magnos206氧分析仪数据采集系统演示
% 
% 此脚本演示如何使用数据模拟器快速测试系统功能

%% 清理环境
clear all;
close all;
clc;

%% 添加路径
addpath(genpath('src'));

fprintf('====================================\n');
fprintf('Magnos206 数据采集系统演示\n');
fprintf('====================================\n\n');

%% 创建数据模拟器
fprintf('1. 创建数据模拟器...\n');
simulator = DataSimulator(...
    'baseValue', 20.9, ...      % 正常大气氧浓度
    'noiseLevel', 0.1, ...      % 0.1%的噪声
    'driftRate', 0.001, ...     % 缓慢漂移
    'anomalyProb', 0.02);       % 2%的异常概率

%% 创建显示界面
fprintf('2. 创建实时显示界面...\n');
gui = RealTimeDataDisplay();

% 添加模拟器到GUI
gui.addCollector(simulator, '模拟数据');

%% 显示使用说明
fprintf('\n');
fprintf('演示步骤：\n');
fprintf('------------------\n');
fprintf('1. 在界面中选择"模拟数据"作为数据源\n');
fprintf('2. 点击"连接"按钮\n');
fprintf('3. 点击"开始"按钮开始采集\n');
fprintf('4. 观察实时数据变化\n');
fprintf('5. 可以点击"导出"保存数据\n');
fprintf('\n');
fprintf('提示：数据会有轻微波动和偶尔的异常值，这是正常的模拟行为\n');
fprintf('\n');

%% 可选：编程方式测试
answer = input('是否运行自动测试？(y/n): ', 's');

if strcmpi(answer, 'y')
    fprintf('\n开始自动测试...\n');
    
    % 连接模拟器
    simulator.connect();
    
    % 创建数据缓冲区
    buffer = DataBuffer(100);
    
    % 采集数据10秒
    fprintf('采集数据中');
    for i = 1:10
        data = simulator.readData();
        if ~isempty(data)
            buffer.addData(data);
            fprintf('.');
        end
        pause(1);
    end
    fprintf(' 完成！\n');
    
    % 显示统计信息
    [timestamps, values] = buffer.getTimeSeries();
    fprintf('\n数据统计：\n');
    fprintf('- 采集点数: %d\n', length(values));
    fprintf('- 平均值: %.2f%%\n', mean(values));
    fprintf('- 标准差: %.3f%%\n', std(values));
    fprintf('- 最小值: %.2f%%\n', min(values));
    fprintf('- 最大值: %.2f%%\n', max(values));
    
    % 绘制简单图表
    figure('Name', '测试数据');
    plot(timestamps, values, 'b-o');
    xlabel('时间');
    ylabel('氧浓度 (%)');
    title('模拟数据测试结果');
    grid on;
    
    % 断开连接
    simulator.disconnect();
    
    fprintf('\n自动测试完成！\n');
end

fprintf('\nGUI界面保持打开，您可以继续手动测试。\n');