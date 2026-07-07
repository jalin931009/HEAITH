USE [復健科排班系統];
GO

-- =========================================================
-- 1. 檢查並清理舊的 Announcement 資料表
-- =========================================================
IF OBJECT_ID('[dbo].[Announcement]', 'U') IS NOT NULL
    DROP TABLE [dbo].[Announcement];
GO

-- =========================================================
-- 2. 建立公告管理資料表 (包含公告內容)
-- =========================================================
CREATE TABLE [dbo].[Announcement] (
    [AnnouncementID] INT IDENTITY(1,1) NOT NULL, -- 公告編號 (自動遞增)
    [Title]          NVARCHAR(200)    NOT NULL, -- 公告標題
    [Content]        NVARCHAR(MAX)    NULL,     -- 公告內容 (新增：MAX可儲存無限長的文字)
    [Status]         NVARCHAR(20)     NOT NULL, -- 狀態 (如：已發布、草稿)
    [TargetAudience] NVARCHAR(100)    NULL,     -- 發布對象 (如：全部、特定姓名)
    [UpdateTime]     DATETIME         NOT NULL, -- 更新時間
    [Issuer]         NVARCHAR(50)     NOT NULL, -- 發布人

    -- 將 公告編號 設定為主鍵 (PK)
    CONSTRAINT [PK_Announcement] PRIMARY KEY CLUSTERED ([AnnouncementID] ASC)
);
GO

-- =========================================================
-- 3. 自動寫入包含「公告內容」的 3 筆測試資料
-- =========================================================
-- 筆數 01
INSERT INTO [dbo].[Announcement] ([Title], [Content], [Status], [TargetAudience], [UpdateTime], [Issuer])
VALUES (
    '每週一、五下午護理之家', 
    '請各位治療師注意，每週一與週五下午需前往護理之家進行支援，請提早準備相關器材。', 
    '已發布', '鄭組長、王曉明', '2025-11-27 11:50:00', '美珠(管理員)'
);

-- 筆數 02
INSERT INTO [dbo].[Announcement] ([Title], [Content], [Status], [TargetAudience], [UpdateTime], [Issuer])
VALUES (
    '10/15抽籤、第一輪劃假', 
    '下個月的排班劃假即將於10/15開放抽籤，請大家在截止日前至系統填寫志願。', 
    '草稿', '全部', '2026-01-15 14:40:00', '美珠(管理員)'
);

-- 筆數 03
INSERT INTO [dbo].[Announcement] ([Title], [Content], [Status], [TargetAudience], [UpdateTime], [Issuer])
VALUES (
    '2026年實習生', 
    '歡迎 2026 年新進實習生報到，詳細的教學計畫與環境介紹已上傳至共享資料夾。', 
    '已發布', '全部', '2026-01-15 14:40:00', '美珠(管理員)'
);
GO

-- =========================================================
-- 4. 立即查詢公告資料表 (包含顯示公告內容)
-- =========================================================
SELECT 
    RIGHT('0' + CAST([AnnouncementID] AS VARCHAR), 2) AS [編號],
    [Title]          AS [公告標題],
    [Content]        AS [公告內容], -- 查詢中顯示內容
    [Status]         AS [狀態],
    ISNULL([TargetAudience], '無') AS [發布對象],
    CONVERT(VARCHAR, [UpdateTime], 120) AS [更新時間],
    [Issuer]         AS [發布人]
FROM [dbo].[Announcement];
GO