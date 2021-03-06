%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(unit_test_staging_service_test).  
  
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("test_src/common_macros.hrl").

%% --------------------------------------------------------------------

%% External exports
-export([test/0,
	 init_test/0,
	 start_computers_dns/0,
	 cleanup/0
	]).
	 
%-compile(export_all).

-define(TIMEOUT,1000*15).

%% ====================================================================
%% External functions
%% ====================================================================
test()->
      {pong,_,lib_service}=lib_service:ping(),
    TestList=[init_test,
	      start_computers_dns,
	      cleanup
	     ],
    test_support:execute(TestList,?MODULE,?TIMEOUT).


%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
init_test()->
    pod:delete(node(),"pod_lib_1"),
    pod:delete(node(),"pod_master"),
    {pong,_,lib_service}=lib_service:ping(),
    ok.
    
%------------------  -------
start_computers_dns()->

    %% Start the master computer
    %% 1. Start Pod and load lib_services
    {ok,MasterPod}=pod:create(node(),"pod_master"),
    ok=container:create(MasterPod,"pod_master",
			[{{service,"lib_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),   
    %% 2. Start tcp server for the computer
    
    ok=rpc:call(MasterPod,lib_service,start_tcp_server,[?DNS_ADDRESS,parallell],2000),
    %% 3. Check if working
    {pong,_,lib_service}=tcp_client:call(?DNS_ADDRESS,{lib_service,ping,[]}),
    %% Succeded
    
    % Load and start dns
    ok=container:create(MasterPod,"pod_master",
			[{{service,"dns_service"},
			  {dir,"/home/pi/erlang/c/source"}}
			]),
    
    {pong,_,dns_service}=tcp_client:call(?DNS_ADDRESS,{dns_service,ping,[]}),
   ok.


cleanup()->
    ok.


%**************************************************************
