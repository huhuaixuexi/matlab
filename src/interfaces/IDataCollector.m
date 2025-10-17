classdef (Abstract) IDataCollector < handle
    % IDataCollector - 数据采集器接口
    % 定义了所有数据采集器必须实现的基本方法
    
    properties (Abstract)
        % 连接状态
        isConnected
        % 采集器名称
        collectorName
        % 采集器类型
        collectorType
    end
    
    methods (Abstract)
        % 连接数据源
        success = connect(obj, varargin)
        
        % 断开连接
        disconnect(obj)
        
        % 读取数据
        data = readData(obj)
        
        % 获取状态
        status = getStatus(obj)
        
        % 设置参数
        setParameters(obj, params)
    end
    
    methods
        function obj = IDataCollector()
            % 构造函数
        end
    end
end