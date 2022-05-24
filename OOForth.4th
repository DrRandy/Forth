
: unimplemented 
    abort" this code has not yet been written" ;

: alternative? ( x y -- x|y ) 
    \ if x is 0 return y, else return x
    over if drop else swap drop then ;

: message-table ( object -- table )
    \ return the table of messages this object knows how to respond to
    unimplemented ;


: find-method-helper ( message object flag -- xt|0 )
    \ recursively search this object and its superclasses for the method and return its xt (or 0 if not found)
    ?dup not if ( keep looking? )
        2dup message-table 
    then ;

: find-method ( message object -- xt ) 
    \ return an xt for the message, or xt for message exception 
    false find-method-helper bad-message alternative? ;

: send-message ( object message -- )
    \ invoke the object's method for this message
    swap find-method execute ;

: create-message 
    \ a message sends itself to its object when invoked
    create  ( n -- ) , 
    does>   ( ... object -- ... )   @ send-message ;
