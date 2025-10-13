#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
故障诊断维修记录数据库生成器
生成5年的模拟故障维修记录并导出为Excel文件
"""

import pandas as pd
import random
from datetime import datetime, timedelta
import numpy as np

class FaultDatabase:
    """故障数据库类，包含所有故障代码和对应的维修措施"""
    
    def __init__(self):
        self.fault_db = self._initialize_database()
    
    def _create_measure(self, step, operation, duration, tools):
        """创建维修措施记录"""
        return {
            'step': step,
            'operation': operation,
            'duration': duration,
            'tools': tools
        }
    
    def _initialize_database(self):
        """初始化故障数据库"""
        db = {}
        
        # ========== 数据偏差型故障 ==========
        
        # 故障代码302
        db['302'] = {
            'fault_type': '数据偏差型故障',
            'fault_code': '302',
            'fault_name': '零点漂移超过允许范围50%',
            'description': '偏差漂移超过了允许范围的一半（±0.75vol%O2）',
            'severity': '中等',
            'priority': 2,
            'maintenance_measures': [
                self._create_measure(1, '检查传感器表面污染', '10分钟', '清洁布、酒精'),
                self._create_measure(2, '检查采样管路冷凝水', '15分钟', '排水工具'),
                self._create_measure(3, '执行零点校准程序', '30分钟', '标准气体'),
                self._create_measure(4, '检查传感器老化程度', '1小时', '测试设备'),
                self._create_measure(5, '更换传感器模块', '2小时', '备用传感器')
            ]
        }
        
        # 故障代码303
        db['303'] = {
            'fault_type': '数据偏差型故障',
            'fault_code': '303',
            'fault_name': '零点漂移超出允许范围',
            'description': '偏差漂移超出允许范围（±1.5vol%O2）',
            'severity': '严重',
            'priority': 1,
            'maintenance_measures': [
                self._create_measure(1, '立即检查传感器状态灯', '5分钟', '无'),
                self._create_measure(2, '检查供电电压24V DC', '10分钟', '万用表'),
                self._create_measure(3, '紧急执行零点量程校准', '45分钟', '标准气体'),
                self._create_measure(4, '检查传感器参比电极', '1.5小时', '专用检测仪'),
                self._create_measure(5, '立即更换传感器', '2小时', '备用传感器')
            ]
        }
        
        # 故障代码304
        db['304'] = {
            'fault_type': '数据偏差型故障',
            'fault_code': '304',
            'fault_name': '灵敏度漂移超出50%',
            'description': '放大漂移超出允许范围的50%',
            'severity': '中等',
            'priority': 2,
            'maintenance_measures': [
                self._create_measure(1, '检查测量池窗片清洁度', '15分钟', '清洁工具'),
                self._create_measure(2, '检查光源强度稳定性', '20分钟', '光强测试仪'),
                self._create_measure(3, '执行量程标定', '40分钟', '量程气体'),
                self._create_measure(4, '检查检测器响应曲线', '1小时', '测试设备'),
                self._create_measure(5, '更换检测器组件', '2小时', '备用检测器')
            ]
        }
        
        # 故障代码305
        db['305'] = {
            'fault_type': '数据偏差型故障',
            'fault_code': '305',
            'fault_name': '灵敏度漂移超出允许范围',
            'description': '放大漂移超出允许范围',
            'severity': '严重',
            'priority': 1,
            'maintenance_measures': [
                self._create_measure(1, '停止测量检查报警', '5分钟', '无'),
                self._create_measure(2, '清洁所有光学元件', '30分钟', '光学清洁套装'),
                self._create_measure(3, '执行完整系统标定', '1小时', '多种标准气体'),
                self._create_measure(4, '调整光路对准', '1.5小时', '光路调整工具'),
                self._create_measure(5, '更换光源和检测器', '3小时', '备件')
            ]
        }
        
        # 故障代码319
        db['319'] = {
            'fault_type': '数据偏差型故障',
            'fault_code': '319',
            'fault_name': '磁力测量回路失衡',
            'description': '磁力式传感器测量回路信号失去平衡',
            'severity': '严重',
            'priority': 1,
            'maintenance_measures': [
                self._create_measure(1, '检查磁场线圈连接', '10分钟', '万用表'),
                self._create_measure(2, '测量磁力传感器输出', '20分钟', '示波器'),
                self._create_measure(3, '调节信号调理电路', '30分钟', '调试设备'),
                self._create_measure(4, '更换磁力传感器', '1小时', '备用传感器'),
                self._create_measure(5, '更换传感器电路板', '2小时', '备用电路板')
            ]
        }
        
        # 故障代码320
        db['320'] = {
            'fault_type': '数据偏差型故障',
            'fault_code': '320',
            'fault_name': '测定放大偏差过高',
            'description': '信号放大器偏差超出正常范围',
            'severity': '中等',
            'priority': 2,
            'maintenance_measures': [
                self._create_measure(1, '检查放大器供电', '10分钟', '万用表'),
                self._create_measure(2, '调整放大器零点增益', '25分钟', '示波器'),
                self._create_measure(3, '更换运放芯片', '45分钟', '备用芯片'),
                self._create_measure(4, '检查信号链路', '1小时', '信号发生器'),
                self._create_measure(5, '更换放大器板', '1.5小时', '备用电路板')
            ]
        }
        
        # 故障代码309-311
        db['309-311'] = {
            'fault_type': '数据偏差型故障',
            'fault_code': '309-311',
            'fault_name': '温度调节器失效',
            'description': '温度控制超出范围',
            'severity': '中等',
            'priority': 2,
            'maintenance_measures': [
                self._create_measure(1, '检查温度传感器', '10分钟', '温度计'),
                self._create_measure(2, '检查加热冷却器', '20分钟', '万用表'),
                self._create_measure(3, '校准PID参数', '40分钟', '调试软件'),
                self._create_measure(4, '更换温度传感器', '1小时', '备用传感器'),
                self._create_measure(5, '更换温控模块', '2小时', '备用模块')
            ]
        }
        
        # ========== 数据传输中断型故障 ==========
        
        # 故障代码101
        db['101'] = {
            'fault_type': '数据传输中断型故障',
            'fault_code': '101',
            'fault_name': '系统控制器关停',
            'description': '主控制器停止工作',
            'severity': '紧急',
            'priority': 1,
            'maintenance_measures': [
                self._create_measure(1, '检查主电源保险丝', '5分钟', '万用表'),
                self._create_measure(2, '检查24V电源输出', '10分钟', '万用表'),
                self._create_measure(3, '重启控制器系统', '15分钟', '无'),
                self._create_measure(4, '检查CPU和内存', '30分钟', '诊断软件'),
                self._create_measure(5, '更换控制器主板', '2小时', '备用主板')
            ]
        }
        
        # 故障代码116
        db['116'] = {
            'fault_type': '数据传输中断型故障',
            'fault_code': '116',
            'fault_name': 'Profibus安装错误',
            'description': 'Profibus模块安装位置错误',
            'severity': '中等',
            'priority': 3,
            'maintenance_measures': [
                self._create_measure(1, '确认安装位置', '5分钟', '无'),
                self._create_measure(2, '重装到X20/X21槽', '15分钟', '螺丝刀'),
                self._create_measure(3, '重配通讯参数', '20分钟', '配置软件'),
                self._create_measure(4, '测试通讯连接', '30分钟', 'Profibus测试仪'),
                self._create_measure(5, '更换Profibus模块', '1小时', '备用模块')
            ]
        }
        
        # 故障代码201-209
        db['201-209'] = {
            'fault_type': '数据传输中断型故障',
            'fault_code': '201-209',
            'fault_name': '系统总线连接中断',
            'description': '系统总线通讯中断',
            'severity': '严重',
            'priority': 1,
            'maintenance_measures': [
                self._create_measure(1, '检查总线电缆', '10分钟', '无'),
                self._create_measure(2, '检查终端电阻', '15分钟', '万用表'),
                self._create_measure(3, '更换总线电缆', '30分钟', '备用电缆'),
                self._create_measure(4, '检查模块供电', '20分钟', '万用表'),
                self._create_measure(5, '更换通讯模块', '1小时', '备用模块')
            ]
        }
        
        # 故障代码300
        db['300'] = {
            'fault_type': '数据传输中断型故障',
            'fault_code': '300',
            'fault_name': '模数转换器无输出',
            'description': 'ADC无新测量值',
            'severity': '严重',
            'priority': 1,
            'maintenance_measures': [
                self._create_measure(1, '检查ADC供电', '10分钟', '万用表'),
                self._create_measure(2, '检查模拟输入', '15分钟', '示波器'),
                self._create_measure(3, '重置ADC芯片', '20分钟', '复位工具'),
                self._create_measure(4, '更换ADC芯片', '1小时', '备用芯片'),
                self._create_measure(5, '更换采集卡', '1.5小时', '备用采集卡')
            ]
        }
        
        # 故障代码308
        db['308'] = {
            'fault_type': '数据传输中断型故障',
            'fault_code': '308',
            'fault_name': '测定值计算错误',
            'description': '计算过程错误',
            'severity': '中等',
            'priority': 2,
            'maintenance_measures': [
                self._create_measure(1, '重启处理程序', '5分钟', '无'),
                self._create_measure(2, '检查CPU内存', '10分钟', '监控软件'),
                self._create_measure(3, '清理系统缓存', '15分钟', '清理工具'),
                self._create_measure(4, '重装固件程序', '45分钟', '固件包'),
                self._create_measure(5, '更换处理器板', '2小时', '备用板')
            ]
        }
        
        # 故障代码318
        db['318'] = {
            'fault_type': '数据传输中断型故障',
            'fault_code': '318',
            'fault_name': 'ADC无新测量',
            'description': 'ADC无新数据',
            'severity': '严重',
            'priority': 1,
            'maintenance_measures': [
                self._create_measure(1, '检查触发信号', '10分钟', '示波器'),
                self._create_measure(2, '检查时钟信号', '15分钟', '示波器'),
                self._create_measure(3, '重配采样参数', '20分钟', '配置软件'),
                self._create_measure(4, '更换时钟芯片', '45分钟', '备用芯片'),
                self._create_measure(5, '更换ADC模块', '1.5小时', '备用模块')
            ]
        }
        
        # 故障代码332-337
        db['332-337'] = {
            'fault_type': '数据传输中断型故障',
            'fault_code': '332-337',
            'fault_name': 'I/O板故障',
            'description': 'I/O板硬件问题',
            'severity': '中等',
            'priority': 2,
            'maintenance_measures': [
                self._create_measure(1, '检查I/O板指示灯', '5分钟', '无'),
                self._create_measure(2, '检查I/O配置', '15分钟', '配置软件'),
                self._create_measure(3, '测试I/O通道', '30分钟', '万用表'),
                self._create_measure(4, '初始化I/O板', '20分钟', '初始化工具'),
                self._create_measure(5, '更换I/O板', '1小时', '备用板')
            ]
        }
        
        # 故障代码338-339
        db['338-339'] = {
            'fault_type': '数据传输中断型故障',
            'fault_code': '338-339',
            'fault_name': '模拟线路故障',
            'description': '线路断裂或短路',
            'severity': '严重',
            'priority': 1,
            'maintenance_measures': [
                self._create_measure(1, '检查接线端子', '10分钟', '螺丝刀'),
                self._create_measure(2, '测量线路通断', '15分钟', '万用表'),
                self._create_measure(3, '检查屏蔽接地', '20分钟', '接地测试仪'),
                self._create_measure(4, '更换信号电缆', '30分钟', '备用电缆'),
                self._create_measure(5, '重新布线', '2小时', '布线工具')
            ]
        }
        
        # ========== 数据保持型故障 ==========
        
        # 故障代码301
        db['301'] = {
            'fault_type': '数据保持型故障',
            'fault_code': '301',
            'fault_name': '超出ADC阈值',
            'description': '超出ADC范围',
            'severity': '中等',
            'priority': 2,
            'maintenance_measures': [
                self._create_measure(1, '确认实际浓度', '5分钟', '便携式分析仪'),
                self._create_measure(2, '检查量程设置', '10分钟', '配置软件'),
                self._create_measure(3, '调整信号衰减', '20分钟', '调节工具'),
                self._create_measure(4, '重选测量量程', '30分钟', '配置软件'),
                self._create_measure(5, '更换大量程传感器', '2小时', '备用传感器')
            ]
        }
        
        # 故障代码344
        db['344'] = {
            'fault_type': '数据保持型故障',
            'fault_code': '344',
            'fault_name': '超上限130%',
            'description': '超过量程130%',
            'severity': '严重',
            'priority': 1,
            'maintenance_measures': [
                self._create_measure(1, '检查工艺异常', '5分钟', '工艺参数表'),
                self._create_measure(2, '检查空气泄漏', '15分钟', '检漏仪'),
                self._create_measure(3, '检查传感器饱和', '20分钟', '测试仪'),
                self._create_measure(4, '切换高量程', '30分钟', '配置软件'),
                self._create_measure(5, '更换高量程传感器', '2小时', '备用传感器')
            ]
        }
        
        # 故障代码345
        db['345'] = {
            'fault_type': '数据保持型故障',
            'fault_code': '345',
            'fault_name': '低于下限-100%',
            'description': '低于量程-100%',
            'severity': '严重',
            'priority': 1,
            'maintenance_measures': [
                self._create_measure(1, '检查传感器接线', '10分钟', '接线图'),
                self._create_measure(2, '检查信号电路', '20分钟', '万用表'),
                self._create_measure(3, '验证零点设置', '30分钟', '零点气体'),
                self._create_measure(4, '重新标定', '45分钟', '标准气体'),
                self._create_measure(5, '更换传感器信号板', '2小时', '备件')
            ]
        }
        
        # ========== 数据波动型故障 ==========
        
        # 故障代码312
        db['312'] = {
            'fault_type': '数据波动型故障',
            'fault_code': '312',
            'fault_name': '压力修正失效',
            'description': '压力测量错误',
            'severity': '中等',
            'priority': 2,
            'maintenance_measures': [
                self._create_measure(1, '检查压力传感器', '10分钟', '压力表'),
                self._create_measure(2, '检查压力管路', '15分钟', '检漏仪'),
                self._create_measure(3, '校准压力传感器', '30分钟', '标准压力源'),
                self._create_measure(4, '检查补偿算法', '20分钟', '配置软件'),
                self._create_measure(5, '更换压力传感器', '1小时', '备用传感器')
            ]
        }
        
        # 外部因素EXT-01
        db['EXT-01'] = {
            'fault_type': '数据波动型故障',
            'fault_code': 'EXT-01',
            'fault_name': '管路污染堵塞',
            'description': '管道或过滤器问题',
            'severity': '中等',
            'priority': 2,
            'maintenance_measures': [
                self._create_measure(1, '检查过滤器压差', '5分钟', '压差表'),
                self._create_measure(2, '更换过滤器', '20分钟', '备用滤芯'),
                self._create_measure(3, '吹扫采样管路', '30分钟', '压缩空气'),
                self._create_measure(4, '检查管路泄漏', '45分钟', '检漏仪'),
                self._create_measure(5, '更换采样管路', '2小时', '备用管路')
            ]
        }
        
        # 外部因素EXT-02
        db['EXT-02'] = {
            'fault_type': '数据波动型故障',
            'fault_code': 'EXT-02',
            'fault_name': '气路扭结泄漏',
            'description': '气路系统问题',
            'severity': '中等',
            'priority': 2,
            'maintenance_measures': [
                self._create_measure(1, '检查管路扭结', '5分钟', '手电筒'),
                self._create_measure(2, '检查流量', '10分钟', '流量计'),
                self._create_measure(3, '逐段检漏', '30分钟', '检漏仪'),
                self._create_measure(4, '紧固接头', '20分钟', '扳手'),
                self._create_measure(5, '重装气路', '3小时', '全套管路')
            ]
        }
        
        return db
    
    def get_fault_codes(self):
        """获取所有故障代码"""
        return list(self.fault_db.keys())
    
    def get_fault_info(self, fault_code):
        """获取指定故障代码的信息"""
        return self.fault_db.get(fault_code, None)
    
    def get_random_maintenance_measure(self, fault_code):
        """随机选择一个维修措施"""
        fault_info = self.get_fault_info(fault_code)
        if fault_info and fault_info['maintenance_measures']:
            return random.choice(fault_info['maintenance_measures'])
        return None


class FaultRecordGenerator:
    """故障记录生成器"""
    
    def __init__(self):
        self.fault_db = FaultDatabase()
        self.records = []
    
    def generate_random_datetime(self, start_date, end_date):
        """生成随机时间"""
        time_between = end_date - start_date
        days_between = time_between.days
        random_days = random.randrange(days_between)
        random_seconds = random.randrange(24 * 60 * 60)
        
        random_date = start_date + timedelta(days=random_days, seconds=random_seconds)
        return random_date.strftime('%Y-%m-%d %H:%M:%S')
    
    def generate_records(self, num_records=1000):
        """生成指定数量的故障记录"""
        print(f"开始生成 {num_records} 条故障维修记录...")
        
        # 设置5年时间范围
        start_date = datetime(2019, 1, 1)
        end_date = datetime(2024, 12, 31)
        
        fault_codes = self.fault_db.get_fault_codes()
        
        # 根据故障严重程度设置权重
        fault_weights = []
        for code in fault_codes:
            fault_info = self.fault_db.get_fault_info(code)
            if fault_info['severity'] == '紧急':
                weight = 1  # 紧急故障较少
            elif fault_info['severity'] == '严重':
                weight = 3
            elif fault_info['severity'] == '中等':
                weight = 5
            else:
                weight = 2
            fault_weights.append(weight)
        
        for i in range(num_records):
            # 根据权重随机选择故障代码
            fault_code = random.choices(fault_codes, weights=fault_weights, k=1)[0]
            fault_info = self.fault_db.get_fault_info(fault_code)
            
            # 随机选择维修措施
            maintenance_measure = self.fault_db.get_random_maintenance_measure(fault_code)
            
            if fault_info and maintenance_measure:
                record = {
                    '故障时间': self.generate_random_datetime(start_date, end_date),
                    '仪表故障代码': fault_code,
                    '故障描述/名称': fault_info['fault_name'],
                    '维修操作': maintenance_measure['operation'],
                    '耗时': maintenance_measure['duration'],
                    '工具': maintenance_measure['tools']
                }
                self.records.append(record)
            
            if (i + 1) % 100 == 0:
                print(f"已生成 {i + 1} 条记录...")
        
        # 按时间排序
        self.records.sort(key=lambda x: x['故障时间'])
        print(f"记录生成完成，共 {len(self.records)} 条记录")
        
        return self.records
    
    def export_to_excel(self, filename='故障诊断维修记录数据库.xlsx'):
        """导出到Excel文件"""
        if not self.records:
            print("没有记录可导出，请先生成记录")
            return
        
        print(f"正在导出到Excel文件: {filename}")
        
        # 创建DataFrame
        df = pd.DataFrame(self.records)
        
        # 导出到Excel
        with pd.ExcelWriter(filename, engine='openpyxl') as writer:
            df.to_excel(writer, sheet_name='故障维修记录', index=False)
            
            # 获取工作表以进行格式设置
            worksheet = writer.sheets['故障维修记录']
            
            # 调整列宽
            for column in worksheet.columns:
                max_length = 0
                column_letter = column[0].column_letter
                for cell in column:
                    try:
                        if len(str(cell.value)) > max_length:
                            max_length = len(str(cell.value))
                    except:
                        pass
                adjusted_width = min(max_length + 2, 50)
                worksheet.column_dimensions[column_letter].width = adjusted_width
        
        print(f"Excel文件导出成功: {filename}")
        return filename
    
    def print_statistics(self):
        """打印统计信息"""
        if not self.records:
            print("没有记录可统计")
            return
        
        print("\n=== 故障维修记录统计 ===")
        print(f"总记录数: {len(self.records)}")
        
        # 按故障代码统计
        fault_code_counts = {}
        fault_type_counts = {}
        
        for record in self.records:
            code = record['仪表故障代码']
            fault_code_counts[code] = fault_code_counts.get(code, 0) + 1
            
            fault_info = self.fault_db.get_fault_info(code)
            if fault_info:
                fault_type = fault_info['fault_type']
                fault_type_counts[fault_type] = fault_type_counts.get(fault_type, 0) + 1
        
        print(f"\n按故障类型统计:")
        for fault_type, count in sorted(fault_type_counts.items()):
            print(f"  {fault_type}: {count} 次")
        
        print(f"\n按故障代码统计 (前10名):")
        sorted_codes = sorted(fault_code_counts.items(), key=lambda x: x[1], reverse=True)
        for code, count in sorted_codes[:10]:
            fault_info = self.fault_db.get_fault_info(code)
            fault_name = fault_info['fault_name'] if fault_info else '未知'
            print(f"  {code} ({fault_name}): {count} 次")


def main():
    """主函数"""
    print("故障诊断维修记录数据库生成器")
    print("=" * 50)
    
    # 创建生成器
    generator = FaultRecordGenerator()
    
    # 生成记录 (可以调整记录数量)
    num_records = 2000  # 5年大约2000条记录
    generator.generate_records(num_records)
    
    # 打印统计信息
    generator.print_statistics()
    
    # 导出到Excel
    filename = generator.export_to_excel()
    
    print(f"\n任务完成！Excel文件已保存为: {filename}")


if __name__ == "__main__":
    main()