classdef DataSimulator < IDataCollector
    % DataSimulator - 数据模拟器
    % 用于测试和演示，模拟氧分析仪数据
    
    properties
        isConnected = false
        collectorName = 'Data Simulator'
        collectorType = 'Simulation'
    end
    
    properties (Access = private)
        baseValue       % 基准值
        noiseLevel      % 噪声水平
        driftRate       % 漂移速率
        anomalyProb     % 异常概率
        lastValue       % 上一个值
        startTime       % 开始时间
    end
    
    methods
        function obj = DataSimulator(varargin)
            % 构造函数
            % 可选参数:
            %   baseValue - 基准氧浓度值 (默认 20.9%)
            %   noiseLevel - 噪声水平 (默认 0.1)
            %   driftRate - 漂移速率 (默认 0.001)
            %   anomalyProb - 异常概率 (默认 0.01)
            
            p = inputParser;
            addParameter(p, 'baseValue', 20.9, @isnumeric);
            addParameter(p, 'noiseLevel', 0.1, @isnumeric);
            addParameter(p, 'driftRate', 0.001, @isnumeric);
            addParameter(p, 'anomalyProb', 0.01, @isnumeric);
            parse(p, varargin{:});
            
            obj.baseValue = p.Results.baseValue;
            obj.noiseLevel = p.Results.noiseLevel;
            obj.driftRate = p.Results.driftRate;
            obj.anomalyProb = p.Results.anomalyProb;
            obj.lastValue = obj.baseValue;
        end
        
        function success = connect(obj, varargin)
            % 连接（模拟）
            obj.isConnected = true;
            obj.startTime = datetime('now');
            obj.lastValue = obj.baseValue;
            success = true;
            fprintf('数据模拟器已连接\n');
        end
        
        function disconnect(obj)
            % 断开连接
            obj.isConnected = false;
            fprintf('数据模拟器已断开\n');
        end
        
        function data = readData(obj)
            % 读取模拟数据
            data = [];
            
            if ~obj.isConnected
                warning('模拟器未连接');
                return;
            end
            
            % 计算经过的时间（分钟）
            elapsedMinutes = minutes(datetime('now') - obj.startTime);
            
            % 生成模拟值
            % 1. 基准值 + 缓慢漂移
            drift = obj.driftRate * elapsedMinutes * sin(elapsedMinutes/60);
            
            % 2. 添加噪声
            noise = obj.noiseLevel * randn();
            
            % 3. 可能的异常值
            if rand() < obj.anomalyProb
                anomaly = (rand() - 0.5) * 2; % ±1%的异常
            else
                anomaly = 0;
            end
            
            % 4. 平滑处理（与上一个值的加权平均）
            newValue = obj.baseValue + drift + noise + anomaly;
            smoothedValue = 0.7 * obj.lastValue + 0.3 * newValue;
            obj.lastValue = smoothedValue;
            
            % 限制在合理范围内
            smoothedValue = max(0, min(100, smoothedValue));
            
            % 确定数据质量
            if abs(smoothedValue - obj.baseValue) > 2
                quality = 'Warning';
            elseif anomaly ~= 0
                quality = 'Uncertain';
            else
                quality = 'Good';
            end
            
            % 创建数据点
            data = DataPoint(smoothedValue, ...
                'unit', '%', ...
                'source', obj.collectorName, ...
                'quality', quality, ...
                'metadata', struct('drift', drift, 'noise', noise, 'anomaly', anomaly));
        end
        
        function status = getStatus(obj)
            % 获取状态
            status = struct();
            status.connected = obj.isConnected;
            status.collectorName = obj.collectorName;
            status.baseValue = obj.baseValue;
            status.currentValue = obj.lastValue;
            
            if obj.isConnected
                status.runtime = char(datetime('now') - obj.startTime);
            else
                status.runtime = 'N/A';
            end
        end
        
        function setParameters(obj, params)
            % 设置参数
            if isfield(params, 'baseValue')
                obj.baseValue = params.baseValue;
            end
            if isfield(params, 'noiseLevel')
                obj.noiseLevel = params.noiseLevel;
            end
            if isfield(params, 'driftRate')
                obj.driftRate = params.driftRate;
            end
            if isfield(params, 'anomalyProb')
                obj.anomalyProb = params.anomalyProb;
            end
        end
        
        function simulateAnomaly(obj, value)
            % 模拟异常值
            % 输入:
            %   value - 异常值
            
            if obj.isConnected
                obj.lastValue = value;
                fprintf('已注入异常值: %.2f%%\n', value);
            end
        end
    end
end