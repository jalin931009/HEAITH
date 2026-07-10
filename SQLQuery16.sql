USE [復健科排班系統];
GO

-- =========================================================
-- 運用【條件聚合 (Conditional Aggregation)】
-- 把直直的資料庫明細，一秒變成你想要的「橫向班次對照表」！
-- =========================================================
SELECT 
    CONVERT(VARCHAR(10), S.[ScheduleDate], 111) AS [排班日期],
    DATENAME(WEEKDAY, S.[ScheduleDate]) AS [星期],
    
    -- A. 電療區 (O) 的各時段排班 (動態把同格的人用逗號分開)
    ISNULL(STRING_AGG(CASE WHEN S.[WorkArea] = '電療區(O)' AND S.[ShiftType] = '早班' THEN E.[EmpName] END, '、'), '—') AS [電療區_早班],
    ISNULL(STRING_AGG(CASE WHEN S.[WorkArea] = '電療區(O)' AND S.[ShiftType] = '午班' THEN E.[EmpName] END, '、'), '—') AS [電療區_午班],
    ISNULL(STRING_AGG(CASE WHEN S.[WorkArea] = '電療區(O)' AND S.[ShiftType] = '晚班' THEN E.[EmpName] END, '、'), '—') AS [電療區_晚班],
    
    -- B. 運動治療區 (N) 的各時段排班
    ISNULL(STRING_AGG(CASE WHEN S.[WorkArea] = '運動治療區(N)' AND S.[ShiftType] = '早班' THEN E.[EmpName] END, '、'), '—') AS [運動區_早班],
    ISNULL(STRING_AGG(CASE WHEN S.[WorkArea] = '運動治療區(N)' AND S.[ShiftType] = '午班' THEN E.[EmpName] END, '、'), '—') AS [運動區_午班],
    ISNULL(STRING_AGG(CASE WHEN S.[WorkArea] = '運動治療區(N)' AND S.[ShiftType] = '晚班' THEN E.[EmpName] END, '、'), '—') AS [運動區_晚班],
    
    -- C. 當天排休的人員清單
    ISNULL(STRING_AGG(CASE WHEN S.[ShiftType] = '排休' THEN E.[EmpName] END, '、'), '—') AS [當日排休人員]

FROM [dbo].[InitialSchedule] S
INNER JOIN [dbo].[Employee] E ON S.[WorkId] = E.[WorkId]
GROUP BY S.[ScheduleDate]
ORDER BY S.[ScheduleDate] ASC;
GO