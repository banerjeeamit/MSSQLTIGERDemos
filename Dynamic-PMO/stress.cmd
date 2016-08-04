.\ostress.exe -S.\SQLPMO -E -d"master" -Q"execute xp_alloc 100, 1" -n40 -r100000 -b -q

REM .\ostress.exe -S.\SQL14SP2 -E -d"master" -Q"execute xp_alloc 100, 1" -n40 -r100000 -b -q