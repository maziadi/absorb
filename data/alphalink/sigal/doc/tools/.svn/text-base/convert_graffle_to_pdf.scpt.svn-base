on run argv
	-- check arguments
	if (count of argv) is not 2 then
		error "usage OmniGraffleConverter input output"
	end if
	set theGraffleFile to POSIX file (item 1 of argv)
	set theBaseName to do shell script "basename \"" & (item 1 of argv) & "\" .graffle"
	set theOutputFile to POSIX file (item 2 of argv)
	
	tell application "OmniGraffle Professional 5"
		-- construct list of open documents
		set openDocCount to (the count of documents)
		set docList to {}
		if openDocCount > 0 then
			set theOriginalDoc to (the first document)
			repeat with i from 1 to number of items in documents
				set doc to item i of documents
				copy (name of doc) to the end of docList
			end repeat
		end if
		
		-- open file
		try
			open file theGraffleFile
		on error
			activate
			set theMessage to "Error: couldn't open file " & (item 1 of argv)
			beep
			display dialog theMessage buttons {"Ok"} with icon stop
			error theMessage
		end try
		
		-- export file
			save document theBaseName in theOutputFile
			if docList does not contain theBaseName then
				close document (theBaseName)
			end if
		
		-- TODO restore front document 
		if openDocCount > 0 then
			
		end if
		
	end tell
end run
