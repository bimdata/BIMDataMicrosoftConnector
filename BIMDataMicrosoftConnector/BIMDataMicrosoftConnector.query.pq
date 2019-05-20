// Use this file to write queries to test your data connector
let
    result = BIMDataConnector.Contents(),
    access_token = BIMDataConnector.Raw("yolo")

in
    access_token