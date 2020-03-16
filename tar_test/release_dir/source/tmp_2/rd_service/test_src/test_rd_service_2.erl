%%% -------------------------------------------------------------------
%%% Author  : uabjle
%%% Description : dbase using dets 
%%%
%%% Created : 10 dec 2012
%%% -------------------------------------------------------------------
-module(test_rd_service_2).
 
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include_lib("eunit/include/eunit.hrl").

%% --------------------------------------------------------------------
-define(POD_ID,["board_w1","board_w2","board_w3"]).
%% External exports

-export([start/0]).


%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Function:init 
%% Description:
%% Returns: non
%% --------------------------------------------------------------------
start()->
    init_test(),
    load_resources_w1_test(),
    load_resources_w2_test(),
    load_resources_w3_test(),
    get_resources_1_test(),
    get_resources_kill_w1_1_test(),
    get_resources_kill_w2_test(),
    stop_test(),
    ok.
    

init_test()->
    [pod:delete(node(),PodId)||PodId<-?POD_ID],
    A=[pod:create(node(),PodId)||PodId<-?POD_ID],
    Pods=[Pod||{ok,Pod}<-A],
    
    %PodsId=[atom_to_list(Pod)||Pod<-Pods],
    os:cmd("cp -r ebin board_w3/ebin"),
    os:cmd("cp -r src/*.app board_w3/ebin"),
    rpc:call('board_w3@asus',code,add_path,[filename:join("board_w3","ebin")],5000),
    timer:sleep(100),
    os:cmd("cp -r ebin board_w2/ebin"),
    os:cmd("cp -r src/*.app board_w2/ebin"),
    rpc:call('board_w2@asus',code,add_path,[filename:join("board_w2","ebin")],5000),
    timer:sleep(100),
    os:cmd("cp -r ebin board_w1/ebin"),
    os:cmd("cp -r src/*.app board_w1/ebin"),
    rpc:call('board_w1@asus',code,add_path,[filename:join("board_w1","ebin")],5000),
    timer:sleep(100),
    [{Pod,rpc:call(Pod,rd_service,start_link,[])}||Pod<-Pods],
    {ok,_Pid}=rd_service:start_link(),
    ok.

ping_test()->
    TestNode=node(),
    Nodes=nodes(),
    [rpc:call(Node,net_adm,ping,[TestNode])||Node<-Nodes],
    ok.

%---------------   ETS test -----------------------------------------

ets_node_test()->
    A=ets_rd:get_active_nodes(),
    true=lists:member(board_w2@asus,A),
    true=ets_rd:member_node(board_w2@asus),
    true=ets_rd:delete_active_node(board_w2@asus),
    false=ets_rd:member_node(board_w2@asus),
    ok.

ets_local_test()->
    Locals=[{service_1_test,node()},{service_2_test,node()},{service_3_test,node()}],
    [ets_rd:store_local(Local)||Local<-Locals],
    A=ets_rd:get_locals(),
    true=lists:member({service_2_test,node()},A),
    ok.

ets_target_test()->
    Targets=[service_1_test,service_2_test,service_3_test],
    [ets_rd:store_target(Target)||Target<-Targets],
    A=ets_rd:get_targets(),
    true=lists:member(service_2_test,A),
    ok.


ets_found_test()->
    Founds=[{service_1_test,node()},{service_2_test,node()},{service_3_test,node()},{service_3_test,node2}],
    [ets_rd:store_found(Found)||Found<-Founds],
    A=ets_rd:get_founds(),
    true=lists:member({service_2_test,node()},A),
    [test_rd_service@asus]=ets_rd:get_resources(service_2_test),
    B=ets_rd:get_resources(service_3_test),
    true=lists:member(node2,B),
    []=ets_rd:get_resources(service_glurk_test),
    ets_rd:delete_found({service_2_test,node()}),
    C=ets_rd:get_founds(),
    false=lists:member({service_2_test,node()},C),
    ok.

		    

%----------------------------------------------------------
debug_nodes_test_xx()->
    [test_rd_service@asus,board_w1@asus,board_w2@asus,board_w3@asus]=rd_service:debug(nodes),
    ok.
load_resources_w1_test()->
    Local=[service_1_w1,service_2_w1,service_3_w1],
    Target=[service_1_w2,service_1_w3,service_1_w1],
    [rpc:call('board_w1@asus',rd_service,add_local_resource,[Service,'board_w1@asus'])||Service<-Local],
    [rpc:call('board_w1@asus',rd_service,add_target_resource_type,[Service])||Service<-Target],
    timer:sleep(300),
    ok.

