*** Settings ***
Documentation     Order robots from RobotSpareBin Industries Inc
...               Robot that will insert data on the web through csv.
Library    RPA.Browser.Selenium    auto_close=${FALSE}
Library    RPA.HTTP
Library    RPA.Excel.Files
library    RPA.Archive
Library    RPA.Tables
Library    RPA.FileSystem
Library    RPA.PDF
Library    RPA.Tasks
Library    RPA.Robocorp.Vault
Library    RPA.Dialogs

*** Variables ***
${site}=           https://robotsparebinindustries.com/#/robot-order
${DIR_Default}=    ${CURDIR}

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Create Folder
    Downloads Arquivo CSV
    File operations
    Open the robot order website
    [Teardown]     Log Out
    

*** Keywords ***

Create Folder
    Log To Console    ${DIR_Default}

    ${condicao}    Does Directory Exist   ${DIR_Default}${/}input
    IF     ${condicao}
        Remove Directory     ${DIR_Default}${/}input    recursive=True
        Create Directory     ${DIR_Default}${/}input
    ELSE
        Create Directory     ${DIR_Default}${/}input
    END


    ${condicao}    Does Directory Exist    ${DIR_Default}${/}output${/}image
    IF     ${condicao}
        Remove Directory     ${DIR_Default}${/}output${/}image    recursive=True
        Create Directory     ${DIR_Default}${/}output${/}image
    ELSE
        
        Create Directory     ${DIR_Default}${/}output${/}image
          
    END

    ${condicao}    Does Directory Exist    ${DIR_Default}${/}file zip
    IF     ${condicao}
        Remove Directory     ${DIR_Default}${/}file zip    recursive=True
        Create Directory     ${DIR_Default}${/}file zip
    ELSE
        Create Directory     ${DIR_Default}${/}file zip

    
    END


Downloads Arquivo CSV
    ${secret}     Get Secret        CredentialsOrderSite
    ${siteCSV}    set variable      ${secret}[URL_SiteCSV]
    Download    ${siteCSV}   overwrite=True

File operations
    Move File    ${DIR_Default}${/}orders.csv    ${DIR_Default}${/}input${/}Orders.csv    overwrite=True
    
Open the robot order website
    #Open Site
    Open Chrome Browser    ${site}    maximized=True
    ${table}=    Read table from CSV    ${DIR_Default}${/}input${/}Orders.csv
    Log   Found columns: ${table.columns}
    #Loop dados Orders
    FOR    ${row}    IN    @{table}
        Close the annoying modal
        Log    Address: ${row}[Address]
        Fill the form    ${row}
        Preview the robot
        Submit the robot
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts
    Close the Browser


Close the annoying modal
    Wait Until Page Contains Element    xpath://button[@class="btn btn-dark"]
    Click Button When Visible    xpath://button[@class="btn btn-dark"]


Fill the form
    [Arguments]    ${rowCSV}
    #Head
    Select From List By Value         id:head    ${rowCSV}[Head]
    #Body
    Click Element If Visible          id=id-body-${rowCSV}[Body]
    #Legs
    Input Text    xpath://input[@class="form-control"][@type="number"]    ${rowCSV}[Legs]
    #Shipping Address
    Input Text    xpath://input[@class="form-control"][@type="text"]      ${rowCSV}[Address]

Preview the robot
    #Preview
    Click Button When Visible    id:preview

Submit the robot
    
    ${Condicao}=    Is Element Visible    xpath://button[@id="order-another"] 
    ${Condicao}=    Is Element Enabled    xpath://button[@id="order-another"]
    ${Tentativas}    Set Variable   ${0}
    
    #check if the screen appeared
    IF    ${Condicao}== False
        WHILE    True
            Set Suite Variable    ${Tentativas}    ${Tentativas + 1}
            TRY
                Click Button When Visible   css:button#order.btn.btn-primary
                Wait Until Page Contains Element    xpath://button[@id="order-another"]
                BREAK
            EXCEPT
                ${Tentativas} =    Evaluate   ${Tentativas} + 1
                IF    ${Tentativas}== 7
                      BREAK
                END
            END

        END
        
    END
    IF    ${Tentativas}== 7
          Log Out
    END
           

Store the receipt as a PDF file
    [Arguments]    ${rowPDF}

    Wait Until Element Is Visible    id:receipt
    #collect PDF
    ${receipt_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}Receipt${rowPDF}.pdf    overwrite=True
    ${pdf}    set variable    ${OUTPUT_DIR}${/}Receipt${rowPDF}.pdf
    [Return]    ${pdf}   

Take a screenshot of the robot
    [Arguments]    ${rowPDF}
    #collect image Robot
    Screenshot    robot-preview-image    ${OUTPUT_DIR}${/}image${/}PrintRobo${rowPDF}.png
    ${screenshot}    set variable    ${OUTPUT_DIR}${/}image${/}PrintRobo${rowPDF}.png
    [Return]     ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}

    #create list
    Wait Until Page Contains Element    xpath://button[@id="order-another"]
    Open Pdf    ${pdf}
    ${files}=    Create List
    ...          ${screenshot}        
    
    Add Files To Pdf     ${files}   ${pdf}    ${true}
    Close Pdf
    

Go to order another robot
    Click Button    xpath://button[@id="order-another"]

Create a ZIP file of the receipts
    Add heading  *** Execution completed successfully ***
    Add icon    Success
    Add text input    Insert name:
    ...    label=What's your name?
    ...    placeholder=Enter your name here to include in the zip file
    ...    rows=1
    ${result}=    Run dialog
    #Archive zip files
    Log To Console    ${result}[Insert name:]   
    Archive Folder With Zip    ${DIR_Default}${/}output    ${DIR_Default}${/}file zip${/}${result}[Insert name:].zip    include=Receipt*.pdf

Close the Browser
    #Close the browser
    Close Browser
Log Out
    Log    Finalize task Error.

No Process
    Log     No Process.