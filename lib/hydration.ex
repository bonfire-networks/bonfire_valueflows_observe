if Code.ensure_loaded?(Bonfire.GraphQL) do
defmodule ValueFlows.Observe.Hydration do

  # alias Bonfire.GraphQL.CommonResolver

  def hydrate() do
    %{
      # FIXME
      # unit_context: [
      #   resolve_type: &CommonResolver.resolve_context_type/2
      # ],
      observation: %{
        # FIXME
        # canonical_url: [
        #   resolve: &CommonsPub.Characters.GraphQL.Resolver.canonical_url_edge/3
        # ],
        # in_scope_of: [
        #   resolve: &CommonResolver.context_edge/3
        # ]
      },
      observable_property: %{
        # canonical_url: [
        #   resolve: &CommonsPub.Characters.GraphQL.Resolver.canonical_url_edge/3
        # ],
        has_observation: [
          resolve: &ValueFlows.Observe.GraphQL.has_observation_edge/3
        ]
      },
      valueflows_observe_query: %{
        units: [
          resolve: &ValueFlows.Observe.GraphQL.all_observations/2
        ],
        units_pages: [
          resolve: &ValueFlows.Observe.GraphQL.units/2
        ],
        observation: [
          resolve: &ValueFlows.Observe.GraphQL.observation/2
        ],
        measures_pages: [
          resolve: &ValueFlows.Observe.GraphQL.measures_pages/2
        ],
        # all_observable_phenomenons: [
        #   resolve: &ValueFlows.Observe.GraphQL.all_observable_phenomenons/2
        # ],
        observable_phenomenon: [
          resolve: &ValueFlows.Observe.GraphQL.observable_phenomenon/2
        ]
      },
      valueflows_observe_mutation: %{
        create_observation: [
          resolve: &ValueFlows.Observe.GraphQL.create_observation/2
        ],
        update_observation: [
          resolve: &ValueFlows.Observe.GraphQL.update_observation/2
        ],
        delete_observation: [
          resolve: &ValueFlows.Observe.GraphQL.delete_observation/2
        ]
      }
    }
  end
end
end
