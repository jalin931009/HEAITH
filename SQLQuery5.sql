USE [復健科排班系統];
GO

-- =========================================================
-- 1. 清理舊資料表
-- =========================================================
IF OBJECT_ID('[dbo].[NightShiftSchedule]', 'U') IS NOT NULL DROP TABLE [dbo].[NightShiftSchedule];
IF OBJECT_ID('[dbo].[EmployeeDispatch]', 'U') IS NOT NULL   DROP TABLE [dbo].[EmployeeDispatch];
GO

-- =========================================================
-- 2. 建立【員工外派紀錄表】
-- =========================================================
CREATE TABLE [dbo].[EmployeeDispatch] (
    [DispatchID]    INT IDENTITY(1,1) NOT NULL, -- 外派自動編號 (主鍵)
    [SerialID]      INT               NOT NULL, -- 關聯到當年度員工序號表的 ID
    [DispatchYear]  INT               NOT NULL, -- 外派年份 (例如：2026)
    [DispatchMonth] INT               NOT NULL, -- 外派月份 (例如：11)
    [Location]      NVARCHAR(100)     NOT NULL, -- 外派地點/項目 (例如：五下下午護理之家)
    [UpdateTime]    DATETIME          DEFAULT GETDATE() NOT NULL,

    CONSTRAINT [PK_EmployeeDispatch] PRIMARY KEY CLUSTERED ([DispatchID] ASC),
    CONSTRAINT [UK_Dispatch_Year_Month] UNIQUE ([SerialID], [DispatchYear], [DispatchMonth]),
    CONSTRAINT [FK_Dispatch_EmployeeSerial] FOREIGN KEY ([SerialID]) REFERENCES [dbo].[EmployeeSerial] ([SerialID])
);
GO

-- =========================================================
-- 3. 建立【晚班排班表】(以月份為單位，支援一人一年3個月規則)
-- =========================================================
CREATE TABLE [dbo].[NightShiftSchedule] (
    [NightShiftID]  INT IDENTITY(1,1) NOT NULL, -- 晚班自動編號 (主鍵)
    [ShiftYear]     INT               NOT NULL, -- 晚班年份 (例如：2026)
    [ShiftMonth]    INT               NOT NULL, -- 晚班月份 (例如：10)
    [SerialID]      INT               NOT NULL, -- 輪值人員的年度序號 ID
    [AreaName]      NVARCHAR(50)      NOT NULL, -- 負責區域 (如：骨科復健組、神經復健組)
    [Remark]        NVARCHAR(100)     NULL,     -- 備註說明

    CONSTRAINT [PK_NightShiftSchedule] PRIMARY KEY CLUSTERED ([NightShiftID] ASC),
    -- 確保同一年、同一月、同一個區域，不會重複排給同一個序號
    CONSTRAINT [UK_Shift_Year_Month_Area] UNIQUE ([ShiftYear], [ShiftMonth], [AreaName], [SerialID]),
    CONSTRAINT [FK_NightShift_EmployeeSerial] FOREIGN KEY ([SerialID]) REFERENCES [dbo].[EmployeeSerial] ([SerialID])
);
GO

-- =========================================================
-- 4. 寫入模擬開發測試資料 (模擬子軒一年扛 3 個月晚班，且11月外派避開)
-- =========================================================
-- 註：SerialID 5 對應子軒(2026001)，SerialID 6 對應陳美珠(2026002)

-- A. 設定外派：子軒在 2026 年 11 月被外派
INSERT INTO [dbo].[EmployeeDispatch] ([SerialID], [DispatchYear], [DispatchMonth], [Location])
VALUES (5, 2026, 11, '五下下午護理之家支援');

-- B. 模擬排班系統產出子軒在 2026 年的 3 個月晚班：
-- 第 1 個月：10月份，子軒正常輪值
INSERT INTO [dbo].[NightShiftSchedule] ([ShiftYear], [ShiftMonth], [SerialID], [AreaName], [Remark])
VALUES (2026, 10, 5, '骨科復健組', '子軒今年第1個月晚班');

-- 11月份（原本要輪到子軒，但因為外派系統自動跳過，改由陳美珠遞補）
INSERT INTO [dbo].[NightShiftSchedule] ([ShiftYear], [ShiftMonth], [SerialID], [AreaName], [Remark])
VALUES (2026, 11, 6, '骨科復健組', '系統偵測序號01(子軒)11月外派，自動由美珠遞補');

-- 第 2 個月：12月份，子軒歸隊輪值
INSERT INTO [dbo].[NightShiftSchedule] ([ShiftYear], [ShiftMonth], [SerialID], [AreaName], [Remark])
VALUES (2026, 12, 5, '神經復健組', '子軒今年第2個月晚班');

-- 第 3 個月：隔年 1 月份（跨年度或是順延），子軒上第 3 個月的晚班
INSERT INTO [dbo].[NightShiftSchedule] ([ShiftYear], [ShiftMonth], [SerialID], [AreaName], [Remark])
VALUES (2026, 1, 5, '骨科復健組', '子軒今年第3個月晚班（順延補回）');
GO

-- =========================================================
-- 5. 驗證查詢 (完美呈現每人滿 3 個月的歷史清單)
-- =========================================================
SELECT 
    CAST(N.[ShiftYear] AS VARCHAR) + ' 年 ' + CAST(N.[ShiftMonth] AS VARCHAR) + ' 月' AS [晚班月份],
    RIGHT(E.[SerialNumber], 2)                AS [值班序號],
    E.[EmpName]                               AS [當班復健師],
    N.[AreaName]                              AS [負責區域],
    ISNULL((SELECT [Location] FROM [dbo].[EmployeeDispatch] 
            WHERE [SerialID] = N.[SerialID] 
              AND [DispatchYear] = N.[ShiftYear] 
              AND [DispatchMonth] = N.[ShiftMonth]), '無外派（正常當班）') AS [當月外派狀態],
    ISNULL(N.[Remark], '')                    AS [排班備註]
FROM [dbo].[NightShiftSchedule] N
INNER JOIN [dbo].[EmployeeSerial] E ON N.[SerialID] = E.[SerialID]
ORDER BY N.[ShiftYear] ASC, N.[ShiftMonth] ASC;
GO