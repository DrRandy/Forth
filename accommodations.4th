

\ msg_          the address of the string containing the instructions displayed to the user
\ Instruction_  words point to the messages selected at each level of instruction

variable Instruction_none
," "                                                constant msg_No_instruction  

variable Instruction_OK_to_close_SR
," Close the service request."                      constant msg_Close_the_SR
," The service request cannot be closed."           constant msg_Cannot_close_the_SR

variable Instruction_mooting
," The service request has been mooted."            constant msg_SR_declared_moot

variable Instruction_mooting_documentation          
," Document the reason for mooting the SR."         constant msg_Mooting_documentation_not_completed

variable Instruction_parking            
," The parking request has been completed."         constant msg_Parking_request_completed
," Notify employee and parking manager, using parking permit template."      constant msg_Parking_request_send_notification
," Create work status for parking accommodation."   constant msg_Parking_request_work_status
," Await response on parking from employee."        constant msg_Parking_request_awaiting_employee_response
," Send employee parking question."                 constant msg_Parking_request_ask_employee_question    

\ initialize variables
msg_No_instruction  Instruction_none !

\ displaying the instructions

: display_instruction ( str -- )
    \ is the message being displayed msg_No_instruction ?
    @ dup msg_No_instruction = if  drop return    \ yes, don't print anything
    else count type cr then ;                     \ no, print the instruction

: Show_instructions ( -- )
    Instruction_OK_to_close_SR display_instruction ;


\ Set_instruction words need a flag on the stack on entry but they don't consume it, they are stack neutral. 

: Set_instruction_mooting ( bool -- bool )
    SR_declared_moot? if  
        msg_SR_declared_moot Instruction_mooting !
        dup if msg_Mooting_documentation_completed      Instruction_mooting_documentation !
        else msg_No_instruction                         Instruction_mooting_documentation !  then
    else 
        msg_No_instruction  Instruction_mooting ! 
        msg_No_instruction  Instruction_mooting_documentation !
    then ;

: Set_instruction_OK_to_close_SR ( bool -- bool ) 
    dup 
    if      msg_Close_the_SR            Instruction_OK_to_close_SR  !
    else    msg_Cannot_close_the_SR     Instruction_OK_to_close_SR  !  then ;

\ Decision-making algorithm
\
\ component lifecycle
\ incoming - 
\ is there enough documentation to make a decision?
\     no  ask for more documentation, await response
\
\     

: Parking_component_completed? ( -- bool )
    SR_has_parking_component? not if ( no parking component, just return true ) then
    notification_of_parking_decision_sent? 
    if msg_Parking_request_completed  Instruction_parking ! true return
    parking_


: All_SR_components_completed? ( -- bool )
    true    Parking_component_completed?
    \   and     Equipment_component_completed?
    \   and     Schedule_component_completed?
    \   and     Leave_component_completed?
    \   and     MSK_component_completed?
    \   and     Vaccine_component_completed? 
    \   and     Other_component_completed?
    and     ;

: Mooting_documentation_completed? ( -- bool )
    User_marks_mooting_documentation_complete? ; 

: SR_declared_moot? ( -- bool )
    User_marks_SR_moot? ;

: Mooting_completed? ( -- bool )  
    SR_declared_moot?    Mooting_documentation_completed?  and 
    Set_instruction_mooting ;

: OK_to_close_SR? ( -- bool )    
    Mooting_completed?    All_SR_components_completed?  or 
    Set_instruction_OK_to_close_SR ;


