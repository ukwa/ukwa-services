
*** Settings ***
Library    Browser

# Set up a browser context for this whole sequence of tests:
Suite Setup     New Page    %{HOST}

*** Test Cases ***
Visit W3ACT, Not Logged In
    New Page    %{HOST}/act/about
    Get Text   button    ==   Login

Log In
    Go To    %{HOST}/act/login
    Fill Secret    input#email    %USERNAME
    Fill Secret    input#password    %PASSWORD
    Click    button#submit
    Get Text     h1    ==    About

Log Out
    Click    text=Logout
    Get Text   button    ==   Login

