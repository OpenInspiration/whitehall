module ServiceListeners
  class PublishingApiPusher
    attr_reader :edition

    def initialize(edition)
      @edition = edition
    end

    def push(event:, options: {})
      case event
      when "force_publish", "publish", "unwithdraw"
        api.publish_async(edition)
      when "update_draft"
        api.save_draft_async(edition)
      when "update_draft_translation"
        api.save_draft_translation_async(edition, options.fetch(:locale))
      when "unpublish"
        api.unpublish_async(edition.unpublishing)
      when "withdraw"
        api.publish_withdrawal_async(
          edition.content_id,
          edition.unpublishing.explanation,
          edition.primary_locale
        )
      when "force_schedule", "schedule"
        api.schedule_async(edition)
      when "unschedule"
        api.unschedule_async(edition)
      when "delete"
        api.discard_draft_async(edition)
      end

      handle_html_attachments(event)
      if edition.try(:document).try(:content_id) &&
          edition.try(:previous_edition) &&
          edition.try(:translations)
        handle_translations
      end
    end

  private

    def handle_html_attachments(event)
      PublishingApiHtmlAttachmentsWorker.perform_async(edition.id, event)
    end

    def handle_translations
      removed_locales = edition.previous_edition.translations.map(&:locale).map(&:to_s) - edition.translations.map(&:locale).map(&:to_s)
      removed_locales.each do |locale|
        File.open("./tmp/redirect-test.txt", "a") { |file| file.write(locale) }
        PublishingApiRedirectWorker.new.perform(
          edition.document.content_id,
          edition.search_link,
          locale
        )
      end
    end

    def api
      Whitehall::PublishingApi
    end
  end
end
