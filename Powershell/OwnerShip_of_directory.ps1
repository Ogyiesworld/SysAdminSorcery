# Define the path to the directory that you want to take ownership of and modify permissions for
$Directory_Path = "C:\Users\administrator\Documents\WindowsPowerShell\Modules\AzureAD"

# Take ownership of the directory and all its contents
# /f specifies the file or directory to take ownership of
# /r applies the command to all files and subdirectories within the specified directory
# /d y automatically answers "yes" to any confirmation prompts (useful in a script to avoid manual intervention)
takeown /f $Directory_Path /r /d y

# Grant full control permissions to the current user (administrator in this case) for the directory and all its contents
# icacls is a command-line utility that modifies the access control lists (ACLs) of files and directories
# /grant adds specified user rights to the ACL
# administrator:F grants full control (F) to the user "administrator"
# /t applies the command to all specified files in the current directory and its subdirectories
icacls $Directory_Path /grant administrator:F /t
