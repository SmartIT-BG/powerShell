CONTACT:

<admin@smartit.bg>

REQUIREMENTS:

1. Requires PowerShell version >= 3.0 (check with $PSVersionTable.PSVersion)

INSTALL:

1. Requires administrative privileges for local and remote machine;

2. Run with Highest Privileges as a Task or elevated privileges (Run As Administrator)


3. Run sync_tasksch_sqlite_init.ps1 first for db initialization stuff

   NOTE: Initialize db and create accounts on machine on which script will be run,
   also, run with same account with which accounts in db are created (because of Secure strings).
  
    Account creation is needed if you run tasks with "Run whether user is logged in or not" option.

USAGE:

1. PowerShell -file sync_tasksch_folder.ps1 -syncFolder "task-folder-name" -remoteServer "acme.intranet"

   NOTE: you can specify how deep on tree is located directory, for example: -syncFolder "TaskFolder\SubFolder1\SubFolder2"
  
   If folder isn't exists on remote machine it will be created, also missing parent folders will be created

   WARNING: All tasks that does not exists on local machine folder, but on remote will be deleted from remote folder!