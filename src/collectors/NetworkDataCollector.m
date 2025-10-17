classdef NetworkDataCollector < IDataCollector
    % NetworkDataCollector - 网络数据采集器
    % 通过TCP/IP协议从Magnos206氧分析仪采集数据
    
    properties
        isConnected = false
        collectorName = 'Magnos206 Network Collector'
        collectorType = 'TCP/IP'
    end
    
    properties (Access = private)
        tcpClient       % TCP客户端对象
        ipAddress       % IP地址
        port            % 端口号
        timeout         % 超时时间
        dataFormat      % 数据格式
        parsePattern    % 数据解析模式
    end
    
    methods
        function obj = NetworkDataCollector(ipAddress, port)
            % 构造函数
            % 输入:
            %   ipAddress - 设备IP地址
            %   port - 端口号
            
            obj.ipAddress = ipAddress;
            obj.port = port;
            obj.timeout = 5; % 默认5秒超时
            obj.dataFormat = 'ASCII'; % 默认ASCII格式
            obj.parsePattern = '(?<value>[\d.]+)\s*%?\s*O2'; % 氧浓度解析模式
        end
        
        function success = connect(obj, varargin)
            % 连接到设备
            % 输入:
            %   varargin - 可选参数
            % 输出:
            %   success - 连接是否成功
            
            success = false;
            
            try
                % 断开现有连接
                if obj.isConnected
                    obj.disconnect();
                end
                
                % 创建TCP客户端
                obj.tcpClient = tcpclient(obj.ipAddress, obj.port, ...
                    'Timeout', obj.timeout);
                
                % 测试连接
                configureTerminator(obj.tcpClient, "LF");
                
                % 发送测试命令
                writeline(obj.tcpClient, '*IDN?');
                pause(0.1);
                
                if obj.tcpClient.NumBytesAvailable > 0
                    response = readline(obj.tcpClient);
                    fprintf('设备响应: %s\n', response);
                    obj.isConnected = true;
                    success = true;
                else
                    warning('设备无响应');
                end
                
            catch ME
                warning('连接失败: %s', ME.message);
                obj.isConnected = false;
            end
        end
        
        function disconnect(obj)
            % 断开连接
            
            try
                if ~isempty(obj.tcpClient) && isvalid(obj.tcpClient)
                    clear obj.tcpClient;
                end
            catch
                % 忽略错误
            end
            
            obj.tcpClient = [];
            obj.isConnected = false;
        end
        
        function data = readData(obj)
            % 读取数据
            % 输出:
            %   data - DataPoint对象
            
            data = [];
            
            if ~obj.isConnected
                warning('设备未连接');
                return;
            end
            
            try
                % 发送读取命令
                writeline(obj.tcpClient, 'READ?');
                pause(0.05); % 短暂等待响应
                
                % 读取响应
                if obj.tcpClient.NumBytesAvailable > 0
                    response = readline(obj.tcpClient);
                    
                    % 解析数据
                    value = obj.parseResponse(response);
                    
                    if ~isnan(value)
                        % 创建数据点
                        data = DataPoint(value, ...
                            'unit', '%', ...
                            'source', obj.collectorName, ...
                            'quality', 'Good', ...
                            'metadata', struct('raw', response));
                    else
                        warning('数据解析失败: %s', response);
                    end
                else
                    warning('设备无响应');
                end
                
            catch ME
                warning('读取数据失败: %s', ME.message);
                % 尝试重新连接
                obj.checkConnection();
            end
        end
        
        function status = getStatus(obj)
            % 获取状态
            % 输出:
            %   status - 状态结构体
            
            status = struct();
            status.connected = obj.isConnected;
            status.ipAddress = obj.ipAddress;
            status.port = obj.port;
            status.collectorName = obj.collectorName;
            
            if obj.isConnected && ~isempty(obj.tcpClient)
                status.bytesAvailable = obj.tcpClient.NumBytesAvailable;
            else
                status.bytesAvailable = 0;
            end
        end
        
        function setParameters(obj, params)
            % 设置参数
            % 输入:
            %   params - 参数结构体
            
            if isfield(params, 'timeout')
                obj.timeout = params.timeout;
                if obj.isConnected && ~isempty(obj.tcpClient)
                    obj.tcpClient.Timeout = obj.timeout;
                end
            end
            
            if isfield(params, 'dataFormat')
                obj.dataFormat = params.dataFormat;
            end
            
            if isfield(params, 'parsePattern')
                obj.parsePattern = params.parsePattern;
            end
        end
        
        function sendCommand(obj, command)
            % 发送命令到设备
            % 输入:
            %   command - 命令字符串
            
            if ~obj.isConnected
                error('设备未连接');
            end
            
            writeline(obj.tcpClient, command);
        end
        
        function response = query(obj, command)
            % 发送查询命令并获取响应
            % 输入:
            %   command - 查询命令
            % 输出:
            %   response - 响应字符串
            
            response = '';
            
            if ~obj.isConnected
                error('设备未连接');
            end
            
            try
                writeline(obj.tcpClient, command);
                pause(0.1);
                
                if obj.tcpClient.NumBytesAvailable > 0
                    response = readline(obj.tcpClient);
                end
            catch ME
                warning('查询失败: %s', ME.message);
            end
        end
    end
    
    methods (Access = private)
        function value = parseResponse(obj, response)
            % 解析响应数据
            % 输入:
            %   response - 响应字符串
            % 输出:
            %   value - 解析后的数值
            
            value = NaN;
            
            try
                % 使用正则表达式解析
                tokens = regexp(response, obj.parsePattern, 'names');
                
                if ~isempty(tokens)
                    value = str2double(tokens.value);
                else
                    % 尝试简单解析
                    nums = regexp(response, '[\d.]+', 'match');
                    if ~isempty(nums)
                        value = str2double(nums{1});
                    end
                end
            catch
                % 解析失败
            end
        end
        
        function checkConnection(obj)
            % 检查连接状态
            
            if ~obj.isConnected || isempty(obj.tcpClient) || ~isvalid(obj.tcpClient)
                obj.isConnected = false;
                fprintf('连接已断开，尝试重新连接...\n');
                obj.connect();
            end
        end
    end
end