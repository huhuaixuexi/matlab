classdef DatabaseDataCollector < IDataCollector
    % DatabaseDataCollector - 数据库数据采集器
    % 从数据库读取和写入数据
    
    properties
        isConnected = false
        collectorName = 'Database Data Collector'
        collectorType = 'Database'
    end
    
    properties (Access = private)
        dbConnection    % 数据库连接对象
        dbType          % 数据库类型（MySQL, PostgreSQL, SQLite等）
        connectionInfo  % 连接信息
        tableName       % 数据表名
        queryTemplate   % 查询模板
        lastQueryTime   % 上次查询时间
        pollingInterval % 轮询间隔（秒）
    end
    
    methods
        function obj = DatabaseDataCollector(dbType, connectionInfo)
            % 构造函数
            % 输入:
            %   dbType - 数据库类型 ('mysql', 'postgresql', 'sqlite', 'odbc')
            %   connectionInfo - 连接信息结构体
            
            obj.dbType = lower(dbType);
            obj.connectionInfo = connectionInfo;
            obj.tableName = 'oxygen_measurements';
            obj.pollingInterval = 1; % 默认1秒
            obj.lastQueryTime = datetime('now');
            
            % 默认查询模板
            obj.queryTemplate = ['SELECT timestamp, value, unit, quality, source ' ...
                                'FROM %s WHERE timestamp > ? ORDER BY timestamp ASC'];
        end
        
        function success = connect(obj, varargin)
            % 连接到数据库
            % 输入:
            %   varargin - 可选参数
            % 输出:
            %   success - 是否成功
            
            success = false;
            
            % 解析可选参数
            p = inputParser;
            addParameter(p, 'tableName', obj.tableName, @ischar);
            addParameter(p, 'createTable', true, @islogical);
            parse(p, varargin{:});
            
            obj.tableName = p.Results.tableName;
            
            try
                % 断开现有连接
                if obj.isConnected
                    obj.disconnect();
                end
                
                % 根据数据库类型建立连接
                switch obj.dbType
                    case 'mysql'
                        obj.dbConnection = database(obj.connectionInfo.database, ...
                            obj.connectionInfo.username, ...
                            obj.connectionInfo.password, ...
                            'Vendor', 'MySQL', ...
                            'Server', obj.connectionInfo.server, ...
                            'PortNumber', obj.connectionInfo.port);
                        
                    case 'postgresql'
                        obj.dbConnection = database(obj.connectionInfo.database, ...
                            obj.connectionInfo.username, ...
                            obj.connectionInfo.password, ...
                            'Vendor', 'PostgreSQL', ...
                            'Server', obj.connectionInfo.server, ...
                            'PortNumber', obj.connectionInfo.port);
                        
                    case 'sqlite'
                        obj.dbConnection = database('', '', '', ...
                            'org.sqlite.JDBC', ...
                            sprintf('jdbc:sqlite:%s', obj.connectionInfo.filename));
                        
                    case 'odbc'
                        obj.dbConnection = database(obj.connectionInfo.datasource, ...
                            obj.connectionInfo.username, ...
                            obj.connectionInfo.password);
                        
                    otherwise
                        error('不支持的数据库类型: %s', obj.dbType);
                end
                
                % 检查连接
                if ~isempty(obj.dbConnection.Message)
                    error('数据库连接失败: %s', obj.dbConnection.Message);
                end
                
                obj.isConnected = true;
                
                % 创建表（如果需要）
                if p.Results.createTable
                    obj.createDataTable();
                end
                
                success = true;
                fprintf('成功连接到数据库: %s\n', obj.connectionInfo.database);
                
            catch ME
                warning('数据库连接失败: %s', ME.message);
                obj.isConnected = false;
            end
        end
        
        function disconnect(obj)
            % 断开数据库连接
            
            try
                if ~isempty(obj.dbConnection) && isopen(obj.dbConnection)
                    close(obj.dbConnection);
                end
            catch
                % 忽略错误
            end
            
            obj.dbConnection = [];
            obj.isConnected = false;
        end
        
        function dataPoint = readData(obj)
            % 读取最新数据
            % 输出:
            %   dataPoint - DataPoint对象
            
            dataPoint = [];
            
            if ~obj.isConnected
                warning('数据库未连接');
                return;
            end
            
            try
                % 构建查询
                query = sprintf(obj.queryTemplate, obj.tableName);
                
                % 执行查询
                curs = exec(obj.dbConnection, query, obj.lastQueryTime);
                curs = fetch(curs);
                data = curs.Data;
                close(curs);
                
                if ~isempty(data) && ~any(strcmp(data, 'No Data'))
                    % 获取最新的一条记录
                    row = data(end, :);
                    
                    % 创建数据点
                    value = cell2mat(row(2));
                    dataPoint = DataPoint(value, ...
                        'unit', row{3}, ...
                        'source', row{5}, ...
                        'quality', row{4});
                    
                    % 设置时间戳
                    dataPoint.timestamp = row{1};
                    
                    % 更新最后查询时间
                    obj.lastQueryTime = dataPoint.timestamp;
                end
                
            catch ME
                warning('读取数据失败: %s', ME.message);
            end
        end
        
        function data = readHistoricalData(obj, startTime, endTime)
            % 读取历史数据
            % 输入:
            %   startTime - 开始时间
            %   endTime - 结束时间
            % 输出:
            %   data - DataPoint对象数组
            
            data = {};
            
            if ~obj.isConnected
                warning('数据库未连接');
                return;
            end
            
            try
                % 构建查询
                query = sprintf(['SELECT timestamp, value, unit, quality, source ' ...
                    'FROM %s WHERE timestamp >= ? AND timestamp <= ? ' ...
                    'ORDER BY timestamp ASC'], obj.tableName);
                
                % 执行查询
                curs = exec(obj.dbConnection, query, {startTime, endTime});
                curs = fetch(curs);
                results = curs.Data;
                close(curs);
                
                if ~isempty(results) && ~any(strcmp(results, 'No Data'))
                    % 转换为DataPoint对象
                    n = size(results, 1);
                    data = cell(n, 1);
                    
                    for i = 1:n
                        row = results(i, :);
                        value = cell2mat(row(2));
                        
                        dp = DataPoint(value, ...
                            'unit', row{3}, ...
                            'source', row{5}, ...
                            'quality', row{4});
                        
                        dp.timestamp = row{1};
                        data{i} = dp;
                    end
                end
                
            catch ME
                warning('读取历史数据失败: %s', ME.message);
            end
        end
        
        function success = writeData(obj, dataPoint)
            % 写入数据到数据库
            % 输入:
            %   dataPoint - DataPoint对象
            % 输出:
            %   success - 是否成功
            
            success = false;
            
            if ~obj.isConnected
                warning('数据库未连接');
                return;
            end
            
            try
                % 准备数据
                colnames = {'timestamp', 'value', 'unit', 'quality', 'source'};
                data = {dataPoint.timestamp, dataPoint.value, ...
                    dataPoint.unit, dataPoint.quality, dataPoint.source};
                
                % 插入数据
                insert(obj.dbConnection, obj.tableName, colnames, data);
                
                success = true;
                
            catch ME
                warning('写入数据失败: %s', ME.message);
            end
        end
        
        function success = writeBatch(obj, dataPoints)
            % 批量写入数据
            % 输入:
            %   dataPoints - DataPoint对象数组
            % 输出:
            %   success - 是否成功
            
            success = false;
            
            if ~obj.isConnected
                warning('数据库未连接');
                return;
            end
            
            try
                % 准备批量数据
                n = length(dataPoints);
                timestamps = cell(n, 1);
                values = zeros(n, 1);
                units = cell(n, 1);
                qualities = cell(n, 1);
                sources = cell(n, 1);
                
                for i = 1:n
                    dp = dataPoints{i};
                    timestamps{i} = dp.timestamp;
                    values(i) = dp.value;
                    units{i} = dp.unit;
                    qualities{i} = dp.quality;
                    sources{i} = dp.source;
                end
                
                % 构建数据表
                colnames = {'timestamp', 'value', 'unit', 'quality', 'source'};
                data = table(timestamps, values, units, qualities, sources, ...
                    'VariableNames', colnames);
                
                % 批量插入
                sqlwrite(obj.dbConnection, obj.tableName, data);
                
                success = true;
                fprintf('成功写入 %d 条数据\n', n);
                
            catch ME
                warning('批量写入失败: %s', ME.message);
            end
        end
        
        function status = getStatus(obj)
            % 获取状态
            % 输出:
            %   status - 状态结构体
            
            status = struct();
            status.connected = obj.isConnected;
            status.dbType = obj.dbType;
            status.database = '';
            status.tableName = obj.tableName;
            status.lastQueryTime = obj.lastQueryTime;
            status.collectorName = obj.collectorName;
            
            if obj.isConnected && isfield(obj.connectionInfo, 'database')
                status.database = obj.connectionInfo.database;
            end
        end
        
        function setParameters(obj, params)
            % 设置参数
            % 输入:
            %   params - 参数结构体
            
            if isfield(params, 'tableName')
                obj.tableName = params.tableName;
            end
            
            if isfield(params, 'pollingInterval')
                obj.pollingInterval = params.pollingInterval;
            end
            
            if isfield(params, 'queryTemplate')
                obj.queryTemplate = params.queryTemplate;
            end
        end
    end
    
    methods (Access = private)
        function createDataTable(obj)
            % 创建数据表
            
            try
                % 根据数据库类型创建表
                switch obj.dbType
                    case {'mysql', 'postgresql'}
                        createSQL = sprintf([...
                            'CREATE TABLE IF NOT EXISTS %s (' ...
                            'id SERIAL PRIMARY KEY, ' ...
                            'timestamp TIMESTAMP NOT NULL, ' ...
                            'value DOUBLE PRECISION NOT NULL, ' ...
                            'unit VARCHAR(20), ' ...
                            'quality VARCHAR(20), ' ...
                            'source VARCHAR(100), ' ...
                            'created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, ' ...
                            'INDEX idx_timestamp (timestamp))'], obj.tableName);
                        
                    case 'sqlite'
                        createSQL = sprintf([...
                            'CREATE TABLE IF NOT EXISTS %s (' ...
                            'id INTEGER PRIMARY KEY AUTOINCREMENT, ' ...
                            'timestamp DATETIME NOT NULL, ' ...
                            'value REAL NOT NULL, ' ...
                            'unit TEXT, ' ...
                            'quality TEXT, ' ...
                            'source TEXT, ' ...
                            'created_at DATETIME DEFAULT CURRENT_TIMESTAMP)'], obj.tableName);
                        
                    otherwise
                        % 通用SQL
                        createSQL = sprintf([...
                            'CREATE TABLE IF NOT EXISTS %s (' ...
                            'id INTEGER PRIMARY KEY, ' ...
                            'timestamp DATETIME NOT NULL, ' ...
                            'value FLOAT NOT NULL, ' ...
                            'unit VARCHAR(20), ' ...
                            'quality VARCHAR(20), ' ...
                            'source VARCHAR(100))'], obj.tableName);
                end
                
                % 执行创建表语句
                exec(obj.dbConnection, createSQL);
                
                % 创建索引（如果是SQLite）
                if strcmp(obj.dbType, 'sqlite')
                    indexSQL = sprintf('CREATE INDEX IF NOT EXISTS idx_timestamp ON %s (timestamp)', obj.tableName);
                    exec(obj.dbConnection, indexSQL);
                end
                
                fprintf('数据表 %s 创建成功\n', obj.tableName);
                
            catch ME
                warning('创建数据表失败: %s', ME.message);
            end
        end
    end
end