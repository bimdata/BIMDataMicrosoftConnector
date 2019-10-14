// This file contains your Data Connector logic
section BIMDataConnector;

client_id = "ddb249a8-82a6-4036-a8dc-5a922cd94d2f";
redirect_uri = "https://powerbi.bimdata.io";
token_uri = "https://iam.bimdata.io/auth/realms/bimdata/protocol/openid-connect/token";
authorize_uri = "https://iam.bimdata.io/auth/realms/bimdata/protocol/openid-connect/auth";

scopes = "bcf:read ifc:read cloud:read document:read user:read openid profile email";


shared BIMDataConnector.TestConnection = () =>
    let
        result = Json.Document(Web.Contents("https://api-beta.bimdata.io/user"))
    in
        result; 

[DataSource.Kind="BIMDataConnector", Publish="BIMDataConnector.Publish"]
shared BIMDataConnector.GetToken = () =>
    let
        access_token = Extension.CurrentCredential(true)[access_token]
    in
        access_token; 

// Data Source Kind description
BIMDataConnector = [
    TestConnection = (dataSourcePath) => { "BIMDataConnector.TestConnection", dataSourcePath },
    Authentication = [
        OAuth = [
            StartLogin=StartLogin,
            FinishLogin=FinishLogin,
            Refresh=Refresh,
            Label="BIMData Connect"
        ]
    ],
    Label = Extension.LoadString("BIMData.io")
];

// Data Source UI publishing description
BIMDataConnector.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { Extension.LoadString("ButtonTitle"), Extension.LoadString("ButtonHelp") },
    LearnMoreUrl = "https://powerbi.bimdata.io/",
    SourceImage = BIMDataConnector.Icons,
    SourceTypeImage = BIMDataConnector.Icons
];

BIMDataConnector.Icons = [
    Icon16 = { Extension.Contents("BIMDataConnector16.png"), Extension.Contents("BIMDataConnector20.png"), Extension.Contents("BIMDataConnector24.png"), Extension.Contents("BIMDataConnector32.png") },
    Icon32 = { Extension.Contents("BIMDataConnector32.png"), Extension.Contents("BIMDataConnector40.png"), Extension.Contents("BIMDataConnector48.png"), Extension.Contents("BIMDataConnector64.png") }
];

StartLogin = (resourceUrl, state, display) =>
    let
        code_verifier =  Text.Combine({Text.Replace(Text.NewGuid(), "-", ""), Text.Replace(Text.NewGuid(), "-", ""), Text.Replace(Text.NewGuid(), "-", "")}),
        code_hash = Binary.ToText(Crypto.CreateHash(CryptoAlgorithm.SHA256, Text.ToBinary(code_verifier, TextEncoding.Ascii)), BinaryEncoding.Base64),
        code_challenge =  Text.Replace(Text.Replace(Text.Replace(code_hash, "=", ""), "+", "-"), "/", "_"),

        authorizeUrl = authorize_uri & "?" & Uri.BuildQueryString([
            response_type = "code",
            client_id = client_id,
            redirect_uri = redirect_uri,
            response_mode = "query",
            code_challenge = code_challenge,
            code_challenge_method = "S256",
            state = state,
            scope = scopes,
            nonce = Text.NewGuid()
        ])
    in
        [
            LoginUri = authorizeUrl,
            CallbackUri = redirect_uri,
            WindowHeight = 1024,
            WindowWidth = 1280,
            Context = [
                CodeVerifier = code_verifier
            ]
        ];

FinishLogin = (context, callbackUri, state) =>
    let
        parts = Uri.Parts(callbackUri)[Query],
        result = if (Record.HasFields(parts, {"error", "error_description"})) then 
                    error Error.Record(parts[error], parts[error_description], parts)
                 else
                    TokenMethod(context, parts[code])
    in
        result;


TokenMethod = (context, code) =>
    let
        Response = Web.Contents(token_uri, [
            Content = Text.ToBinary(Uri.BuildQueryString([
                client_id = client_id,
                code_verifier = context[CodeVerifier],
                code = code,
                redirect_uri = redirect_uri,
                grant_type = "authorization_code"
            ])),
            Headers=[#"Content-type" = "application/x-www-form-urlencoded",#"Accept" = "application/json"],
            ManualStatusHandling = {400} 
        ]),
        body = Json.Document(Response),
        result = if (Record.HasFields(body, {"error", "error_description"})) then 
            error Error.Record(body[error], body[error_description], body)
         else
            body
    in
        result;


Refresh = (resourceUrl, refresh_token) =>  
    let
        Response = Web.Contents(token_uri, [
            Content = Text.ToBinary(Uri.BuildQueryString([
                client_id = client_id,
                grant_type = "refresh_token",
                refresh_token = refresh_token
            ])),
            Headers=[#"Content-type" = "application/x-www-form-urlencoded",#"Accept" = "application/json"],
            ManualStatusHandling = {400} 
        ]),
        body = Json.Document(Response),
        result = if (Record.HasFields(body, {"error", "error_description"})) then 
            error Error.Record(body[error], body[error_description], body)
         else
            body
    in
        result;