\ ===========================================
\ standard additions
\ ===========================================


: not ( bool -- bool ) if false else true then ;
: no-op ;
' no-op constant 'no-op
0 constant none

here ," code not yet written" count exception constant unimplemented_code

: unimplemented ( -- ) unimplemented_code throw ;



\ ===========================================
\ stacks
\ ===========================================

here ," user stack underflow" count exception constant user_stack_underflow
here ," user stack overflow"  count exception constant user_stack_overflow


: create-stack 
    create  ( size -- )
        \ size    number of cells in the stack ( + 4 for operations )
        dup ( size  )                          , 
            ( depth )                        0 , 
            ( underflow ) user_stack_underflow ,
            ( overflow  )  user_stack_overflow ,
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



\ ===========================================
\ assertions
\ ===========================================

here ," assertion missing execution token"  count exception constant assertion_no_xt
here ," assertions stack underflow"         count exception constant assertions_underflow
here ," assertions stack overflow"          count exception constant assertions_overflow

6 cells constant cells/assertion_frame

: assertion_frames ( n -- n*frames ) cells/assertion_frame * ;

20 assertion_frames create-stack [assertions]
assertions_underflow [assertions] _underflow!
assertions_overflow  [assertions] _overflow!

here ," " constant empty_string

variable vshow_assertions 	\ state variable, off or on
vshow_assertions on 		\ on by default

variable vshow-tests 	\ state variable, off or on
vshow-tests on			\ on by default

variable vshow-suites 	\ state variable, off or on
vshow-suites on			\ on by default


: show_assertions 
    \ turns on assertion, test, and suite messages
    vshow_assertions on 
    vshow-tests on
    vshow-suites on ;
        
: hide_assertions 
    \ turns off assertion, test, and suite messages
    vshow_assertions off 
    vshow-tests off
    vshow-suites off ;
    
: show_assertions? vshow_assertions @ ;	\ true if on, false if off



: show-tests 
    \ turns on test and suite messages
    vshow-tests on 
    vshow-suites on ;
        
: hide-tests 
    \ turn off test and suite messages
    vshow-tests off 
    vshow-suites off ;
        
: show-tests? vshow-tests @ ;	\ true if on, false if off


: show-suites 
    \ turns on suite messages
    vshow-suites on ; 
    
: hide-suites 
    \ turn off suite messages
    vshow-suites off ;
    
: show-suites? vshow-suites @ ; \ true if on, false if off
	

: push-assertion ( assertion-msg  assertion-xt -- )
    \ push the assertion to the stack and populate it
    ( assertion-xt   )          [assertions] _push
    ( assertion-msg  )          [assertions] _push  
    ( actual         )     0    [assertions] _push 
    ( expected       )     0    [assertions] _push 
    ( vprintactual   )  true    [assertions] _push 
    ( vprintexpected )  true    [assertions] _push ;

: drop-assertion  ( -- )
    \ take the current assertion off the stack
    ( vprintexpected )          [assertions] _drop
    ( vprintactual   )          [assertions] _drop
    ( expected       )          [assertions] _drop  
    ( actual         )          [assertions] _drop 
    ( assertion-msg  )          [assertions] _drop 
    ( assertion-xt   )          [assertions] _drop ;


: create-assertion

    create { assertion-msg  assertion-xt }
        assertion-xt  if assertion-xt   else assertion_no_xt throw then   ,  
        assertion-msg if assertion-msg  else empty_string then            ,
    does> ( baseaddr -- )
        dup 1 cells + @         ( -- baseaddr  assertion-msg ) 
        swap 0 cells + @        ( -- assertion-msg   assertion-xt )
        push-assertion ;
        

: current-assertion ( -- assertion )    
    \ returns the current assertion, or throws exception if there isn't one
    [assertions] _vtop ; 
    
: assertion-xt      ( assertion -- xt   )   current-assertion 6 cells - @ ; \ constant
: vassertion-msg    ( assertion -- msg  )   current-assertion 5 cells -   ; \ string variable
: vactual           ( assertion -- addr )   current-assertion 4 cells -   ; \ placeholder variable
: vexpected         ( assertion -- addr )   current-assertion 3 cells -   ; \ placeholder variable
: vprintactual      ( assertion -- addr )   current-assertion 2 cells -   ; \ boolean variable
: vprintexpected    ( assertion -- addr )   current-assertion 1 cells -   ; \ boolean variable

: assertion-msg!    ( actual   -- )   vassertion-msg   ! ;
: actual!           ( actual   -- )   vactual   ! ;
: expected!         ( expected -- )   vexpected ! ;

: assertion-msg     ( -- actual   )   vassertion-msg   @ ;
: actual            ( -- actual   )   vactual   @ ;
: expected          ( -- expected )   vexpected @ ;

