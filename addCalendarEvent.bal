import ballerina/io;
import ballerina/http;
import ballerina/config;
import ballerina/runtime;
import ballerina/log;
import wso2/gsheets4;

function main(string... args) {

    addEventsToCalendar();

}


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


function getEventDetailsFromGSheet() returns (string[][]) {

    //Read all the values from the sheet.
    string spreadsheetId = config:getAsString("SPREADSHEET_ID");
    string sheetName = config:getAsString("SHEET_NAME");

    string[][] values = check spreadsheetClient->getSheetValues(spreadsheetId, sheetName, "", "");

    log:printInfo("Retrieved customer details from spreadsheet id:" + spreadsheetId + " ;sheet name: " + sheetName);

    return values;
}

function addEventsToCalendar() {

    //Retrieve the customer details from spreadsheet.
    string[][] values = getEventDetailsFromGSheet();

    int i = 0;
    //Iterate through each customer details and send customized email.
    foreach value in values {
        //Skip the first row as it contains header values. skip rows with empty summary
        if (i > 0 && value[0]!="") {
            string summary = value[0];
            string decription = value[1];
            string color = value[2];
            string location = value[3];
            string startDate = value[4];
            string startTime = value[5];
            string endDate = value[6];
            string endTime = value[7];

            // log:printInfo(summary+" - "+decription+" - "+color+" - "+location+" - "+startDate+" - "+startTime+" - "+endDate+" - "+endTime);

            //creating request body to be sent with the http post request , contains event data in json format
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

            http:Request req = new;

            //setting the created json as payload on the http request
            req.setJsonPayload(eventData, contentType = "application/json");

            //obtaining response received by excecuting the http post request on the google calendar api
            var response = oauth2Client->post("/calendar/v3/calendars/primary/events?conferenceDataVersion=0&maxAttendees=10&sendNotifications=true&supportsAttachments=false&fields=summary", req);

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
        }
        i = i + 1;//incrementing the value by 1 to iterate through the spread sheet
    }
}
