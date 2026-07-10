USE [復健科排班系統];
GO

-- =========================================================
-- 1. 清理舊資料表 (確保環境乾淨)
-- =========================================================
IF OBJECT_ID('[dbo].[WorkHours]', 'U')        IS NOT NULL DROP TABLE [dbo].[WorkHours];
IF OBJECT_ID('[dbo].[AttendanceRecord]', 'U') IS NOT NULL DROP TABLE [dbo].[AttendanceRecord];
GO

-- =========================================================
-- 2. 建立【當日出缺勤明細表】
-- =========================================================
CREATE TABLE [dbo].[AttendanceRecord] (
    [AttendanceID]     INT IDENTITY(1,1) NOT NULL, 
    [WorkId]           NVARCHAR(20)      NOT NULL, 
    [LogDate]          DATE              NOT NULL, 
    [AttendanceStatus] NVARCHAR(20)      NOT NULL, 
    [ActualHours]      DECIMAL(4,1)      NOT NULL, 
    [UpdateTime]       DATETIME          DEFAULT GETDATE() NOT NULL,

    CONSTRAINT [PK_AttendanceRecord] PRIMARY KEY CLUSTERED ([AttendanceID] ASC),
    CONSTRAINT [UK_Emp_Attendance_Date] UNIQUE ([WorkId], [LogDate]),
    CONSTRAINT [FK_Attendance_Employee] FOREIGN KEY ([WorkId]) REFERENCES [dbo].[Employee] ([WorkId])
);
GO

-- =========================================================
-- 3. 建立【WorkHours 工時資料表】(實體儲存每週統計)
-- =========================================================
CREATE TABLE [dbo].[WorkHours] (
    [WorkHoursID]      INT IDENTITY(1,1) NOT NULL, 
    
    -- 【特別設計】：保留「週開始日」與「週結束日」，這樣不管要撈單週還是 4 週的大週期，都超級好抓！
    [WeekNoString]     NVARCHAR(100)     NOT NULL, 
    [WeekStartDate]    DATE              NOT NULL, -- 週開始日期
    [WeekEndDate]      DATE              NOT NULL, -- 週結束日期
    
    [WorkId]           NVARCHAR(20)      NOT NULL, 
    [RequiredHours]    INT               NOT NULL, -- 本周應工時 (A)
    [ActualHoursSum]   INT               NOT NULL, -- 實際上班工時 (B)
    [ApprovedLeaveHrs] INT               NOT NULL, -- 已核准請假時數 (C)
    
    -- 【自動計算欄位】：應補未請時數 (B + C - A)
    [OwedHours]        AS (([ActualHoursSum] + [ApprovedLeaveHrs]) - [RequiredHours]), 

    [WeekStatusText]   NVARCHAR(50)      DEFAULT '時數無異常' NOT NULL,
    [LastCalcTime]     DATETIME          DEFAULT GETDATE() NOT NULL,

    CONSTRAINT [PK_WorkHours] PRIMARY KEY CLUSTERED ([WorkHoursID] ASC),
    CONSTRAINT [UK_Week_Employee_Hours] UNIQUE ([WeekNoString], [WorkId]),
    CONSTRAINT [FK_WorkHours_Employee] FOREIGN KEY ([WorkId]) REFERENCES [dbo].[Employee] ([WorkId])
);
GO

-- =========================================================
-- 4. 寫入模擬開發測試假資料 (完整模擬第 43 週期內的 4 個禮拜)
-- =========================================================
DBCC CHECKIDENT ('[dbo].[WorkHours]', RESEED, 0);

-- 確保測試員工「子軒」與「蔡承佑」存在
IF NOT EXISTS (SELECT 1 FROM [dbo].[Employee] WHERE [WorkId] = '333') INSERT INTO [dbo].[Employee] ([WorkId], [EmpName], [Gender], [JobTitle]) VALUES ('333', '子軒', '男', '復健師');
IF NOT EXISTS (SELECT 1 FROM [dbo].[Employee] WHERE [WorkId] = '777') INSERT INTO [dbo].[Employee] ([WorkId], [EmpName], [Gender], [JobTitle]) VALUES ('777', '蔡承佑', '男', '復健師');

-- 灌入第 43 週期（04/13 ~ 05/10）內完整 4 週的數據
INSERT INTO [dbo].[WorkHours] ([WeekNoString], [WeekStartDate], [WeekEndDate], [WorkId], [RequiredHours], [ActualHoursSum], [ApprovedLeaveHrs], [WeekStatusText])
VALUES
-- 【第 1 週：04/13 ~ 04/19】
('第43週期_第1週', '2026-04-13', '2026-04-19', '333', 40, 40, 0, '時數無異常'),
('第43週期_第1週', '2026-04-13', '2026-04-19', '777', 40, 32, 0, '尚未請假'), -- 蔡承佑這週缺 8 小時

-- 【第 2 週：04/20 ~ 04/26】
('第43週期_第2週', '2026-04-20', '2026-04-26', '333', 40, 40, 0, '時數無異常'),
('第43週期_第2週', '2026-04-20', '2026-04-26', '777', 40, 40, 0, '時數無異常'),

-- 【第 3 週：04/27 ~ 05/03】
('第43週期_第3週', '2026-04-27', '2026-05-03', '333', 40, 40, 0, '時數無異常'),
('第43週期_第3週', '2026-04-27', '2026-05-03', '777', 40, 40, 0, '時數無異常'),

-- 【第 4 週：05/04 ~ 05/10】
('第43週期_第4週', '2026-05-04', '2026-05-10', '333', 40, 40, 0, '時數無異常'),
('第43週期_第4週', '2026-05-04', '2026-05-10', '777', 40, 40, 0, '時數無異常');
GO

-- =========================================================
-- 5. 驗證查詢：【大週期工時畫面】
-- 當美珠姐在網頁按「第43週期 (2026-04-13~2026-05-10)」，Java 就丟出這段 SQL
-- =========================================================
SELECT 
    '第43週期 (2026-04-13~2026-05-10)' AS [查詢排班週期],
    E.[EmpName] AS [員工姓名],
    CASE E.[JobTitle] WHEN '實習生' THEN '實習生' ELSE '正職復健師' END AS [身分類別],
    
    -- 4 週總和計算
    CAST(SUM(W.[RequiredHours]) AS VARCHAR) + '小時' AS [週期應工時(A)],
    CAST(SUM(W.[ActualHoursSum]) AS VARCHAR) + '小時' AS [實際上班工時(B)],
    CAST(SUM(W.[ApprovedLeaveHrs]) AS VARCHAR) + '小時' AS [已核准請假時數(C)],
    CAST(SUM(W.[OwedHours]) AS VARCHAR) + '小時' AS [應補未請時數(B+C-A)],
    
    -- 週期狀態判定：只要這 4 週內有任何一週小於 0 且沒請假，就亮紅燈
    CASE 
        WHEN SUM(W.[OwedHours]) < 0 THEN '尚未請假'
        ELSE '時數無異常'
    END AS [週期工時狀態]

FROM [dbo].[WorkHours] W
INNER JOIN [dbo].[Employee] E ON W.[WorkId] = E.[WorkId]

-- 【關鍵核心】：利用 BETWEEN 限制日期，完美把這 28 天涵蓋的所有週通通抓出來加總！
WHERE W.[WeekStartDate] >= '2026-04-13' AND W.[WeekEndDate] <= '2026-05-10'

GROUP BY E.[EmpName], E.[JobTitle]
ORDER BY SUM(W.[ActualHoursSum]) DESC;
GO