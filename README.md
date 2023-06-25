# WebResponseCheck

***THIS IS STILL WIP***

Example of a powershell script that can read and output from a log file.

Straight forward powershell script that can be used to read a log file with an example log style.

Log Transaction sample:
```
2022-06-10T09:46:37.330 6300c7d4-dec5-43cf-af65-f9700745d33b GET /doc/comments - - - frontend19
2022-06-10T09:46:37.490 6300c7d4-dec5-43cf-af65-f9700745d33b HANDLE - - - - worker36
2022-06-10T09:46:37.600 6300c7d4-dec5-43cf-af65-f9700745d33b RESPOND - - 200 - frontend19
```

Log file is in a simple format with the following fields:
```
datestamp, request GUID, action type, requested url, -, status, -, server/worker id
```

The .ps1 will prompt for the path of the log file and then will prompt for a location to save the log file:

![File Path prompts](https://github.com/frasersmith5/WebResponseCheck/assets/2691536/7bba9386-263e-419a-a4f6-15575f461d56)

This will take some time depending on the size of the log file so be patient :)

Once the script has ran, the console will display an output to show any server that has a response time of over 500ms and will order them by their average highest response time:

![Script Completed](https://github.com/frasersmith5/WebResponseCheck/assets/2691536/eddfe33f-951d-4545-aa4b-e7af3340d5f4)

The response time can be configured by editing the .ps1 file on line 50 for POST to HANDLE actions and line 80 for HANDLE to RESPOND actions:

![Response Time Edit line](https://github.com/frasersmith5/WebResponseCheck/assets/2691536/09e1e222-f50f-4ffb-9c8c-d9ffbbca5e9a)

The log output file that is generated contains the same statistics as the console but also includes all of the entries that matches the criteria from the log. For example:

![sameple-output.log](https://github.com/frasersmith5/WebResponseCheck/assets/2691536/9508e015-a23f-4cc2-9fa3-faffd2b05bf5)

This script should run on any Windows system. I have attached 2x sample logs - a full size log with 600,000 log entries and a significantly shortened version with only 1000 lines (much quicker for testing). I have also attached a sample output file to show what you can expect - sample_output.log
