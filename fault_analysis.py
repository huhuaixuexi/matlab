#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
故障诊断维修记录分析系统
对故障记录进行全面的统计分析、效率分析、模式识别和预测分析
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime, timedelta
import warnings
from scipy import stats
from sklearn.preprocessing import LabelEncoder
from sklearn.cluster import KMeans
from sklearn.linear_model import LinearRegression
import matplotlib.font_manager as fm

# 设置中文字体
plt.rcParams['font.sans-serif'] = ['DejaVu Sans']
plt.rcParams['axes.unicode_minus'] = False
warnings.filterwarnings('ignore')

class FaultAnalyzer:
    """故障分析器类"""
    
    def __init__(self, excel_file):
        """初始化分析器"""
        self.df = pd.read_excel(excel_file)
        self.preprocess_data()
        
    def preprocess_data(self):
        """数据预处理"""
        # 转换故障时间为datetime格式
        self.df['故障时间'] = pd.to_datetime(self.df['故障时间'])
        
        # 添加时间相关的衍生字段
        self.df['年份'] = self.df['故障时间'].dt.year
        self.df['月份'] = self.df['故障时间'].dt.month
        self.df['季度'] = self.df['故障时间'].dt.quarter
        self.df['星期'] = self.df['故障时间'].dt.dayofweek
        self.df['小时'] = self.df['故障时间'].dt.hour
        
        # 提取数据故障主类型
        self.df['数据故障主类型'] = self.df['数据故障代码'].str.split(' ').str[0].str.split('.').str[0]
        
        # 转换耗时为分钟数
        self.df['耗时分钟'] = self.df['耗时'].apply(self.parse_duration)
        
    def parse_duration(self, duration_str):
        """解析耗时字符串，转换为分钟数"""
        if '小时' in duration_str:
            hours = float(duration_str.replace('小时', '').strip())
            return hours * 60
        elif '分钟' in duration_str:
            return float(duration_str.replace('分钟', '').strip())
        else:
            return 0
    
    def basic_statistics_analysis(self):
        """1. 基础统计分析"""
        print("\n" + "="*50)
        print("1. 基础统计分析")
        print("="*50)
        
        # 故障频率分析
        print("\n【故障频率分析】")
        fault_counts = self.df['仪表故障代码'].value_counts()
        total_faults = len(self.df)
        
        print(f"总故障数: {total_faults}")
        print("\n各故障代码发生次数及占比:")
        for code, count in fault_counts.head(10).items():
            percentage = (count / total_faults) * 100
            print(f"{code}: {count}次 ({percentage:.1f}%)")
        
        # 时间分布分析
        print("\n【时间分布分析】")
        yearly_counts = self.df.groupby('年份').size()
        print("\n年度故障分布:")
        for year, count in yearly_counts.items():
            print(f"{year}年: {count}次")
        
        # 季度分析
        quarterly_counts = self.df.groupby(['年份', '季度']).size()
        print("\n季度故障趋势:")
        for (year, quarter), count in quarterly_counts.tail(8).items():
            print(f"{year}年Q{quarter}: {count}次")
        
        # 故障类型分布
        print("\n【故障类型分布】")
        type_counts = self.df['故障类型'].value_counts()
        for fault_type, count in type_counts.items():
            percentage = (count / total_faults) * 100
            print(f"{fault_type}: {count}次 ({percentage:.1f}%)")
        
        return {
            'fault_counts': fault_counts,
            'yearly_counts': yearly_counts,
            'quarterly_counts': quarterly_counts,
            'type_counts': type_counts
        }
    
    def maintenance_efficiency_analysis(self):
        """2. 维修效率分析"""
        print("\n" + "="*50)
        print("2. 维修效率分析")
        print("="*50)
        
        # 平均维修时间
        print("\n【平均维修时间分析】")
        avg_repair_time = self.df.groupby('故障类型')['耗时分钟'].agg(['mean', 'min', 'max', 'count'])
        print("\n各故障类型维修时间统计(分钟):")
        for fault_type, stats in avg_repair_time.iterrows():
            print(f"{fault_type}:")
            print(f"  平均: {stats['mean']:.1f}, 最短: {stats['min']:.0f}, 最长: {stats['max']:.0f}, 次数: {stats['count']}")
        
        # 工具使用频率
        print("\n【工具使用频率分析】")
        tools_list = []
        for tools in self.df['工具']:
            if tools != '无':
                tools_list.extend([t.strip() for t in tools.split('、')])
        
        tools_freq = pd.Series(tools_list).value_counts()
        print("\n最常用工具TOP10:")
        for tool, freq in tools_freq.head(10).items():
            print(f"{tool}: {freq}次")
        
        # 维修操作效果
        print("\n【维修操作效果分析】")
        operation_stats = self.df.groupby('维修操作')['耗时分钟'].agg(['mean', 'count'])
        operation_stats = operation_stats.sort_values('count', ascending=False)
        
        print("\n最常见维修操作及平均耗时:")
        for operation, stats in operation_stats.head(10).iterrows():
            print(f"{operation}: {stats['count']}次, 平均{stats['mean']:.1f}分钟")
        
        return {
            'avg_repair_time': avg_repair_time,
            'tools_freq': tools_freq,
            'operation_stats': operation_stats
        }
    
    def fault_pattern_analysis(self):
        """3. 故障模式分析"""
        print("\n" + "="*50)
        print("3. 故障模式分析")
        print("="*50)
        
        # 故障严重程度分布
        print("\n【故障严重程度分布】")
        severity_counts = self.df['严重程度'].value_counts()
        total = len(self.df)
        for severity, count in severity_counts.items():
            percentage = (count / total) * 100
            print(f"{severity}: {count}次 ({percentage:.1f}%)")
        
        # 优先级分析
        print("\n【优先级分析】")
        priority_counts = self.df['优先级'].value_counts().sort_index()
        for priority, count in priority_counts.items():
            percentage = (count / total) * 100
            print(f"优先级{priority}: {count}次 ({percentage:.1f}%)")
        
        # 高优先级故障详情
        high_priority = self.df[self.df['优先级'] == 1]
        print(f"\n高优先级(1级)故障主要类型:")
        for fault_code, count in high_priority['仪表故障代码'].value_counts().head(5).items():
            fault_name = high_priority[high_priority['仪表故障代码'] == fault_code]['故障描述/名称'].iloc[0]
            print(f"{fault_code} - {fault_name}: {count}次")
        
        # 季节性模式
        print("\n【季节性模式分析】")
        seasonal_counts = self.df.groupby('季度').size()
        print("\n各季度故障分布:")
        season_names = {1: '春季', 2: '夏季', 3: '秋季', 4: '冬季'}
        for season, count in seasonal_counts.items():
            avg_monthly = count / (len(self.df['年份'].unique()) * 3)
            print(f"{season_names[season]}(Q{season}): {count}次, 平均每月{avg_monthly:.1f}次")
        
        # 工作日vs周末分析
        self.df['是否工作日'] = self.df['星期'].apply(lambda x: '工作日' if x < 5 else '周末')
        workday_counts = self.df['是否工作日'].value_counts()
        print("\n工作日vs周末故障分布:")
        for day_type, count in workday_counts.items():
            percentage = (count / total) * 100
            print(f"{day_type}: {count}次 ({percentage:.1f}%)")
        
        return {
            'severity_counts': severity_counts,
            'priority_counts': priority_counts,
            'seasonal_counts': seasonal_counts,
            'workday_counts': workday_counts
        }
    
    def correlation_analysis(self):
        """4. 关联性分析"""
        print("\n" + "="*50)
        print("4. 关联性分析")
        print("="*50)
        
        # 故障代码关联分析
        print("\n【故障代码关联分析】")
        # 创建故障代码共现矩阵
        fault_codes = self.df['仪表故障代码'].unique()
        
        # 分析同一天发生的故障
        daily_faults = self.df.groupby(self.df['故障时间'].dt.date)['仪表故障代码'].apply(list)
        
        co_occurrence = {}
        for faults in daily_faults:
            if len(faults) > 1:
                for i in range(len(faults)):
                    for j in range(i+1, len(faults)):
                        pair = tuple(sorted([faults[i], faults[j]]))
                        co_occurrence[pair] = co_occurrence.get(pair, 0) + 1
        
        if co_occurrence:
            print("\n同日发生的故障对:")
            for pair, count in sorted(co_occurrence.items(), key=lambda x: x[1], reverse=True)[:5]:
                print(f"{pair[0]} & {pair[1]}: {count}次")
        
        # 维修操作与耗时关系
        print("\n【维修操作与耗时关系】")
        # 按严重程度分组分析平均耗时
        severity_time = self.df.groupby('严重程度')['耗时分钟'].mean().sort_values(ascending=False)
        print("\n不同严重程度的平均维修时间:")
        for severity, avg_time in severity_time.items():
            print(f"{severity}: {avg_time:.1f}分钟")
        
        # 工具与故障类型匹配
        print("\n【工具与故障类型匹配分析】")
        # 分析每种故障类型最常用的工具
        for fault_type in self.df['故障类型'].unique():
            subset = self.df[self.df['故障类型'] == fault_type]
            tools_list = []
            for tools in subset['工具']:
                if tools != '无':
                    tools_list.extend([t.strip() for t in tools.split('、')])
            
            if tools_list:
                top_tool = pd.Series(tools_list).value_counts().iloc[0]
                print(f"{fault_type}: 最常用工具 - {pd.Series(tools_list).value_counts().index[0]} ({top_tool}次)")
        
        # 故障代码与耗时的相关性
        print("\n【故障复杂度分析】")
        fault_complexity = self.df.groupby('仪表故障代码').agg({
            '耗时分钟': 'mean',
            '优先级': 'mean',
            '故障描述/名称': 'first'
        }).sort_values('耗时分钟', ascending=False)
        
        print("\n最复杂故障TOP5(按平均维修时间):")
        for code, stats in fault_complexity.head(5).iterrows():
            print(f"{code} - {stats['故障描述/名称']}: 平均{stats['耗时分钟']:.1f}分钟")
        
        return {
            'co_occurrence': co_occurrence,
            'severity_time': severity_time,
            'fault_complexity': fault_complexity
        }
    
    def predictive_analysis(self):
        """5. 预测性分析"""
        print("\n" + "="*50)
        print("5. 预测性分析")
        print("="*50)
        
        # 故障趋势预测
        print("\n【故障趋势预测】")
        # 按月统计故障数
        monthly_faults = self.df.groupby(pd.Grouper(key='故障时间', freq='M')).size()
        
        # 简单线性回归预测
        X = np.arange(len(monthly_faults)).reshape(-1, 1)
        y = monthly_faults.values
        
        model = LinearRegression()
        model.fit(X, y)
        
        # 预测未来6个月
        future_months = np.arange(len(monthly_faults), len(monthly_faults) + 6).reshape(-1, 1)
        predictions = model.predict(future_months)
        
        print("\n未来6个月故障预测:")
        current_date = monthly_faults.index[-1]
        for i, pred in enumerate(predictions):
            future_date = current_date + pd.DateOffset(months=i+1)
            print(f"{future_date.strftime('%Y-%m')}: 预计{pred:.0f}次故障")
        
        # 备件需求预测
        print("\n【备件需求预测】")
        # 统计各类传感器更换频率
        sensor_replacements = self.df[self.df['维修操作'].str.contains('更换')]
        
        parts_freq = {}
        for operation in sensor_replacements['维修操作']:
            if '传感器' in operation:
                parts_freq['传感器'] = parts_freq.get('传感器', 0) + 1
            if '电路板' in operation or '板' in operation:
                parts_freq['电路板'] = parts_freq.get('电路板', 0) + 1
            if '模块' in operation:
                parts_freq['模块'] = parts_freq.get('模块', 0) + 1
            if '电缆' in operation or '线路' in operation:
                parts_freq['电缆'] = parts_freq.get('电缆', 0) + 1
        
        print("\n基于历史数据的年度备件需求预测:")
        years = len(self.df['年份'].unique())
        for part, count in parts_freq.items():
            annual_need = count / years
            print(f"{part}: 年均需求{annual_need:.1f}个, 建议库存{int(annual_need * 1.5)}个")
        
        # 预防性维护计划
        print("\n【预防性维护计划建议】")
        # 分析高频故障的平均间隔时间
        top_faults = self.df['仪表故障代码'].value_counts().head(5).index
        
        print("\n基于故障间隔的维护周期建议:")
        for fault_code in top_faults:
            fault_dates = self.df[self.df['仪表故障代码'] == fault_code]['故障时间'].sort_values()
            if len(fault_dates) > 1:
                intervals = fault_dates.diff().dropna().dt.days
                avg_interval = intervals.mean()
                suggested_interval = int(avg_interval * 0.8)  # 提前20%进行维护
                
                fault_name = self.df[self.df['仪表故障代码'] == fault_code]['故障描述/名称'].iloc[0]
                print(f"{fault_code} - {fault_name}:")
                print(f"  平均故障间隔: {avg_interval:.0f}天")
                print(f"  建议维护周期: {suggested_interval}天")
        
        # 季节性维护建议
        print("\n季节性维护重点:")
        seasonal_severity = self.df.groupby(['季度', '严重程度']).size().unstack(fill_value=0)
        for season in range(1, 5):
            if season in seasonal_severity.index:
                season_data = seasonal_severity.loc[season]
                if '严重' in season_data.index:
                    severe_ratio = season_data['严重'] / season_data.sum() * 100
                    season_names = {1: '春季', 2: '夏季', 3: '秋季', 4: '冬季'}
                    if severe_ratio > 30:
                        print(f"{season_names[season]}: 严重故障占比{severe_ratio:.1f}%, 建议加强预防性检查")
        
        return {
            'monthly_faults': monthly_faults,
            'predictions': predictions,
            'parts_freq': parts_freq
        }
    
    def generate_visualizations(self):
        """生成可视化图表"""
        print("\n" + "="*50)
        print("6. 生成可视化报告")
        print("="*50)
        
        # 创建图表布局
        fig = plt.figure(figsize=(20, 24))
        
        # 1. 故障类型分布饼图
        ax1 = plt.subplot(4, 3, 1)
        self.df['故障类型'].value_counts().plot(kind='pie', autopct='%1.1f%%', ax=ax1)
        ax1.set_title('Fault Type Distribution', fontsize=12, pad=20)
        ax1.set_ylabel('')
        
        # 2. 月度故障趋势图
        ax2 = plt.subplot(4, 3, 2)
        monthly_faults = self.df.groupby(pd.Grouper(key='故障时间', freq='M')).size()
        monthly_faults.plot(kind='line', marker='o', ax=ax2)
        ax2.set_title('Monthly Fault Trend', fontsize=12, pad=20)
        ax2.set_xlabel('Date')
        ax2.set_ylabel('Fault Count')
        ax2.grid(True, alpha=0.3)
        
        # 3. 严重程度分布条形图
        ax3 = plt.subplot(4, 3, 3)
        severity_order = ['紧急', '严重', '中等']
        severity_counts = self.df['严重程度'].value_counts().reindex(severity_order)
        colors = ['#FF4444', '#FF8800', '#FFDD00']
        severity_counts.plot(kind='bar', color=colors, ax=ax3)
        ax3.set_title('Fault Severity Distribution', fontsize=12, pad=20)
        ax3.set_xlabel('Severity')
        ax3.set_ylabel('Count')
        ax3.set_xticklabels(severity_order, rotation=0)
        
        # 4. TOP10故障代码
        ax4 = plt.subplot(4, 3, 4)
        top_faults = self.df['仪表故障代码'].value_counts().head(10)
        top_faults.plot(kind='barh', ax=ax4)
        ax4.set_title('TOP 10 Fault Codes', fontsize=12, pad=20)
        ax4.set_xlabel('Count')
        ax4.set_ylabel('Fault Code')
        
        # 5. 维修时间分布箱线图
        ax5 = plt.subplot(4, 3, 5)
        repair_time_by_type = []
        fault_types = self.df['故障类型'].unique()
        for ft in fault_types:
            repair_time_by_type.append(self.df[self.df['故障类型'] == ft]['耗时分钟'].values)
        ax5.boxplot(repair_time_by_type, labels=fault_types)
        ax5.set_title('Repair Time Distribution by Fault Type', fontsize=12, pad=20)
        ax5.set_xlabel('Fault Type')
        ax5.set_ylabel('Time (minutes)')
        plt.setp(ax5.xaxis.get_majorticklabels(), rotation=45, ha='right')
        
        # 6. 季度故障分布
        ax6 = plt.subplot(4, 3, 6)
        quarterly_counts = self.df.groupby('季度').size()
        quarters = ['Q1', 'Q2', 'Q3', 'Q4']
        quarterly_counts.plot(kind='bar', ax=ax6, color='skyblue')
        ax6.set_title('Quarterly Fault Distribution', fontsize=12, pad=20)
        ax6.set_xlabel('Quarter')
        ax6.set_ylabel('Count')
        ax6.set_xticklabels(quarters, rotation=0)
        
        # 7. 优先级分布
        ax7 = plt.subplot(4, 3, 7)
        priority_counts = self.df['优先级'].value_counts().sort_index()
        priority_counts.plot(kind='bar', ax=ax7, color=['red', 'orange', 'green'])
        ax7.set_title('Priority Level Distribution', fontsize=12, pad=20)
        ax7.set_xlabel('Priority Level')
        ax7.set_ylabel('Count')
        ax7.set_xticklabels(['1 (High)', '2 (Medium)', '3 (Low)'], rotation=0)
        
        # 8. 数据故障类型分布
        ax8 = plt.subplot(4, 3, 8)
        data_fault_counts = self.df['数据故障主类型'].value_counts()
        data_fault_names = {
            '001': 'Full Scale',
            '002': 'Zero Output',
            '003': 'Data Missing',
            '004': 'Data Hold',
            '005': 'Fluctuation',
            '006': 'Data Offset'
        }
        data_fault_labels = [data_fault_names.get(code, code) for code in data_fault_counts.index]
        data_fault_counts.plot(kind='pie', autopct='%1.1f%%', ax=ax8, labels=data_fault_labels)
        ax8.set_title('Data Fault Type Distribution', fontsize=12, pad=20)
        ax8.set_ylabel('')
        
        # 9. 工具使用频率TOP10
        ax9 = plt.subplot(4, 3, 9)
        tools_list = []
        for tools in self.df['工具']:
            if tools != '无':
                tools_list.extend([t.strip() for t in tools.split('、')])
        tools_freq = pd.Series(tools_list).value_counts().head(10)
        tools_freq.plot(kind='barh', ax=ax9, color='green')
        ax9.set_title('TOP 10 Most Used Tools', fontsize=12, pad=20)
        ax9.set_xlabel('Usage Frequency')
        ax9.set_ylabel('Tool')
        
        # 10. 故障热力图（按星期和小时）
        ax10 = plt.subplot(4, 3, 10)
        heatmap_data = self.df.groupby(['星期', '小时']).size().unstack(fill_value=0)
        if not heatmap_data.empty:
            sns.heatmap(heatmap_data, cmap='YlOrRd', annot=False, fmt='d', ax=ax10, cbar_kws={'label': 'Count'})
            ax10.set_title('Fault Heatmap (Day of Week vs Hour)', fontsize=12, pad=20)
            ax10.set_xlabel('Hour of Day')
            ax10.set_ylabel('Day of Week')
            ax10.set_yticklabels(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'])
        
        # 11. 年度故障趋势
        ax11 = plt.subplot(4, 3, 11)
        yearly_counts = self.df.groupby('年份').size()
        yearly_counts.plot(kind='bar', ax=ax11, color='purple')
        ax11.set_title('Annual Fault Trend', fontsize=12, pad=20)
        ax11.set_xlabel('Year')
        ax11.set_ylabel('Count')
        ax11.set_xticklabels(yearly_counts.index, rotation=0)
        
        # 12. 维修操作效率TOP10
        ax12 = plt.subplot(4, 3, 12)
        operation_efficiency = self.df.groupby('维修操作').agg({
            '耗时分钟': 'mean',
            '仪表故障代码': 'count'
        }).rename(columns={'仪表故障代码': 'count'})
        operation_efficiency = operation_efficiency[operation_efficiency['count'] >= 2]
        operation_efficiency = operation_efficiency.sort_values('耗时分钟').head(10)
        
        operation_efficiency['耗时分钟'].plot(kind='barh', ax=ax12, color='orange')
        ax12.set_title('TOP 10 Fastest Maintenance Operations', fontsize=12, pad=20)
        ax12.set_xlabel('Average Time (minutes)')
        ax12.set_ylabel('Operation')
        
        plt.tight_layout()
        
        # 保存图表
        report_filename = f'故障分析报告_{datetime.now().strftime("%Y%m%d_%H%M%S")}.png'
        plt.savefig(report_filename, dpi=300, bbox_inches='tight')
        print(f"\n可视化报告已保存: {report_filename}")
        
        # 关闭图形以释放内存
        plt.close()
        
        return report_filename
    
    def generate_summary_report(self):
        """生成文字总结报告"""
        report_filename = f'故障分析总结报告_{datetime.now().strftime("%Y%m%d_%H%M%S")}.txt'
        
        with open(report_filename, 'w', encoding='utf-8') as f:
            f.write("="*70 + "\n")
            f.write("故障诊断维修记录分析总结报告\n")
            f.write(f"生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write("="*70 + "\n\n")
            
            # 概览
            f.write("【数据概览】\n")
            f.write(f"分析时间范围: {self.df['故障时间'].min().strftime('%Y-%m-%d')} 至 {self.df['故障时间'].max().strftime('%Y-%m-%d')}\n")
            f.write(f"总记录数: {len(self.df)}\n")
            f.write(f"覆盖故障类型: {self.df['故障类型'].nunique()}种\n")
            f.write(f"涉及故障代码: {self.df['仪表故障代码'].nunique()}个\n\n")
            
            # 关键发现
            f.write("【关键发现】\n")
            
            # 最频繁故障
            top_fault = self.df['仪表故障代码'].value_counts().index[0]
            top_fault_count = self.df['仪表故障代码'].value_counts().iloc[0]
            top_fault_name = self.df[self.df['仪表故障代码'] == top_fault]['故障描述/名称'].iloc[0]
            f.write(f"1. 最频繁故障: {top_fault} - {top_fault_name} (发生{top_fault_count}次)\n")
            
            # 平均维修时间
            avg_time = self.df['耗时分钟'].mean()
            f.write(f"2. 平均维修时间: {avg_time:.1f}分钟\n")
            
            # 严重故障占比
            severe_ratio = (self.df['严重程度'] == '严重').sum() / len(self.df) * 100
            f.write(f"3. 严重故障占比: {severe_ratio:.1f}%\n")
            
            # 高优先级故障
            high_priority_ratio = (self.df['优先级'] == 1).sum() / len(self.df) * 100
            f.write(f"4. 高优先级故障占比: {high_priority_ratio:.1f}%\n\n")
            
            # 建议
            f.write("【改进建议】\n")
            f.write("1. 重点关注高频故障的预防性维护\n")
            f.write("2. 优化备件库存管理，确保常用配件充足\n")
            f.write("3. 加强季节性维护，特别是故障高发季节\n")
            f.write("4. 定期培训维修人员，提高维修效率\n")
            f.write("5. 建立故障预警机制，提前发现潜在问题\n")
            
        print(f"\n文字总结报告已保存: {report_filename}")
        return report_filename

def main():
    """主函数"""
    # 获取最新的Excel文件
    import glob
    excel_files = glob.glob('故障诊断维修记录_*.xlsx')
    if not excel_files:
        print("错误: 未找到故障记录Excel文件!")
        return
    
    # 使用最新的文件
    latest_file = max(excel_files)
    print(f"正在分析文件: {latest_file}")
    
    # 创建分析器
    analyzer = FaultAnalyzer(latest_file)
    
    # 执行各项分析
    basic_stats = analyzer.basic_statistics_analysis()
    efficiency_stats = analyzer.maintenance_efficiency_analysis()
    pattern_stats = analyzer.fault_pattern_analysis()
    correlation_stats = analyzer.correlation_analysis()
    predictive_stats = analyzer.predictive_analysis()
    
    # 生成可视化报告
    visualization_file = analyzer.generate_visualizations()
    
    # 生成文字总结报告
    summary_file = analyzer.generate_summary_report()
    
    print("\n" + "="*50)
    print("分析完成!")
    print("="*50)
    print(f"可视化报告: {visualization_file}")
    print(f"文字总结报告: {summary_file}")

if __name__ == "__main__":
    main()