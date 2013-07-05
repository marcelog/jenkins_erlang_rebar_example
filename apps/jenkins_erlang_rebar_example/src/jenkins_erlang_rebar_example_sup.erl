%%% @doc Main supervisor.
-module(jenkins_erlang_rebar_example_sup).
-author('marcelog@gmail.com').

-behaviour(supervisor).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Exports.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Public API
-export([start_link/0]).

%%% Supervisor callbacks
-export([init/1]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Types
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Helper macro for declaring children of supervisor
-define(WRK(I), {I, {I, start_link, []}, permanent, 5000, worker, [I]}).
-define(WRK(I, A), {I, {I, start_link, A}, permanent, 5000, worker, [I]}).
-define(WRK(N, I, A), {N, {I, start_link, A}, permanent, 5000, worker, [I]}).
-define(SUP(I, A), {I, {I, start_link, A}, permanent, infinity, supervisor, [I]}).
-define(SUP(I), {I, {I, start_link, []}, permanent, infinity, supervisor, [I]}).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Public API.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @doc Starts the supervisor.
-spec start_link() -> supervisor:startlink_ret().
start_link() ->
  supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Supervisor API.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @doc Called by the supervisor behavior, returns children specs.
-spec init([]) ->
  {ok, {{
    supervisor:strategy(),
    pos_integer(),
    pos_integer()
  },[supervisor:child_spec()]}}
  | ignore.
init([]) ->
  {ok, {{one_for_one, 5, 10}, []}}.

