on firefoxRunning()
	tell application "System Events" to (name of processes) contains "firefox"
end firefoxRunning

on firefoxForeground()
	tell application "System Events"
		set frontApp to name of first application process whose frontmost is true
		if (frontApp = "firefox") then
			return true
		else
			return false
		end if
	end tell
end firefoxForeground

on run argv
	
	if (firefoxRunning() = true) then
		repeat until firefoxForeground() = true
			tell application "Firefox" to activate
		end repeat
		tell application "System Events" to tell process "firefox"
			keystroke "t" using {command down}
			keystroke item 1 of argv & return
		end tell
	else
		do shell script "open -a Firefox " & (item 1 of argv)
	end if
end run
