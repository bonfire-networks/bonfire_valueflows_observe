if Code.ensure_loaded?(Bonfire.API.GraphQL) do
defmodule ValueFlows.Observe.Hydration do

  # alias Bonfire.API.GraphQL.CommonResolver
  alias ValueFlows.Observe.Observations.ObservationsResolvers
  alias ValueFlows.Observe.ObservablePropertiesGraphQL
  alias ValueFlows.Observe.ObservablePhenomenonsGraphQL

  def hydrate() do
    %{
      # FIXME
      # observation_context: [
      #   resolve_type: &CommonResolver.resolve_context_type/2
      # ],
      observable_object: [
        resolve_type: &ObservationsResolvers.resolve_observable_object_type/2
      ],
      observable_result: [
        resolve_type: &ObservationsResolvers.resolve_observable_result_type/2
      ],
      observer: [
        resolve_type: &ObservationsResolvers.resolve_observer_type/2
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
          resolve: &ObservationsResolvers.has_feature_of_interest/3
        ],
        has_result: [
          resolve: &ObservationsResolvers.has_result_edge/3
        ],
        made_by_sensor: [
          resolve: &ObservationsResolvers.made_by_edge/3
        ]

      },

      observable_property: %{
        has_choices: [
          resolve: &ObservablePropertiesGraphQL.phenomenons_edge/3
        ],
      },
      observable_phenomenon: %{
        formula_quantifier: [
          resolve: &ObservablePhenomenonsGraphQL.formula_quantifier_edge/3
        ],
        choice_of: [
          resolve: &ObservablePhenomenonsGraphQL.choice_of_edge/3
        ],
      },

      valueflows_observe_queries: %{
        observations: [
          resolve: &ObservationsResolvers.all_observations/2
        ],
        observations_pages: [
          resolve: &ObservationsResolvers.observations/2
        ],
        observation: [
          resolve: &ObservationsResolvers.observation/2
        ],

        observable_properties_pages: [
          resolve: &ObservablePropertiesGraphQL.observable_properties/2
        ],
        # all_observable_properties: [
        #   resolve: &ObservablePropertiesGraphQL.all_observable_properties/2
        # ],
        observable_property: [
          resolve: &ObservablePropertiesGraphQL.observable_property/2
        ],

        observable_phenomenon_pages: [
          resolve: &ObservablePhenomenonsGraphQL.observable_phenomenons/2
        ],
        # all_observable_phenomenons: [
        #   resolve: &ObservablePhenomenonsGraphQL.all_observable_phenomenons/2
        # ],
        observable_phenomenon: [
          resolve: &ObservablePhenomenonsGraphQL.get/2
        ]
      },
      valueflows_observe_mutations: %{
        create_observation: [
          resolve: &ObservationsResolvers.create_observation/2
        ],
        update_observation: [
          resolve: &ObservationsResolvers.update_observation/2
        ],
        delete_observation: [
          resolve: &ObservationsResolvers.delete_observation/2
        ],

        create_observable_property: [
          resolve: &ObservablePropertiesGraphQL.create_observable_property/2
        ],
        update_observable_property: [
          resolve: &ObservablePropertiesGraphQL.update_observable_property/2
        ],
        delete_observable_property: [
          resolve: &ObservablePropertiesGraphQL.delete_observable_property/2
        ],

        create_observable_phenomenon: [
          resolve: &ObservablePhenomenonsGraphQL.create_observable_phenomenon/2
        ],
        update_observable_phenomenon: [
          resolve: &ObservablePhenomenonsGraphQL.update_observable_phenomenon/2
        ],
        delete_observable_phenomenon: [
          resolve: &ObservablePhenomenonsGraphQL.delete_observable_phenomenon/2
        ]
      }
    }
  end
end
end
