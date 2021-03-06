require 'minitest/autorun'
require 'mocha/setup'
require 'ruby-progressbar'

require_relative '../../../config/environment'
require_relative '../../../lib/sync_checker/request_queue'
require_relative '../../../lib/sync_checker/sync_check'

module SyncChecker
  class SyncCheckTest < Minitest::Test
    def setup
      ProgressBar.stubs(:create).returns(stub_everything)
    end

    def test_it_creates_a_queued_request_for_each_check
      document_checks = [
        stub,
        stub
      ]

      options = {
        mutex: Mutex.new,
        failures: stub(:<< => true, results: []),
        hydra: stub(run: nil, queue: nil, queued_requests: [])
      }

      checker = SyncCheck.new(document_checks, options)

      document_checks.each do |document_check|
        RequestQueue.expects(:new).with(
          document_check,
          options[:failures],
          options[:mutex]
        ).returns(stub(requests: []))
      end

      checker.run
    end

    def test_queues_the_requests
      document_checks = [
        stub(id: 1, base_path: "/one"),
        stub(id: 2, base_path: "/one"),
      ]

      checker = SyncCheck.new(document_checks, hydra: hydra = stub(queue: nil, run: nil, queued_requests: []))

      RequestQueue.stubs(:new).returns(stub(requests: [1, 2]))
      hydra.expects(:queue).with(1)
      hydra.expects(:queue).with(2)

      checker.run
    end

    def test_it_creates_a_hydra
      Typhoeus::Hydra.expects(:new).with(max_concurrency: 20).returns(hydra = stub)
      checker = SyncCheck.new([])
      checker.hydra == hydra
    end

    def test_runs_the_hydra
      Typhoeus::Hydra.expects(:new)
        .with(max_concurrency: 20)
        .returns(hydra = stub(queued_requests: []))
      hydra.expects(:run)
      checker = SyncCheck.new([])
      checker.run
    end
  end
end
