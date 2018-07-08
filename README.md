# Google-Spreadsheet-To-Calendar-With-Ballerina

Integration of Google Sheets with Ballerina to create events on Google Calendar using the data from spread sheet.

	Add the credentails reqiured in the ballerina.conf file
	
## Working with gsheets4 Connector actions

In order for you to use the gsheets4 Connector, first you need to create a gsheets4 Client endpoint.

	endpoint gsheets4:Client spreadsheetClient {
    clientConfig: {
        auth: {
            accessToken: config:getAsString("OAUTH2_ACCESS_TOKEN"),
            refreshToken: config:getAsString("OAUTH2_REFRESH_TOKEN"),
            clientId: config:getAsString("OAUTH2_CLIENT_ID"),
            clientSecret:  config:getAsString("OAUTH2_CLIENT_SECRET")
        }
    }
	};
	
The credentials stored in the ballerina.conf file is accessed and assigned to authenticate the client.
	

## Working with googleAPIs

Google APIS are conected through http requests, in order to use the http request must create an endpoint to auth the client.

	endpoint http:Client oauth2Client {
    url: config:getAsString("OAUTH2_BASE_URL"),
    auth: {
        scheme: http:OAUTH2,
        accessToken: config:getAsString("OAUTH2_ACCESS_TOKEN"),
        clientId: config:getAsString("OAUTH2_CLIENT_ID"),
        clientSecret: config:getAsString("OAUTH2_CLIENT_SECRET"),
        refreshToken: config:getAsString("OAUTH2_REFRESH_TOKEN")

    }
	};

After setting up the above environment, data from spread sheet can be obatined by using methods provided bn the gsheets4 connector.

	string[][] values = check spreadsheetClient->getSheetValues(spreadsheetId, sheetName, "", "");
	
Invoking this method it returns a 2d string array contaning the data in the relevent spread sheet.

	string summary = value[0];
	string decription = value[1];
	string color = value[2];
	string location = value[3];
	string startDate = value[4];
	string startTime = value[5];
	string endDate = value[6];
	string endTime = value[7];

The values obatined from the 2d array are assigned to relevant variables and added to the json object.


	json eventData = {
	  "end": {
	   "dateTime": endDate+"T"+endTime+":00+05:30"
	  },
	  "start": {
	   "dateTime": startDate+"T"+startTime+":00+05:30"
	  },
	  "summary": summary,
	  "description": decription,
	  "colorId": color,
	  "guestsCanModify": false,
	  "kind": "calendar#event",
	  "location": location,
	  "reminders": {
	   "useDefault": true
	  },
	  "locked": true
	};
							
An http request is created, the json object created and set as payload for the http request.

	 http:Request req = new;
	 
	 req.setJsonPayload(eventData, contentType = "application/json");
	 
Http post request is made on the required path to add an event in the google calendar along with the json object sent as the request body

	var response = oauth2Client->post("/calendar/v3/calendars/primary/events?conferenceDataVersion=0&maxAttendees=10&sendNotifications=true&supportsAttachments=false&fields=summary", req);

The response then received from the api is printed in the console

	match response {
                http:Response resp => {
                    var msg = resp.getJsonPayload();
                    match msg {
                        json jsonPayload => {
                            log:printInfo(jsonPayload.toString());//print the json response recevied
                        }
                        error err => {
                            log:printError(err.message, err = err);
                        }
                    }
                }
                error err => { log:printError(err.message, err = err); }

            }
