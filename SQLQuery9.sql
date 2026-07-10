USE [復健科排班系統];
GO

-- =========================================================
-- 1. 先強制刪除所有相關的鎖鏈表（解除外鍵綁定）
-- =========================================================
IF OBJECT_ID('[dbo].[NightShiftSchedule]', 'U') IS NOT NULL DROP TABLE [dbo].[NightShiftSchedule];
IF OBJECT_ID('[dbo].[EmployeeDispatch]', 'U') IS NOT NULL   DROP TABLE [dbo].[EmployeeDispatch];
IF OBJECT_ID('[dbo].[Account]', 'U') IS NOT NULL           DROP TABLE [dbo].[Account];
GO

-- =========================================================
-- 2. 刪除並重建【Employee 表】（已修正：職稱可自由填寫）
-- =========================================================
IF OBJECT_ID('[dbo].[Employee]', 'U') IS NOT NULL           DROP TABLE [dbo].[Employee];
GO

CREATE TABLE [dbo].[Employee] (
    [WorkId]       NVARCHAR(20)     NOT NULL, -- 員工編號 (如 333，作為主鍵)
    [EmpName]      NVARCHAR(50)     NULL,     -- 員工姓名
    [Gender]       NVARCHAR(10)     NULL,     -- 性別
    [JobTitle]     NVARCHAR(50)     NULL,     -- 職稱 (已拿掉預設值，前端傳什麼就存什麼！)
    [Email]        VARCHAR(100)     NULL,     -- 電子郵件
    [Phone]        VARCHAR(20)      NULL,     -- 手機號碼
    [HomeTel]      VARCHAR(20)      NULL,     -- 住處電話
    [PhotoPath]    NVARCHAR(255)    NULL,     -- 照片檔案路徑
    [ArrivalDate]  DATE             DEFAULT '2026-05-24' NOT NULL, -- 到職日
    [CreateAccountDate] DATETIME    DEFAULT GETDATE() NOT NULL, -- 開戶日期

    CONSTRAINT [PK_Employee] PRIMARY KEY CLUSTERED ([WorkId] ASC)
);
GO

-- =========================================================
-- 3. 重新塞入模擬測試資料（測試自訂職稱功能）
-- =========================================================
-- 這裡我們直接幫子軒自己輸入職稱叫「物理治療師」來測試
INSERT INTO [dbo].[Employee] ([WorkId], [EmpName], [Gender], [JobTitle], [Email], [Phone], [HomeTel], [PhotoPath])
VALUES ('333', '子軒', '男', '書記', 'XXXX@gmail.com', '0912-345678', '02-23456789', 'subright_photo.png');
GO

-- =========================================================
-- 4. 驗證查詢
-- =========================================================
SELECT * FROM [dbo].[Employee];
GO