USE [復健科排班系統];
GO

-- =========================================================
-- 1. 清理舊的換班/傳班資料表
-- =========================================================
IF OBJECT_ID('[dbo].[ShiftTransferApplication]', 'U') IS NOT NULL DROP TABLE [dbo].[ShiftTransferApplication];
GO

-- =========================================================
-- 2. 建立【換班/傳班申請表】
-- =========================================================
CREATE TABLE [dbo].[ShiftTransferApplication] (
    [TransferID]       INT IDENTITY(1,1) NOT NULL, 

    -- 【換班編號】例如: XFER-20260710-001
    [FormDocNo]        AS ('XFER-' + CONVERT(VARCHAR(8), [ApplyTime], 112) + '-' + RIGHT('000' + CAST([TransferID] AS VARCHAR), 3)), 

    -- A. 申請人資訊
    [ApplicantWorkId]  NVARCHAR(20)      NOT NULL, 
    [SourceDate]       DATE              NOT NULL, 
    [SourceTime]       NVARCHAR(50)      NOT NULL, 
    [SourceArea]       NVARCHAR(50)      NOT NULL, 
    [Reason]           NVARCHAR(255)     NULL,     
    [ApplyTime]        DATETIME          DEFAULT GETDATE() NOT NULL, 

    -- B. 換班對象資訊
    [TargetWorkId]     NVARCHAR(20)      NOT NULL, 
    [TargetShiftInfo]  NVARCHAR(100)     NOT NULL, 
    
    -- 不同意原因小視窗
    [RejectReasonCode] INT               NULL,     
    [TargetReply]      NVARCHAR(255)     NULL,     
    [TargetSignTime]   DATETIME          NULL,     

    -- C. 流程審核狀態 (1=待對方確認, 2=待組長審核, 3=換班成功, 0=已拒絕)
    [Status]           INT               DEFAULT 1 NOT NULL, 

    -- D. 簽核歷史紀錄
    [LeaderWorkId]     NVARCHAR(20)      NULL,     
    [LeaderSignTime]   DATETIME          NULL,     

    CONSTRAINT [PK_ShiftTransferApplication] PRIMARY KEY CLUSTERED ([TransferID] ASC),
    CONSTRAINT [FK_Transfer_Applicant] FOREIGN KEY ([ApplicantWorkId]) REFERENCES [dbo].[Employee] ([WorkId]),
    CONSTRAINT [FK_Transfer_Target]    FOREIGN KEY ([TargetWorkId])    REFERENCES [dbo].[Employee] ([WorkId])
);
GO

-- =========================================================
-- 3. 寫入模擬開發測試資料
-- =========================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[Employee] WHERE [WorkId] = '444')
BEGIN
    INSERT INTO [dbo].[Employee] ([WorkId], [EmpName], [Gender], [JobTitle], [Email])
    VALUES ('444', '王小明', '男', '復健師', 'xiaoming@gmail.com');
END;

-- 測試資料 1
INSERT INTO [dbo].[ShiftTransferApplication] (
    [ApplicantWorkId], [SourceDate], [SourceTime], [SourceArea], 
    [TargetWorkId], [TargetShiftInfo], [Reason], [Status])
VALUES (
    '333', '2026-07-20', '08:00~16:00', '電療區(O)', 
    '444', '休假', '需要參與研討會', 1);

-- 測試資料 2
INSERT INTO [dbo].[ShiftTransferApplication] (
    [ApplicantWorkId], [SourceDate], [SourceTime], [SourceArea], [Reason],
    [TargetWorkId], [TargetShiftInfo], [RejectReasonCode], [TargetReply], [TargetSignTime], [Status])
VALUES (
    '333', '2026-07-22', '13:00~21:00', '運動治療區(N)', '臨時有私事處理', 
    '444', '2026/07-22 08:00~17:00 [電療區(O)]', 4, '那天下午我已經有排別家醫院的門診支援了', '2026-07-10 15:30:00', 0);

-- 測試資料 3
INSERT INTO [dbo].[ShiftTransferApplication] (
    [ApplicantWorkId], [SourceDate], [SourceTime], [SourceArea], [Reason],
    [TargetWorkId], [TargetShiftInfo], [TargetSignTime], [Status], [LeaderWorkId], [LeaderSignTime])
VALUES (
    '333', '2026-07-15', '08:00~12:00', '電療區(O)', '早班時間調整', 
    '444', '休假', '2026-07-09 10:00:00', 3, 'LEADER01', '2026-07-09 14:00:00');
GO

-- =========================================================
-- 4. 驗證查詢 (修正：由小到大排序，1號單會在最上面)
-- =========================================================
SELECT 
    T.[FormDocNo] AS [換班編號], 
    CONVERT(VARCHAR(10), T.[ApplyTime], 111) AS [申請日期],
    E1.[EmpName] AS [申請人],
    CONVERT(VARCHAR(10), T.[SourceDate], 111) + ' ' + T.[SourceTime] + ' [' + T.[SourceArea] + ']' AS [原持有的班次],
    '換班給' AS [動作],
    E2.[EmpName] AS [換班對象],
    T.[TargetShiftInfo] AS [換班對象原班次], 
    CASE T.[Status] 
        WHEN 1 THEN '待對方確認' 
        WHEN 2 THEN '待組長審核'
        WHEN 3 THEN '換班成功' 
        ELSE '已拒絕/取消' 
    END AS [目前流程進度],
    CASE T.[Status]
        WHEN 0 THEN 
            CASE T.[RejectReasonCode]
                WHEN 1 THEN '已安排私人行程'
                WHEN 2 THEN '體力/健康狀況不佳'
                WHEN 3 THEN '班次時段不適合'
                WHEN 4 THEN T.[TargetReply] 
                ELSE '未註明原因'
            END
        ELSE '' 
    END AS [不同意原因]
FROM [dbo].[ShiftTransferApplication] T
INNER JOIN [dbo].[Employee] E1 ON T.[ApplicantWorkId] = E1.[WorkId]
INNER JOIN [dbo].[Employee] E2 ON T.[TargetWorkId] = E2.[WorkId]
ORDER BY T.[TransferID] ASC; -- 核心修正：改為正序排列！
GO