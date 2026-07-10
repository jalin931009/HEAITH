USE [復健科排班系統];
GO

-- =========================================================
-- 1. 清理舊的劃休資料表 (確保環境乾淨)
-- =========================================================
IF OBJECT_ID('[dbo].[LeavePreference]', 'U') IS NOT NULL DROP TABLE [dbo].[LeavePreference];
GO

-- =========================================================
-- 2. 建立【LeavePreference 劃休假日表】(完全對齊圖 17-2 畫面欄位)
-- =========================================================
CREATE TABLE [dbo].[LeavePreference] (
    -- 核心修復：流水號改為從 1 開始 (IDENTITY(1,1))
    [PreferenceID]    INT IDENTITY(1,1) NOT NULL, 
    
    -- 【全新欄位】：對應圖 17-2，例如 2025/10/15
    [OpenDate]        DATE              NOT NULL, -- 開放劃休的日期 
    
    -- 【核心調整】：改為「劃休期間」，精準儲存該週期的起迄日期 (例如：2026-01-01 到 2026-06-30)
    [LeaveStartDate]  DATE              NOT NULL, -- 劃休期間(起)
    [LeaveEndDate]    DATE              NOT NULL, -- 劃休期間(迄)
    
    [WorkId]          NVARCHAR(20)      NOT NULL, -- 復健師序號/工號 (外鍵關聯)
    [TargetDate]      DATE              NOT NULL, -- 他希望劃休的具體日期 (例如：2026-05-01)
    [PreferenceOrder] INT               NOT NULL, -- 填寫志願序 (紅色圈圈數字，最多到20)
    
    -- 系統跑完序號分發後的狀態 (0=未中選, 1=分發中, 2=已中選)
    [SelectionStatus] INT               DEFAULT 1 NOT NULL, 
    [SubmitTime]      DATETIME          DEFAULT GETDATE() NOT NULL,

    CONSTRAINT [PK_LeavePreference] PRIMARY KEY CLUSTERED ([PreferenceID] ASC),
    -- 防呆約束：同一個復健師在同一個劃休期間與開放日下，志願序數字不能重複填寫
    CONSTRAINT [UK_Emp_Leave_Period_PrefOrder] UNIQUE ([OpenDate], [LeaveStartDate], [WorkId], [PreferenceOrder]),
    CONSTRAINT [FK_LeavePreference_Employee] FOREIGN KEY ([WorkId]) REFERENCES [dbo].[Employee] ([WorkId])
);
GO

-- =========================================================
-- 3. 灌入符合你最新要求的臨床模擬開發測試假資料
-- =========================================================
-- 重設自增計數器，雙重保險確保從 1 開始
DBCC CHECKIDENT ('[dbo].[LeavePreference]', RESEED, 1);

-- 模擬情境：
-- 在 2025/10/15 當天，開放了 2026/01/01~2026/06/30 (上半年度) 的第一輪預劃休假。
-- 子軒(333)與蔡承佑(777)第一志願都填了 2026/05/01 勞動節。
-- 經過 Java 系統比對兩人的員工序號後：子軒搶贏(已中選=2)，蔡承佑落榜(未中選=0)。
INSERT INTO [dbo].[LeavePreference] ([OpenDate], [LeaveStartDate], [LeaveEndDate], [WorkId], [TargetDate], [PreferenceOrder], [SelectionStatus])
VALUES
('2025-10-15', '2026-01-01', '2026-06-30', '333', '2026-05-01', 1, 2), -- 子軒第一志願 (中選)
('2025-10-15', '2026-01-01', '2026-06-30', '777', '2026-05-01', 1, 0), -- 蔡承佑第一志願 (未中選)
('2025-10-15', '2026-01-01', '2026-06-30', '777', '2026-05-02', 2, 2); -- 蔡承佑第二志願 (中選)
GO

-- =========================================================
-- 4. 驗證查詢 (將英文欄位漂亮的翻譯成中文，並檢查排序)
-- =========================================================
SELECT 
    P.[PreferenceID] AS [流水號], -- 這次絕對是從 1 開始！
    CONVERT(VARCHAR(10), P.[OpenDate], 111) AS [開放劃休日期],
    
    -- 完美拼出「劃休期間」欄位 (例如：2026/01/01~2026/06/30)
    CONVERT(VARCHAR(10), P.[LeaveStartDate], 111) + '~' + CONVERT(VARCHAR(10), P.[LeaveEndDate], 111) AS [劃休期間],
    
    P.[WorkId] AS [work id],
    E.[EmpName] AS [復健師姓名],
    '第' + CAST(P.[PreferenceOrder] AS VARCHAR) + '志願' AS [填寫志願序],
    CONVERT(VARCHAR(10), P.[TargetDate], 111) AS [希望劃休日期],
    CASE P.[SelectionStatus]
        WHEN 1 THEN '系統序號分發中'
        WHEN 2 THEN '已中選'
        ELSE '未中選'
    END AS [分發結果]
FROM [dbo].[LeavePreference] P
INNER JOIN [dbo].[Employee] E ON P.[WorkId] = E.[WorkId]
ORDER BY P.[PreferenceID] ASC; -- 依流水號正序排列，1 號最先出列！
GO