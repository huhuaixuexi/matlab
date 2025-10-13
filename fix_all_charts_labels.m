%% 完整修复所有图表标签的脚本
% 这个脚本包含了所有需要修复的图表标签代码片段

% 注意：这是一个参考文件，不是可执行文件
% 包含了所有图表的完整标签设置

%% 第1页：基础统计和分布

% 1. 故障类型分布饼图
title('故障类型分布饼图', 'FontSize', 14, 'FontWeight', 'bold');
% 饼图不需要坐标轴标签

% 2. 月度故障趋势图
title('月度故障趋势图', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('时间（年-月）', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('故障数量（次）', 'FontSize', 12, 'FontWeight', 'bold');

% 3. 严重程度分布条形图
title('故障严重程度分布条形图', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('严重程度等级', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('故障数量（次）', 'FontSize', 12, 'FontWeight', 'bold');

% 4. TOP10故障代码
title('TOP 10 故障代码横向条形图', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('故障发生次数', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('故障代码', 'FontSize', 12, 'FontWeight', 'bold');

% 5. 数据故障类型分布
title('数据故障类型分布饼图', 'FontSize', 14, 'FontWeight', 'bold');
% 饼图不需要坐标轴标签

% 6. 年度故障统计
title('年度故障统计条形图', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('年份', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('故障数量（次）', 'FontSize', 12, 'FontWeight', 'bold');

%% 第2页：维修效率和模式分析

% 1. 维修时间分布（各故障类型）
title('各故障类型平均维修时间条形图', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('故障类型', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('维修时间（分钟）', 'FontSize', 12, 'FontWeight', 'bold');

% 2. 工具使用频率TOP10
title('TOP 10 常用工具横向条形图', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('使用次数', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('工具名称', 'FontSize', 12, 'FontWeight', 'bold');

% 3. 季度故障分布
title('季度故障分布条形图', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('季度', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('故障数量（次）', 'FontSize', 12, 'FontWeight', 'bold');

% 4. 优先级分布
title('故障优先级分布饼图', 'FontSize', 14, 'FontWeight', 'bold');
% 饼图不需要坐标轴标签

% 5. 工作日vs周末分布
title('工作日vs周末故障分布饼图', 'FontSize', 14, 'FontWeight', 'bold');
% 饼图不需要坐标轴标签

% 6. 故障时间热力图
title('故障发生时间分布热力图', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('小时（0-23点）', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('星期', 'FontSize', 12, 'FontWeight', 'bold');

%% 第3页：关联分析和预测

% 1. 严重程度与维修时间关系
title('严重程度与平均维修时间条形图', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('严重程度', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('平均维修时间（分钟）', 'FontSize', 12, 'FontWeight', 'bold');

% 2. 最复杂故障TOP5
title('最复杂故障TOP5横向条形图', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('平均维修时间（分钟）', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('故障代码', 'FontSize', 12, 'FontWeight', 'bold');

% 3. 故障趋势预测
title('故障趋势与预测折线图', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('时间（年-月）', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('故障数量（次）', 'FontSize', 12, 'FontWeight', 'bold');

% 4. 备件需求分析
title('备件更换统计条形图', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('备件类型', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('更换次数', 'FontSize', 12, 'FontWeight', 'bold');

% 5-6. 维修操作效率TOP10
title('TOP 10 最快维修操作横向条形图', 'FontSize', 14, 'FontWeight', 'bold');
xlabel('平均维修时间（分钟）', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('维修操作（含次数）', 'FontSize', 12, 'FontWeight', 'bold');