*** Settings ***
Documentation     Verify behaviour of the Wayback archival website playback service.
Resource          _resource.robot
Suite setup       Run Keywords    Reset Browsers
Suite teardown    Run Keywords    Close All Browsers


*** Test Cases ***
Open Browser
    Open Browser To Home Page

Check Wayback EN Home Page
    [Tags]  wayback locale en
    Go To    %{HOST}/wayback/en
    Page Should Contain    UK Web Archive Access System

Check Wayback CY Home Page
    [Tags]  wayback locale cy
    Go To    %{HOST}/wayback/cy
    Page Should Contain    System fynediad Archif We y DG

Check Wayback EN Replay Page
    [Tags]  wayback locale en
    Go To    %{HOST}/wayback/en/archive/2018/https://www.bl.uk/
    Wait Until Page Contains    Language:    timeout=10s
    Page Should Contain    Back to Calendar

Check Wayback CY Replay Page
    [Tags]  wayback locale cy
    Go To    %{HOST}/wayback/cy/archive/2018/https://www.bl.uk
    Wait Until Page Contains    Iaith:    timeout=10s
    Page Should Contain    Dychwelyd i'r Calendr

Check Wayback Open Access
    [Tags]   wayback 200
    # Choosing a test page that does not have long-running JavaScript (which slows down testing).
    Check Allowed    %{HOST}/wayback/archive/19950418155600/http://portico.bl.uk   text=Library

Check Wayback Blocked (451)
    [Tags]  wayback 451
    Check Blocked    %{HOST}/wayback/archive/http://www.google.com

Check Wayback Excluded (404)
    [Tags]  wayback 404
    Check Excluded    %{HOST}/wayback/archive/http://intranet.ad.bl.uk/