: show_actual  ( -- )       vprintactual on  ;
: hide_actual  ( -- )       vprintactual off ;
: show_actual? ( -- bool )  vprintactual @   ;

: show_expected  ( -- )     vprintexpected on  ;
: hide_expected  ( -- )     vprintexpected off ;
: show_expected? ( -- bool) vprintexpected @   ;


: print_assertion_passfail          cr if ." PASS ASSERTION "  else  ." FAIL ASSERTION " then  ;
: print_assertion_message           assertion-msg count type ;
: print_assertion_expected_actual
    show_expected? if ." EXPECTED = " expected . then
    show_actual?   if ." ACTUAL = "   actual   . then ;

: print-assertion-result ( bool -- )
    show_assertions? if 
        print_assertion_passfail 
        print_assertion_message 
        print_assertion_expected_actual 
    else drop then ;
     
        

: ]assert ( sys: -- bool , assertions: addr -- ) 
    actual expected assertion-xt execute dup print-assertion-result drop-assertion ;


\ ---------------------------------
\ utility word for debugging
\ ---------------------------------

: check ( bool -- )  cr if ." PASS" else ." FAIL" then ; \ for quick checks

\ ---------------------------------
\ basic assertions, full syntax
\ ---------------------------------

empty_string   
     
:noname ( actual expected -- bool ) \ true = PASS, false = FAIL
    = ;        
