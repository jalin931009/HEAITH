USE [復健科排班系統];
GO

-- =========================================================
-- 1. 清理舊的請假相關資料表 (確保環境乾淨)
-- =========================================================
IF OBJECT_ID('[dbo].[LeaveDetail]', 'U')       IS NOT NULL DROP TABLE [dbo].[LeaveDetail];
IF OBJECT_ID('[dbo].[LeaveApplication]', 'U')  IS NOT NULL DROP TABLE [dbo].[LeaveApplication];
IF OBJECT_ID('[dbo].[EmployeeLeaveQuota]', 'U') IS NOT NULL DROP TABLE [dbo].[EmployeeLeaveQuota];
GO

-- =========================================================
-- 2. 建立【員工年度假別配額表】
-- =========================================================
CREATE TABLE [dbo].[EmployeeLeaveQuota] (
    [QuotaID]          INT IDENTITY(1,1) NOT NULL,
    [WorkId]           NVARCHAR(20)      NOT NULL,
    [LeaveType]        NVARCHAR(20)      NOT NULL,
    [YearOption]       INT               NOT NULL,
    [TotalDays]        DECIMAL(4,1)      NOT NULL,
    [RemainingDays]    DECIMAL(4,1)      NOT NULL,
    [UpdateTime]       DATETIME          DEFAULT GETDATE() NOT NULL,

    CONSTRAINT [PK_EmployeeLeaveQuota] PRIMARY KEY CLUSTERED ([QuotaID] ASC),
    CONSTRAINT [UK_Emp_Leave_Year] UNIQUE ([WorkId], [LeaveType], [YearOption]),
    CONSTRAINT [FK_Quota_Employee] FOREIGN KEY ([WorkId]) REFERENCES [dbo].[Employee] ([WorkId])
);
GO

-- =========================================================
-- 3. 建立【請假主表】
-- =========================================================
CREATE TABLE [dbo].[LeaveApplication] (
    [LeaveID]          INT IDENTITY(1,1) NOT NULL, 
    
    -- 標準格式：LEAVE-20260710-001
    [FormDocNo]        AS ('LEAVE-' + CONVERT(VARCHAR(8), [ApplyTime], 112) + '-' + RIGHT('000' + CAST([LeaveID] AS VARCHAR), 3)), 

    [WorkId]           NVARCHAR(20)      NOT NULL, 
    [ApplyType]        NVARCHAR(20)      NOT NULL, 
    [LeaveType]        NVARCHAR(20)      NOT NULL, 
    [AgentWorkId]      NVARCHAR(20)      NOT NULL, 
    [ReasonNotes]      NVARCHAR(255)     NULL,     
    [TotalHours]       DECIMAL(5,1)      NOT NULL, 
    [ApplyTime]        DATETIME          DEFAULT GETDATE() NOT NULL, 

    [RejectReasonCode] INT               NULL,     
    [RejectReply]      NVARCHAR(255)     NULL,     
    [AgentSignTime]    DATETIME          NULL,     

    [Status]           INT               DEFAULT 1 NOT NULL, 

    [ClerkWorkId]      NVARCHAR(20)      NULL, 
    [ClerkSignTime]    DATETIME          NULL, 
    [LeaderWorkId]     NVARCHAR(20)      NULL, 
    [LeaderSignTime]   DATETIME          NULL, 
    [PdfFilePath]      NVARCHAR(255)     NULL,     

    CONSTRAINT [PK_LeaveApplication] PRIMARY KEY CLUSTERED ([LeaveID] ASC),
    CONSTRAINT [FK_Leave_Employee] FOREIGN KEY ([WorkId]) REFERENCES [dbo].[Employee] ([WorkId]),
    CONSTRAINT [FK_Leave_Agent]    FOREIGN KEY ([AgentWorkId]) REFERENCES [dbo].[Employee] ([WorkId])
);
GO

-- =========================================================
-- 4. 建立【請假日期時間明細表】
-- =========================================================
CREATE TABLE [dbo].[LeaveDetail] (
    [DetailID]         INT IDENTITY(1,1) NOT NULL,
    [LeaveID]          INT               NOT NULL,
    [LeaveDate]        DATE              NOT NULL,
    [TimeType]         NVARCHAR(20)      NOT NULL,
    [StartTime]        VARCHAR(5)        NULL,
    [EndTime]          VARCHAR(5)        NULL,
    [HoursCount]       DECIMAL(4,1)      NOT NULL,

    CONSTRAINT [PK_LeaveDetail] PRIMARY KEY CLUSTERED ([DetailID] ASC),
    CONSTRAINT [FK_Detail_Leave] FOREIGN KEY ([LeaveID]) REFERENCES [dbo].[LeaveApplication] ([LeaveID]) ON DELETE CASCADE
);
GO

-- =========================================================
-- 5. 寫入模擬開發測試資料
-- =========================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[Employee] WHERE [WorkId] = '555')
BEGIN
    INSERT INTO [dbo].[Employee] ([WorkId], [EmpName], [Gender], [JobTitle]) VALUES ('555', '王小美', '女', '復健師');
