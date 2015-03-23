SmartIT <admin@smartit.bg>

Very simple script, that can permit or not your program to run on last day or first day of the current month.

Imagine this situation:

You are using 'Windows Task Scheduler' as your task scheduler. 
You need a schedule plan that runs your program every day, except last day or first day of the month. On Windows Server 2008 R2 you can't do it.

USAGE:

scheduleLastFirst.ps1 -scriptFile "yourscript.bat" -runOnFirstOfMonth "Off" -runOnLastOfMonth "On"