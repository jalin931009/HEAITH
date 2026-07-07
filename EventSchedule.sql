USE [復健科排班系統];
GO

-- =========================================================
-- 1. 清理舊資料表
-- =========================================================
IF OBJECT_ID('[dbo].[NationalHolidays]', 'U') IS NOT NULL DROP TABLE [dbo].[NationalHolidays];
IF OBJECT_ID('[dbo].[ConfigLog]', 'U') IS NOT NULL       DROP TABLE [dbo].[ConfigLog];
IF OBJECT_ID('[dbo].[SystemConfig]', 'U') IS NOT NULL    DROP TABLE [dbo].[SystemConfig];
GO

-- =========================================================
-- 2. 建立【系統全域參數設定表】(包含：抽籤、排班、臨時停班、限制工時)
-- =========================================================
CREATE TABLE [dbo].[SystemConfig] (
    [ConfigID]              INT IDENTITY(1,1) NOT NULL,
    [DrawDate]              VARCHAR(10)   NULL, -- 抽籤日期 (如 '10/15')
    [FirstHalfOpenDate]     VARCHAR(10)   NULL, -- 上半年開放劃假日
    [SecondHalfOpenDate]    VARCHAR(10)   NULL, -- 下半年開放劃假日
    [ScheduleIntervalWeeks] INT           DEFAULT 4 NOT NULL, -- 排班區間週數
    
    -- 【臨時停班欄位】放在主表，控制目前最新的停班狀態
    [SuspensionDate]        VARCHAR(10)   NULL, -- 臨時停班日期 (如 '10/31')
    [SuspensionShift]       NVARCHAR(20)  NULL, -- 臨時停班時段 (如：全天班/早班/午班)
    
    -- 【限制工時欄位】放在主表，全院統一維持一筆標準限制
    [FullTimeMaxHours]      INT           DEFAULT 40 NOT NULL, -- 正職每週工時上限
    [InternMaxHours]        INT           DEFAULT 20 NOT NULL, -- 實習每週工時上限

    CONSTRAINT [PK_SystemConfig] PRIMARY KEY CLUSTERED ([ConfigID] ASC)
);
GO

-- =========================================================
-- 3. 建立【國定放假日管理表】(獨立出來，支援多筆節日清單)
-- =========================================================
CREATE TABLE [dbo].[NationalHolidays] (
    [HolidayID]   INT IDENTITY(1,1) NOT NULL,
    [HolidayName] NVARCHAR(50) NOT NULL, -- 節日名稱
    [StartDate]   VARCHAR(10)  NOT NULL, -- 開始日期
    [EndDate]     VARCHAR(10)  NOT NULL, -- 結束日期
    [UpdateTime]  DATETIME     DEFAULT GETDATE() NOT NULL,

    CONSTRAINT [PK_NationalHolidays] PRIMARY KEY CLUSTERED ([HolidayID] ASC)
);
GO

-- =========================================================
-- 4. 建立【控制台修改歷程紀錄表】
-- =========================================================
CREATE TABLE [dbo].[ConfigLog] (
    [LogID]       INT IDENTITY(1,1) NOT NULL,
    [ChangeDate]  DATETIME          DEFAULT GETDATE() NOT NULL,
    [ChangeItem]  NVARCHAR(50)      NOT NULL, 
    [NewValue]    NVARCHAR(100)     NOT NULL, 
    [OldValue]    NVARCHAR(100)     NOT NULL, 
    [Executor]    NVARCHAR(50)      NOT NULL, 

    CONSTRAINT [PK_ConfigLog] PRIMARY KEY CLUSTERED ([LogID] ASC)
);
GO

-- =========================================================
-- 5. 初始化寫入資料 (模擬管理員已經設定好的狀態)
-- =========================================================

-- 寫入主參數 (正職 40 小時、實習 20 小時)
INSERT INTO [dbo].[SystemConfig] 
([DrawDate], [FirstHalfOpenDate], [SecondHalfOpenDate], [ScheduleIntervalWeeks], [SuspensionDate], [SuspensionShift], [FullTimeMaxHours], [InternMaxHours])
VALUES 
('10/15', '10/15', '04/01', 4, '無', '無', 40, 20);

-- 寫入國定假日清單
INSERT INTO [dbo].[NationalHolidays] ([HolidayName], [StartDate], [EndDate])
VALUES ('元旦', '01/01', '01/01'),
       ('和平紀念日', '02/28', '02/28'),
       ('勞動節', '05/01', '05/01'),
       ('雙十節', '10/10', '10/10');

-- 寫入一筆歷程紀錄
INSERT INTO [dbo].[ConfigLog] ([ChangeDate], [ChangeItem], [NewValue], [OldValue], [Executor])
VALUES ('2024-10-30 16:00:00', '臨時停班', '10月31日 全天班', '無', '美珠(管理員)');
GO

-- =========================================================
-- 6. 查詢顯示成果 (看看全部欄位的中文化漂亮顯示)
-- =========================================================

-- A. 查看主設定 (包含臨時停班與限制工時)
SELECT 
    [DrawDate]              AS [抽籤日期],
    [FirstHalfOpenDate]     AS [上半年開放劃假],
    [SecondHalfOpenDate]    AS [下半年開放劃假],
    CAST([ScheduleIntervalWeeks] AS VARCHAR) + ' 週' AS [排班區間],
    ISNULL([SuspensionDate], '無')   AS [臨時停班日期],
    ISNULL([SuspensionShift], '無')  AS [臨時停班時段],
    CAST([FullTimeMaxHours] AS VARCHAR) + ' 小時' AS [正職每週工時上限],
    CAST([InternMaxHours] AS VARCHAR) + ' 小時'   AS [實習每週工時上限]
FROM [dbo].[SystemConfig];

-- B. 查看國定假日清單
SELECT 
    RIGHT('0' + CAST([HolidayID] AS VARCHAR), 2) AS [編號],
    [HolidayName] AS [節日名稱],
    [StartDate] + ' ～ ' + [EndDate] AS [放假區間]
FROM [dbo].[NationalHolidays];
GO