# frozen_string_literal: true

require 'spec_helper'
require 'time'
require 'json'

RSpec.describe 'Integration Tests' do
  def check(payload)
    path = ['./assets/check', '/opt/resource/check'].find { |p| File.exist? p }
    JSON.parse `echo '#{payload.to_json}' | #{path}`
  end

  context '/opt/resourece/check' do
    def expect_timestamps(output)
      timestamps = output.map { |v| Time.parse(v['timestamp']) }
      expect(timestamps).to eq timestamps.sort
    end

    it 'returns a list of all tags, branches, and PRs' do
      output = check(
        source: {
          uri: 'https://github.com/jtarchie/github-pullrequest-resource'
        }
      )

      expect(output).to include hash_including('branch' => 'remotes/origin/master')
      expect(output).to include hash_including('branch' => 'remotes/origin/pr/51')
      expect(output).to include hash_including('tag' => 'v22')
      expect_timestamps output
    end

    it 'filters out tags' do
      output = check(
        source: {
          uri: 'https://github.com/jtarchie/github-pullrequest-resource',
          tags: {
            only: /^v\\d$/
          }
        }
      )

      expect(output).to include hash_including('branch' => 'remotes/origin/master')
      expect(output).to include hash_including('branch' => 'remotes/origin/pr/51')
      expect(output).to include hash_including('tag' => 'v2')
      expect(output).to_not include hash_including('tag' => 'v22')
      expect_timestamps output
    end

    it 'filters out branches' do
      output = check(
        source: {
          uri: 'https://github.com/jtarchie/github-pullrequest-resource',
          branches: {
            only: /pr/
          }
        }
      )

      expect(output).to include hash_including('branch' => 'remotes/origin/pr/51')
      expect(output).to include hash_including('tag' => 'v2')
      expect(output).to include hash_including('tag' => 'v22')
      expect(output).to_not include hash_including('branch' => 'remotes/origin/master')
      expect_timestamps output
    end

    it 'ignores tags' do
      output = check(
        source: {
          uri: 'https://github.com/jtarchie/github-pullrequest-resource',
          tags: {
            ignore: /^v\\d$/
          }
        }
      )

      expect(output).to include hash_including('branch' => 'remotes/origin/master')
      expect(output).to include hash_including('branch' => 'remotes/origin/pr/51')
      expect(output).to include hash_including('tag' => 'v22')
      expect(output).to_not include hash_including('tag' => 'v2')
      expect_timestamps output
    end

    it 'ignores branches' do
      output = check(
        source: {
          uri: 'https://github.com/jtarchie/github-pullrequest-resource',
          branches: {
            ignore: /pr/
          }
        }
      )

      expect(output).to include hash_including('branch' => 'remotes/origin/master')
      expect(output).to include hash_including('tag' => 'v2')
      expect(output).to include hash_including('tag' => 'v22')
      expect(output).to_not include hash_including('branch' => 'remotes/origin/pr/51')
      expect_timestamps output
    end

    it 'only returns most recent versions' do
      output = check(
        source: {
          uri: 'https://github.com/jtarchie/github-pullrequest-resource',
          branches: {
            ignore: /pr/
          }
        },
        version: {
          tag: 'v22',
          sha: '698106d7b91cb186451fe50c732f0dfff9471a1b',
          timestamp: '2017-03-02 04:25:16 UTC'
        }
      )

      expect(output.first.fetch('tag')).to eq 'v22'
      expect(output).to include hash_including('branch' => 'remotes/origin/master')
      expect(output).to_not include hash_including('branch' => 'remotes/origin/pr/51')
      expect(output).to_not include hash_including('tag' => 'v2')
      expect_timestamps output
    end
  end
end
