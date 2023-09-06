USE [bedagDBA]
GO
--Versuch
IF OBJECT_ID(N'tempdb..#dcus') IS NOT NULL DROP TABLE #dcus
SELECT
	 [primary] = [a].[instance]
	,[secondary] = [b].[instance]
	,[ha] = CASE WHEN [b].[instance] IS NULL THEN N'bronze' ELSE N'platin' END
	,[env] = CASE
				WHEN SUBSTRING([a].[instance], 4,1) = N'A' THEN N'A - prod'
				WHEN SUBSTRING([a].[instance], 4,1) = N'T' THEN N'T - entwicklung'
				WHEN SUBSTRING([a].[instance], 4,1) = N'U' THEN N'U - test'
			END
	,[a].[maxsrvmem]
	,[dcu] = [a].[maxsrvmem]/10240
INTO
	#dcus
FROM 
	[invnt_all].[sql_collinstoptions] [a]
	LEFT JOIN [invnt_all].[sql_collinstoptions] [b]
	ON [b].[instance] LIKE N'%AF4%D2%'
	AND REPLACE(RIGHT([a].[instance],PATINDEX(N'%\%',REVERSE([a].[instance]))-1),N'DB', N'D2')  = RIGHT([b].[instance],PATINDEX(N'%\%',REVERSE([b].[instance]))-1)
WHERE 
	[a].[instance] LIKE N'%AF4%DB%'

IF OBJECT_ID(N'tempdb..#dbs') IS NOT NULL DROP TABLE #dbs
SELECT
	 [a].[instance]
	,[env] = CASE
				WHEN SUBSTRING([a].[instance], 4,1) = N'A' THEN N'A - prod'
				WHEN SUBSTRING([a].[instance], 4,1) = N'T' THEN N'T - entwicklung'
				WHEN SUBSTRING([a].[instance], 4,1) = N'U' THEN N'U - test'
			END
	,[a].[dbname]
	,[data_size_mb] = CAST(SUM([a].[size_used_mb]) AS money)
INTO
	#dbs
FROM
	[bedagDBA].[invnt_all].[sql_colldbfileinfos] [a]
WHERE
	(
	[a].[dbname] LIKE N'%AF4%'
	OR [a].[instance] LIKE N'%AF4%'
	) 
	AND [a].[dbname] NOT IN (N'master',N'model',N'msdb',N'tempdb',N'bedagDBA')
	AND [a].[type] = N'ROWS'
GROUP BY
	 [a].[instance]
	,[a].[dbname]
ORDER BY 1


SELECT *
	,[data] = (SELECT SUM([data_size_mb]) FROM #dbs WHERE [instance] = [a].[primary])
	,[ram-oltp-10perc] = (SELECT SUM([data_size_mb]) FROM #dbs WHERE [instance] = [a].[primary])/10
	,[ram-olap-01perc] = (SELECT SUM([data_size_mb]) FROM #dbs WHERE [instance] = [a].[primary])/100
FROM 
	#dcus [a]

SELECT 
	 *
	,[ram-oltp-10perc] = [data_size_mb]/10
	,[dbru-oltp] = CAST([data_size_mb]/10/512+1 as int)
	,[ram-olap-01perc] = [data_size_mb]/100
	,[dbru-olap] = CAST([data_size_mb]/100/512+1 as int)
FROM #dbs