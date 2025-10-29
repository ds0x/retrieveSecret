--retrieveSecret: an AppleScript subroutine to retrieve secrets from AWS Secrets Manager.
--Disclaimer: retrieveSecret requires IAM permissions on the host to read the secret.
on awsMD(MDPath)
	set sessionToken to (do shell script "curl -X PUT http://169.254.169.254/latest/api/token -s -H 'X-aws-ec2-metadata-token-ttl-seconds: 21600'")
	set MDReturn to (do shell script "curl -H 'X-aws-ec2-metadata-token: " & sessionToken & "' -s http://169.254.169.254/latest/meta-data/" & MDPath)
	return MDReturn
end awsMD

set currentRegion to (my awsMD("placement/region"))

--The subroutine itself, called later as "my retrieveSecret("mySecretIdentifier")"
on retrieveSecret(secretRegion, secretID)
	--Detects the architecture type and sets AWS binary paths appropriately.
	set x86orASi to CPU type of (system info)
	if x86orASi contains "ARM" then
		set awsPath to "/opt/homebrew/bin/"
	else
		set awsPath to "/usr/local/bin/"
	end if
	--Initial command uses the aws command line tool and returns only the lines with "SecretString".
	set secretReturn to (do shell script awsPath & "aws secretsmanager get-secret-value --region " & secretRegion & " --secret-id " & secretID & " --query SecretString")
	--Parses the output of the command. First, removes the prefix…
	set AppleScript's text item delimiters to "\"{\\\""
	set secretBlob to text item 2 of secretReturn
	--Checks if multiple items are present, and creates a set of lists to return if so.
	if secretBlob contains "\\\",\\\"" then
		set multiSecret to {}
		set secretKeyList to {}
		set secretValueList to {}
		set AppleScript's text item delimiters to "\\\",\\\""
		repeat with i from 1 to (count text items of secretBlob)
			copy (text item i of secretBlob) to the end of multiSecret
		end repeat
		repeat with secretCount from 1 to (count multiSecret)
			set activeBlob to item secretCount of multiSecret
			--…separates the key and value using a closing quote and colon…
			set AppleScript's text item delimiters to "\\\":"
			set {secretKey, secretValue} to text items of activeBlob
			--…removes the opening quote from secretValue…
			set AppleScript's text item delimiters to "\\\""
			set secretValue to text item 2 of secretValue
			--…removes the closing curly bracket from the secretValue if the last one…
			if secretCount is equal to (count multiSecret) then
				set AppleScript's text item delimiters to "\\\"}"
				set secretValue to text item 1 of secretValue
			end if
			set AppleScript's text item delimiters to ""
			copy secretKey to the end of secretKeyList
			copy secretValue to the end of secretValueList
		end repeat
		return {secretKeyList, secretValueList}
	else
		--…separate the key and value using a closing quote and colon…
		set AppleScript's text item delimiters to "\\\":"
		set {secretKey, secretValue} to text items of secretBlob
		--…removes the closing curly bracket from the secretValue…
		set AppleScript's text item delimiters to "\\\"}"
		set secretValue to text item 1 of secretValue
		--…cleans the opening quote from secretValue…
		set AppleScript's text item delimiters to "\\\""
		set secretValue to text item 2 of secretValue
		set AppleScript's text item delimiters to ""
		--…and returns the clean key/value pair(s)!
		return {secretKey, secretValue}
	end if
end retrieveSecret


--Replace "viewLaunchCode" with the name of your AWS secret.
set {namesOfSecret, mySecretValues} to my retrieveSecret(currentRegion, "viewLaunchCode")

--This sample code will display the keys and values retrieved in a dialog, one per key-value pair.
repeat with i from 1 to (count namesOfSecret)
	display dialog "Secret " & i & ", called " & (item i of namesOfSecret as string) & ", is " & (item i of mySecretValues as string)
end repeat
