
*** Settings ***
Library    Collections
Library    RequestsLibrary

# Set up a session for this whole sequence of tests:
Suite Setup     Create Session    act_api    %{HOST}   disable_warnings=1

*** Test Cases ***
Log into API
    &{data}=    Create Dictionary   email=%{W3ACT_USERNAME}  password=%{W3ACT_PASSWORD}
    ${resp}=    POST On Session    act_api    %{HOST}/act/login    data=${data}
    Should Be Equal As Strings  ${resp.status_code}  200


