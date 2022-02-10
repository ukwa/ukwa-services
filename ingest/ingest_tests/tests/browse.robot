
*** Settings ***
Library    Browser    auto_closing_level=SUITE

# Set up a browser context for this whole sequence of tests:
Suite Setup     New Page    %{HOST}  # HOST includes any web server authentication


*** Test Cases ***
	
W3ACT Not Logged In Requires Authentication # W3ACT authentication; web server already logged in if needed
    New Page    %{HOST_NO_AUTH}/act/about     # redirects to login
	${test}=    Get URL
    Should Be Equal As Strings     ${test}    %{HOST_NO_AUTH}/act/login
    
W3ACT Not Logged In Allows Login	
	Get Text   button    ==   Login

Wayback Not Logged In Requires Authentication
	&{response}=             HTTP                       %{HOST_NO_AUTH}/act/wayback/ 
    Should Be Equal As Strings    ${response.status}              401

Notebook Apps Not Logged In Requires Authentication
	&{response}=             HTTP                       %{HOST_NO_AUTH}/act/nbapps/ 
    Should Be Equal As Strings    ${response.status}              401

Log Viewer Not Logged In Requires Authentication
	&{response}=             HTTP                       %{HOST_NO_AUTH}/act/logs/ 
    Should Be Equal As Strings    ${response.status}              401

W3ACT Log In
    New Page    %{HOST}     # not sure why we need to re-init web server auth considering the auto close scope
    Go To    %{HOST_NO_AUTH}/act/login
    Fill Secret    input#email    %W3ACT_USERNAME
    Fill Secret    input#password    %W3ACT_PASSWORD
    Click    button#submit     # takes us to About page
    ${test}=    Get URL
    Should Be Equal As Strings     ${test}    %{HOST_NO_AUTH}/act/about

Wayback Logged In
	&{response}=             HTTP                       %{HOST_NO_AUTH}/act/wayback/ 
    Should Be Equal As Strings    ${response.status}              200

Notebook Apps Logged In
	&{response}=             HTTP                       %{HOST_NO_AUTH}/act/nbapps/ 
    Should Be Equal As Strings    ${response.status}              200

Log Viewer Logged In
	&{response}=             HTTP                       %{HOST_NO_AUTH}/act/logs/ 
    Should Be Equal As Strings    ${response.status}              200
	
Log Out Returns To Login
    Click    text=Logout
    Get Text   button    ==   Login

# test that logging out denies access as before to the various services

Wayback Not Logged In Requires Authentication
	&{response}=             HTTP                       %{HOST_NO_AUTH}/act/wayback/ 
    Should Be Equal As Strings    ${response.status}              401

Notebook Apps Not Logged In Requires Authentication
	&{response}=             HTTP                       %{HOST_NO_AUTH}/act/nbapps/ 
    Should Be Equal As Strings    ${response.status}              401

Log Viewer Not Logged In Requires Authentication
	&{response}=             HTTP                       %{HOST_NO_AUTH}/act/logs/ 
    Should Be Equal As Strings    ${response.status}              401