create-assertion assert_equal[

here ," expected unequal: "    

:noname ( actual expected -- bool ) \ true = PASS, false = FAIL
    = not ;        
create-assertion assert_not_equal[

here ," expected true"

:noname ( actual expected -- bool ) \ true = PASS, false = FAIL
    drop true expected! dup actual!   \ update actual and expected 
    hide_actual  hide_expected      \ don't need output
    if true else false then ;
create-assertion assert_true[ 

here ," expected false: "

:noname ( actual expected -- bool ) \ true = PASS, false = FAIL
    drop false expected! dup actual!  \ update actual and expected 
    show_actual  hide_expected      \ don't need output
    if false else true then ;
create-assertion assert_false[ 


\ ---------------------------------
\ simple assertions, easy syntax
\ ---------------------------------

: assert_true ( actual -- bool ) \ convenience method for assert_true[
    true swap assert_true[ actual! expected! ]assert ;

: assert    assert_true ; \ synonym

: assert_false ( actual -- bool ) \ convenience method for assert_false[
    false swap assert_false[ actual! expected! ]assert ;

: assert_not assert_false ; \ synonym

: assert_equal ( actual expected -- bool ) \ convenience method for assert_equal[ 
    swap assert_equal[ actual! expected! ]assert ;

: assert_not_equal ( actual expected -- bool ) \ convenience method for assert_not_equal[ 
    swap assert_not_equal[ actual! expected! ]assert ;

cr ." Haven't started yet." .s







true assert_true drop
true assert drop
false assert_not drop
false assert_false drop 
123 123 assert_equal drop
123 456 assert_not_equal drop
cr depth 0 = check .s


\ false [if]
here ," failure expected " constant fail_msg
assert_false[ hide_assertions       false assert_true      actual! fail_msg assertion-msg! show_assertions ]assert drop
assert_false[ hide_assertions       false assert           actual! fail_msg assertion-msg! show_assertions ]assert drop
assert_false[ hide_assertions       true assert_not        actual! fail_msg assertion-msg! show_assertions ]assert drop
assert_false[ hide_assertions       true assert_false      actual! fail_msg assertion-msg! show_assertions ]assert drop
assert_false[ hide_assertions       1 22 assert_equal      actual! fail_msg assertion-msg! show_assertions ]assert drop
assert_false[ hide_assertions       1 1 assert_not_equal   actual! fail_msg assertion-msg! show_assertions ]assert drop
depth 0 = check .s
\ [then]


\ ---------------------------------
\ stack assertions, both syntaxes
\ ---------------------------------

here ," stack should be empty"

:noname ( stack actual expected -- bool ) \ true = PASS, false = FAIL
    drop drop true expected! _empty? dup actual!  \ update actual and expected 
    hide_actual  hide_expected                  \ don't need output
    if true else false then ;
create-assertion assert_stack_empty[

: assert_stack_empty ( stack -- bool ) \ convenience method for assert_stack_empty[
    assert_stack_empty[   ]assert ;

here ," stack should be full"

:noname ( stack actual expected -- bool ) \ true = PASS, false = FAIL
    drop drop true expected! _full? dup actual!   \ update actual and expected 
    hide_actual  hide_expected                  \ don't need output
    if true else false then ;
create-assertion assert_stack_full[

: assert_stack_full ( stack -- bool ) \ convenience method for assert_stack_full[
    assert_stack_full[   ]assert ;

here ," stack size"

:noname ( testsize stack actual expected -- bool ) \ true = PASS, false = FAIL
    drop drop _size dup actual! swap dup expected!  =   \ update actual and expected 
    if true else false then ;
create-assertion assert_stack_size[

: assert_stack_size ( testsize stack -- bool ) \ convenience method for assert_stack_size[
    assert_stack_size[   ]assert ;

here ," stack depth: "

:noname ( testdepth stack actual expected -- bool ) \ true = PASS, false = FAIL
    drop drop _depth dup actual! swap dup expected!  =   \ update actual and expected 
    show_actual show_expected
    if true else false then ;
create-assertion assert_stack_depth[

: assert_stack_depth ( testsize stack -- bool ) \ convenience method for assert_stack_depth[
    assert_stack_depth[   ]assert ;


\ ===========================================
\ tests
\ ===========================================

: test-xt 		( base-addr -- xt ) @ ;
: teardown-xt 	( base-addr -- xt ) cell+ @ ;
: setup-xt 		( base-addr -- xt ) cell+ cell+ @ ;
: test-msg		( base-addr -- str-addr ) cell+ cell+ cell+ @ ;

: print-test-result ( msg bool -- )
    cr if ." PASS TEST "   else  ." FAIL TEST "   then  count type ;

: create-test-with-setup-and-teardown
	create ( test-msg setup-xt teardown-xt test-xt -- )
	    ( test-xt ) ,	  \ the xt for the test code itself ( -- bool )
	    ( teardown-xt )	, \ the xt for the teardown code, to clean up after the test ( -- )
	    ( setup-xt ) ,	  \ the xt for the setup code, to prepare for the test ( -- )
	    ( test-msg ) ,	  \ str-addr of a message (usually a description of the test)
	does> ( base-addr -- bool ) 
    	>r 
        r@ setup-xt execute
	    r@ test-xt execute dup
        r@ test-msg swap  print-test-result 
	    r@ teardown-xt execute  rdrop ;

: create-test  ( test-msg test-xt -- )  \ a test with no setup or teardown
    'no-op ( setup-xt    ) swap 
    'no-op ( teardown-xt ) swap
    ( -- test-msg setup-xt teardown-xt test-xt ) 
    create-test-with-setup-and-teardown  ;



\ ===========================================
\ suites
\ ===========================================

: suite-xt 		( base-addr -- xt ) @ ;
\ teardown-xt 	( base-addr -- xt ) cell+ @ ;  \ already defined
\ setup-xt 		( base-addr -- xt ) cell+ cell+ @ ;  \ already defined
: suite-msg		( base-addr -- str-addr ) cell+ cell+ cell+ @ ;

: print-suite-result ( msg bool -- )
    cr if ." PASS SUITE "   else  ." FAIL SUITE "   then  count type ;


: create-suite-with-setup-and-teardown
	create ( suite-msg setup-xt teardown-xt suite-xt -- )
	    ( suite-xt ) ,	  \ the xt for the test code itself ( -- bool )
	    ( teardown-xt )	, \ the xt for the teardown code, to clean up after the test ( -- )
	    ( setup-xt ) ,	  \ the xt for the setup code, to prepare for the test ( -- )
	    ( test-msg ) ,	  \ str-addr of a message (usually a description of the test)
	does> ( base-addr -- bool ) 
    	>r 
        r@ setup-xt execute
	    r@ suite-xt execute dup
        r@ suite-msg swap  print-suite-result
	    r@ teardown-xt execute  rdrop ;

: create-suite  ( suite-msg suite-xt -- )  \ a test with no setup or teardown
    'no-op ( setup-xt    ) swap 
    'no-op ( teardown-xt ) swap
    ( -- suite-msg setup-xt teardown-xt suite-xt ) 
    create-suite-with-setup-and-teardown  ;


\ ===========================================
\ tests
\ ===========================================

\ ---------------------------------
\ test complex assertion words
\ ---------------------------------

here ," complex assertion words"
:noname ( -- bool ) \ true = PASS,  false = FAIL
    [assertions] _depth  assert_equal[    actual!  0 expected! ]assert 
    assert_equal[       3 actual! 3 expected! ]assert and
    assert_not_equal[   4 actual! 3 expected! ]assert and
    assert_true[                true actual! ]assert and
    assert_false[              false actual! ]assert and
    [assertions] _depth assert_equal[     actual!  0 expected! ]assert and  
;
create-test test_complex_assertions


\ ---------------------------------
\ test simple assertion words
\ ---------------------------------

here ," simple assertion words"
:noname ( -- bool ) \ true = PASS,  false = FAIL

    \ assert, assert_true 
    true  assert  
    false not assert and 
    true  assert_true and 
    false not assert and 

    \ assert_not, assert_false
    false assert_false and 
    true  not assert_not and 
    false assert_false and 
    true  not assert_not and 

    \ assert_equal, assert_not_equal
    3 3 assert_equal and
    3 4 assert_not_equal and  
;
create-test test_simple_assertions


\ ---------------------------------
\ suite testing all assertion words
\ ---------------------------------

here ," testing assertion words"
:noname ( -- bool ) \ true = PASS,  false = FAIL 
    test_simple_assertions 
    test_complex_assertions  and  ; 
create-suite suite_assertions







\ ---------------------------------
\ suite testing all stack words
\ ---------------------------------

4 constant test_stack_size 
test_stack_size  create-stack [test]

: setup_empty_stack 
    [test] _reset ;

: setup_2_item_stack
    [test] _reset
    12 [test] _push
    34 [test] _push ;

: setup_full_stack
    [test] _reset
    12 [test] _push
    34 [test] _push 
    56 [test] _push 
    78 [test] _push ;

here ," empty stack"
' setup_empty_stack
' no-op
:noname 
        test_stack_size [test] assert_stack_size
        [test] assert_stack_empty
    and [test] _full? assert_not
    and 0 [test] assert_stack_depth
    and 123 [test] _push         1 [test] assert_stack_depth
    and 234 [test] _push         2 [test] assert_stack_depth
    and     [test] _drop         1 [test] assert_stack_depth
    and     [test] _pop          0 [test] assert_stack_depth
    and ( 123 -- ) 123 assert_equal
    and [test] assert_stack_empty
    and ;
create-test-with-setup-and-teardown test_empty_stack
   
here ," full stack"
' setup_full_stack
' no-op
:noname 
        test_stack_size [test] assert_stack_size
        [test] assert_stack_full
    and [test] _empty? assert_not
    and 4 [test] assert_stack_depth
    and assert_equal[ 78 expected! [test] _top actual! ]assert
    and ;
create-test-with-setup-and-teardown test_full_stack
   

here ," testing all stack words"
:noname ( -- bool ) \ true = PASS,  false = FAIL 
    test_empty_stack
    \ test_stack_underflow and
    \ test_overflow and
    test_full_stack and
;
create-suite suite_stacks


\ ---------------------------------
\ run tests
\ ---------------------------------

suite_assertions drop
suite_stacks drop
depth 0 = check ."  the stack should be empty after all tests are run"

\
\ ===========================================================
\ SUITE assertions
\ tests of all assertions 
\ ===========================================================



\ TEST math_assertions
here ," tests of math assertions "
:noname ( -- boolean ) \ true if PASS, false = FAIL
    true assert_equal[ 123 actual! 123 expected!  ]assert  
    and  assert_not_equal[ 123 actual! 456 expected!  ]assert  
    and     ;
create-test test_math_assertions



\ TEST logic_assertions
here ," tests of logic assertions"
:noname ( -- boolean ) \ true if PASS, false = FAIL
    true assert_false[ 123 456 = actual!  ]assert  
    and  assert_true[ 123 123 = actual!  ]assert  
    and     ;
create-test test_logic_assertions



\ TEST complex_assertions
here ," tests of nested assertions"
:noname ( -- boolean ) \ true if PASS, false = FAIL
    true assert_true[ hide_assertions assert_true[ 123 123 = actual! true expected! ]assert  actual! show_assertions  ]assert  
    and  assert_false[ hide_assertions assert_true[ 123 456 = actual! true expected! ]assert actual! show_assertions  ]assert  
    and     ;
create-test test_complex_assertions



\ SUITE assertions
here ," tests of all assertions  "
:noname ( -- bool ) \ true = PASS, false = FAIL
    true test_math_assertions 
    and  test_logic_assertions 
    and  test_complex_assertions 
    and    ;
create-suite suite_assertions




suite_assertions drop
depth 0 = check ."  stack depth should be 0 following testing"


: alternative? ( x y -- x|y ) 
    \ if x is 0 return y, else return x
    over if drop else swap drop then ;

: message-table ( object -- table )
    \ return the table of messages this object knows how to respond to
    unimplemented ;


: find-method-helper ( message object flag -- xt|0 )
    \ recursively search this object and its superclasses for the method and return its xt (or 0 if not found)
    ?dup not if ( keep looking? )
        2dup message-table entry-for-key ?dup
        if ( we found the method corresponding to message )
            swap drop swap drop ( -- xt ) exit
        else ( we didn't find the method corresponding to message, check the superclass, if there is one )
            superclass ?dup if false recurse  else drop false then   
        then
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
