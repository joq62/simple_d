%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%% 
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(etcd_service_tests). 
   
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").
-include("common_macros.hrl").
%% --------------------------------------------------------------------

%% External exports
-export([start/0]).



%% ====================================================================
%% External functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function:tes cases
%% Description: List of test cases 
%% Returns: non
%% --------------------------------------------------------------------
cases_test()->
    [clean_start(),
     eunit_start(),
     % Add funtional test cases 
     etcd_service_test_cases:start(),
 %    lib_service_test_cases:pod_container_cases(),
     % cleanup and stop eunit 
     clean_stop(),
     eunit_stop()].


%% --------------------------------------------------------------------
%% Function:start/0 
%% Description: Initiate the eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------
start()->
    spawn(fun()->eunit:test({timeout,30,etcd_service}) end).



clean_start()->
    file:delete("computer_1.config"),
    pod:delete(node(),"pod_lib_1"),
    pod:delete(node(),"pod_lib_2"),
    pod:delete(node(),"pod_master").


eunit_start()->
    [start_service(lib_service),
     check_started_service(lib_service)].



clean_stop()->
    pod:delete(node(),"pod_lib_1"),
    pod:delete(node(),"pod_lib_2"),
    pod:delete(node(),"pod_master").

eunit_stop()->
    [stop_service(lib_service),
     timer:sleep(1000),
     init:stop()].

%% --------------------------------------------------------------------
%% Function:support functions
%% Description: Stop eunit tests, set upp needed processes etc
%% Returns: non
%% --------------------------------------------------------------------

start_service(Service)->
    ?assertEqual(ok,application:start(Service)).
check_started_service(Service)->
    ?assertMatch({pong,_,Service},Service:ping()).
stop_service(Service)->
    ?assertEqual(ok,application:stop(Service)),
    ?assertEqual(ok,application:unload(Service)).

