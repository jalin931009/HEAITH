USE [復健科排班系統];
GO

-- =========================================================
-- 1. 檢查並清理舊的 EmployeeSerial 資料表
-- =========================================================
IF OBJECT_ID('[dbo].[EmployeeSerial]', 'U') IS NOT NULL
    DROP TABLE [dbo].[EmployeeSerial];
GO

-- =========================================================
-- 2. 建立【員工年度序號表】
-- =========================================================
CREATE TABLE [dbo].[EmployeeSerial] (
    [SerialID]     INT IDENTITY(1,1) NOT NULL, -- 系統自動編號 (主鍵)
    [SerialNumber] VARCHAR(20)     NOT NULL, -- 序號 (如：2026001)
    [EmpName]      NVARCHAR(50)    NOT NULL, -- 姓名
    [Gender]       NVARCHAR(10)    NOT NULL, -- 性別
    [YearNumber]   INT             NOT NULL, -- 年份 (用來區分是哪一年的序號)
    [CreateDate]   DATETIME        DEFAULT GETDATE() NOT NULL, -- 建立時間

    CONSTRAINT [PK_EmployeeSerial] PRIMARY KEY CLUSTERED ([SerialID] ASC),
    -- 確保同一年之內，同一個序號不會重複發放
    CONSTRAINT [UK_Year_Serial] UNIQUE ([YearNumber], [SerialNumber])
);
GO

-- =========================================================
-- 3. 自動寫入測試資料 (包含歷年數據，供前台程式碼抓取歷史紀錄)
-- =========================================================
INSERT INTO [dbo].[EmployeeSerial] ([SerialNumber], [EmpName], [Gender], [YearNumber])
VALUES 
-- 2024 年資料
('2024001', '林子軒', '男', 2024),
('2024002', '陳美珠', '女', 2024),

-- 2025 年資料
('2025001', '林子軒', '男', 2025),
('2025002', '陳美珠', '女', 2025),

-- 2026 年資料
('2026001', '林子軒', '男', 2026),
('2026002', '陳美珠', '女', 2026);
GO

-- =========================================================
-- 4. 查詢顯示成果
-- =========================================================
SELECT 
    CAST([YearNumber] AS VARCHAR) + ' 年' AS [年度],
    [SerialNumber] AS [序號],
    [EmpName]      AS [姓名],
    [Gender]       AS [性別]
FROM [dbo].[EmployeeSerial]
ORDER BY [YearNumber] DESC, [SerialNumber] ASC;
GO