END;

IF NOT EXISTS (SELECT 1 FROM [dbo].[EmployeeLeaveQuota] WHERE [WorkId] = '333' AND [LeaveType] = '特休')
BEGIN
    INSERT INTO [dbo].[EmployeeLeaveQuota] ([WorkId], [LeaveType], [YearOption], [TotalDays], [RemainingDays]) VALUES ('333', '特休', 2026, 7.0, 5.0);
END;

-- 單據 1：待職代審核
INSERT INTO [dbo].[LeaveApplication] ([WorkId], [ApplyType], [LeaveType], [AgentWorkId], [ReasonNotes], [TotalHours], [Status])
VALUES ('333', '網班請假(3日前)', '事假', '555', '照顧小孩', 20.0, 1);

DECLARE @NewLeaveID INT = SCOPE_IDENTITY();
INSERT INTO [dbo].[LeaveDetail] ([LeaveID], [LeaveDate], [TimeType], [StartTime], [EndTime], [HoursCount])
VALUES (@NewLeaveID, '2026-05-17', '整天', '08:00', '17:00', 8.0),
       (@NewLeaveID, '2026-05-18', '整天', '08:00', '17:00', 8.0),
       (@NewLeaveID, '2026-05-19', '彈性小時', '13:00', '17:00', 4.0);

-- 單據 2：不同意退件
INSERT INTO [dbo].[LeaveApplication] ([WorkId], [ApplyType], [LeaveType], [AgentWorkId], [TotalHours], [Status], [RejectReasonCode], [RejectReply], [AgentSignTime])
VALUES ('333', '網班請假(3日前)', '事假', '555', 8.0, 0, 4, '未在三日前提交申請', '2026-05-15 11:00:00');

-- 單據 3：已核准通過
INSERT INTO [dbo].[LeaveApplication] ([WorkId], [ApplyType], [LeaveType], [AgentWorkId], [TotalHours], [Status], [AgentSignTime], [ClerkWorkId], [ClerkSignTime], [LeaderWorkId], [LeaderSignTime], [PdfFilePath])
VALUES ('333', '網班請假(3日前)', '特休', '555', 8.0, 4, '2026-04-21 09:00:00', 'CLERK01', '2026-04-21 11:00:00', 'LEADER01', '2026-04-21 14:00:00', '/storage/pdf/LEAVE-20260421-003.pdf');
GO

-- =========================================================
-- 6. 驗證查詢 (完美修正：精準補上【申請人】欄位！)
-- =========================================================
SELECT 
    S.[FormDocNo] AS [請假編號], 
    CONVERT(VARCHAR(10), S.[ApplyTime], 111) AS [申請日期],
    E1.[EmpName]  AS [申請人], -- 這裡！把請假本人的姓名抓出來秀在總表上！
    S.[LeaveType] AS [請假類別],
    ISNULL(
        (SELECT TOP 1 CONVERT(VARCHAR(10), D.[LeaveDate], 111) FROM [dbo].[LeaveDetail] D WHERE D.[LeaveID] = S.[LeaveID] ORDER BY D.[LeaveDate] ASC) + ' ~ ' +
        (SELECT TOP 1 CONVERT(VARCHAR(10), D.[LeaveDate], 111) FROM [dbo].[LeaveDetail] D WHERE D.[LeaveID] = S.[LeaveID] ORDER BY D.[LeaveDate] DESC),
        CONVERT(VARCHAR(10), S.[ApplyTime], 111)
    ) + ' (共 ' + CAST(S.[TotalHours] AS VARCHAR) + ' 小時)' AS [請假日期/時間],
    E2.[EmpName] AS [職務代理人],
    CASE S.[Status]
        WHEN 1 THEN '職代審核'
        WHEN 2 THEN '書記審核'
        WHEN 3 THEN '組長審核'
        ELSE '已完成'
    END AS [目前狀態],
    CASE S.[Status]
        WHEN 0 THEN '不同意'
        WHEN 4 THEN '同意'
        ELSE '前往審核'
    END AS [審核結果],
    CASE S.[Status]
        WHEN 0 THEN 
            CASE S.[RejectReasonCode]
                WHEN 1 THEN '已安排私人行程'
                WHEN 2 THEN '體力健康狀況不佳'
                WHEN 3 THEN '班次時段不適合'
                WHEN 4 THEN S.[RejectReply]
                ELSE '未註明原因'
            END
        ELSE ''
    END AS [不同意原因],
    ISNULL(S.[PdfFilePath], '—') AS [PDF實體檔案下載路徑]
FROM [dbo].[LeaveApplication] S
INNER JOIN [dbo].[Employee] E1 ON S.[WorkId] = E1.[WorkId] -- 串接基本資料表抓申請人名字
INNER JOIN [dbo].[Employee] E2 ON S.[AgentWorkId] = E2.[WorkId] -- 串接基本資料表抓職代名字
ORDER BY S.[ApplyTime] DESC;
GO