classdef DataBuffer < handle
    % DataBuffer - 数据缓冲区类
    % 用于存储和管理采集的数据
    
    properties (Access = private)
        buffer          % 数据缓冲区
        maxSize         % 最大缓冲区大小
        currentIndex    % 当前索引
    end
    
    properties (SetAccess = private)
        count           % 当前数据点数量
    end
    
    methods
        function obj = DataBuffer(maxSize)
            % 构造函数
            % 输入:
            %   maxSize - 最大缓冲区大小
            
            if nargin < 1
                maxSize = 10000;
            end
            
            obj.maxSize = maxSize;
            obj.buffer = cell(maxSize, 1);
            obj.currentIndex = 0;
            obj.count = 0;
        end
        
        function addData(obj, dataPoint)
            % 添加数据点到缓冲区
            % 输入:
            %   dataPoint - DataPoint对象
            
            obj.currentIndex = mod(obj.currentIndex, obj.maxSize) + 1;
            obj.buffer{obj.currentIndex} = dataPoint;
            
            if obj.count < obj.maxSize
                obj.count = obj.count + 1;
            end
        end
        
        function data = getData(obj, n)
            % 获取最近的n个数据点
            % 输入:
            %   n - 要获取的数据点数量
            % 输出:
            %   data - DataPoint对象数组
            
            if nargin < 2
                n = obj.count;
            end
            
            n = min(n, obj.count);
            data = cell(n, 1);
            
            for i = 1:n
                idx = mod(obj.currentIndex - i, obj.maxSize) + 1;
                data{n - i + 1} = obj.buffer{idx};
            end
        end
        
        function [timestamps, values] = getTimeSeries(obj, n)
            % 获取时间序列数据
            % 输入:
            %   n - 要获取的数据点数量
            % 输出:
            %   timestamps - 时间戳数组
            %   values - 数值数组
            
            if nargin < 2
                n = obj.count;
            end
            
            data = obj.getData(n);
            timestamps = NaT(n, 1);
            values = nan(n, 1);
            
            for i = 1:n
                if ~isempty(data{i})
                    timestamps(i) = data{i}.timestamp;
                    values(i) = data{i}.value;
                end
            end
        end
        
        function clear(obj)
            % 清空缓冲区
            obj.buffer = cell(obj.maxSize, 1);
            obj.currentIndex = 0;
            obj.count = 0;
        end
        
        function saveToFile(obj, filename)
            % 保存数据到文件
            % 输入:
            %   filename - 文件名
            
            data = obj.getData();
            save(filename, 'data');
        end
    end
end