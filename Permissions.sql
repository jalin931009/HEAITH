USE [復健科排班系統];
GO

-- =========================================================
-- 1. 清理舊資料表 (避免重複執行報錯)
-- =========================================================
IF OBJECT_ID('[dbo].[AreaShiftMinStaff]', 'U') IS NOT NULL DROP TABLE [dbo].[AreaShiftMinStaff];
IF OBJECT_ID('[dbo].[LeaveLimitRule]', 'U') IS NOT NULL    DROP TABLE [dbo].[LeaveLimitRule];
GO

-- =========================================================
-- 2. 建立【特定日期區間劃假人數上限表】(對應行事曆劃假人數畫面)
-- =========================================================
CREATE TABLE [dbo].[LeaveLimitRule] (
    [RuleID]        INT IDENTITY(1,1) NOT NULL, -- 自動編號 (主鍵)
    [StartDate]     DATE              NOT NULL, -- 調整區間 - 開始日期
    [EndDate]       DATE              NOT NULL, -- 調整區間 - 結束日期
    [MaxLeaveCount] INT               NOT NULL, -- 調整人數為 X 人 (如畫面上的 3 人)
    [UpdateTime]    DATETIME          DEFAULT GETDATE() NOT NULL, -- 設定時間

    CONSTRAINT [PK_LeaveLimitRule] PRIMARY KEY CLUSTERED ([RuleID] ASC)
);
GO

-- =========================================================
-- 3. 建立【各復健區域時段當班人數下限表】(對應 Ortho/Neuro 上下午晚人數畫面)
-- =========================================================
CREATE TABLE [dbo].[AreaShiftMinStaff] (
    [SettingID]     INT IDENTITY(1,1) NOT NULL, -- 自動編號 (主鍵)
    [AreaCode]      VARCHAR(20)       NOT NULL, -- 區域代碼 (如：'Ortho', 'Neuro')
    [AreaName]      NVARCHAR(50)      NOT NULL, -- 區域名稱 (如：'物理治療區', '電療區')
    [ShiftType]     NVARCHAR(10)      NOT NULL, -- 時段 (如：'上午', '下午', '晚上')
    [MinStaffCount] INT               DEFAULT 5 NOT NULL, -- 人數下限 (如畫面上的 5 人)
    [UpdateTime]    DATETIME          DEFAULT GETDATE() NOT NULL, -- 最後修改時間

    CONSTRAINT [PK_AreaShiftMinStaff] PRIMARY KEY CLUSTERED ([SettingID] ASC)
);
GO

-- =========================================================
-- 4. 依照你的最新假畫面，精準寫入初始化測試資料
-- =========================================================

-- A. 寫入行事曆選取的 10/24 ～ 10/31 劃假限制為 3 人
INSERT INTO [dbo].[LeaveLimitRule] ([StartDate], [EndDate], [MaxLeaveCount])
VALUES ('2025-10-15', '2026-10-15', 3);

-- B. 寫入 Ortho (骨科) 上午、下午、晚上各至少 5 人的下限限制
INSERT INTO [dbo].[AreaShiftMinStaff] ([AreaCode], [AreaName], [ShiftType], [MinStaffCount])
VALUES ('Ortho', '電療區', '上午', 5),
       ('Ortho', '電療區', '下午', 6),
       ('Ortho', '電療區', '晚上', 3);

-- C. 寫入 Neuro (神經) 上午、下午各至少 5 人的下限限制 (假畫面沒有晚上，配合畫面)
INSERT INTO [dbo].[AreaShiftMinStaff] ([AreaCode], [AreaName], [ShiftType], [MinStaffCount])
VALUES ('Neuro', '運動治療區', '上午', 4),
       ('Neuro', '運動治療區', '下午', 4);
GO

-- =========================================================
-- 5. 格式化查詢成果 (以中文化標頭呈現，完美還原你的設計需求)
-- =========================================================

-- 查看畫面一：特殊期間劃假人數規則
SELECT 
    RIGHT('0' + CAST([RuleID] AS VARCHAR), 2) AS [規則編號],
    CONVERT(VARCHAR(10), [StartDate], 111) + ' ～ ' + CONVERT(VARCHAR(10), [EndDate], 111) AS [控制日期區間],
    CAST([MaxLeaveCount] AS VARCHAR) + ' 人' AS [每日劃假上限人數]
FROM [dbo].[LeaveLimitRule];

-- 查看畫面二：Ortho / Neuro 各時段留守人數最低限制
SELECT 
    [AreaCode]   AS [區域代碼],
    [AreaName]   AS [復健組別],
    [ShiftType]  AS [排班時段],
    CAST([MinStaffCount] AS VARCHAR) + ' 人' AS [當班人數最低下限],
    CONVERT(VARCHAR(16), [UpdateTime], 120) AS [更改時間]
FROM [dbo].[AreaShiftMinStaff]
ORDER BY [AreaCode] DESC, CASE [ShiftType] WHEN '上午' THEN 1 WHEN '下午' THEN 2 WHEN '晚上' THEN 3 END;
GO