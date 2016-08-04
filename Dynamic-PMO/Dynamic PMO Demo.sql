--select @@servername
--Register dll that we will use to allocate memory
--sp_addextendedproc 'xp_alloc', 'c:\SQL\xp_alloc.dll';
--select @@VERSION
--Show number of nodes and schedulers
--alter server configuration set softnuma off
select * from sys.dm_os_nodes
select * from sys.dm_os_schedulers where status='VISIBLE ONLINE'

--Turn off dynamic partitioning
dbcc traceon(8074,-1)

--Show a thread safe memory object
select type, creation_options,partition_type,contention_factor,waiting_tasks_count,exclusive_access_count
from 
sys.dm_os_memory_objects 
where type = 'MEMOBJ_XP'

--Clear the current stats to start afresh
dbcc sqlperf("sys.dm_os_wait_stats" , CLEAR )

--Verify that the waitstats have been cleared
select * from sys.dm_os_wait_stats where wait_type = 'CMEMTHREAD' 

--Create and start a new XE session to capture promotion events
CREATE EVENT SESSION [DynPMO] ON SERVER 
ADD EVENT sqlos.pmo_promotion (
    ACTION(sqlos.cpu_id,sqlos.numa_node_id,sqlos.scheduler_id))
ADD TARGET package0.event_file(SET filename=N'DynPMO')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=5 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=ON,STARTUP_STATE=OFF)

GO

ALTER EVENT SESSION DynPMO ON SERVER
 STATE = START
go

--Run stress.cmd to start the workload.
--Look at the contention 
select * from sys.dm_os_wait_stats where wait_type = 'CMEMTHREAD' 


select type, creation_options,partition_type,contention_factor,waiting_tasks_count,exclusive_access_count 
from 
sys.dm_os_memory_objects 
where type = 'MEMOBJ_XP'

--Enable dynamic promotion of memory object
dbcc traceoff(8074,-1)

--clear the stats and show that the contention is neglible
dbcc sqlperf("sys.dm_os_wait_stats" , CLEAR )
select * from sys.dm_os_wait_stats where wait_type = 'CMEMTHREAD' 

--Show that the object is now partitioned.
select type, creation_options,partition_type,contention_factor,waiting_tasks_count,exclusive_access_count 
from 
sys.dm_os_memory_objects 
where type = 'MEMOBJ_XP'

--Stop the session and examine the extended events
ALTER EVENT SESSION DynPMO ON SERVER
 STATE = stop
go


















--Look at various memory object types
select   memory_object_address
          , type
          , creation_options
          , case
                     when (0x80 = creation_options & 0x80) then 'Partitioning by Node requested'               
                     when (0x40 = creation_options & 0x40) then 'Partitioning by CPU requested.'
                     when (0x2 = creation_options & 0x2) then 'No partitioning requested'
                     else 'Not CMemThread'
               end as requested_partitioning
          , case     when partition_type = 0 then 'Non-partitionable memory object'
                     when partition_type = 1 or
                                        partition_type = 2 and ((select count(*) from sys.dm_os_memory_nodes) <= 2)
                                                                          then 'Partitionable memory object, currently not partitioned'
                     when partition_type = 2 then 'Partitionable memory object, partitioned by NUMA node'
                     when partition_type = 3 then 'Partitionable memory object, partitioned by CPU'
                     else 'Unknown'
               end as runtime_partitioning
          , partition_type
          , contention_factor
          , waiting_tasks_count
          , exclusive_access_count
from sys.dm_os_memory_objects

select * from sys.dm_os_memory_objects 
where  (0x82 = creation_options & 0xC2) and partition_type = 3
or     ((0x2 = creation_options & 0xC2) and (partition_type = 3 or partition_type = 2 and ((select count(*) from sys.dm_os_memory_nodes) > 2)))
