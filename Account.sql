USE [復健科排班系統];
GO

-- =========================================================
-- 1. 檢查並清理舊的 Account 資料表 (避免重複執行報錯)
-- =========================================================
IF OBJECT_ID('[dbo].[Account]', 'U') IS NOT NULL
    DROP TABLE [dbo].[Account];
GO

-- =========================================================
-- 2. 建立帳號密碼權限資料表 (包含忘記密碼驗證功能)
-- =========================================================
CREATE TABLE [dbo].[Account] (
    [AccountID]  VARCHAR(20)  NOT NULL, -- 帳號 (主鍵，如：admin, user01)
    [Password]   VARCHAR(100) NOT NULL, -- 密碼 
    [Email]      VARCHAR(100) NOT NULL, -- 電子信箱 (用來寄送忘記密碼驗證信)
    [EmployeeID] VARCHAR(10)  NULL,     -- 員工編號 (對應到 Employee 表)
    [Role]       NVARCHAR(20) NULL,     -- 權限角色 (如：管理員、復健師)
    [CreateDate] DATETIME     DEFAULT GETDATE(), -- 帳號建立時間 (自動帶入當下時間)
    [IsLocked]   BIT          DEFAULT 0,         -- 帳號鎖定狀態 (0=正常, 1=被鎖定)

    -- 【忘記密碼與驗證碼專用欄位】
    [ResetCode]           VARCHAR(10) NULL, -- 暫存驗證碼 (產生時寫入，驗證成功後清空)
    [ResetCodeExpireTime] DATETIME    NULL, -- 驗證碼過期時間 (用來檢查是否在時效內)

    -- 將 登入帳號 (AccountID) 設定為主鍵 (PK)
    CONSTRAINT [PK_Account] PRIMARY KEY CLUSTERED ([AccountID] ASC)
);
GO

-- =========================================================
-- 3. 自動寫入 3 筆測試帳密資料 (包含信箱欄位)
-- =========================================================
-- 帳密 1：管理員
INSERT INTO [dbo].[Account] ([AccountID], [Password], [Email], [EmployeeID], [Role], [IsLocked])
VALUES ('admin', 'admin123', 'admin@rehab.tw', 'EMP001', '管理員', 0);

-- 帳密 2：管理員
INSERT INTO [dbo].[Account] ([AccountID], [Password], [Email], [EmployeeID], [Role], [IsLocked])
VALUES ('taming', 'pwd456', 'taming@rehab.tw', 'EMP002', '管理員', 0);

-- 帳密 3：復健師
INSERT INTO [dbo].[Account] ([AccountID], [Password], [Email], [EmployeeID], [Role], [IsLocked])
VALUES ('TEST', 'BBC713', 'test_therapist@rehab.tw', 'EMP003', '復健師', 0);
GO

-- =========================================================
-- 4. 立即查看建立出來的帳密資料表內容
-- =========================================================
SELECT 
    [AccountID]  AS [帳號],
    [Password]   AS [密碼],
    [Email]      AS [電子信箱],
    [EmployeeID] AS [員工編號],
    [Role]       AS [權限角色],
    CONVERT(VARCHAR, [CreateDate], 120) AS [建立時間],
    CASE [IsLocked] WHEN 1 THEN '已鎖定' WHEN 0 THEN '正常' ELSE '未知' END AS [帳號狀態],
    ISNULL([ResetCode], '無暫存驗證碼') AS [重設驗證碼],
    ISNULL(CONVERT(VARCHAR, [ResetCodeExpireTime], 120), '未申請') AS [驗證碼過期時間]
FROM [dbo].[Account];
GO