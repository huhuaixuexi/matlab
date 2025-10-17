classdef DataPoint < handle
    % DataPoint - 数据点类
    % 用于存储单个测量数据点的信息
    
    properties
        timestamp       % 时间戳
        value          % 测量值
        unit           % 单位
        quality        % 数据质量标志
        source         % 数据源
        metadata       % 元数据
    end
    
    methods
        function obj = DataPoint(value, varargin)
            % 构造函数
            % 输入:
            %   value - 测量值
            %   varargin - 可选参数对
            
            obj.timestamp = datetime('now');
            obj.value = value;
            obj.quality = 'Good';
            obj.metadata = struct();
            
            % 解析可选参数
            p = inputParser;
            addParameter(p, 'unit', '%', @ischar);
            addParameter(p, 'source', 'Unknown', @ischar);
            addParameter(p, 'quality', 'Good', @ischar);
            addParameter(p, 'metadata', struct(), @isstruct);
            parse(p, varargin{:});
            
            obj.unit = p.Results.unit;
            obj.source = p.Results.source;
            obj.quality = p.Results.quality;
            obj.metadata = p.Results.metadata;
        end
        
        function str = toString(obj)
            % 转换为字符串表示
            str = sprintf('[%s] %.4f %s (Quality: %s, Source: %s)', ...
                datestr(obj.timestamp, 'yyyy-mm-dd HH:MM:SS.FFF'), ...
                obj.value, obj.unit, obj.quality, obj.source);
        end
        
        function s = toStruct(obj)
            % 转换为结构体
            s = struct('timestamp', obj.timestamp, ...
                      'value', obj.value, ...
                      'unit', obj.unit, ...
                      'quality', obj.quality, ...
                      'source', obj.source, ...
                      'metadata', obj.metadata);
        end
    end
end