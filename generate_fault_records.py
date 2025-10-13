#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
故障诊断维修记录数据库生成器
生成5年的模拟故障维修记录并导出为Excel文件
"""

import random
from datetime import datetime, timedelta
import pandas as pd
from typing import List, Dict, Tuple

class MaintenanceMeasure:
    """维修措施类"""
    def __init__(self, step: int, operation: str, duration: str, tools: str):
        self.step = step
        self.operation = operation
        self.duration = duration
        self.tools = tools

class FaultCode:
    """故障代码类"""
    def __init__(self, fault_type: str, fault_code: str, fault_name: str, 
                 description: str, severity: str, priority: int, 
                 maintenance_measures: List[MaintenanceMeasure]):
        self.fault_type = fault_type
        self.fault_code = fault_code
        self.fault_name = fault_name
        self.description = description
        self.severity = severity
        self.priority = priority
        self.maintenance_measures = maintenance_measures

# 定义故障数据库
class FaultDatabase:
    """故障数据库"""
    def __init__(self):
        self.faults = self._initialize_database()
    
    def _initialize_database(self) -> Dict[str, FaultCode]:
        """初始化故障数据库"""
        db = {}
        
        # ========== 数据偏差型故障 ==========
        
        # 故障代码302
        db['302'] = FaultCode(
            fault_type='数据偏差型故障',
            fault_code='302',
            fault_name='零点漂移超过允许范围50%',
            description='偏差漂移超过了允许范围的一半（±0.75vol%O2）',
            severity='中等',
            priority=2,
            maintenance_measures=[
                MaintenanceMeasure(1, '检查传感器表面污染', '10分钟', '清洁布、酒精'),
                MaintenanceMeasure(2, '检查采样管路冷凝水', '15分钟', '排水工具'),
                MaintenanceMeasure(3, '执行零点校准程序', '30分钟', '标准气体'),
                MaintenanceMeasure(4, '检查传感器老化程度', '1小时', '测试设备'),
                MaintenanceMeasure(5, '更换传感器模块', '2小时', '备用传感器')
            ]
        )
        
        # 故障代码303
        db['303'] = FaultCode(
            fault_type='数据偏差型故障',
            fault_code='303',
            fault_name='零点漂移超出允许范围',
            description='偏差漂移超出允许范围（±1.5vol%O2）',
            severity='严重',
            priority=1,
            maintenance_measures=[
                MaintenanceMeasure(1, '立即检查传感器状态灯', '5分钟', '无'),
                MaintenanceMeasure(2, '检查供电电压24V DC', '10分钟', '万用表'),
                MaintenanceMeasure(3, '紧急执行零点量程校准', '45分钟', '标准气体'),
                MaintenanceMeasure(4, '检查传感器参比电极', '1.5小时', '专用检测仪'),
                MaintenanceMeasure(5, '立即更换传感器', '2小时', '备用传感器')
            ]
        )
        
        # 故障代码304
        db['304'] = FaultCode(
            fault_type='数据偏差型故障',
            fault_code='304',
            fault_name='灵敏度漂移超出50%',
            description='放大漂移超出允许范围的50%',
            severity='中等',
            priority=2,
            maintenance_measures=[
                MaintenanceMeasure(1, '检查测量池窗片清洁度', '15分钟', '清洁工具'),
                MaintenanceMeasure(2, '检查光源强度稳定性', '20分钟', '光强测试仪'),
                MaintenanceMeasure(3, '执行量程标定', '40分钟', '量程气体'),
                MaintenanceMeasure(4, '检查检测器响应曲线', '1小时', '测试设备'),
                MaintenanceMeasure(5, '更换检测器组件', '2小时', '备用检测器')
            ]
        )
        
        # 故障代码305
        db['305'] = FaultCode(
            fault_type='数据偏差型故障',
            fault_code='305',
            fault_name='灵敏度漂移超出允许范围',
            description='放大漂移超出允许范围',
            severity='严重',
            priority=1,
            maintenance_measures=[
                MaintenanceMeasure(1, '停止测量检查报警', '5分钟', '无'),
                MaintenanceMeasure(2, '清洁所有光学元件', '30分钟', '光学清洁套装'),
                MaintenanceMeasure(3, '执行完整系统标定', '1小时', '多种标准气体'),
                MaintenanceMeasure(4, '调整光路对准', '1.5小时', '光路调整工具'),
                MaintenanceMeasure(5, '更换光源和检测器', '3小时', '备件')
            ]
        )
        
        # 故障代码319
        db['319'] = FaultCode(
            fault_type='数据偏差型故障',
            fault_code='319',
            fault_name='磁力测量回路失衡',
            description='磁力式传感器测量回路信号失去平衡',
            severity='严重',
            priority=1,
            maintenance_measures=[
                MaintenanceMeasure(1, '检查磁场线圈连接', '10分钟', '万用表'),
                MaintenanceMeasure(2, '测量磁力传感器输出', '20分钟', '示波器'),
                MaintenanceMeasure(3, '调节信号调理电路', '30分钟', '调试设备'),
                MaintenanceMeasure(4, '更换磁力传感器', '1小时', '备用传感器'),
                MaintenanceMeasure(5, '更换传感器电路板', '2小时', '备用电路板')
            ]
        )
        
        # 故障代码320
        db['320'] = FaultCode(
            fault_type='数据偏差型故障',
            fault_code='320',
            fault_name='测定放大偏差过高',
            description='信号放大器偏差超出正常范围',
            severity='中等',
            priority=2,
            maintenance_measures=[
                MaintenanceMeasure(1, '检查放大器供电', '10分钟', '万用表'),
                MaintenanceMeasure(2, '调整放大器零点增益', '25分钟', '示波器'),
                MaintenanceMeasure(3, '更换运放芯片', '45分钟', '备用芯片'),
                MaintenanceMeasure(4, '检查信号链路', '1小时', '信号发生器'),
                MaintenanceMeasure(5, '更换放大器板', '1.5小时', '备用电路板')
            ]
        )
        
        # 故障代码309-311
        db['309-311'] = FaultCode(
            fault_type='数据偏差型故障',
            fault_code='309-311',
            fault_name='温度调节器失效',
            description='温度控制超出范围',
            severity='中等',
            priority=2,
            maintenance_measures=[
                MaintenanceMeasure(1, '检查温度传感器', '10分钟', '温度计'),
                MaintenanceMeasure(2, '检查加热冷却器', '20分钟', '万用表'),
                MaintenanceMeasure(3, '校准PID参数', '40分钟', '调试软件'),
                MaintenanceMeasure(4, '更换温度传感器', '1小时', '备用传感器'),
                MaintenanceMeasure(5, '更换温控模块', '2小时', '备用模块')
            ]
        )
        
        # ========== 数据传输中断型故障 ==========
        
        # 故障代码101
        db['101'] = FaultCode(
            fault_type='数据传输中断型故障',
            fault_code='101',
            fault_name='系统控制器关停',
            description='主控制器停止工作',
            severity='紧急',
            priority=1,
            maintenance_measures=[
                MaintenanceMeasure(1, '检查主电源保险丝', '5分钟', '万用表'),
                MaintenanceMeasure(2, '检查24V电源输出', '10分钟', '万用表'),
                MaintenanceMeasure(3, '重启控制器系统', '15分钟', '无'),
                MaintenanceMeasure(4, '检查CPU和内存', '30分钟', '诊断软件'),
                MaintenanceMeasure(5, '更换控制器主板', '2小时', '备用主板')
            ]
        )
        
        # 故障代码116
        db['116'] = FaultCode(
            fault_type='数据传输中断型故障',
            fault_code='116',
            fault_name='Profibus安装错误',
            description='Profibus模块安装位置错误',
            severity='中等',
            priority=3,
            maintenance_measures=[
                MaintenanceMeasure(1, '确认安装位置', '5分钟', '无'),
                MaintenanceMeasure(2, '重装到X20/X21槽', '15分钟', '螺丝刀'),
                MaintenanceMeasure(3, '重配通讯参数', '20分钟', '配置软件'),
                MaintenanceMeasure(4, '测试通讯连接', '30分钟', 'Profibus测试仪'),
                MaintenanceMeasure(5, '更换Profibus模块', '1小时', '备用模块')
            ]
        )
        
        # 故障代码201-209
        db['201-209'] = FaultCode(
            fault_type='数据传输中断型故障',
            fault_code='201-209',
            fault_name='系统总线连接中断',
            description='系统总线通讯中断',
            severity='严重',
            priority=1,
            maintenance_measures=[
                MaintenanceMeasure(1, '检查总线电缆', '10分钟', '无'),
                MaintenanceMeasure(2, '检查终端电阻', '15分钟', '万用表'),
                MaintenanceMeasure(3, '更换总线电缆', '30分钟', '备用电缆'),
                MaintenanceMeasure(4, '检查模块供电', '20分钟', '万用表'),
                MaintenanceMeasure(5, '更换通讯模块', '1小时', '备用模块')
            ]
        )
        
        # 故障代码300
        db['300'] = FaultCode(
            fault_type='数据传输中断型故障',
            fault_code='300',
            fault_name='模数转换器无输出',
            description='ADC无新测量值',
            severity='严重',
            priority=1,
            maintenance_measures=[
                MaintenanceMeasure(1, '检查ADC供电', '10分钟', '万用表'),
                MaintenanceMeasure(2, '检查模拟输入', '15分钟', '示波器'),
                MaintenanceMeasure(3, '重置ADC芯片', '20分钟', '复位工具'),
                MaintenanceMeasure(4, '更换ADC芯片', '1小时', '备用芯片'),
                MaintenanceMeasure(5, '更换采集卡', '1.5小时', '备用采集卡')
            ]
        )
        
        # 故障代码308
        db['308'] = FaultCode(
            fault_type='数据传输中断型故障',
            fault_code='308',
            fault_name='测定值计算错误',
            description='计算过程错误',
            severity='中等',
            priority=2,
            maintenance_measures=[
                MaintenanceMeasure(1, '重启处理程序', '5分钟', '无'),
                MaintenanceMeasure(2, '检查CPU内存', '10分钟', '监控软件'),
                MaintenanceMeasure(3, '清理系统缓存', '15分钟', '清理工具'),
                MaintenanceMeasure(4, '重装固件程序', '45分钟', '固件包'),
                MaintenanceMeasure(5, '更换处理器板', '2小时', '备用板')
            ]
        )
        
        # 故障代码318
        db['318'] = FaultCode(
            fault_type='数据传输中断型故障',
            fault_code='318',
            fault_name='ADC无新测量',
            description='ADC无新数据',
            severity='严重',
            priority=1,
            maintenance_measures=[
                MaintenanceMeasure(1, '检查触发信号', '10分钟', '示波器'),
                MaintenanceMeasure(2, '检查时钟信号', '15分钟', '示波器'),
                MaintenanceMeasure(3, '重配采样参数', '20分钟', '配置软件'),
                MaintenanceMeasure(4, '更换时钟芯片', '45分钟', '备用芯片'),
                MaintenanceMeasure(5, '更换ADC模块', '1.5小时', '备用模块')
            ]
        )
        
        # 故障代码332-337
        db['332-337'] = FaultCode(
            fault_type='数据传输中断型故障',
            fault_code='332-337',
            fault_name='I/O板故障',
            description='I/O板硬件问题',
            severity='中等',
            priority=2,
            maintenance_measures=[
                MaintenanceMeasure(1, '检查I/O板指示灯', '5分钟', '无'),
                MaintenanceMeasure(2, '检查I/O配置', '15分钟', '配置软件'),
                MaintenanceMeasure(3, '测试I/O通道', '30分钟', '万用表'),
                MaintenanceMeasure(4, '初始化I/O板', '20分钟', '初始化工具'),
                MaintenanceMeasure(5, '更换I/O板', '1小时', '备用板')
            ]
        )
        
        # 故障代码338-339
        db['338-339'] = FaultCode(
            fault_type='数据传输中断型故障',
            fault_code='338-339',
            fault_name='模拟线路故障',
            description='线路断裂或短路',
            severity='严重',
            priority=1,
            maintenance_measures=[
                MaintenanceMeasure(1, '检查接线端子', '10分钟', '螺丝刀'),
                MaintenanceMeasure(2, '测量线路通断', '15分钟', '万用表'),
                MaintenanceMeasure(3, '检查屏蔽接地', '20分钟', '接地测试仪'),
                MaintenanceMeasure(4, '更换信号电缆', '30分钟', '备用电缆'),
                MaintenanceMeasure(5, '重新布线', '2小时', '布线工具')
            ]
        )
        
        # ========== 数据保持型故障 ==========
        
        # 故障代码301
        db['301'] = FaultCode(
            fault_type='数据保持型故障',
            fault_code='301',
            fault_name='超出ADC阈值',
            description='超出ADC范围',
            severity='中等',
            priority=2,
            maintenance_measures=[
                MaintenanceMeasure(1, '确认实际浓度', '5分钟', '便携式分析仪'),
                MaintenanceMeasure(2, '检查量程设置', '10分钟', '配置软件'),
                MaintenanceMeasure(3, '调整信号衰减', '20分钟', '调节工具'),
                MaintenanceMeasure(4, '重选测量量程', '30分钟', '配置软件'),
                MaintenanceMeasure(5, '更换大量程传感器', '2小时', '备用传感器')
            ]
        )
        
        # 故障代码344
        db['344'] = FaultCode(
            fault_type='数据保持型故障',
            fault_code='344',
            fault_name='超上限130%',
            description='超过量程130%',
            severity='严重',
            priority=1,
            maintenance_measures=[
                MaintenanceMeasure(1, '检查工艺异常', '5分钟', '工艺参数表'),
                MaintenanceMeasure(2, '检查空气泄漏', '15分钟', '检漏仪'),
                MaintenanceMeasure(3, '检查传感器饱和', '20分钟', '测试仪'),
                MaintenanceMeasure(4, '切换高量程', '30分钟', '配置软件'),
                MaintenanceMeasure(5, '更换高量程传感器', '2小时', '备用传感器')
            ]
        )
        
        # 故障代码345
        db['345'] = FaultCode(
            fault_type='数据保持型故障',
            fault_code='345',
            fault_name='低于下限-100%',
            description='低于量程-100%',
            severity='严重',
            priority=1,
            maintenance_measures=[
                MaintenanceMeasure(1, '检查传感器接线', '10分钟', '接线图'),
                MaintenanceMeasure(2, '检查信号电路', '20分钟', '万用表'),
                MaintenanceMeasure(3, '验证零点设置', '30分钟', '零点气体'),
                MaintenanceMeasure(4, '重新标定', '45分钟', '标准气体'),
                MaintenanceMeasure(5, '更换传感器信号板', '2小时', '备件')
            ]
        )
        
        # ========== 数据波动型故障 ==========
        
        # 故障代码312
        db['312'] = FaultCode(
            fault_type='数据波动型故障',
            fault_code='312',
            fault_name='压力修正失效',
            description='压力测量错误',
            severity='中等',
            priority=2,
            maintenance_measures=[
                MaintenanceMeasure(1, '检查压力传感器', '10分钟', '压力表'),
                MaintenanceMeasure(2, '检查压力管路', '15分钟', '检漏仪'),
                MaintenanceMeasure(3, '校准压力传感器', '30分钟', '标准压力源'),
                MaintenanceMeasure(4, '检查补偿算法', '20分钟', '配置软件'),
                MaintenanceMeasure(5, '更换压力传感器', '1小时', '备用传感器')
            ]
        )
        
        # 外部因素EXT-01
        db['EXT-01'] = FaultCode(
            fault_type='数据波动型故障',
            fault_code='EXT-01',
            fault_name='管路污染堵塞',
            description='管道或过滤器问题',
            severity='中等',
            priority=2,
            maintenance_measures=[
                MaintenanceMeasure(1, '检查过滤器压差', '5分钟', '压差表'),
                MaintenanceMeasure(2, '更换过滤器', '20分钟', '备用滤芯'),
                MaintenanceMeasure(3, '吹扫采样管路', '30分钟', '压缩空气'),
                MaintenanceMeasure(4, '检查管路泄漏', '45分钟', '检漏仪'),
                MaintenanceMeasure(5, '更换采样管路', '2小时', '备用管路')
            ]
        )
        
        # 外部因素EXT-02
        db['EXT-02'] = FaultCode(
            fault_type='数据波动型故障',
            fault_code='EXT-02',
            fault_name='气路扭结泄漏',
            description='气路系统问题',
            severity='中等',
            priority=2,
            maintenance_measures=[
                MaintenanceMeasure(1, '检查管路扭结', '5分钟', '手电筒'),
                MaintenanceMeasure(2, '检查流量', '10分钟', '流量计'),
                MaintenanceMeasure(3, '逐段检漏', '30分钟', '检漏仪'),
                MaintenanceMeasure(4, '紧固接头', '20分钟', '扳手'),
                MaintenanceMeasure(5, '重装气路', '3小时', '全套管路')
            ]
        )
        
        return db
    
    def get_all_fault_codes(self) -> List[str]:
        """获取所有故障代码"""
        return list(self.faults.keys())
    
    def get_fault(self, code: str) -> FaultCode:
        """获取指定故障代码的信息"""
        return self.faults.get(code)


class FaultRecordGenerator:
    """故障记录生成器"""
    def __init__(self, db: FaultDatabase, years: int = 5):
        self.db = db
        self.years = years
        self.start_date = datetime.now() - timedelta(days=365 * years)
        self.end_date = datetime.now()
    
    def generate_random_datetime(self) -> datetime:
        """生成随机日期时间"""
        time_between = self.end_date - self.start_date
        days_between = time_between.days
        random_days = random.randint(0, days_between)
        random_seconds = random.randint(0, 86400)
        
        random_date = self.start_date + timedelta(days=random_days, seconds=random_seconds)
        return random_date
    
    def generate_records(self, num_records: int = 1000) -> List[Dict]:
        """生成故障记录"""
        records = []
        fault_codes = self.db.get_all_fault_codes()
        
        # 根据故障优先级设置权重（优先级高的故障发生频率相对较低）
        weights = []
        for code in fault_codes:
            fault = self.db.get_fault(code)
            # 紧急/严重故障权重较低，中等故障权重较高
            if fault.severity == '紧急':
                weights.append(0.5)
            elif fault.severity == '严重':
                weights.append(1.0)
            else:
                weights.append(2.0)
        
        for _ in range(num_records):
            # 根据权重随机选择故障代码
            fault_code = random.choices(fault_codes, weights=weights, k=1)[0]
            fault = self.db.get_fault(fault_code)
            
            # 从维修措施中随机选择一项
            measure = random.choice(fault.maintenance_measures)
            
            # 生成随机时间
            fault_time = self.generate_random_datetime()
            
            # 创建记录
            record = {
                '故障时间': fault_time.strftime('%Y-%m-%d %H:%M:%S'),
                '仪表故障代码': fault.fault_code,
                '故障描述/名称': fault.fault_name,
                '故障类型': fault.fault_type,
                '严重程度': fault.severity,
                '维修操作': measure.operation,
                '耗时': measure.duration,
                '工具': measure.tools
            }
            
            records.append(record)
        
        # 按时间排序
        records.sort(key=lambda x: x['故障时间'])
        
        return records
    
    def export_to_excel(self, records: List[Dict], filename: str = '故障诊断维修记录.xlsx'):
        """导出记录到Excel文件"""
        df = pd.DataFrame(records)
        
        # 创建Excel写入器
        with pd.ExcelWriter(filename, engine='openpyxl') as writer:
            df.to_excel(writer, sheet_name='故障维修记录', index=False)
            
            # 获取工作表
            worksheet = writer.sheets['故障维修记录']
            
            # 调整列宽
            column_widths = {
                'A': 20,  # 故障时间
                'B': 15,  # 仪表故障代码
                'C': 30,  # 故障描述/名称
                'D': 20,  # 故障类型
                'E': 12,  # 严重程度
                'F': 35,  # 维修操作
                'G': 12,  # 耗时
                'H': 25   # 工具
            }
            
            for col, width in column_widths.items():
                worksheet.column_dimensions[col].width = width
        
        print(f"✅ 成功生成 {len(records)} 条故障记录")
        print(f"✅ Excel文件已保存：{filename}")
        
        # 打印统计信息
        self.print_statistics(records)
    
    def print_statistics(self, records: List[Dict]):
        """打印统计信息"""
        df = pd.DataFrame(records)
        
        print("\n" + "="*60)
        print("📊 故障记录统计信息")
        print("="*60)
        
        print(f"\n总记录数: {len(records)}")
        print(f"时间范围: {records[0]['故障时间']} 至 {records[-1]['故障时间']}")
        
        print("\n按故障类型统计:")
        print(df['故障类型'].value_counts())
        
        print("\n按严重程度统计:")
        print(df['严重程度'].value_counts())
        
        print("\n前10个高频故障代码:")
        print(df['仪表故障代码'].value_counts().head(10))
        
        print("\n按年份统计:")
        df_temp = df.copy()
        df_temp['年份'] = pd.to_datetime(df_temp['故障时间']).dt.year
        print(df_temp['年份'].value_counts().sort_index())


def main():
    """主函数"""
    print("="*60)
    print("故障诊断维修记录数据库生成器")
    print("="*60)
    
    # 初始化数据库
    print("\n正在初始化故障数据库...")
    db = FaultDatabase()
    print(f"✅ 已加载 {len(db.get_all_fault_codes())} 种故障代码")
    
    # 创建生成器
    generator = FaultRecordGenerator(db, years=5)
    
    # 生成记录（默认1000条，可以根据需要调整）
    print("\n正在生成故障记录...")
    num_records = 1500  # 5年约1500条记录，平均每年300条
    records = generator.generate_records(num_records=num_records)
    
    # 导出到Excel
    print("\n正在导出Excel文件...")
    generator.export_to_excel(records)
    
    print("\n" + "="*60)
    print("✅ 所有任务完成！")
    print("="*60)


if __name__ == "__main__":
    main()
