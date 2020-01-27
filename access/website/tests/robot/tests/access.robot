*** Settings ***
Documentation     Verify different access settings in reading-room, open-access and qa-access collections
Resource          _resource.robot
Suite setup       Run Keywords    Reset Browsers
Suite teardown    Run Keywords    Close All Browsers


*** Test Cases ***
Open Browser
    Open Browser To Home Page

NPLD -- Check Open Access
    Check Allowed    %{HOST}/wayback/archive/http://portico.bl.uk   text=library

NPLD -- Check Blocked (451)
    Check Blocked    %{HOST}/wayback/archive/http://www.google.com

NPLD -- Check Excluded (404)
    Check Excluded    %{HOST}/wayback/archive/http://intranet.ad.bl.uk/
