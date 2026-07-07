USE [復健科排班系統];
GO

-- =========================================================
-- 1. 檢查並清理舊的暫存表
-- =========================================================
IF OBJECT_ID('[dbo].[Table_1]', 'U') IS NOT NULL
    DROP TABLE [dbo].[Table_1];
GO

IF OBJECT_ID('[dbo].[Employee]', 'U') IS NOT NULL
    DROP TABLE [dbo].[Employee];
GO

-- =========================================================
-- 2. 建立完整版的員工/治療師基本資料表
-- =========================================================
CREATE TABLE [dbo].[Employee] (
    [EmployeeID] VARCHAR(10)  NOT NULL, -- 員工編號 (主鍵)
    [Name]       NVARCHAR(50) NOT NULL, -- 姓名
    [Gender]     CHAR(1)      NULL,     -- 性別 (M/F)
    [JobTitle]   NVARCHAR(30) NULL,     -- 職稱
    [Seniority]  INT          NULL,     -- 年資 (年)
    [IsActive]   BIT          NULL,     -- 在職狀態 (1=在職, 0=離職)
    
    CONSTRAINT [PK_Employee] PRIMARY KEY CLUSTERED ([EmployeeID] ASC)
);
GO

-- =========================================================
-- 3. 自動寫入測試資料
-- =========================================================
INSERT INTO [dbo].[Employee] ([EmployeeID], [Name], [Gender], [JobTitle], [Seniority], [IsActive])
VALUES ('EMP001', '陳美珠', 'F', '組長', 10, 1);

INSERT INTO [dbo].[Employee] ([EmployeeID], [Name], [Gender], [JobTitle], [Seniority], [IsActive])
VALUES ('EMP002', '子軒', 'M', '書記', 4, 1);

INSERT INTO [dbo].[Employee] ([EmployeeID], [Name], [Gender], [JobTitle], [Seniority], [IsActive])
VALUES ('EMP003', '王小明', 'M', '物理治療師', 4, 1);
GO

-- =========================================================
-- 4. 立即查看建立出來的資料表內容
-- =========================================================
SELECT 
    [EmployeeID] AS [員工編號],
    [Name]       AS [姓名],
    [Gender]     AS [性別],
    [JobTitle]   AS [職稱],
    [Seniority]  AS [年資(年)],
    CASE [IsActive] WHEN 1 THEN '在職' WHEN 0 THEN '離職' ELSE '未知' END AS [在職狀態]
FROM [dbo].[Employee];
GO