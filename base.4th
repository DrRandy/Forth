\ ===========================================
\ standard additions
\ ===========================================

: not ( bool -- bool ) if false else true then ;

0 constant none

: no-op ;       
' no-op constant 'no-op

\ create a new exception "name" with error msg str
: create-exception ( str "name" --) count exception constant ;

here ," stack underflow" create-exception underflow_exception
here ," stack overflow"  create-exception overflow_exception
here ," not implemented" create-exception unimplemented_exception

:noname  unimplemented_exception throw ;	constant 'TBD

\ create a new deferred word "name" with default behavior to throw exception
: TBD ( "name" -- ) defer 'TBD latestxt defer! ;


\ ===========================================
\ stacks
\ ===========================================

: create-stack 
    create  ( size -- )
        \ size    number of cells in the stack ( + 4 for operations )
        dup ( size  )                          , 
            ( depth )                        0 , 
            ( underflow )  underflow_exception ,
            ( overflow  )   overflow_exception ,
            ( stackbase )            cells allot
    does>   ( -- base )  ;

: _base       ( stack -- addr )   4 cells +   ;   \ where stuff gets stored
: _voverflow  ( stack -- exc  )   3 cells +   ;   \ variable, the exception to throw in event of underflow
: _vunderflow ( stack -- exc  )   2 cells +   ;   \ variable, the exception to throw in event of overflow
: _vdepth     ( stack -- addr )   1 cells +   ;   \ variable, use for depth
: _size       ( stack -- addr )   0 cells + @ ;   \ constant, fixed at creation

: _depth    ( stack -- n )  _vdepth   @ ;   \ number of items on the stack
: _depth+   ( stack -- )    _vdepth dup @ 1 + swap ! ;    \ increment _depth
: _depth-   ( stack -- )    _vdepth dup @ 1 - swap ! ;    \ increment _depth

: _reset    ( stack -- )    _vdepth 0 swap ! ;  \ stack back to 0 items

: _empty?   ( stack -- bool ) _depth 1 < ;   \ is stack empty? 
: _full?    ( stack -- bool ) dup _depth swap _size >= ; \ is stack full? 

: _underflow!   ( exc stack --   ) _vunderflow ! ;  \ set the underflow exception
: _underflow    ( stack -- exc   ) _vunderflow @ ;  \ get the underflow exception
: _underflow?   ( stack -- stack ) \ if empty, reset the stack and abort
    dup _empty? if dup _reset  _underflow throw then ;
    
: _overflow!    ( exc stack --   ) _voverflow ! ;  \ set the underflow exception
: _overflow     ( stack -- exc   ) _voverflow @ ;  \ get the underflow exception
: _overflow?    ( stack -- stack ) \ if full, reset the stack and abort
    dup _full?  if dup _reset  _overflow  throw  then ;

: _vtop     ( stack -- addr ) dup _base swap _depth cells + ; \ addr for top of stack
: _top      ( stack -- n ) _underflow? _vtop 1 cells - @  ; \ throws an error if stack is empty


: _drop ( sys: stack --  ,  stack:  x -- ) _underflow? _depth- ;
: _pop  ( sys: stack -- x,  stack:  x -- ) _underflow? dup _top swap _drop ;
: _push ( sys: x stack -- , stack:  -- x ) _overflow?  dup _vtop rot swap ! _depth+ ;
: _dup  ( sys: stack --  ,  stack:  x -- x x ) _overflow? dup _top swap _push ; 



