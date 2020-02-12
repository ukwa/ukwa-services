*** Settings ***
Documentation     Verify URL resolution functionality required by e.g. Document Harvester
Resource          _resource.robot
Suite setup       Run Keywords    Reset Browsers
Suite teardown    Run Keywords    Close All Browsers


*** Test Cases ***
Open Browser
    Open Browser To Home Page

Resolve an Archived Web Page
    [Tags]   resolve
    Go To    %{HOST}/access/resolve/19950418155600/http://portico.bl.uk
    Page Should Contain    Portico

