Nonterminals queries named_queries named_query fragments.
Terminals '$name' '$type' '$docs' '$fragment' '$named_param'.
Rootsymbol queries.


queries -> fragments     : [ {nil, normal, nil, join_fragments('$1', [])} ].
queries -> named_queries : '$1'.

named_queries -> named_query               : [ '$1' ].
named_queries -> named_query named_queries : [ '$1' | '$2' ].

named_query -> '$name' fragments
               : {extract_name('$1'), normal, nil, join_fragments('$2', [])}.
named_query -> '$name' '$docs' fragments
               : {extract_name('$1'), normal, extract_docs('$2'), join_fragments('$3', [])}.
named_query -> '$name' '$type' fragments
               : {extract_name('$1'), extract_type('$2'), nil, join_fragments('$3', [])}.
named_query -> '$name' '$type' '$docs' fragments
               : {extract_name('$1'), extract_type('$2'), extract_docs('$3'), join_fragments('$4', [])}.

fragments -> '$fragment'              : [ extract_fragment('$1') ].
fragments -> '$fragment' fragments    : [ extract_fragment('$1') | '$2' ].
fragments -> '$named_param'           : [ extract_named('$1') ].
fragments -> '$named_param' fragments : [ extract_named('$1') | '$2' ].

Erlang code.

extract_type({'$type', _, {<<>>, _, _}}) ->
  normal;
extract_type({'$type', _, {Value, _, _}}) ->
  binary_to_atom(Value).

extract_name({'$name', _, {Value, _, _}}) ->
  Value1 = [X || <<X>> <= Value, not lists:member(X, "#")],
  list_to_atom(Value1).

extract_docs({'$docs', _, {<<>>, _, _}}) ->
  nil;
extract_docs({'$docs', _, {Value, _, _}}) ->
  Value.

extract_fragment({'$fragment', _, {Value, _, _}}) ->
  Value.

extract_named({'$named_param', _, {Value, _, _}}) ->
  binary_to_atom(Value).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Helper for joining fragments

join_fragments([], Acc) ->
  'Elixir.Enum':reverse(Acc);

join_fragments(Values, Acc) ->
  case 'Elixir.Enum':split_while(Values, fun(Value) -> is_binary(Value) end) of
    {NewValues, [Diff | Rest]} ->
      NewAcc = [Diff, 'Elixir.Enum':join(NewValues, <<" ">>) | Acc],
      join_fragments(Rest, NewAcc);

    {NewValues, []} ->
      NewAcc = ['Elixir.Enum':join(NewValues, <<" ">>) | Acc],
      join_fragments([], NewAcc)
  end.
