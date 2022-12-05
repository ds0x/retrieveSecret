--retrieveSecret: an AppleScript subroutine to retrieve secrets from AWS Secrets Manager.
--Disclaimer: retrieveSecret requires IAM permissions on the host to read the secret.


--The subroutine itself, called later as "my retrieveSecret("mySecretIdentifier")"
on retrieveSecret(secretID)
  --Initial command uses the aws command line tool and returns only the lines with "SecretString".
	set secretReturn to (do shell script "/usr/local/bin/aws secretsmanager get-secret-value --secret-id " & secretID & " | grep 'SecretString'")
  --Parses the output of the command. First, removes the prefix…
	set AppleScript's text item delimiters to "    \"SecretString\": \"{\\\""
	set secretBlob to text item 2 of secretReturn
  --…separates the values using a closing quote and colon…
	set AppleScript's text item delimiters to "\\\":"
	set {secretKey, secretValue} to text items of secretBlob
  --…removes the closing curly bracket from the secretValue…
	set AppleScript's text item delimiters to "\\\"}"
	set secretValue to text item 1 of secretValue
  --…removes the opening quote from secretValue…
	set AppleScript's text item delimiters to "\\\""
	set secretValue to text item 2 of secretValue
	set AppleScript's text item delimiters to ""
  --…and returns the clean key/value pair!
	return {secretKey, secretValue}
end retrieveSecret


--Replace "viewLaunchCode" with the ID of your AWS secret.
set {nameOfSecret,mySecretValue} to my retrieveSecret("viewLaunchCode")

display dialog "Your secret " & nameOfSecret & " is " & mySecretValue

--Multi-Secret support coming next!
