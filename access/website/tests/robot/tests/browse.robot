*** Settings ***
Documentation     Verify different access settings in reading-room, open-access and qa-access collections
Resource          _resource.robot
Suite setup       Run Keywords    Reset Browsers
Suite teardown    Run Keywords    Close All Browsers


*** Test Cases ***
Open Browser
    Open Browser To Home Page

Browse View Collections
    [Tags]   browse 
    Go To    %{HOST}/ukwa/collection
    Page Should Contain    Topics

Browse View A Collection
    [Tags]   browse
    Go To    %{HOST}/ukwa/collection/44
    Page Should Contain    Blogs

Browse EN View Collections
    [Tags]   browse locale en
    Go To    %{HOST}/en/ukwa/collection
    Page Should Contain    Topics

Browse EN View A Collection
    [Tags]   browse locale en
    Go To    %{HOST}/en/ukwa/collection/44
    Page Should Contain    Blogs

Browse CY View Collections
    [Tags]   browse locale cy
    Go To    %{HOST}/cy/ukwa/collection
    Page Should Contain    Topics

Browse CY View A Collection
    [Tags]   browse locale cy
    Go To    %{HOST}/cy/ukwa/collection/44
    Page Should Contain    Blogs

