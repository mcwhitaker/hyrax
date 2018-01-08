module Hyrax
  module Actors
    # Responsible for generating the workflow for the given curation_concern.
    # Done through direct collaboration with the configured Hyrax::Actors::InitializeWorkflowActor.workflow_factory
    #
    # @see Hyrax::Actors::InitializeWorkflowActor.workflow_factory
    # @see Hyrax::Workflow::WorkflowFactory for default workflow factory
    class InitializeWorkflowActor < AbstractActor
      class_attribute :workflow_factory
      self.workflow_factory = ::Hyrax::Workflow::WorkflowFactory

      # @param [Hyrax::Actors::Environment] env
      # @return [Valkyrie::Resource,FalseClass] the saved resource if create was successful
      def create(env)
        saved = next_actor.create(env)
        return false unless saved
        create_workflow(saved, env)
        saved
      end

      private

        # @return [TrueClass]
        def create_workflow(saved, env)
          workflow_factory.create(saved,
                                  env.attributes,
                                  env.user,
                                  persister: env.change_set_persister.metadata_adapter.persister)
        end
    end
  end
end
