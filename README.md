BIMDataMicrosoftConnector
=========================

Based on https://github.com/Microsoft/DataConnectors
And:
  - https://docs.microsoft.com/en-us/power-query/samples/github/readme
  - https://docs.microsoft.com/en-us/power-query/samples/mygraph/readme
  - https://docs.microsoft.com/en-us/power-query/handlingauthentication#authentication-kinds
  - https://docs.microsoft.com/en-us/powerquery-m/power-query-m-reference


This connector uses OpenId Connect with authentication flow with PKCE. 

# TODO List:
- Hack the Refresh method to silently renew the access token (see https://github.com/Microsoft/DataConnectors/blob/master/docs/m-extensions.md#implementing-an-oauth-flow)
- Check if On-Premise Gateway (https://powerbi.microsoft.com/en-us/blog/on-premises-data-gateway-july-update-is-now-available/) could be an interesting solution
