require 'spec_helper'

describe Fastlane::Actions::AnalyzeCommitsAction do
  describe "Analyze Commits" do
    before do
    end

    def test_analyze_commits(commits)
      # for simplicity, these two actions are grouped together because they need to be run for every test,
      # but require different commits to be passed each time. So we can't use the "before :each" for this
      allow(Fastlane::Actions::AnalyzeCommitsAction).to receive(:get_last_tag).and_return('v1.0.8-1-g71ce4d8')
      allow(Fastlane::Actions::AnalyzeCommitsAction).to receive(:get_commits_from_hash).and_return(commits)
    end

    def execute_lane_test(params)
      Fastlane::FastFile.new.parse("lane :test do analyze_commits( #{params} ) end").runner.execute(:test)
    end

    it "should increment fix and return true" do
      commits = [
        "docs: ...|",
        "bugfix: ...|"
      ]
      test_analyze_commits(commits)

      expect(execute_lane_test(match: 'v*')).to eq(["1.0.9", true])
      expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::RELEASE_NEXT_VERSION]).to eq("1.0.9")
    end

    it "should increment feat and fix and return true" do
      commits = [
        "docs: ...|",
        "feature: ...|",
        "bugfix: ...|"
      ]
      test_analyze_commits(commits)

      expect(execute_lane_test(match: 'v*')).to eq(["1.1.0", true])
      expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::RELEASE_NEXT_VERSION]).to eq("1.1.0")
    end

    it "should increment major change and return true" do
      commits = [
        "docs: ...|",
        "feature: ...|",
        "bugfix: ...|BREAKING CHANGE: Test"
      ]
      test_analyze_commits(commits)

      expect(execute_lane_test(match: 'v*')).to eq(["2.0.0", true])
      expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::RELEASE_NEXT_VERSION]).to eq("2.0.0")
    end

    it "should increment major change and return true" do
      commits = [
        "docs: ...|",
        "feature: ...|",
        "bugfix!: ...|BREAKING CHANGE: Bump major version"
      ]
      test_analyze_commits(commits)

      expect(execute_lane_test(match: 'v*')).to eq(["2.0.0", true])
      expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::RELEASE_NEXT_VERSION]).to eq("2.0.0")
    end

    describe "scopes" do
      commits = [
        "bugfix(scope): ...|",
        "feature(ios): ...|",
        "bugfix(ios): ...|",
        "feature(android): ...|",
        "bugfix(android): ...|"
      ]

      describe "parsing of scopes" do
        it "should correctly parse and output scopes" do
          test_analyze_commits(commits)

          expect(execute_lane_test(match: 'v*')).to eq(["1.1.0", true])
          expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::RELEASE_NEXT_VERSION]).to eq("1.1.0")
        end
      end

      describe "filtering by scopes" do
        it "should accommodate an empty ignore_scopes array" do
          test_analyze_commits(commits)

          expect(execute_lane_test(match: 'v*', ignore_scopes: [])).to eq(["1.1.0", true])
          expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::RELEASE_NEXT_VERSION]).to eq("1.1.0")
        end

        it "should skip a single scopes if it has been added to ignore_scopes" do
          test_analyze_commits(commits)

          expect(execute_lane_test(match: 'v*', ignore_scopes: ['android'])).to eq(["1.1.0", true])
          expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::RELEASE_NEXT_VERSION]).to eq("1.1.0")
        end

        it "should skip multiple scopes if they have been added to ignore_scopes" do
          test_analyze_commits(commits)

          expect(execute_lane_test(match: 'v*', ignore_scopes: ['android', 'ios'])).to eq(["1.0.9", true])
          expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::RELEASE_NEXT_VERSION]).to eq("1.0.9")
        end

        it "should not pass analysis checks if all commits are caught by excluded scopes" do
          commits = [
            "bugfix(ios): ...|"
          ]
          test_analyze_commits(commits)

          expect(execute_lane_test(match: 'v*', ignore_scopes: ['ios'])).to eq(["1.0.8", false])
        end
      end
    end

    it "should return false since there is no change that would increase version" do
      commits = [
        "docs: ...|",
        "chore: ...|",
        "refactor: ...|"
      ]
      test_analyze_commits(commits)

      expect(execute_lane_test(match: 'v*')).to eq(["1.0.8", false])
      expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::RELEASE_NEXT_VERSION]).to eq("1.0.8")
    end

    it "should return false since there is no change that would increase version" do
      commits = [
        "Merge ...|",
        "Custom ...|"
      ]
      test_analyze_commits(commits)

      expect(execute_lane_test(match: 'v*')).to eq(["1.0.8", false])
      expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::RELEASE_NEXT_VERSION]).to eq("1.0.8")
    end

    it "should deal with multiline comments" do
      commits = [
        "bugfix: add alpha deploy (#10)|* chore: test alpha build with CircleCI

        * chore: skip code check for now

        * chore: ignore gems dirs
        ",
        "chore: add alpha deploy triggered by alpha branch|",
        "bugfix: fix navigation after user logs in|"
      ]
      test_analyze_commits(commits)

      expect(execute_lane_test(match: 'v*')).to eq(["1.0.9", true])
      expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::RELEASE_NEXT_VERSION]).to eq("1.0.9")
    end

    it "should provide codepush last version" do
      commits = [
        "bugfix: ...|codepush: ok",
        "bugfix: ...|codepush: ok",
        "bugfix: ...|codepush: ok",
        "bugfix: ...|codepush: ok",
        "bugfix: ...|codepush: ok",
        "bugfix: ...",
        "bugfix: ...|codepush: ok",
        "docs: ...|codepush: ok",
        "feature: ...|codepush: ok",
        "bugfix: ...|codepush: ok"
      ]
      allow(Fastlane::Actions::AnalyzeCommitsAction).to receive(:get_last_tag).and_return('v0.0.0-1-g71ce4d8')
      allow(Fastlane::Actions::AnalyzeCommitsAction).to receive(:get_commits_from_hash).and_return(commits)

      expect(execute_lane_test(match: 'v*')).to eq(["0.1.0", true])
      expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::RELEASE_NEXT_VERSION]).to eq("0.1.0")
      expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::RELEASE_LAST_INCOMPATIBLE_CODEPUSH_VERSION]).to eq("0.0.6")
    end

    it "should accept only codepush: ok as codepush friendly commit" do
      commits = [
        "bugfix: ...|codepush: ok",
        "bugfix: ...|codepush: ok",
        "bugfix: ...|codepush: ok",
        "bugfix: ...|codepush",
        "bugfix: ...|codepush: ok",
        "docs: ...|codepush: ok",
        "feature: ...|codepush: ok",
        "bugfix: ...|codepush: ok"
      ]
      allow(Fastlane::Actions::AnalyzeCommitsAction).to receive(:get_last_tag).and_return('v0.0.0-1-g71ce4d8')
      allow(Fastlane::Actions::AnalyzeCommitsAction).to receive(:get_commits_from_hash).and_return(commits)

      expect(execute_lane_test(match: 'v*')).to eq(["0.1.0", true])
      expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::RELEASE_NEXT_VERSION]).to eq("0.1.0")
      expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::RELEASE_LAST_INCOMPATIBLE_CODEPUSH_VERSION]).to eq("0.0.4")
    end

    it "should docs, test, etc commits are codepush friendly automatically" do
      commits = [
        "bugfix: ...|codepush: ok",
        "bugfix: ...|codepush: ok",
        "bugfix: ...|codepush",
        "test: ...",
        "refactor: ...|codepush: ok",
        "feature: ...|codepush: ok",
        "perf: ...|codepush: ok",
        "chore: ...",
        "docs: ...",
        "feature: ...|codepush: ok",
        "bugfix: ...|codepush: ok"
      ]
      allow(Fastlane::Actions::AnalyzeCommitsAction).to receive(:get_last_tag).and_return('v0.0.0-1-g71ce4d8')
      allow(Fastlane::Actions::AnalyzeCommitsAction).to receive(:get_commits_from_hash).and_return(commits)

      expect(execute_lane_test(match: 'v*')).to eq(["0.1.0", true])
      expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::RELEASE_NEXT_VERSION]).to eq("0.1.0")
      expect(Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::RELEASE_LAST_INCOMPATIBLE_CODEPUSH_VERSION]).to eq("0.0.3")
    end

    after do
    end
  end
end
