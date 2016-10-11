require 'equivalent-xml'

require "minitest/autorun"
require "mocha/setup"
require "active_support/json"

require_relative "../../whitehall/govspeak_renderer"

module SyncChecker
  module Checks
    class HtmlUnpublishedCheckTest < Minitest::Test
      def setup
        Whitehall::GovspeakRenderer.stubs(:new).returns(@stub_renderer = stub)
      end

      def test_returns_no_errors_if_the_attachable_has_no_unpublishing
        attachment = stub(
          attachable: stub(
            unpublishing: nil,
            "withdrawn?" => false,
            "draft?" => false
          )
        )

        assert_equal [], HtmlAttachmentUnpublishedCheck.new(attachment).call(stub)
      end

      def test_returns_no_errors_if_the_attachable_is_withdrawn_and_the_attachment_has_a_withdrawn_notice
        attachment = stub(
          attachable: stub(
            unpublishing: stub(
              unpublishing_reason_id: 5,
              explanation: "Withdrawnificated"
            ),
            "withdrawn?" => true,
            "draft?" => false
          )
        )

        response = stub(
          body: {
            withdrawn_notice: {
              explanation: "<p>Withdrawnificated</p>"
            }
          }.to_json
        )

        @stub_renderer.stubs(:govspeak_to_html).returns("<p>Withdrawnificated</p>")

        assert_equal [], HtmlAttachmentUnpublishedCheck.new(attachment).call(response)
      end

      def test_returns_an_error_if_the_document_should_by_withdrawn_but_has_no_notice
        attachment = stub(
          attachable: stub(
            unpublishing: stub(
              unpublishing_reason_id: 5,
              explanation: "Withdrawnificated"
            ),
            "withdrawn?" => true,
            "draft?" => false
          )
        )

        response = stub(
          body: {
            withdrawn_notice: { }
          }.to_json
        )

        @stub_renderer.stubs(:govspeak_to_html).returns("<p>Withdrawnificated</p>")

        expected_error = "expected withdrawn notice: '<p>Withdrawnificated</p>' but got ''"

        assert_equal [expected_error],
          HtmlAttachmentUnpublishedCheck.new(attachment).call(response)
      end

      def test_returns_no_error_if_the_attachable_is_unpublished_in_error_and_the_attachment_returns_a_redirect_to_the_parent
        attachment = stub(
          attachable: stub(
            unpublishing: stub(
              unpublishing_reason_id: 1,
              explanation: "Unpublished Error",
              alternative_url: "https://gov.uk/alt",
              "redirect?" => false
            ),
            "withdrawn?" => false,
            "draft?" => true
          )
        )

        response = stub(
          #we can't currently test the destination of a content-store redirect item
          #as it isn't in the JSON
          body: {
            schema_name: "redirect",
            withdrawn_notice: {},
            details: {}
          }.to_json
        )

        assert_equal [],
          HtmlAttachmentUnpublishedCheck.new(attachment).call(response)
      end
    end

    def test_returns_no_error_if_the_attachable_is_unpublished_in_error_and_the_attachment_returns_a_redirect_to_the_alternative_url
      attachment = stub(
        attachable: stub(
          unpublishing: stub(
            unpublishing_reason_id: 1,
            explanation: "Unpublished Error",
            alternative_url: "https://gov.uk/alt",
            "redirect?" => true
          ),
          "withdrawn?" => false,
          "draft?" => true
        )
      )

      response = stub(
        #we can't currently test the destination of a content-store redirect item
        #as it isn't in the JSON
        body: {
          schema_name: "redirect",
          withdrawn_notice: {},
          details: {}
        }.to_json
      )

      assert_equal [],
        HtmlAttachmentUnpublishedCheck.new(attachment).call(response)
    end

    def test_returns_an_error_if_the_attachable_is_unpublished_in_error_and_the_attachment_does_not_redirect
      attachment = stub(
        attachable: stub(
          unpublishing: stub(
            unpublishing_reason_id: 1,
            explanation: "Unpublished Error",
            alternative_url: "https://gov.uk/alt",
            "redirect?" => true
          ),
          "withdrawn?" => false,
          "draft?" => true
        )
      )

      response = stub(
        #we can't currently test the destination of a content-store redirect item
        #as it isn't in the JSON
        body: {
          schema_name: "gone",
          withdrawn_notice: {},
          details: {}
        }.to_json
      )

      expected_error = "attachment should to redirect parent"

      assert_equal [expected_error],
        HtmlAttachmentUnpublishedCheck.new(attachment).call(response)
    end

    HtmlAttachmentUnpublishedCheck = Struct.new(:attachment) do
      attr_reader :attachable, :content_item, :unpublishing

      def call(response)
        @attachable = attachment.attachable
        @unpublishing = attachable.unpublishing

        failures = []
        return failures unless attachable.unpublishing.present?

        @content_item = JSON.parse(response.body)
        if attachable_has_been_withdrawn?
          failures << check_for_withdrawn_notice
        else attachable_has_been_unpublished?
          failures << check_for_redirect_to_parent
        end

        failures.compact
      end

    private

      def attachable_has_been_withdrawn?
        attachable.withdrawn?
      end

      def check_for_withdrawn_notice
        expected_notice l
        content_item["withdrawn_notice"]
      end

      def check_for_withdrawn_notice#(unpublishing, content_item)
        item_withdrawn_explanation = content_item["withdrawn_notice"]["explanation"]
        return if unpublishing.explanation.blank? && item_withdrawn_explanation.blank?

        withdrawn_explanation = Whitehall::GovspeakRenderer.new.govspeak_to_html(unpublishing.explanation)

        if !EquivalentXml.equivalent?(withdrawn_explanation, item_withdrawn_explanation)
          "expected withdrawn notice: '#{withdrawn_explanation}' but got '#{item_withdrawn_explanation}'"
        end
      end

      def attachable_has_been_unpublished?
        attachable.draft? && attachable.unpublishing.present?
      end

      def check_for_redirect_to_parent
        "attachment should redirect to parent" unless content_item["schema_name"] == "redirect"
      end
    end
  end
end
