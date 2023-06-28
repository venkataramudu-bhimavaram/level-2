*** Settings ***
Documentation      Orders robots from RobotSpareBin Industries Inc.
...                Saves the order HTML receipt as a PDF file.
...                Saves the screenshot of the ordered robot.
...                Embeds the screenshot of the robot to the PDF receipt.
...                Creates ZIP archive of the receipts and the images.
...                Author: www.github.com/joergschultzelutter

Library           RPA.Browser.Selenium
Library    RPA.FTP
Library    RPA.Tables
Library    Collections
Library    RPA.JSON
Library    RPA.Desktop
Library    RPA.RobotLogListener
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.FileSystem


*** Variables ***
${url}            https://robotsparebinindustries.com/#/robot-order
${img_folder}     ${CURDIR}${/}image_files
${pdf_folder}     ${CURDIR}${/}pdf_files
${output_folder}  ${CURDIR}${/}output

${orders_file}    ${CURDIR}${/}orders.csv
${zip_file}       ${output_folder}${/}pdf_archive.zip

*** Test Cases ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
*** Keywords ***
Directory Cleanup
    Log To console      Cleaning up content from previous test runs
    Create Directory    ${output_folder}
    Create Directory    ${img_folder}
    Create Directory    ${pdf_folder}

    Empty Directory     ${img_folder}
    Empty Directory     ${pdf_folder}
    Empty Directory     ${output_folder}
    
Get orders  
    ${data}=    Read table from CSV    ${CURDIR}/orders.csv    
     RETURN    ${data}

Open the robot order website
    ${orders}=    Get orders
    Open Available Browser    url=${url}   
    FOR    ${data}    IN    @{orders}
        Wait And Click Button    //button[normalize-space()='OK']
        Fill the form    ${data}
        Wait Until Keyword Succeeds     10x     2s    Preview the robot
        Wait Until Keyword Succeeds     10x     2s    Submit The Order
        ${orderid}  ${img_filename}=    Take a screenshot of the robot
        ${pdf_filename}=                Store the receipt as a PDF file    ORDER_NUMBER=${order_id}
        Embed the robot screenshot to the receipt PDF file     IMG_FILE=${img_filename}    PDF_FILE=${pdf_filename}
        Go to order another robot
    END
       
Fill the form
    [Arguments]    ${myrow}
    Set Local Variable    ${order_no}   ${myrow}[Order number]
    Set Local Variable    ${head}       ${myrow}[Head]
    Set Local Variable    ${body}       ${myrow}[Body]
    Set Local Variable    ${legs}       ${myrow}[Legs]
    Set Local Variable    ${address}    ${myrow}[Address]

    Set Local Variable      ${input_head}       //*[@id="head"]
    Set Local Variable      ${input_body}       body
    Set Local Variable      ${input_legs}       xpath://html/body/div/div/div[1]/div/div[1]/form/div[3]/input
    Set Local Variable      ${input_address}    //*[@id="address"]
    Set Local Variable      ${btn_preview}      //*[@id="preview"]
    Set Local Variable      ${btn_order}        //*[@id="order"]
    Set Local Variable      ${img_preview}      //*[@id="robot-preview-image"]

    Wait Until Element Is Visible   ${input_head}
    Wait Until Element Is Enabled   ${input_head}
    Select From List By Value       ${input_head}           ${head}

    Wait Until Element Is Enabled   ${input_body}
    Select Radio Button             ${input_body}           ${body}

    Wait Until Element Is Enabled   ${input_legs}
    Input Text                      ${input_legs}           ${legs}
    Wait Until Element Is Enabled   ${input_address}
    Input Text                      ${input_address}        ${address}

Preview the robot
    Set Local Variable              ${btn_preview}      //*[@id="preview"]
    Set Local Variable              ${img_preview}      //*[@id="robot-preview-image"]
    Click Button                    ${btn_preview}
    Wait Until Element Is Visible   ${img_preview}

Submit the order
    Set Local Variable              ${btn_order}        //*[@id="order"]
    Set Local Variable              ${lbl_receipt}      //*[@id="receipt"]
    Mute Run On Failure             Page Should Contain Element 
    Click button                    ${btn_order}
    Page Should Contain Element     ${lbl_receipt}

Take a screenshot of the robot
    Set Local Variable      ${lbl_orderid}      xpath://html/body/div/div/div[1]/div/div[1]/div/div/p[1]
    Set Local Variable      ${img_robot}        //*[@id="robot-preview-image"]
    Wait Until Element Is Visible   ${img_robot}
    Wait Until Element Is Visible   ${lbl_orderid} 

    ${orderid}=                     Get Text            //*[@id="receipt"]/p[1]

    Set Local Variable              ${fully_qualified_img_filename}    ${img_folder}${/}${orderid}.png
    Sleep   1sec
    Log To Console                  Capturing Screenshot to ${fully_qualified_img_filename}
    Capture Element Screenshot      ${img_robot}    ${fully_qualified_img_filename}
    
    [Return]    ${orderid}  ${fully_qualified_img_filename}

Store the receipt as a PDF file
    [Arguments]        ${ORDER_NUMBER}

    Wait Until Element Is Visible   //*[@id="receipt"]
    Log To Console                  Printing ${ORDER_NUMBER}
    ${order_receipt_html}=          Get Element Attribute   //*[@id="receipt"]  outerHTML

    Set Local Variable              ${fully_qualified_pdf_filename}    ${pdf_folder}${/}${ORDER_NUMBER}.pdf

    Html To Pdf                     content=${order_receipt_html}   output_path=${fully_qualified_pdf_filename}

    [Return]    ${fully_qualified_pdf_filename}

Embed the robot screenshot to the receipt PDF file
    [Arguments]     ${IMG_FILE}     ${PDF_FILE}

    Log To Console                  Printing Embedding image ${IMG_FILE} in pdf file ${PDF_FILE}

    Open PDF        ${PDF_FILE}
    @{myfiles}=       Create List     ${IMG_FILE}:x=0,y=0
    Add Files To PDF    ${myfiles}    ${PDF_FILE}     ${True}

    #Close PDF           ${PDF_FILE}

Go to order another robot
    # Define local variables for the UI elements
    Set Local Variable      ${btn_order_another_robot}      //*[@id="order-another"]
    Click Button            ${btn_order_another_robot}

Create a Zip File of the Receipts
    Archive Folder With Zip     ${pdf_folder}  ${zip_file}   recursive=True  include=*.pdf

Log Out And Close The Browser
    Close Browser
