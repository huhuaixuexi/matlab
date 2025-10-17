classdef RealTimeDataDisplay < handle
    % RealTimeDataDisplay - 实时数据显示GUI
    % 用于显示氧分析仪的实时数据
    
    properties (Access = private)
        % GUI组件
        figure          % 主窗口
        plotAxes        % 绘图坐标轴
        currentValueText % 当前值显示
        statusText      % 状态显示
        dataTable       % 数据表格
        
        % 控制按钮
        startButton
        stopButton
        clearButton
        exportButton
        
        % 数据采集器下拉菜单
        collectorDropdown
        connectButton
        
        % 定时器
        updateTimer
        
        % 数据
        dataBuffer      % 数据缓冲区
        dataCollector   % 当前数据采集器
        collectors      % 可用的数据采集器
        
        % 绘图句柄
        plotLine
        
        % 配置
        updateInterval  % 更新间隔（秒）
        displayPoints   % 显示的数据点数
    end
    
    methods
        function obj = RealTimeDataDisplay()
            % 构造函数
            
            % 初始化属性
            obj.updateInterval = 1.0;  % 1秒更新一次
            obj.displayPoints = 100;   % 显示最近100个点
            obj.dataBuffer = DataBuffer(1000);
            obj.collectors = {};
            
            % 创建GUI
            obj.createGUI();
            
            % 创建定时器
            obj.updateTimer = timer(...
                'ExecutionMode', 'fixedRate', ...
                'Period', obj.updateInterval, ...
                'TimerFcn', @(~,~)obj.updateDisplay(), ...
                'ErrorFcn', @(~,~)obj.handleTimerError());
        end
        
        function delete(obj)
            % 析构函数
            
            % 停止定时器
            if ~isempty(obj.updateTimer) && isvalid(obj.updateTimer)
                stop(obj.updateTimer);
                delete(obj.updateTimer);
            end
            
            % 断开数据采集器
            if ~isempty(obj.dataCollector)
                obj.dataCollector.disconnect();
            end
            
            % 关闭窗口
            if ~isempty(obj.figure) && isvalid(obj.figure)
                close(obj.figure);
            end
        end
        
        function addCollector(obj, collector, name)
            % 添加数据采集器
            % 输入:
            %   collector - 数据采集器对象
            %   name - 显示名称
            
            obj.collectors{end+1} = struct('collector', collector, 'name', name);
            
            % 更新下拉菜单
            if ~isempty(obj.collectorDropdown)
                names = cellfun(@(x)x.name, obj.collectors, 'UniformOutput', false);
                obj.collectorDropdown.String = names;
            end
        end
        
        function start(obj)
            % 开始数据采集
            
            if isempty(obj.dataCollector) || ~obj.dataCollector.isConnected
                obj.showStatus('错误: 请先连接数据源', 'red');
                return;
            end
            
            % 启动定时器
            if strcmp(obj.updateTimer.Running, 'off')
                start(obj.updateTimer);
                obj.showStatus('数据采集已开始', 'green');
                
                % 更新按钮状态
                obj.startButton.Enable = 'off';
                obj.stopButton.Enable = 'on';
            end
        end
        
        function stop(obj)
            % 停止数据采集
            
            % 停止定时器
            if strcmp(obj.updateTimer.Running, 'on')
                stop(obj.updateTimer);
                obj.showStatus('数据采集已停止', 'blue');
                
                % 更新按钮状态
                obj.startButton.Enable = 'on';
                obj.stopButton.Enable = 'off';
            end
        end
        
        function clear(obj)
            % 清空数据
            
            obj.dataBuffer.clear();
            
            % 清空图形
            if ~isempty(obj.plotLine) && isvalid(obj.plotLine)
                obj.plotLine.XData = [];
                obj.plotLine.YData = [];
            end
            
            % 清空表格
            obj.dataTable.Data = {};
            
            % 清空当前值
            obj.currentValueText.String = '-- %';
            
            obj.showStatus('数据已清空', 'blue');
        end
        
        function export(obj)
            % 导出数据
            
            % 获取所有数据
            data = obj.dataBuffer.getData();
            
            if isempty(data)
                obj.showStatus('没有数据可导出', 'red');
                return;
            end
            
            % 选择保存文件
            [filename, pathname] = uiputfile({
                '*.xlsx', 'Excel文件 (*.xlsx)';
                '*.csv', 'CSV文件 (*.csv)';
                '*.mat', 'MAT文件 (*.mat)'}, ...
                '保存数据', 'oxygen_data');
            
            if isequal(filename, 0)
                return;
            end
            
            fullpath = fullfile(pathname, filename);
            [~, ~, ext] = fileparts(filename);
            
            try
                % 准备数据
                n = length(data);
                timestamps = NaT(n, 1);
                values = nan(n, 1);
                units = cell(n, 1);
                qualities = cell(n, 1);
                sources = cell(n, 1);
                
                for i = 1:n
                    if ~isempty(data{i})
                        timestamps(i) = data{i}.timestamp;
                        values(i) = data{i}.value;
                        units{i} = data{i}.unit;
                        qualities{i} = data{i}.quality;
                        sources{i} = data{i}.source;
                    end
                end
                
                % 创建表格
                dataTable = table(timestamps, values, units, qualities, sources, ...
                    'VariableNames', {'Timestamp', 'Value', 'Unit', 'Quality', 'Source'});
                
                % 根据文件类型保存
                switch lower(ext)
                    case '.xlsx'
                        writetable(dataTable, fullpath);
                    case '.csv'
                        writetable(dataTable, fullpath);
                    case '.mat'
                        save(fullpath, 'data', 'dataTable');
                end
                
                obj.showStatus(sprintf('数据已导出到: %s', filename), 'green');
                
            catch ME
                obj.showStatus(sprintf('导出失败: %s', ME.message), 'red');
            end
        end
    end
    
    methods (Access = private)
        function createGUI(obj)
            % 创建GUI界面
            
            % 创建主窗口
            obj.figure = figure(...
                'Name', 'Magnos206 氧分析仪实时数据显示', ...
                'NumberTitle', 'off', ...
                'Position', [100, 100, 1000, 700], ...
                'CloseRequestFcn', @(~,~)delete(obj));
            
            % 创建布局
            mainLayout = uiextras.VBox('Parent', obj.figure, 'Padding', 5);
            
            % 顶部控制面板
            controlPanel = uiextras.HBox('Parent', mainLayout, 'Spacing', 5);
            
            % 数据源选择
            sourcePanel = uiextras.HBox('Parent', controlPanel, 'Spacing', 5);
            uicontrol('Parent', sourcePanel, 'Style', 'text', 'String', '数据源:', ...
                'HorizontalAlignment', 'right');
            obj.collectorDropdown = uicontrol('Parent', sourcePanel, 'Style', 'popupmenu', ...
                'String', {'请选择数据源'});
            obj.connectButton = uicontrol('Parent', sourcePanel, 'Style', 'pushbutton', ...
                'String', '连接', 'Callback', @(~,~)obj.connectCollector());
            sourcePanel.Sizes = [60, -1, 80];
            
            % 控制按钮
            buttonPanel = uiextras.HBox('Parent', controlPanel, 'Spacing', 5);
            obj.startButton = uicontrol('Parent', buttonPanel, 'Style', 'pushbutton', ...
                'String', '开始', 'Callback', @(~,~)obj.start(), ...
                'BackgroundColor', [0.2, 0.8, 0.2]);
            obj.stopButton = uicontrol('Parent', buttonPanel, 'Style', 'pushbutton', ...
                'String', '停止', 'Callback', @(~,~)obj.stop(), ...
                'BackgroundColor', [0.8, 0.2, 0.2], 'Enable', 'off');
            obj.clearButton = uicontrol('Parent', buttonPanel, 'Style', 'pushbutton', ...
                'String', '清空', 'Callback', @(~,~)obj.clear());
            obj.exportButton = uicontrol('Parent', buttonPanel, 'Style', 'pushbutton', ...
                'String', '导出', 'Callback', @(~,~)obj.export());
            
            controlPanel.Sizes = [-1, 350];
            
            % 中间显示区域
            displayPanel = uiextras.HBox('Parent', mainLayout, 'Spacing', 5);
            
            % 左侧：实时曲线
            plotPanel = uiextras.VBox('Parent', displayPanel, 'Spacing', 5);
            obj.plotAxes = axes('Parent', plotPanel);
            obj.setupPlot();
            
            % 右侧：当前值和数据表
            rightPanel = uiextras.VBox('Parent', displayPanel, 'Spacing', 5);
            
            % 当前值显示
            currentPanel = uiextras.VBox('Parent', rightPanel, 'Padding', 10);
            uicontrol('Parent', currentPanel, 'Style', 'text', ...
                'String', '当前氧浓度', 'FontSize', 12, 'FontWeight', 'bold');
            obj.currentValueText = uicontrol('Parent', currentPanel, 'Style', 'text', ...
                'String', '-- %', 'FontSize', 24, 'FontWeight', 'bold', ...
                'ForegroundColor', [0, 0, 0.8]);
            currentPanel.Sizes = [30, -1];
            
            % 数据表格
            tablePanel = uiextras.VBox('Parent', rightPanel, 'Padding', 5);
            uicontrol('Parent', tablePanel, 'Style', 'text', ...
                'String', '最近数据', 'FontSize', 10, 'FontWeight', 'bold');
            obj.dataTable = uitable('Parent', tablePanel, ...
                'ColumnName', {'时间', '数值(%)', '质量'}, ...
                'ColumnWidth', {150, 80, 60}, ...
                'RowName', []);
            tablePanel.Sizes = [25, -1];
            
            rightPanel.Sizes = [150, -1];
            displayPanel.Sizes = [-2, -1];
            
            % 底部状态栏
            statusPanel = uiextras.HBox('Parent', mainLayout, 'Padding', 5);
            obj.statusText = uicontrol('Parent', statusPanel, 'Style', 'text', ...
                'String', '就绪', 'HorizontalAlignment', 'left');
            
            % 设置布局大小
            mainLayout.Sizes = [40, -1, 25];
        end
        
        function setupPlot(obj)
            % 设置绘图
            
            % 创建绘图线
            obj.plotLine = plot(obj.plotAxes, NaN, NaN, 'b-', 'LineWidth', 2);
            
            % 设置坐标轴
            xlabel(obj.plotAxes, '时间');
            ylabel(obj.plotAxes, '氧浓度 (%)');
            title(obj.plotAxes, '实时氧浓度曲线');
            grid(obj.plotAxes, 'on');
            
            % 设置Y轴范围
            ylim(obj.plotAxes, [0, 25]);
            
            % 启用缩放和平移
            zoom(obj.plotAxes, 'on');
            pan(obj.plotAxes, 'on');
        end
        
        function connectCollector(obj)
            % 连接选中的数据采集器
            
            idx = obj.collectorDropdown.Value;
            
            if idx <= 0 || idx > length(obj.collectors)
                obj.showStatus('请选择有效的数据源', 'red');
                return;
            end
            
            % 断开当前连接
            if ~isempty(obj.dataCollector)
                obj.dataCollector.disconnect();
            end
            
            % 获取新的采集器
            obj.dataCollector = obj.collectors{idx}.collector;
            
            % 连接
            try
                success = obj.dataCollector.connect();
                
                if success
                    obj.showStatus(sprintf('已连接到: %s', obj.collectors{idx}.name), 'green');
                    obj.connectButton.String = '断开';
                    obj.connectButton.Callback = @(~,~)obj.disconnectCollector();
                else
                    obj.showStatus('连接失败', 'red');
                end
            catch ME
                obj.showStatus(sprintf('连接错误: %s', ME.message), 'red');
            end
        end
        
        function disconnectCollector(obj)
            % 断开数据采集器
            
            if ~isempty(obj.dataCollector)
                obj.stop(); % 先停止采集
                obj.dataCollector.disconnect();
                obj.dataCollector = [];
                
                obj.showStatus('已断开连接', 'blue');
                obj.connectButton.String = '连接';
                obj.connectButton.Callback = @(~,~)obj.connectCollector();
            end
        end
        
        function updateDisplay(obj)
            % 更新显示（定时器回调）
            
            try
                % 读取新数据
                if ~isempty(obj.dataCollector) && obj.dataCollector.isConnected
                    dataPoint = obj.dataCollector.readData();
                    
                    if ~isempty(dataPoint)
                        % 添加到缓冲区
                        obj.dataBuffer.addData(dataPoint);
                        
                        % 更新当前值显示
                        obj.currentValueText.String = sprintf('%.2f %%', dataPoint.value);
                        
                        % 根据数值设置颜色
                        if dataPoint.value < 18
                            obj.currentValueText.ForegroundColor = [0.8, 0, 0]; % 红色
                        elseif dataPoint.value > 22
                            obj.currentValueText.ForegroundColor = [0.8, 0.4, 0]; % 橙色
                        else
                            obj.currentValueText.ForegroundColor = [0, 0.6, 0]; % 绿色
                        end
                        
                        % 更新图形
                        obj.updatePlot();
                        
                        % 更新表格
                        obj.updateTable();
                    end
                end
            catch ME
                % 错误处理
                obj.showStatus(sprintf('更新失败: %s', ME.message), 'red');
            end
        end
        
        function updatePlot(obj)
            % 更新曲线图
            
            % 获取时间序列数据
            [timestamps, values] = obj.dataBuffer.getTimeSeries(obj.displayPoints);
            
            if ~isempty(timestamps)
                % 更新曲线数据
                obj.plotLine.XData = timestamps;
                obj.plotLine.YData = values;
                
                % 自动调整X轴范围
                if length(timestamps) > 1
                    xlim(obj.plotAxes, [timestamps(1), timestamps(end)]);
                end
                
                % 更新坐标轴标签
                datetick(obj.plotAxes, 'x', 'HH:MM:SS', 'keeplimits');
            end
        end
        
        function updateTable(obj)
            % 更新数据表格
            
            % 获取最近10个数据点
            data = obj.dataBuffer.getData(10);
            
            tableData = {};
            for i = 1:length(data)
                if ~isempty(data{i})
                    tableData{i, 1} = datestr(data{i}.timestamp, 'HH:MM:SS');
                    tableData{i, 2} = sprintf('%.2f', data{i}.value);
                    tableData{i, 3} = data{i}.quality;
                end
            end
            
            obj.dataTable.Data = tableData;
        end
        
        function showStatus(obj, message, color)
            % 显示状态信息
            % 输入:
            %   message - 状态信息
            %   color - 颜色（'red', 'green', 'blue', 'black'）
            
            obj.statusText.String = sprintf('[%s] %s', datestr(now, 'HH:MM:SS'), message);
            
            switch color
                case 'red'
                    obj.statusText.ForegroundColor = [0.8, 0, 0];
                case 'green'
                    obj.statusText.ForegroundColor = [0, 0.6, 0];
                case 'blue'
                    obj.statusText.ForegroundColor = [0, 0, 0.8];
                otherwise
                    obj.statusText.ForegroundColor = [0, 0, 0];
            end
        end
        
        function handleTimerError(obj)
            % 处理定时器错误
            obj.showStatus('定时器错误，尝试重启...', 'red');
            
            % 尝试重启定时器
            try
                stop(obj.updateTimer);
                pause(0.5);
                start(obj.updateTimer);
            catch
                obj.showStatus('定时器重启失败', 'red');
            end
        end
    end
end