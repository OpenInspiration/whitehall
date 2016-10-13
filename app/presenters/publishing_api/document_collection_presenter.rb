module PublishingApi
  class DocumentCollectionPresenter
    def initialize(item)
      @item = item
    end

    def content_id
      item.content_id
    end

    def content
      content = BaseItemPresenter.new(item).base_attributes
      content.merge!(
        description: item.summary,
        details: details,
        document_type: "document_collection",
        public_updated_at: item.public_timestamp || item.updated_at,
        rendering_app: Whitehall::RenderingApp::WHITEHALL_FRONTEND,
        schema_name: "document_collection",
      )
      content.merge!(PayloadBuilder::PublicDocumentPath.for(item))
    end

  private

    attr_reader :item

    def details
      {
        first_public_at: first_public_at,
       }
    end

    def first_public_at
      item.document.published? ? item.first_public_at : item.document.created_at
    end
  end
end
