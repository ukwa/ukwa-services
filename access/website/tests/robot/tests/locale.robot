*** Settings ***
Documentation     Verify locale-specific routes and localized strings
Resource          _resource.robot
Suite setup       Run Keywords    Reset Browsers
Suite teardown    Run Keywords    Close All Browsers


*** Test Cases ***
Open Browser
    Open Browser To Home Page

Check Wayback EN Home Page
    Go To    %{HOST}/wayback/en
    Page Should Contain    UK Web Archive Access System

Check Wayback CY Home Page
    Go To    %{HOST}/wayback/cy
    Page Should Contain    System fynediad Archif We y DG

Check Wayback EN Replay Page
    Go To    %{HOST}/wayback/en/archive/2018/https://www.bl.uk/
    Wait Until Page Contains    Language:    timeout=10s
    Page Should Contain    Back to Calendar

Check Wayback CY Replay Page
    Go To    %{HOST}/wayback/cy/archive/2018/https://www.bl.uk
    Wait Until Page Contains    Iaith:    timeout=10s
    Page Should Contain    Dychwelyd i'r Calendr

    
