USE [復健科排班系統];
GO

-- =========================================================
-- 1. 清理舊資料表 (確保環境乾淨)
-- =========================================================
IF OBJECT_ID('[dbo].[ShiftSwapApplication]', 'U') IS NOT NULL DROP TABLE [dbo].[ShiftSwapApplication];
GO

-- =========================================================
-- 2. 建立【調班申請表】
-- =========================================================
CREATE TABLE [dbo].[ShiftSwapApplication] (
    [SwapID]           INT IDENTITY(1,1) NOT NULL, -- 調班申請自動編號 (主鍵)
    
    -- 【調班編號】系統自動計算生成，例如: SWAP-20260710-001
    [FormDocNo]        AS ('SWAP-' + CONVERT(VARCHAR(8), [ApplyTime], 112) + '-' + RIGHT('000' + CAST([SwapID] AS VARCHAR), 3)), 

    -- A. 申請人資訊
    [ApplicantWorkId]  NVARCHAR(20)      NOT NULL, -- 申請人員工編號
    [SourceDate]       DATE              NOT NULL, -- 原持有的班次日期
    [SourceTime]       NVARCHAR(50)      NOT NULL, -- 原持有的班次時間
    [SourceArea]       NVARCHAR(50)      NOT NULL, -- 原持有的班次區域
    [Reason]           NVARCHAR(255)     NULL,     -- 調班原因留言
    [ApplyTime]        DATETIME          DEFAULT GETDATE() NOT NULL, -- 申請發起時間

    -- B. 調班對象資訊 & 審核欄位
    [TargetWorkId]     NVARCHAR(20)      NOT NULL, -- 被調班人員工編號
    [TargetDate]       DATE              NOT NULL, -- 想交換的班次日期
    [TargetTime]       NVARCHAR(50)      NOT NULL, -- 想交換的班次時間
    [TargetArea]       NVARCHAR(50)      NOT NULL, -- 想交換的班次區域 
    
    -- 不同意原因控制欄位
    [RejectReasonCode] INT               NULL,     -- 1=已安排私人行程, 2=體力/健康狀況不佳, 3=班次時段不適合, 4=其他
    [TargetReply]      NVARCHAR(255)     NULL,     -- 補充說明文字
    [TargetSignTime]   DATETIME          NULL,     -- 被調班人點擊時間

    -- C. 流程審核狀態 (1=待對方, 2=待書記, 3=待組長, 4=成功完成, 0=已拒絕)
    [Status]           INT               DEFAULT 1 NOT NULL, 

    -- D. 各關卡簽核歷史紀錄與 PDF 下載
    [ClerkWorkId]      NVARCHAR(20)      NULL,     
    [ClerkSignTime]    DATETIME          NULL,     
    [LeaderWorkId]     NVARCHAR(20)      NULL,     
    [LeaderSignTime]   DATETIME          NULL,     
    [PdfFilePath]      NVARCHAR(255)     NULL,     -- PDF 檔案下載路徑

    CONSTRAINT [PK_ShiftSwapApplication] PRIMARY KEY CLUSTERED ([SwapID] ASC),
    CONSTRAINT [FK_Swap_Applicant] FOREIGN KEY ([ApplicantWorkId]) REFERENCES [dbo].[Employee] ([WorkId]),
    CONSTRAINT [FK_Swap_Target]    FOREIGN KEY ([TargetWorkId])    REFERENCES [dbo].[Employee] ([WorkId])
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

-- 測試資料 1：申請剛送出 (Status=1)
INSERT INTO [dbo].[ShiftSwapApplication] (
    [ApplicantWorkId], [SourceDate], [SourceTime], [SourceArea], 
    [TargetWorkId], [TargetDate], [TargetTime], [TargetArea], [Reason], [Status])
VALUES (
    '333', '2026-10-15', '13:00~21:00', '運動治療區(N)', 
    '444', '2026-11-12', '13:00~21:00', '電療區(O)', '当月需照顾小孩', 1);

-- 測試資料 2：不同意退件 (Status=0)
INSERT INTO [dbo].[ShiftSwapApplication] (
    [ApplicantWorkId], [SourceDate], [SourceTime], [SourceArea], [Reason],
    [TargetWorkId], [TargetDate], [TargetTime], [TargetArea], 
    [RejectReasonCode], [TargetReply], [TargetSignTime], [Status])
VALUES (
    '333', '2026-08-20', '13:00~21:00', '電療區(O)', '需要北上開會', 
    '444', '2026-08-21', '13:00~21:00', '運動治療區(N)', 
    1, NULL, '2026-07-10 14:00:00', 0);

-- 測試資料 3：成功完成 (Status=4)
INSERT INTO [dbo].[ShiftSwapApplication] (
    [ApplicantWorkId], [SourceDate], [SourceTime], [SourceArea], [Reason],
    [TargetWorkId], [TargetDate], [TargetTime], [TargetArea], 
    [TargetSignTime], [Status], [ClerkWorkId], [ClerkSignTime], [LeaderWorkId], [LeaderSignTime], [PdfFilePath])
VALUES (
    '333', '2026-05-10', '13:00~21:00', '電療區(O)', '私人事假調整', 
    '444', '2026-05-11', '13:00~21:00', '運動治療區(N)', 
    '2026-05-01 14:00:00', 4, 'CLERK01', '2026-05-01 15:30:00', 'LEADER01', '2026-05-01 17:00:00',
    '/storage/pdf/SWAP-20260501-002.pdf');
GO

-- =========================================================
-- 4. 驗證查詢 (完美對齊請假總表：改為 [調班編號]、補上 [申請日期])
-- =========================================================
SELECT 
    S.[FormDocNo] AS [調班編號], -- 修正 1：正名為調班編號
    CONVERT(VARCHAR(10), S.[ApplyTime], 111) AS [申請日期], -- 修正 2：補上申請日期 (YYYY/MM/DD)
    E1.[EmpName] AS [申請人],
    CONVERT(VARCHAR(10), S.[SourceDate], 111) + ' ' + S.[SourceTime] + ' [' + S.[SourceArea] + ']' AS [原持有的班次],
    '調班' AS [動作],
    E2.[EmpName] AS [調班對象],
    CONVERT(VARCHAR(10), S.[TargetDate], 111) + ' ' + S.[TargetTime] + ' [' + S.[TargetArea] + ']' AS [想交換的班次],
    CASE S.[Status] 
        WHEN 1 THEN '步驟2：待對方審核' 
        WHEN 2 THEN '步驟3：待書記審核'
        WHEN 3 THEN '步驟4：待組長審核'
        WHEN 4 THEN '步驟5：調班成功(PDF已生成)' 
        ELSE '已拒絕/取消' 
    END AS [目前流程進度],
    CASE S.[RejectReasonCode]
        WHEN 1 THEN '已安排私人行程'
        WHEN 2 THEN '體力/健康狀況不佳'
        WHEN 3 THEN '班次時段不適合'
        WHEN 4 THEN '其他(' + ISNULL(S.[TargetReply], '') + ')'
        ELSE '' 
    END AS [不同意原因],
    ISNULL(S.[PdfFilePath], '—') AS [PDF實體檔案下載路徑]
FROM [dbo].[ShiftSwapApplication] S
INNER JOIN [dbo].[Employee] E1 ON S.[ApplicantWorkId] = E1.[WorkId]
INNER JOIN [dbo].[Employee] E2 ON S.[TargetWorkId] = E2.[WorkId]
ORDER BY S.[ApplyTime] DESC;
GO