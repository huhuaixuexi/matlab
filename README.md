# Magnos206 磁力机械式氧分析仪数据采集系统

## 系统概述

本系统为Magnos206磁力机械式氧分析仪提供了完整的MATLAB数据采集解决方案，实现了多源异构数据的统一接入、实时数据采集、存储和可视化功能。

### 主要特性

- **多数据源支持**
  - TCP/IP网络接口实时数据采集
  - Excel历史数据文件读取
  - 数据库连接（支持MySQL、PostgreSQL、SQLite等）
  - 数据模拟器（用于测试和演示）

- **实时数据处理**
  - 实时数据流采集和显示
  - 数据缓冲和预处理
  - 异常值检测和数据质量标记

- **可视化界面**
  - 实时曲线显示
  - 当前值大字体显示
  - 数据表格展示
  - 状态监控

- **数据导出**
  - Excel格式（.xlsx）
  - CSV格式（.csv）
  - MATLAB格式（.mat）

## 系统架构

```
/workspace/
├── src/                      # 源代码目录
│   ├── core/                # 核心类
│   │   ├── DataPoint.m      # 数据点类
│   │   └── DataBuffer.m     # 数据缓冲区类
│   ├── interfaces/          # 接口定义
│   │   └── IDataCollector.m # 数据采集器接口
│   ├── collectors/          # 数据采集器实现
│   │   ├── NetworkDataCollector.m    # 网络采集器
│   │   ├── ExcelDataCollector.m      # Excel采集器
│   │   └── DatabaseDataCollector.m   # 数据库采集器
│   ├── gui/                 # 图形界面
│   │   └── RealTimeDataDisplay.m     # 实时显示界面
│   └── utils/               # 工具类
│       └── DataSimulator.m  # 数据模拟器
├── config/                  # 配置文件
│   └── system_config.json   # 系统配置
├── data/                    # 数据目录
│   └── excel/              # Excel数据文件
├── main_magnos206.m        # 主程序
└── demo_magnos206.m        # 演示程序
```

## 快速开始

### 1. 运行演示程序

```matlab
% 在MATLAB中运行
demo_magnos206
```

这将启动一个使用模拟数据的演示，您可以快速了解系统功能。

### 2. 运行主程序

```matlab
% 在MATLAB中运行
main_magnos206
```

这将启动完整的数据采集系统。

### 3. 配置数据源

#### 网络数据采集配置

编辑 `config/system_config.json` 中的网络配置：

```json
"network": {
  "enabled": true,
  "ipAddress": "192.168.1.100",  // 设备IP地址
  "port": 5025,                   // 端口号
  "timeout": 5
}
```

#### Excel数据源配置

将Excel文件放置在 `data/excel/` 目录下，文件格式应包含以下列：
- 时间戳（Timestamp）
- 数值（Value）
- 单位（Unit）- 可选
- 质量（Quality）- 可选

#### 数据库配置

```json
"database": {
  "enabled": true,
  "type": "sqlite",  // 或 "mysql", "postgresql"
  "connectionInfo": {
    "filename": "data/oxygen_data.db"  // SQLite
    // 或对于其他数据库：
    // "server": "localhost",
    // "port": 3306,
    // "database": "oxygen_db",
    // "username": "user",
    // "password": "pass"
  }
}
```

## 使用指南

### 基本操作流程

1. **选择数据源**：从下拉菜单选择要使用的数据采集器
2. **连接设备**：点击"连接"按钮建立连接
3. **开始采集**：点击"开始"按钮开始实时数据采集
4. **监控数据**：观察实时曲线、当前值和数据表格
5. **导出数据**：点击"导出"按钮保存采集的数据

### 编程接口使用

```matlab
% 创建网络数据采集器
collector = NetworkDataCollector('192.168.1.100', 5025);

% 连接设备
if collector.connect()
    % 读取数据
    dataPoint = collector.readData();
    
    % 显示数据
    fprintf('氧浓度: %.2f%%\n', dataPoint.value);
    
    % 断开连接
    collector.disconnect();
end
```

### 批量处理历史数据

```matlab
% 创建Excel采集器
excelCollector = ExcelDataCollector('data/excel/history.xlsx');

% 连接并读取所有数据
if excelCollector.connect()
    allData = excelCollector.readAll();
    
    % 处理数据...
    
    excelCollector.disconnect();
end
```

## 系统要求

- MATLAB R2018b 或更高版本
- MATLAB GUI Layout Toolbox（用于界面布局）
- Database Toolbox（用于数据库连接，可选）
- Instrument Control Toolbox（用于TCP/IP通信，推荐）

## 故障排除

### 网络连接问题

1. 检查设备IP地址和端口是否正确
2. 确保设备和计算机在同一网络
3. 检查防火墙设置
4. 使用ping命令测试网络连通性

### Excel读取问题

1. 确保Excel文件格式正确
2. 检查列映射配置
3. 确保文件路径正确

### 数据库连接问题

1. 检查数据库服务是否运行
2. 验证连接参数
3. 确保有适当的访问权限

## 扩展开发

### 添加新的数据采集器

1. 创建新类继承自 `IDataCollector`
2. 实现所有抽象方法
3. 在主程序中注册新的采集器

```matlab
classdef MyCustomCollector < IDataCollector
    % 实现必要的属性和方法...
end
```

### 自定义数据处理

可以在 `DataPoint` 类的基础上添加自定义的数据处理逻辑：

```matlab
% 创建带有自定义元数据的数据点
dp = DataPoint(value, ...
    'metadata', struct('temperature', 25, 'pressure', 1013));
```

## 许可证

本项目仅供学习和研究使用。

## 联系方式

如有问题或建议，请创建Issue或Pull Request。
