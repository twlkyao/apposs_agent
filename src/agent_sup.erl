%% 应用的主supervisor
-module(agent_sup).

-behaviour(supervisor).

%% API
-export([start_link/0, start_link/2, stop/0]).

%% Supervisor callbacks
-export([init/1]).

-ifdef(TEST).
-compile(export_all).
-endif.

%% Helper macro for declaring children of supervisor
-define(CHILD(I, Type, Fun, Args), {I, {I, Fun, Args}, permanent, 5000, Type, [I]}).

%% ===================================================================
%% API functions
%% ===================================================================

start_link() ->
  start_link("http://localhost:3000", 5000).

start_link(Center_url, Pull_delay) ->
  crypto:start(),
  ssh:start(temporary),
  supervisor:start_link({local, ?MODULE}, ?MODULE, [Center_url, Pull_delay]).

stop() ->
  ChildSpecs = supervisor:which_children(?MODULE),
  lists:foreach(
    fun
      ({Id, _Child, _Type, _Modules}) -> 
        supervisor:terminate_child(?MODULE, Id),
        supervisor:delete_child(?MODULE, Id);
      (_E) -> ok
    end,
    ChildSpecs
  ),
  inets:stop().
  
%% ===================================================================
%% Supervisor callbacks
%% ===================================================================

init([Center_url, Pull_delay]) ->
  HttpChannelSup = ?CHILD(web_sup, supervisor, start_link, []),
  Responder = ?CHILD(responder, worker, start_link, [Center_url]),
  ConnSup = ?CHILD(client_sup, supervisor, start_link, []),
  PullerSup = ?CHILD(puller_sup, supervisor, start_link, [Pull_delay]),
  {ok, { {one_for_one, 3, 30}, [HttpChannelSup, Responder,ConnSup,PullerSup]} }.
