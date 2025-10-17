classdef ExcelDataCollector < IDataCollector
    % ExcelDataCollector - Excel数据采集器
    % 从Excel文件读取历史数据
    
    properties
        isConnected = false
        collectorName = 'Excel Data Collector'
        collectorType = 'File'
    end
    
    properties (Access = private)
        filename        % Excel文件名
        sheetName       % 工作表名称
        dataRange       % 数据范围
        currentRow      % 当前读取行
        totalRows       % 总行数
        columnMapping   % 列映射
        data            % 缓存的数据
        timestamps      % 时间戳列
        values          % 数值列
    end
    
    methods
        function obj = ExcelDataCollector(filename)
            % 构造函数
            % 输入:
            %   filename - Excel文件路径
            
            obj.filename = filename;
            obj.sheetName = '';
            obj.dataRange = '';
            obj.currentRow = 1;
            obj.totalRows = 0;
            
            % 默认列映射
            obj.columnMapping = struct(...
                'timestamp', 1, ...  % 时间戳在第1列
                'value', 2, ...      % 数值在第2列
                'unit', 3, ...       % 单位在第3列（可选）
                'quality', 4 ...     % 质量在第4列（可选）
            );
        end
        
        function success = connect(obj, varargin)
            % 连接到Excel文件
            % 输入:
            %   varargin - 可选参数（sheetName, dataRange等）
            % 输出:
            %   success - 是否成功
            
            success = false;
            
            % 解析可选参数
            p = inputParser;
            addParameter(p, 'sheetName', '', @ischar);
            addParameter(p, 'dataRange', '', @ischar);
            addParameter(p, 'timestampColumn', 1, @isnumeric);
            addParameter(p, 'valueColumn', 2, @isnumeric);
            parse(p, varargin{:});
            
            obj.sheetName = p.Results.sheetName;
            obj.dataRange = p.Results.dataRange;
            obj.columnMapping.timestamp = p.Results.timestampColumn;
            obj.columnMapping.value = p.Results.valueColumn;
            
            try
                % 检查文件是否存在
                if ~exist(obj.filename, 'file')
                    error('文件不存在: %s', obj.filename);
                end
                
                % 获取Excel信息
                [~, sheets] = xlsfinfo(obj.filename);
                
                % 如果没有指定工作表，使用第一个
                if isempty(obj.sheetName)
                    if ~isempty(sheets)
                        obj.sheetName = sheets{1};
                    else
                        error('Excel文件中没有工作表');
                    end
                end
                
                % 读取数据
                if isempty(obj.dataRange)
                    % 读取整个工作表
                    [num, txt, raw] = xlsread(obj.filename, obj.sheetName);
                else
                    % 读取指定范围
                    [num, txt, raw] = xlsread(obj.filename, obj.sheetName, obj.dataRange);
                end
                
                obj.data = raw;
                obj.totalRows = size(raw, 1);
                
                % 提取时间戳和数值列
                obj.extractColumns();
                
                obj.isConnected = true;
                success = true;
                
                fprintf('成功连接到Excel文件: %s\n', obj.filename);
                fprintf('工作表: %s, 数据行数: %d\n', obj.sheetName, obj.totalRows);
                
            catch ME
                warning('连接Excel文件失败: %s', ME.message);
                obj.isConnected = false;
            end
        end
        
        function disconnect(obj)
            % 断开连接
            
            obj.isConnected = false;
            obj.data = [];
            obj.timestamps = [];
            obj.values = [];
            obj.currentRow = 1;
        end
        
        function dataPoint = readData(obj)
            % 读取下一个数据点
            % 输出:
            %   dataPoint - DataPoint对象
            
            dataPoint = [];
            
            if ~obj.isConnected
                warning('未连接到Excel文件');
                return;
            end
            
            if obj.currentRow > obj.totalRows
                % 已读取完所有数据
                return;
            end
            
            try
                % 获取当前行数据
                timestamp = obj.timestamps(obj.currentRow);
                value = obj.values(obj.currentRow);
                
                % 获取可选数据
                unit = '%';
                quality = 'Good';
                
                if obj.columnMapping.unit > 0 && obj.columnMapping.unit <= size(obj.data, 2)
                    unitData = obj.data{obj.currentRow, obj.columnMapping.unit};
                    if ischar(unitData)
                        unit = unitData;
                    end
                end
                
                if obj.columnMapping.quality > 0 && obj.columnMapping.quality <= size(obj.data, 2)
                    qualityData = obj.data{obj.currentRow, obj.columnMapping.quality};
                    if ischar(qualityData)
                        quality = qualityData;
                    end
                end
                
                % 创建数据点
                dataPoint = DataPoint(value, ...
                    'unit', unit, ...
                    'source', sprintf('%s (Row %d)', obj.collectorName, obj.currentRow), ...
                    'quality', quality);
                
                % 设置时间戳
                dataPoint.timestamp = timestamp;
                
                % 移动到下一行
                obj.currentRow = obj.currentRow + 1;
                
            catch ME
                warning('读取数据失败 (行 %d): %s', obj.currentRow, ME.message);
                obj.currentRow = obj.currentRow + 1;
            end
        end
        
        function data = readBatch(obj, n)
            % 批量读取数据
            % 输入:
            %   n - 要读取的数据点数量
            % 输出:
            %   data - DataPoint对象数组
            
            data = cell(n, 1);
            count = 0;
            
            for i = 1:n
                dataPoint = obj.readData();
                if isempty(dataPoint)
                    break;
                end
                count = count + 1;
                data{count} = dataPoint;
            end
            
            % 裁剪到实际大小
            data = data(1:count);
        end
        
        function data = readAll(obj)
            % 读取所有剩余数据
            % 输出:
            %   data - DataPoint对象数组
            
            remainingRows = obj.totalRows - obj.currentRow + 1;
            data = obj.readBatch(remainingRows);
        end
        
        function status = getStatus(obj)
            % 获取状态
            % 输出:
            %   status - 状态结构体
            
            status = struct();
            status.connected = obj.isConnected;
            status.filename = obj.filename;
            status.sheetName = obj.sheetName;
            status.currentRow = obj.currentRow;
            status.totalRows = obj.totalRows;
            status.progress = sprintf('%.1f%%', (obj.currentRow-1)/obj.totalRows*100);
            status.collectorName = obj.collectorName;
        end
        
        function setParameters(obj, params)
            % 设置参数
            % 输入:
            %   params - 参数结构体
            
            if isfield(params, 'columnMapping')
                obj.columnMapping = params.columnMapping;
                if obj.isConnected
                    % 重新提取列
                    obj.extractColumns();
                end
            end
            
            if isfield(params, 'currentRow')
                obj.currentRow = params.currentRow;
            end
        end
        
        function reset(obj)
            % 重置到第一行
            obj.currentRow = 1;
        end
        
        function seekToRow(obj, row)
            % 跳转到指定行
            % 输入:
            %   row - 行号
            
            if row >= 1 && row <= obj.totalRows
                obj.currentRow = row;
            else
                error('行号超出范围: %d (总行数: %d)', row, obj.totalRows);
            end
        end
    end
    
    methods (Access = private)
        function extractColumns(obj)
            % 提取时间戳和数值列
            
            try
                % 提取时间戳
                timestampCol = obj.data(:, obj.columnMapping.timestamp);
                obj.timestamps = NaT(obj.totalRows, 1);
                
                for i = 1:obj.totalRows
                    ts = timestampCol{i};
                    if isnumeric(ts)
                        % Excel日期序列号
                        obj.timestamps(i) = datetime(ts, 'ConvertFrom', 'excel');
                    elseif ischar(ts) || isstring(ts)
                        % 尝试解析字符串
                        try
                            obj.timestamps(i) = datetime(ts);
                        catch
                            % 使用默认格式
                            obj.timestamps(i) = datetime(ts, 'InputFormat', 'yyyy-MM-dd HH:mm:ss');
                        end
                    elseif isdatetime(ts)
                        obj.timestamps(i) = ts;
                    end
                end
                
                % 提取数值
                valueCol = obj.data(:, obj.columnMapping.value);
                obj.values = nan(obj.totalRows, 1);
                
                for i = 1:obj.totalRows
                    val = valueCol{i};
                    if isnumeric(val)
                        obj.values(i) = val;
                    elseif ischar(val) || isstring(val)
                        % 尝试转换字符串为数值
                        obj.values(i) = str2double(val);
                    end
                end
                
            catch ME
                error('提取数据列失败: %s', ME.message);
            end
        end
    end
end