load_resources_w2_test()->
    Local=[service_1_w2,service_2_w2,service_3_w1],
    Target=[service_1_w1,service_1_w3,service_2_w1,service_3_w1],
    [rpc:call('board_w2@asus',rd_service,add_local_resource,[Service,'board_w2@asus'])||Service<-Local],
    [rpc:call('board_w2@asus',rd_service,add_target_resource_type,[Service])||Service<-Target],
    rpc:call('board_w2@asus',rd_service,trade_resources,[]),
    timer:sleep(300),
 
    rpc:call('board_w2@asus',rd_service,debug,[found]),
    Resources=rpc:call('board_w2@asus',rd_service,fetch_resources,[service_3_w1]),
    true=lists:member('board_w1@asus',Resources),
    []=rpc:call('board_w2@asus',rd_service,fetch_resources,[service_glurk_w1]),
    
    ok.

load_resources_w3_test()->
    Local=[service_1_w3,service_2_w3,service_3_w3],
    Target=[],
    [rpc:call('board_w3@asus',rd_service,add_local_resource,[Service,'board_w3@asus'])||Service<-Local],
    [rpc:call('board_w3@asus',rd_service,add_target_resource_type,[Service])||Service<-Target],
    rpc:call('board_w3@asus',rd_service,trade_resources,[]),
    timer:sleep(300),
    ok.

get_resources_1_test()->
     Local=[],
    Target=[service_1_w2,service_1_w3,service_1_w1,service_1_w2,service_2_w2,service_3_w1,
	    service_1_w3,service_2_w3,service_3_w3],
    [rd_service:add_local_resource(Service,node())||Service<-Local],
    [rd_service:add_target_resource_type(Service)||Service<-Target],
    rd_service:trade_resources(),
    timer:sleep(500),
    R=[{Service,rd_service:fetch_resources(Service)}||Service<-Target],
    io:format(" ~p~n",[{R,?MODULE,?LINE}]),
    [{service_1_w2,_},
     {service_1_w3,_},
     {service_1_w1,_},
     {service_1_w2,_},
     {service_2_w2,_},
     {service_3_w1,_},
     {service_1_w3,_},
     {service_2_w3,_},
     {service_3_w3,_}]=R,
    ok.

get_resources_kill_w2_test()->
  %  glurk=rd_service:debug(found),
%    pod:delete('board_w1@asus',"board_w1"),
   % timer:sleep(1000),
    pod:delete('board_w2@asus',"board_w2"),
  %  timer:sleep(1000),
 
   Target=[service_1_w2,service_1_w3,service_1_w1,service_1_w2,service_2_w2,service_3_w1,
	    service_1_w3,service_2_w3,service_3_w3],
    rpc:call('board_w3@asus',rd_service,trade_resources,[]),
    rpc:call('board_w1@asus',rd_service,trade_resources,[]),
    rpc:call('board_w2@asus',rd_service,trade_resources,[]),

    rd_service:trade_resources(),
    timer:sleep(500),
    A=ets_rd:get_active_nodes(),  
 %   false=lists:member('board_w1@asus',A),
    false=lists:member('board_w2@asus',A),
    rd_service:trade_resources(),
    timer:sleep(500),

    rd_service:trade_resources(),
    timer:sleep(500),

    rd_service:trade_resources(),
    timer:sleep(500),
    R=[{Service,rd_service:fetch_resources(Service)}||Service<-Target],
    io:format("killed 'board_w2@asus' ~p~n",[{R,?MODULE,?LINE}]),
 
    ok.
get_resources_kill_w1_1_test()->
  %  glurk=rd_service:debug(found),
    pod:delete('board_w1@asus',"board_w1"),
    Target=[service_1_w2,service_1_w3,service_1_w1,service_1_w2,service_2_w2,service_3_w1,
	    service_1_w3,service_2_w3,service_3_w3],
    rpc:call('board_w3@asus',rd_service,trade_resources,[]),
    rpc:call('board_w1@asus',rd_service,trade_resources,[]),
    rpc:call('board_w2@asus',rd_service,trade_resources,[]),
    rd_service:trade_resources(),
    timer:sleep(500),
    R=[{Service,rd_service:fetch_resources(Service)}||Service<-Target],
    io:format("killed 'board_w1@asus' ~p~n",[{R,?MODULE,?LINE}]),

    ok.	       

stop_test()->
    [pod:delete(node(),PodId)||PodId<-?POD_ID],
    rd_service:stop(),
    do_kill().
do_kill()->
    init:stop().

