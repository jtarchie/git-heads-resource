# frozen_string_literal: true

require 'json'
require 'spec_helper'
require 'time'
require 'tmpdir'

RSpec.describe 'Integration Tests' do
  def check(payload)
    path = ['./assets/check', '/opt/resource/check'].find { |p| File.exist? p }
    JSON.parse `echo '#{payload.to_json}' | #{path}`
  end

  def get(payload, dir)
    path = ['./assets/in', '/opt/resource/in'].find { |p| File.exist? p }
    JSON.parse `echo '#{payload.to_json}' | #{path} #{dir}`
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
            only: /^v\d$/
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
            ignore: /^v\d$/
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

    it 'does not fail on an empty version' do
      output = check(
        source: {
          uri: 'https://github.com/jtarchie/github-pullrequest-resource',
          branches: {
            ignore: /pr/
          }
        },
        version: nil
      )

      expect(output.size).to be > 0
      expect_timestamps output
    end
  end

  context '/opt/resource/in' do
    it 'fetches a tag version' do
      dir = Dir.mktmpdir
      output = get({
                     source: {
                       uri: 'https://github.com/jtarchie/github-pullrequest-resource'
                     },
                     version: {
                       tag: 'v22',
                       sha: '698106d7b91cb186451fe50c732f0dfff9471a1b',
                       timestamp: '2017-03-02 04:25:16 UTC'
                     }
                   }, dir)

      Dir.chdir(dir) do
        expect(`git rev-parse HEAD`.chomp).to eq '698106d7b91cb186451fe50c732f0dfff9471a1b'
      end

      expect(output).to eq(
        'version' => {
          'tag' => 'v22',
          'sha' => '698106d7b91cb186451fe50c732f0dfff9471a1b',
          'timestamp' => '2017-03-02 04:25:16 UTC'
        }
      )
    end

    it 'fetches a branch version' do
      dir = Dir.mktmpdir
      output = get({
                     source: {
                       uri: 'https://github.com/jtarchie/github-pullrequest-resource'
                     },
                     version: {
                       tag: 'remotes/origin/pr/51',
                       sha: '46ed2c41c36c91d0ba02185549d1522f8611f627',
                       timestamp: '2016-12-17 04:25:16 UTC'
                     }
                   }, dir)

      Dir.chdir(dir) do
        expect(`git rev-parse HEAD`.chomp).to eq '46ed2c41c36c91d0ba02185549d1522f8611f627'
      end

      expect(output).to eq(
        'version' => {
          'tag' => 'remotes/origin/pr/51',
          'sha' => '46ed2c41c36c91d0ba02185549d1522f8611f627',
          'timestamp' => '2016-12-17 04:25:16 UTC'
        }
      )
    end
  end
end
