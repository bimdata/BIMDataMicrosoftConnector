// This file contains your Data Connector logic
section BIMDataConnector;

client_id = "710475";
redirect_uri = "http://www.lewifi.fr/";
token_uri = "https://login-staging.bimdata.io/token";
authorize_uri = "https://login-staging.bimdata.io/authorize";

scope_prefix = "";
scopes = "bcf:read check:read cloud:read document:read ifc:read org:read user:read webhook:read openid profile email";

[DataSource.Kind="BIMDataConnector", Publish="BIMDataConnector.Publish"]
shared BIMDataConnector.Contents = () =>
    let
        source = Json.Document(Web.Contents("https://api-staging.bimdata.io/cloud")),
        access_token = Table.FromList(Lines.FromText((Extension.CurrentCredential()[access_token])), null, {"access_token"})
    in
        access_token; 

// Data Source Kind description
BIMDataConnector = [
    TestConnection = (dataSourcePath) => { "BIMDataConnector.Contents", dataSourcePath },
    Authentication = [
    Implicit = [],
        OAuth = [
            StartLogin=StartLogin,
            FinishLogin=FinishLogin
        ]
    ],
    Label = Extension.LoadString("DataSourceLabel")
];

// Data Source UI publishing description
BIMDataConnector.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.microsoft.com/",
    SourceImage = BIMDataConnector.Icons,
    SourceTypeImage = BIMDataConnector.Icons
];

BIMDataConnector.Icons = [
    Icon16 = { Extension.Contents("BIMDataConnector16.png"), Extension.Contents("BIMDataConnector20.png"), Extension.Contents("BIMDataConnector24.png"), Extension.Contents("BIMDataConnector32.png") },
    Icon32 = { Extension.Contents("BIMDataConnector32.png"), Extension.Contents("BIMDataConnector40.png"), Extension.Contents("BIMDataConnector48.png"), Extension.Contents("BIMDataConnector64.png") }
];

StartLogin = (resourceUrl, state, display) =>
    let
        authorizeUrl = authorize_uri & "?" & Uri.BuildQueryString([
            response_type = "id_token token",
            client_id = client_id,  
            redirect_uri = redirect_uri,
            state = state,
            scope = scopes,
            nonce = GenerateRandomString()
        ])
    in
        [
            LoginUri = authorizeUrl,
            CallbackUri = redirect_uri,
            WindowHeight = 720,
            WindowWidth = 1024,
            Context = null
        ];

FinishLogin = (context, callbackUri, state) =>
    let
        // parse the full callbackUri, and extract the Query string
        fragment = Uri.Parts(callbackUri)[Fragment],
        //fragmentList = Text.Split(fragment, "access_token="),
        fragments = Text.Split(fragment, "&"),
        parts = List.Accumulate(fragments, [], (state, current) => Record.AddField(state, Text.Split(current, "="){0}, Text.Split(current, "="){1})),
        table = Table.FromRecords([parts]),
        // if the query string contains an "error" field, raise an error
        // otherwise call TokenMethod to exchange our code for an access_token
        result = if (Record.HasFields(parts, {"error", "error_description"})) then
                    error Error.Record(parts[error], parts[error_description], parts)
                 else
                    parts
    in
        result;

Value.IfNull = (a, b) => if a <> null then a else b;
       
GenerateRandomString = () =>
    let 
    StringLength = 32,
    ValidCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456879",
    fnRandomCharacter = (text) => Text.Range(ValidCharacters,Int32.From(Number.RandomBetween(0, Text.Length(ValidCharacters)-1)),1),
    GenerateList = List.Generate(()=> [Counter=0, Character=fnRandomCharacter(ValidCharacters)],
                   each [Counter] < StringLength,
                   each [Counter=[Counter]+1, Character=fnRandomCharacter(ValidCharacters)],
                   each [Character]),
    RandomString = List.Accumulate(GenerateList, "", (a,b) => a & b)
    in
        RandomString;