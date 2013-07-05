-module(dummy_SUITE).
-author('marcelog@gmail.com').

-export([all/0, init_per_testcase/2, end_per_testcase/2]).
-export([can_do_nothing/1]).

-spec init_per_testcase(term(), term()) -> void.
init_per_testcase(_TestCase, _Config) ->
  jenkins_erlang_rebar_example:start(),
  [].

-spec end_per_testcase(term(), term()) -> void.
end_per_testcase(_TestCase, _Config) ->
  jenkins_erlang_rebar_example:stop().
  
-spec all() -> [atom()].
all() ->
  [can_do_nothing].

-spec can_do_nothing(term()) -> void.
can_do_nothing(_Config) ->
  ok.