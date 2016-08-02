-- Mem Grant Warning

-- Added MIN_GRANT_PERCENT for repro on SQL 2014 SP2 and 2016 only, because fix for this scenario is in those releases.

--Execute in 2014 for warning; coming soon for 2016
USE [memgrants]
GO
DBCC FREEPROCCACHE
GO
SELECT o.col3, o.col2, d.col2
FROM orders o
JOIN orders_detail d ON o.col2 = d.col1
WHERE o.col3 <= 8000
OPTION (LOOP JOIN, MAXDOP 1, MIN_GRANT_PERCENT = 20)
GO

/*
In SELECT node properties:
MaxQueryMemory for maximum query memory grant under RG MAX_MEMORY_PERCENT hint
MaxCompileMemory for maximum query optimizer memory in KB during compile under RG
*/