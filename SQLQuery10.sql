USE [復健科排班系統];
GO

-- =========================================================
-- 1. 清理舊的 Account 資料表
-- =========================================================
IF OBJECT_ID('[dbo].[Account]', 'U') IS NOT NULL
    DROP TABLE [dbo].[Account];
GO

-- =========================================================
-- 2. 建立全新的【帳號密碼表】(員工編號即為帳號)
-- =========================================================
CREATE TABLE [dbo].[Account] (
    [WorkId]     NVARCHAR(20)  NOT NULL, -- 帳號 (直接對應 Employee 表的員工編號)
    [Password]   VARCHAR(100)  NOT NULL, -- 密碼 (建議前端傳入時可做加密)
    [Status]     INT           DEFAULT 1 NOT NULL, -- 帳號狀態 (1=正常啟用, 0=停用)
    [UpdateTime] DATETIME      DEFAULT GETDATE() NOT NULL, -- 最後修改時間

    -- 設定 WorkId 為這張表的主鍵 (PK)
    CONSTRAINT [PK_Account] PRIMARY KEY CLUSTERED ([WorkId] ASC),
    
    -- 【核心外鍵設定】強烈綁定基本資料表！
    -- 確保 Account 表裡的帳號，必須是 Employee 表裡真正存在的 WorkId
    CONSTRAINT [FK_Account_Employee] FOREIGN KEY ([WorkId]) 
        REFERENCES [dbo].[Employee] ([WorkId])
        ON DELETE CASCADE -- 如果員工基本資料被刪除，帳密也會自動一起刪除，防止流浪資料
);
GO

-- =========================================================
-- 3. 寫入配合註冊畫面的模擬測試資料 (幫員工 333 子軒開通帳密)
-- =========================================================
INSERT INTO [dbo].[Account] ([WorkId], [Password], [Status])
VALUES ('333', 'password123', 1); -- 帳號就是 333
GO

-- =========================================================
-- 4. 驗證查詢 (模擬前端登入時，同時抓取「帳密」與「員工姓名」)
-- =========================================================
SELECT 
    A.[WorkId]   AS [帳號(員工編號)],
    A.[Password] AS [密碼],
    E.[EmpName]  AS [姓名],
    E.[JobTitle] AS [職稱],
    CASE A.[Status] WHEN 1 THEN '正常啟用' ELSE '停用' END AS [帳號狀態]
FROM [dbo].[Account] A
INNER JOIN [dbo].[Employee] E ON A.[WorkId] = E.[WorkId];
GO