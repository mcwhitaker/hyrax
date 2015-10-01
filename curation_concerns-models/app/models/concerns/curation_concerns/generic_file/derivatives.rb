module CurationConcerns
  module GenericFile
    module Derivatives
      extend ActiveSupport::Concern

      included do
        Hydra::Derivatives.source_file_service = CurationConcerns::LocalFileService
        Hydra::Derivatives.output_file_service = CurationConcerns::PersistDerivatives
      end

      # This completely overrides the version in Hydra::Works so that we
      # read and write to a local file. It's important that characterization runs
      # before derivatives so that we have a credible mime_type field to work with.
      def create_derivatives(filename)
        case mime_type
        when *self.class.pdf_mime_types
          Hydra::Derivatives::PdfDerivatives.create(filename,
                                                    outputs: [{ label: :thumbnail, format: 'jpg', size: '338x493', url: derivative_url('thumbnail') }])
        when *self.class.office_document_mime_types
          Hydra::Derivatives::DocumentDerivatives.create(filename,
                                                         outputs: [{ label: :thumbnail, format: 'jpg',
                                                                     size: '200x150>',
                                                                     url: derivative_url('thumbnail') }])
        when *self.class.audio_mime_types
          Hydra::Derivatives::AudioDerivatives.create(filename,
                                                      outputs: [{ label: 'mp3', format: 'mp3', url: derivative_url('mp3') },
                                                                { label: 'ogg', format: 'ogg', url: derivative_url('ogg') }])
        when *self.class.video_mime_types
          Hydra::Derivatives::VideoDerivatives.create(filename,
                                                      outputs: [{ label: :thumbnail, format: 'jpg', url: derivative_url('thumbnail') },
                                                                { label: 'webm', format: 'webm', url: derivative_url('webm') },
                                                                { label: 'mp4', format: 'mp4', url: derivative_url('mp4') }])
        when *self.class.image_mime_types
          Hydra::Derivatives::ImageDerivatives.create(filename,
                                                      outputs: [{ label: :thumbnail, format: 'jpg', size: '200x150>', url: derivative_url('thumbnail') }])
        end
      end

      private

        # The destination_name parameter has to match up with the file parameter
        # passed to the DownloadsController
        def derivative_url(destination_name)
          path = DerivativePath.derivative_path_for_reference(self, destination_name)
          URI("file://#{path}").to_s
        end
    end
  end
end
