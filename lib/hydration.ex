if Code.ensure_loaded?(Bonfire.GraphQL) do
defmodule ValueFlows.Observe.Hydration do

  # alias Bonfire.GraphQL.CommonResolver

  def hydrate() do
    %{
      # FIXME
      # observation_context: [
      #   resolve_type: &CommonResolver.resolve_context_type/2
      # ],
      observable_object: [
        resolve_type: &ValueFlows.Observe.GraphQL.resolve_observable_object_type/2
      ],
      observable_result: [
        resolve_type: &ValueFlows.Observe.GraphQL.resolve_observable_result_type/2
      ],
      observer: [
        resolve_type: &ValueFlows.Observe.GraphQL.resolve_observer_type/2
      ],
      observation: %{
        # FIXME
        # canonical_url: [
        #   resolve: &CommonsPub.Characters.GraphQL.Resolver.canonical_url_edge/3
        # ],
        # in_scope_of: [
        #   resolve: &CommonResolver.context_edge/3
        # ]
        has_feature_of_interest: [
          resolve: &ValueFlows.Observe.GraphQL.has_feature_of_interest/3
        ],
        # observed_property: [
        #   resolve: &ValueFlows.Observe.GraphQL.observed_property_edge/3
        # ],
        has_result: [
          resolve: &ValueFlows.Observe.GraphQL.has_result_edge/3
        ],
        made_by_sensor: [
          resolve: &ValueFlows.Observe.GraphQL.made_by_edge/3
        ]

      },
      observable_property: %{
        label: [
          resolve: &ValueFlows.Observe.GraphQL.name_as_label/3
        ],
      },
      valueflows_observe_queries: %{
        observations: [
          resolve: &ValueFlows.Observe.GraphQL.all_observations/2
        ],
        observations_pages: [
          resolve: &ValueFlows.Observe.GraphQL.observations/2
        ],
        observation: [
          resolve: &ValueFlows.Observe.GraphQL.observation/2
        ],
        observable_phenomenon_pages: [
          resolve: &ValueFlows.Observe.GraphQL.observable_phenomenons_pages/2
        ],
        # all_observable_phenomenons: [
        #   resolve: &ValueFlows.Observe.GraphQL.all_observable_phenomenons/2
        # ],
        observable_phenomenon: [
          resolve: &ValueFlows.Observe.GraphQL.observable_phenomenon/2
        ]
      },
      valueflows_observe_mutations: %{
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
