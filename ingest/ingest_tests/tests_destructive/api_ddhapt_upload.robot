
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

POST a Document
    &{data}=    Create Dictionary   target_id=9022  wayback_timestamp=20211003002015  document_url=https://www.amnesty.org/download/Documents/EUR2500882019ENGLISH.PDF landing_page_url=https://www.amnesty.org/en/documents/eur25/0088/2019/en/ filename=EUR2500882019ENGLISH.PDF
    ${resp}=    POST On Session    act_api    %{HOST}/act/documents    json=[${data}]
    Should Be Equal As Strings  ${resp.status_code}  200
    Should Be Equal As Strings  ${resp.text}  No new documents added

