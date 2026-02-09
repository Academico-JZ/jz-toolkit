Set fso = CreateObject("Scripting.FileSystemObject")
Set WshShell = CreateObject("WScript.Shell")
strPath = fso.GetParentFolderName(WScript.ScriptFullName)
WshShell.Run Chr(34) & strPath & "\LimpezaSilenciosa.bat" & Chr(34), 0, False
