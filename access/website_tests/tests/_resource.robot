*** Settings ***
Documentation     A resource file with reusable keywords and variables.
...
...               The system specific keywords created here form our own
...               domain specific language. They utilize keywords provided
...               by the imported SeleniumLibrary.
Library           SeleniumLibrary
Library           /tmp/make_profile.py
Library           RequestsLibrary
Library           OperatingSystem

*** Variables ***
${SELENIUM}          http://hub:4444/wd/hub
${BROWSER}           Firefox
${DELAY}             0


*** Keywords ***

# Browser Reset for each Test Suite
Reset Browsers
    Set Selenium Speed    ${DELAY}
    Log To Console    Waiting for ${BROWSER} browser startup
    Sleep     10s     Wait for browser startup
    Close All Browsers


# Open Browsers
Open Browser To Home Page
    [Tags]  homepage
    Log To Console  Going to %{HOST}
    Open Browser    %{HOST}/    browser=${BROWSER}    remote_url=${SELENIUM}

Open Browser With Proxy
    [Tags]  wayback wayback-proxy
    [Arguments]    ${coll}=test
    ${profile}=    make_profile
    Open Browser    %{HOST}/    browser=Firefox    remote_url=${SELENIUM}    ff_profile_dir=${profile}


# Access Checks
Check Excluded
    [Arguments]    ${url}
    Go To   ${url}
    Page Should Contain    Not Found

Check Blocked
    [Arguments]    ${url}
    Go To   ${url}
    Page Should Contain    Available in Legal Deposit Library Reading Rooms only

Check Allowed
    [Arguments]    ${url}   ${text}
    Go To    ${url}
    Page Should Not Contain    URL Not Found
    Page Should Not Contain    Available in Legal Deposit Library Reading Rooms only
    Page Should Contain    ${text}


# Prefer Checks
Check Response Is Raw
    [Arguments]    ${resp}    ${path}     ${host}=%{HOST}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings    ${resp.url}    ${host}${path}
    Should Be Equal As Strings    ${resp.headers['Preference-Applied']}    raw
    Should Not Contain    ${resp.text}    WB Insert
    Should Not Contain    ${resp.text}    wombat.js

Check Response Is Banner Only
    [Arguments]    ${resp}    ${path}    ${host}=%{HOST}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings    ${resp.url}    ${host}${path}
    Should Be Equal As Strings    ${resp.headers['Preference-Applied']}    banner-only
    Should Contain    ${resp.text}    WB Insert
    Should Not Contain    ${resp.text}    wombat.js

Check Response is Rewritten
    [Arguments]    ${resp}    ${path}    ${host}=%{HOST}
    Should Be Equal As Strings    ${resp.status_code}    200
    Should Be Equal As Strings    ${resp.url}    ${host}${path}
    Should be Equal As Strings    ${resp.headers['Preference-Applied']}    rewritten
    Should Contain    ${resp.text}    WB Insert
    Should Contain    ${resp.text}    wombat.js


