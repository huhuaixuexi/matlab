%% 氧分析仪故障诊断与维护建议知识库系统
% 功能：建立故障知识库，提供智能维护决策支持
% 版本：v2.1 (修复版)
% 日期：2025年10月8日
% 改进：修复字符串匹配、添加输入验证、优化性能、修复语法错误

classdef FaultKnowledgeBase_Fixed < handle
    % 故障诊断与维护建议知识库类
    
    properties (Access = private)
        faultDatabase      % 故障数据库
        maintenanceLog     % 维护日志
        statisticsData     % 统计数据
        customMeasures     % 用户自定义维护措施
        faultCodeToType    % 故障代码到类型的映射（性能优化）
    end
    
    methods (Access = public)
        function obj = FaultKnowledgeBase_Fixed()
            % 构造函数：初始化知识库
            obj.initializeFaultDatabase();
            obj.maintenanceLog = {};
            obj.statisticsData = struct();
            obj.customMeasures = {};
            obj.faultCodeToType = containers.Map();
            obj.buildFaultCodeMapping();
            fprintf('故障知识库系统初始化完成\n');
        end
        
        function initializeFaultDatabase(obj)
            % 初始化故障数据库
            obj.faultDatabase = obj.buildFaultDatabase();
            fprintf('故障数据库加载完成，共%d条故障记录\n', length(obj.faultDatabase));
        end
        
        function buildFaultCodeMapping(obj)
            % 构建故障代码到类型的映射（性能优化）
            for i = 1:length(obj.faultDatabase)
                obj.faultCodeToType(obj.faultDatabase{i}.fault_code) = ...
                    obj.faultDatabase{i}.fault_type;
            end
        end
        
        function db = buildFaultDatabase(obj)
            % 构建完整的故障数据库
            db = {};
            
            % ========== 数据偏差型故障 ==========
            
            % 故障代码302
            db{end+1} = struct(...
                'fault_type', '数据偏差型故障', ...
                'fault_code', '302', ...
                'fault_name', '零点漂移超过允许范围50%', ...
                'description', '偏差漂移超过了允许范围的一半（±0.75vol%O2）', ...
                'severity', '中等', ...
                'priority', 2, ...
                'maintenance_measures', {
                    obj.createMeasure(1, '检查传感器表面污染', '10分钟', '清洁布、酒精');
                    obj.createMeasure(2, '检查采样管路冷凝水', '15分钟', '排水工具');
                    obj.createMeasure(3, '执行零点校准程序', '30分钟', '标准气体');
                    obj.createMeasure(4, '检查传感器老化程度', '1小时', '测试设备');
                    obj.createMeasure(5, '更换传感器模块', '2小时', '备用传感器')
                });
            
            % 故障代码303
            db{end+1} = struct(...
                'fault_type', '数据偏差型故障', ...
                'fault_code', '303', ...
                'fault_name', '零点漂移超出允许范围', ...
                'description', '偏差漂移超出允许范围（±1.5vol%O2）', ...
                'severity', '严重', ...
                'priority', 1, ...
                'maintenance_measures', {
                    obj.createMeasure(1, '立即检查传感器状态灯', '5分钟', '无');
                    obj.createMeasure(2, '检查供电电压24V DC', '10分钟', '万用表');
                    obj.createMeasure(3, '紧急执行零点量程校准', '45分钟', '标准气体');
                    obj.createMeasure(4, '检查传感器参比电极', '1.5小时', '专用检测仪');
                    obj.createMeasure(5, '立即更换传感器', '2小时', '备用传感器')
                });
            
            % 故障代码304
            db{end+1} = struct(...
                'fault_type', '数据偏差型故障', ...
                'fault_code', '304', ...
                'fault_name', '灵敏度漂移超出50%', ...
                'description', '放大漂移超出允许范围的50%', ...
                'severity', '中等', ...
                'priority', 2, ...
                'maintenance_measures', {
                    obj.createMeasure(1, '检查测量池窗片清洁度', '15分钟', '清洁工具');
                    obj.createMeasure(2, '检查光源强度稳定性', '20分钟', '光强测试仪');
                    obj.createMeasure(3, '执行量程标定', '40分钟', '量程气体');
                    obj.createMeasure(4, '检查检测器响应曲线', '1小时', '测试设备');
                    obj.createMeasure(5, '更换检测器组件', '2小时', '备用检测器')
                });
            
            % 故障代码305
            db{end+1} = struct(...
                'fault_type', '数据偏差型故障', ...
                'fault_code', '305', ...
                'fault_name', '灵敏度漂移超出允许范围', ...
                'description', '放大漂移超出允许范围', ...
                'severity', '严重', ...
                'priority', 1, ...
                'maintenance_measures', {
                    obj.createMeasure(1, '停止测量检查报警', '5分钟', '无');
                    obj.createMeasure(2, '清洁所有光学元件', '30分钟', '光学清洁套装');
                    obj.createMeasure(3, '执行完整系统标定', '1小时', '多种标准气体');
                    obj.createMeasure(4, '调整光路对准', '1.5小时', '光路调整工具');
                    obj.createMeasure(5, '更换光源和检测器', '3小时', '备件')
                });
            
            % 故障代码319
            db{end+1} = struct(...
                'fault_type', '数据偏差型故障', ...
                'fault_code', '319', ...
                'fault_name', '测定电桥失衡', ...
                'description', '测量电桥电路失去平衡', ...
                'severity', '严重', ...
                'priority', 1, ...
                'maintenance_measures', {
                    obj.createMeasure(1, '检查电桥电路连接', '10分钟', '螺丝刀');
                    obj.createMeasure(2, '测量电桥各臂电阻', '20分钟', '精密电阻表');
                    obj.createMeasure(3, '调节电桥平衡电位器', '30分钟', '示波器');
                    obj.createMeasure(4, '更换精密电阻', '1小时', '备用电阻');
                    obj.createMeasure(5, '更换电桥电路板', '2小时', '备用电路板')
                });
            
            % 故障代码320
            db{end+1} = struct(...
                'fault_type', '数据偏差型故障', ...
                'fault_code', '320', ...
                'fault_name', '测定放大偏差过高', ...
                'description', '信号放大器偏差超出正常范围', ...
                'severity', '中等', ...
                'priority', 2, ...
                'maintenance_measures', {
                    obj.createMeasure(1, '检查放大器供电', '10分钟', '万用表');
                    obj.createMeasure(2, '调整放大器零点增益', '25分钟', '示波器');
                    obj.createMeasure(3, '更换运放芯片', '45分钟', '备用芯片');
                    obj.createMeasure(4, '检查信号链路', '1小时', '信号发生器');
                    obj.createMeasure(5, '更换放大器板', '1.5小时', '备用电路板')
                });
            
            % 故障代码309-311
            db{end+1} = struct(...
                'fault_type', '数据偏差型故障', ...
                'fault_code', '309-311', ...
                'fault_name', '温度调节器失效', ...
                'description', '温度控制超出范围', ...
                'severity', '中等', ...
                'priority', 2, ...
                'maintenance_measures', {
                    obj.createMeasure(1, '检查温度传感器', '10分钟', '温度计');
                    obj.createMeasure(2, '检查加热冷却器', '20分钟', '万用表');
                    obj.createMeasure(3, '校准PID参数', '40分钟', '调试软件');
                    obj.createMeasure(4, '更换温度传感器', '1小时', '备用传感器');
                    obj.createMeasure(5, '更换温控模块', '2小时', '备用模块')
                });
            
            % ========== 数据传输中断型故障 ==========
            
            % 故障代码101
            db{end+1} = struct(...
                'fault_type', '数据传输中断型故障', ...
                'fault_code', '101', ...
                'fault_name', '系统控制器关停', ...
                'description', '主控制器停止工作', ...
                'severity', '紧急', ...
                'priority', 1, ...
                'maintenance_measures', {
                    obj.createMeasure(1, '检查主电源保险丝', '5分钟', '万用表');
                    obj.createMeasure(2, '检查24V电源输出', '10分钟', '万用表');
                    obj.createMeasure(3, '重启控制器系统', '15分钟', '无');
                    obj.createMeasure(4, '检查CPU和内存', '30分钟', '诊断软件');
                    obj.createMeasure(5, '更换控制器主板', '2小时', '备用主板')
                });
            
            % 故障代码116
            db{end+1} = struct(...
                'fault_type', '数据传输中断型故障', ...
                'fault_code', '116', ...
                'fault_name', 'Profibus安装错误', ...
                'description', 'Profibus模块安装位置错误', ...
                'severity', '中等', ...
                'priority', 3, ...
                'maintenance_measures', {
                    obj.createMeasure(1, '确认安装位置', '5分钟', '无');
                    obj.createMeasure(2, '重装到X20/X21槽', '15分钟', '螺丝刀');
                    obj.createMeasure(3, '重配通讯参数', '20分钟', '配置软件');
                    obj.createMeasure(4, '测试通讯连接', '30分钟', 'Profibus测试仪');
                    obj.createMeasure(5, '更换Profibus模块', '1小时', '备用模块')
                });
            
            % 故障代码201-209
            db{end+1} = struct(...
                'fault_type', '数据传输中断型故障', ...
                'fault_code', '201-209', ...
                'fault_name', '系统总线连接中断', ...
                'description', '系统总线通讯中断', ...
                'severity', '严重', ...
                'priority', 1, ...
                'maintenance_measures', {
                    obj.createMeasure(1, '检查总线电缆', '10分钟', '无');
                    obj.createMeasure(2, '检查终端电阻', '15分钟', '万用表');
                    obj.createMeasure(3, '更换总线电缆', '30分钟', '备用电缆');
                    obj.createMeasure(4, '检查模块供电', '20分钟', '万用表');
                    obj.createMeasure(5, '更换通讯模块', '1小时', '备用模块')
                });
            
            % 故障代码300
            db{end+1} = struct(...
                'fault_type', '数据传输中断型故障', ...
                'fault_code', '300', ...
                'fault_name', '模数转换器无输出', ...
                'description', 'ADC无新测量值', ...
                'severity', '严重', ...
                'priority', 1, ...
                'maintenance_measures', {
                    obj.createMeasure(1, '检查ADC供电', '10分钟', '万用表');
                    obj.createMeasure(2, '检查模拟输入', '15分钟', '示波器');
                    obj.createMeasure(3, '重置ADC芯片', '20分钟', '复位工具');
                    obj.createMeasure(4, '更换ADC芯片', '1小时', '备用芯片');
                    obj.createMeasure(5, '更换采集卡', '1.5小时', '备用采集卡')
                });
            
            % 故障代码308
            db{end+1} = struct(...
                'fault_type', '数据传输中断型故障', ...
                'fault_code', '308', ...
                'fault_name', '测定值计算错误', ...
                'description', '计算过程错误', ...
                'severity', '中等', ...
                'priority', 2, ...
                'maintenance_measures', {
                    obj.createMeasure(1, '重启处理程序', '5分钟', '无');
                    obj.createMeasure(2, '检查CPU内存', '10分钟', '监控软件');
                    obj.createMeasure(3, '清理系统缓存', '15分钟', '清理工具');
                    obj.createMeasure(4, '重装固件程序', '45分钟', '固件包');
                    obj.createMeasure(5, '更换处理器板', '2小时', '备用板')
                });
            
            % 故障代码318
            db{end+1} = struct(...
                'fault_type', '数据传输中断型故障', ...
                'fault_code', '318', ...
                'fault_name', 'ADC无新测量', ...
                'description', 'ADC无新数据', ...
                'severity', '严重', ...
                'priority', 1, ...
                'maintenance_measures', {
                    obj.createMeasure(1, '检查触发信号', '10分钟', '示波器');
                    obj.createMeasure(2, '检查时钟信号', '15分钟', '示波器');
                    obj.createMeasure(3, '重配采样参数', '20分钟', '配置软件');
                    obj.createMeasure(4, '更换时钟芯片', '45分钟', '备用芯片');
                    obj.createMeasure(5, '更换ADC模块', '1.5小时', '备用模块')
                });
            
            % 故障代码332-337
            db{end+1} = struct(...
                'fault_type', '数据传输中断型故障', ...
                'fault_code', '332-337', ...
                'fault_name', 'I/O板故障', ...
                'description', 'I/O板硬件问题', ...
                'severity', '中等', ...
                'priority', 2, ...
                'maintenance_measures', {
                    obj.createMeasure(1, '检查I/O板指示灯', '5分钟', '无');
                    obj.createMeasure(2, '检查I/O配置', '15分钟', '配置软件');
                    obj.createMeasure(3, '测试I/O通道', '30分钟', '万用表');
                    obj.createMeasure(4, '初始化I/O板', '20分钟', '初始化工具');
                    obj.createMeasure(5, '更换I/O板', '1小时', '备用板')
                });
            
            % 故障代码338-339
            db{end+1} = struct(...
                'fault_type', '数据传输中断型故障', ...
                'fault_code', '338-339', ...
                'fault_name', '模拟线路故障', ...
                'description', '线路断裂或短路', ...
                'severity', '严重', ...
                'priority', 1, ...
                'maintenance_measures', {
                    obj.createMeasure(1, '检查接线端子', '10分钟', '螺丝刀');
                    obj.createMeasure(2, '测量线路通断', '15分钟', '万用表');
                    obj.createMeasure(3, '检查屏蔽接地', '20分钟', '接地测试仪');
                    obj.createMeasure(4, '更换信号电缆', '30分钟', '备用电缆');
                    obj.createMeasure(5, '重新布线', '2小时', '布线工具')
                });
            
            % ========== 数据保持型故障 ==========
            
            % 故障代码301
            db{end+1} = struct(...
                'fault_type', '数据保持型故障', ...
                'fault_code', '301', ...
                'fault_name', '超出ADC阈值', ...
                'description', '超出ADC范围', ...
                'severity', '中等', ...
                'priority', 2, ...
                'maintenance_measures', {
                    obj.createMeasure(1, '确认实际浓度', '5分钟', '便携式分析仪');
                    obj.createMeasure(2, '检查量程设置', '10分钟', '配置软件');
                    obj.createMeasure(3, '调整信号衰减', '20分钟', '调节工具');
                    obj.createMeasure(4, '重选测量量程', '30分钟', '配置软件');
                    obj.createMeasure(5, '更换大量程传感器', '2小时', '备用传感器')
                });
            
            % 故障代码344
            db{end+1} = struct(...
                'fault_type', '数据保持型故障', ...
                'fault_code', '344', ...
                'fault_name', '超上限130%', ...
                'description', '超过量程130%', ...
                'severity', '严重', ...
                'priority', 1, ...
                'maintenance_measures', {
                    obj.createMeasure(1, '检查工艺异常', '5分钟', '工艺参数表');
                    obj.createMeasure(2, '检查空气泄漏', '15分钟', '检漏仪');
                    obj.createMeasure(3, '检查传感器饱和', '20分钟', '测试仪');
                    obj.createMeasure(4, '切换高量程', '30分钟', '配置软件');
                    obj.createMeasure(5, '更换高量程传感器', '2小时', '备用传感器')
                });
            
            % 故障代码345
            db{end+1} = struct(...
                'fault_type', '数据保持型故障', ...
                'fault_code', '345', ...
                'fault_name', '低于下限-100%', ...
                'description', '低于量程-100%', ...
                'severity', '严重', ...
                'priority', 1, ...
                'maintenance_measures', {
                    obj.createMeasure(1, '检查传感器接线', '10分钟', '接线图');
                    obj.createMeasure(2, '检查信号电路', '20分钟', '万用表');
                    obj.createMeasure(3, '验证零点设置', '30分钟', '零点气体');
                    obj.createMeasure(4, '重新标定', '45分钟', '标准气体');
                    obj.createMeasure(5, '更换传感器信号板', '2小时', '备件')
                });
            
            % ========== 数据波动型故障 ==========
            
            % 故障代码312
            db{end+1} = struct(...
                'fault_type', '数据波动型故障', ...
                'fault_code', '312', ...
                'fault_name', '压力修正失效', ...
                'description', '压力测量错误', ...
                'severity', '中等', ...
                'priority', 2, ...
                'maintenance_measures', {
                    obj.createMeasure(1, '检查压力传感器', '10分钟', '压力表');
                    obj.createMeasure(2, '检查压力管路', '15分钟', '检漏仪');
                    obj.createMeasure(3, '校准压力传感器', '30分钟', '标准压力源');
                    obj.createMeasure(4, '检查补偿算法', '20分钟', '配置软件');
                    obj.createMeasure(5, '更换压力传感器', '1小时', '备用传感器')
                });
            
            % 外部因素EXT-01
            db{end+1} = struct(...
                'fault_type', '数据波动型故障', ...
                'fault_code', 'EXT-01', ...
                'fault_name', '管路污染堵塞', ...
                'description', '管道或过滤器问题', ...
                'severity', '中等', ...
                'priority', 2, ...
                'maintenance_measures', {
                    obj.createMeasure(1, '检查过滤器压差', '5分钟', '压差表');
                    obj.createMeasure(2, '更换过滤器', '20分钟', '备用滤芯');
                    obj.createMeasure(3, '吹扫采样管路', '30分钟', '压缩空气');
                    obj.createMeasure(4, '检查管路泄漏', '45分钟', '检漏仪');
                    obj.createMeasure(5, '更换采样管路', '2小时', '备用管路')
                });
            
            % 外部因素EXT-02
            db{end+1} = struct(...
                'fault_type', '数据波动型故障', ...
                'fault_code', 'EXT-02', ...
                'fault_name', '气路扭结泄漏', ...
                'description', '气路系统问题', ...
                'severity', '中等', ...
                'priority', 2, ...
                'maintenance_measures', {
                    obj.createMeasure(1, '检查管路扭结', '5分钟', '手电筒');
                    obj.createMeasure(2, '检查流量', '10分钟', '流量计');
                    obj.createMeasure(3, '逐段检漏', '30分钟', '检漏仪');
                    obj.createMeasure(4, '紧固接头', '20分钟', '扳手');
                    obj.createMeasure(5, '重装气路', '3小时', '全套管路')
                });
        end
        
        function measure = createMeasure(obj, level, desc, time, tools)
            % 创建维护措施结构
            % 输入验证
            if nargin < 5
                error('需要提供所有必需参数：level, desc, time, tools');
            end
            
            if ~isnumeric(level) || level < 1 || level > 5
                error('维护级别必须在1-5之间');
            end
            
            if isempty(desc) || isempty(time) || isempty(tools)
                error('措施描述、时间和工具不能为空');
            end
            
            measure = struct(...
                'level', level, ...
                'measure', desc, ...
                'time', time, ...
                'tools', tools);
        end
        
        function [fault_info, measures] = getFaultInfo(obj, fault_type, fault_code)
            % 根据故障类型和代码获取故障信息
            % 输入验证
            if nargin < 2
                error('需要提供故障类型参数');
            end
            
            if nargin < 3
                fault_code = '';
            end
            
            if isempty(fault_type)
                error('故障类型不能为空');
            end
            
            fault_info = [];
            measures = {};
            
            % 使用精确匹配而不是contains
            for i = 1:length(obj.faultDatabase)
                if strcmp(obj.faultDatabase{i}.fault_type, fault_type)
                    if ~isempty(fault_code) && strcmp(obj.faultDatabase{i}.fault_code, fault_code)
                        fault_info = obj.faultDatabase{i};
                        measures = fault_info.maintenance_measures;
                        break;
                    elseif isempty(fault_code)
                        % 返回该类型的第一个故障
                        fault_info = obj.faultDatabase{i};
                        measures = fault_info.maintenance_measures;
                        break;
                    end
                end
            end
            
            if isempty(fault_info)
                fprintf('未找到匹配的故障信息\n');
            end
        end
        
        function fault_info = getFaultByCode(obj, fault_code)
            % 根据故障代码直接获取故障信息（新增方法）
            % 输入验证
            if nargin < 2 || isempty(fault_code)
                error('需要提供故障代码');
            end
            
            fault_info = [];
            
            for i = 1:length(obj.faultDatabase)
                if strcmp(obj.faultDatabase{i}.fault_code, fault_code)
                    fault_info = obj.faultDatabase{i};
                    break;
                end
            end
            
            if isempty(fault_info)
                fprintf('未找到故障代码 %s 的信息\n', fault_code);
            end
        end
        
        function displayFaultInfo(obj, fault_info, measures)
            % 显示故障信息和维护建议
            if isempty(fault_info)
                fprintf('没有可显示的故障信息\n');
                return;
            end
            
            fprintf('\n========================================\n');
            fprintf('故障诊断与维护建议\n');
            fprintf('========================================\n');
            fprintf('故障类型: %s\n', fault_info.fault_type);
            fprintf('故障代码: %s\n', fault_info.fault_code);
            fprintf('故障名称: %s\n', fault_info.fault_name);
            fprintf('故障描述: %s\n', fault_info.description);
            fprintf('严重程度: %s\n', fault_info.severity);
            fprintf('优先级: %d\n\n', fault_info.priority);
            
            if nargin < 3 || isempty(measures)
                measures = fault_info.maintenance_measures;
            end
            
            fprintf('维护措施（从简单到复杂）:\n');
            fprintf('----------------------------------------\n');
            for i = 1:length(measures)
                m = measures{i};
                fprintf('%d. %s\n', m.level, m.measure);
                fprintf('   预计时间: %s\n', m.time);
                fprintf('   所需工具: %s\n', m.tools);
                fprintf('----------------------------------------\n');
            end
        end
        
        function logMaintenance(obj, fault_code, actual_measure, result, timestamp)
            % 记录实际维护情况
            % 输入验证
            if nargin < 4
                error('需要提供故障代码、维护措施和结果');
            end
            
            if nargin < 5
                timestamp = now;
            end
            
            if isempty(fault_code) || isempty(actual_measure) || isempty(result)
                error('故障代码、维护措施和结果不能为空');
            end
            
            % 验证故障代码是否存在
            if ~obj.faultCodeToType.isKey(fault_code)
                warning('故障代码 %s 不在数据库中，但仍会记录维护日志', fault_code);
            end
            
            log_entry = struct(...
                'timestamp', timestamp, ...
                'fault_code', fault_code, ...
                'actual_measure', actual_measure, ...
                'result', result);
            
            obj.maintenanceLog{end+1} = log_entry;
            
            % 生成安全的字段名
            field_name = ['fault_' fault_code];
            field_name = regexprep(field_name, '[^a-zA-Z0-9_]', '_');
            
            if ~isfield(obj.statisticsData, field_name)
                obj.statisticsData = setfield(obj.statisticsData, field_name, struct(...
                    'count', 0, ...
                    'success_rate', 0, ...
                    'total_time', 0, ...
                    'last_occurrence', timestamp));
            end
            
            % 更新统计数据 - 使用更安全的方式
            current_struct = getfield(obj.statisticsData, field_name);
            current_struct.count = current_struct.count + 1;
            current_struct.last_occurrence = timestamp;
            obj.statisticsData = setfield(obj.statisticsData, field_name, current_struct);
            
            fprintf('维护记录已保存\n');
        end
        
        function addCustomMeasure(obj, fault_code, measure_desc, time, tools)
            % 添加用户自定义维护措施
            % 输入验证
            if nargin < 5
                error('需要提供所有必需参数：fault_code, measure_desc, time, tools');
            end
            
            if isempty(fault_code) || isempty(measure_desc) || isempty(time) || isempty(tools)
                error('所有参数都不能为空');
            end
            
            custom = struct(...
                'fault_code', fault_code, ...
                'measure', measure_desc, ...
                'time', time, ...
                'tools', tools, ...
                'added_date', datestr(now));
            
            obj.customMeasures{end+1} = custom;
            fprintf('自定义维护措施已添加\n');
        end
        
        function report = generateStatisticsReport(obj)
            % 生成故障统计分析报告（优化版本）
            fprintf('\n========================================\n');
            fprintf('故障统计分析报告\n');
            fprintf('========================================\n');
            fprintf('生成时间: %s\n\n', datestr(now));
            
            if isempty(obj.maintenanceLog)
                fprintf('暂无维护记录\n');
                report = struct('timestamp', datestr(now), 'total_logs', 0);
                return;
            end
            
            % 统计各故障类型
            fault_types = {'数据偏差型故障', '数据传输中断型故障', ...
                          '数据保持型故障', '数据波动型故障'};
            
            type_stats = containers.Map();
            for i = 1:length(fault_types)
                type_stats(fault_types{i}) = struct('count', 0, 'codes', {});
            end
            
            % 统计故障代码
            code_stats = containers.Map();
            
            for j = 1:length(obj.maintenanceLog)
                log_code = obj.maintenanceLog{j}.fault_code;
                
                % 统计故障代码
                if code_stats.isKey(log_code)
                    code_stats(log_code) = code_stats(log_code) + 1;
                else
                    code_stats(log_code) = 1;
                end
                
                % 统计故障类型
                if obj.faultCodeToType.isKey(log_code)
                    fault_type = obj.faultCodeToType(log_code);
                    if type_stats.isKey(fault_type)
                        type_stats(fault_type).count = type_stats(fault_type).count + 1;
                        type_stats(fault_type).codes{end+1} = log_code;
                    end
                end
            end
            
            % 显示统计结果
            for i = 1:length(fault_types)
                type_name = fault_types{i};
                stats = type_stats(type_name);
                fprintf('%s: %d次\n', type_name, stats.count);
                
                if stats.count > 0
                    unique_codes = unique(stats.codes);
                    for c = 1:length(unique_codes)
                        code = unique_codes{c};
                        count = sum(strcmp(stats.codes, code));
                        fprintf('  - 故障代码%s: %d次\n', code, count);
                    end
                end
                fprintf('\n');
            end
            
            % 显示最频繁的故障
            if ~isempty(code_stats)
                fprintf('最频繁故障TOP5:\n');
                fprintf('----------------------------------------\n');
                codes = code_stats.keys;
                counts = cell2mat(code_stats.values);
                [~, idx] = sort(counts, 'descend');
                
                for i = 1:min(5, length(codes))
                    fprintf('%d. %s: %d次\n', i, codes{idx(i)}, counts(idx(i)));
                end
                fprintf('\n');
            end
            
            % 预测性维护建议
            fprintf('预测性维护建议:\n');
            fprintf('----------------------------------------\n');
            
            total_logs = length(obj.maintenanceLog);
            if total_logs > 20
                fprintf('1. 系统故障频率较高，建议立即进行全面检查\n');
                fprintf('2. 增加预防性维护频率\n');
                fprintf('3. 准备充足备件库存\n');
                fprintf('4. 加强人员培训\n');
            elseif total_logs > 10
                fprintf('1. 建议增加预防性维护频率\n');
                fprintf('2. 准备常见故障备件\n');
                fprintf('3. 加强人员培训\n');
            elseif total_logs > 5
                fprintf('1. 建议建立定期维护计划\n');
                fprintf('2. 储备基本维护工具\n');
            else
                fprintf('1. 系统运行良好\n');
                fprintf('2. 继续保持常规维护\n');
            end
            
            fprintf('----------------------------------------\n\n');
            
            % 返回报告
            report = struct(...
                'timestamp', datestr(now), ...
                'total_logs', total_logs, ...
                'custom_measures', length(obj.customMeasures), ...
                'fault_types', type_stats, ...
                'fault_codes', code_stats);
        end
        
        function exportToExcel(obj, filename)
            % 导出维护记录到Excel
            % 输入验证
            if nargin < 2
                filename = sprintf('maintenance_log_%s.xlsx', datestr(now, 'yyyymmdd_HHMMSS'));
            end
            
            if isempty(obj.maintenanceLog)
                fprintf('没有维护记录可导出\n');
                return;
            end
            
            % 准备数据
            data_cell = {};
            for i = 1:length(obj.maintenanceLog)
                log = obj.maintenanceLog{i};
                data_cell{i,1} = datestr(log.timestamp);
                data_cell{i,2} = log.fault_code;
                data_cell{i,3} = log.actual_measure;
                data_cell{i,4} = log.result;
            end
            
            % 创建表格
            T = table(data_cell(:,1), data_cell(:,2), data_cell(:,3), data_cell(:,4), ...
                     'VariableNames', {'时间', '故障代码', '维护措施', '结果'});
            
            % 写入Excel
            try
                writetable(T, filename);
                fprintf('维护记录已导出到: %s\n', filename);
            catch ME
                fprintf('导出失败: %s\n', ME.message);
                fprintf('尝试导出为CSV格式...\n');
                try
                    csv_filename = strrep(filename, '.xlsx', '.csv');
                    writetable(T, csv_filename);
                    fprintf('维护记录已导出到: %s\n', csv_filename);
                catch ME2
                    fprintf('CSV导出也失败: %s\n', ME2.message);
                end
            end
        end
        
        function searchFaults(obj, keyword)
            % 搜索故障信息（新增方法）
            % 输入验证
            if nargin < 2 || isempty(keyword)
                error('需要提供搜索关键词');
            end
            
            fprintf('\n搜索关键词: "%s"\n', keyword);
            fprintf('========================================\n');
            
            found_count = 0;
            for i = 1:length(obj.faultDatabase)
                fault = obj.faultDatabase{i};
                
                % 在故障名称、描述中搜索
                if contains(fault.fault_name, keyword, 'IgnoreCase', true) || ...
                   contains(fault.description, keyword, 'IgnoreCase', true) || ...
                   contains(fault.fault_code, keyword, 'IgnoreCase', true)
                    
                    found_count = found_count + 1;
                    fprintf('%d. [%s] %s\n', found_count, fault.fault_code, fault.fault_name);
                    fprintf('   类型: %s\n', fault.fault_type);
                    fprintf('   描述: %s\n', fault.description);
                    fprintf('   严重程度: %s\n\n', fault.severity);
                end
            end
            
            if found_count == 0
                fprintf('未找到匹配的故障信息\n');
            else
                fprintf('共找到 %d 条匹配记录\n', found_count);
            end
        end
        
        function listAllFaults(obj)
            % 列出所有故障信息（新增方法）
            fprintf('\n所有故障信息列表\n');
            fprintf('========================================\n');
            
            fault_types = {'数据偏差型故障', '数据传输中断型故障', ...
                          '数据保持型故障', '数据波动型故障'};
            
            for t = 1:length(fault_types)
                fprintf('\n【%s】\n', fault_types{t});
                fprintf('----------------------------------------\n');
                
                count = 0;
                for i = 1:length(obj.faultDatabase)
                    if strcmp(obj.faultDatabase{i}.fault_type, fault_types{t})
                        count = count + 1;
                        fault = obj.faultDatabase{i};
                        fprintf('%d. [%s] %s\n', count, fault.fault_code, fault.fault_name);
                        fprintf('   严重程度: %s, 优先级: %d\n', fault.severity, fault.priority);
                    end
                end
                
                if count == 0
                    fprintf('暂无此类故障\n');
                end
            end
            
            fprintf('\n总计: %d 条故障记录\n', length(obj.faultDatabase));
        end
        
        function backupData(obj, backup_filename)
            % 备份数据（新增方法）
            if nargin < 2
                backup_filename = sprintf('fault_kb_backup_%s.mat', datestr(now, 'yyyymmdd_HHMMSS'));
            end
            
            backup_data = struct(...
                'faultDatabase', obj.faultDatabase, ...
                'maintenanceLog', obj.maintenanceLog, ...
                'statisticsData', obj.statisticsData, ...
                'customMeasures', obj.customMeasures, ...
                'backup_time', now);
            
            try
                save(backup_filename, 'backup_data');
                fprintf('数据已备份到: %s\n', backup_filename);
            catch ME
                fprintf('备份失败: %s\n', ME.message);
            end
        end
        
        function loadData(obj, backup_filename)
            % 加载备份数据（新增方法）
            if nargin < 2
                error('需要提供备份文件名');
            end
            
            if ~exist(backup_filename, 'file')
                error('备份文件不存在: %s', backup_filename);
            end
            
            try
                load(backup_filename, 'backup_data');
                obj.faultDatabase = backup_data.faultDatabase;
                obj.maintenanceLog = backup_data.maintenanceLog;
                obj.statisticsData = backup_data.statisticsData;
                obj.customMeasures = backup_data.customMeasures;
                obj.buildFaultCodeMapping();
                fprintf('数据已从 %s 加载\n', backup_filename);
            catch ME
                fprintf('加载失败: %s\n', ME.message);
            end
        end
        
    end  % methods
    
end  % classdef