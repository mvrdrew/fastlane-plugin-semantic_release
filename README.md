# simple_semantic_release plugin for `fastlane`

[![License](https://img.shields.io/github/license/SiarheiFedartsou/fastlane-plugin-versioning.svg)](https://github.com/SiarheiFedartsou/fastlane-plugin-versioning/blob/master/LICENSE)

## Credit

This is a fork of `fastlane-plugin_semantic_release`. It was forked to change the version numbering to be a little less enthusiastic, as the [original author has made it clear](https://github.com/xotahal/fastlane-plugin-semantic_release/issues/11) he has no plans to change it. While it's true that worrying about version numbering is a waste of time this plugin is meant to solve, it would still be nice to have an option to keep version increments to a minimum.

In addition to the version numbering changes, some additional changes have been made to the changelog generation to conform more closely the the [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format, as well as remove some Markdown lint errors.

## Getting Started

This fork is not going to be published, in order to use it you'll need to point to this repository directly.

Update your project's `Pluginfile` and add this line:

```ruby
gem 'fastlane-plugin-simple_semantic_release', git: 'https://github.com/mvrdrew/fastlane-plugin-simple_semantic_release'
```

## About

Automated version managment and generator of release notes. Inspired by [semantic-release](https://github.com/semantic-release/semantic-release) for npm packages. Based on [conventional commits](https://www.conventionalcommits.org/).

### Articles

[Semantic Release for Fastlane](https://medium.com/@xotahal/semantic-release-for-fastlane-781df4cf5888?source=friends_link&sk=5c02e32daca7a68539e27e0e1bac1092) @ Medium - By Jiri Otahal

## Available Actions

### `conventional_changelog`

- parses all commits since last version
- groups those commits by their type (fix, feat, docs, refactor, chore, etc)
- and creates formated release notes either in markdown or in slack format

Available parameters:

- `format: 'slack|markdown|plain'` (defaults to `markdown`). This formats the changelog for the destination you need. If you're using this for TestFlight changelogs, we suggest using the `plain` option
- `title: 'My Title'` - is appended to the release notes title, "1.1.8 My Title (YYYY-MM-DD)"
- `display_title: true|false` (defaults to true) - allows you to hide the entire first line of the changelog
- `display_links: true|false` (defaults to true) - allows you to hide links to commits from your changelog
- `commit_url: 'https://github.com/username/repository/commit'` - prepended to the commit ID to build usable links
- View other options by searching for `available_options` in `conventional_changelog.rb`

Example:

```ruby
notes = conventional_changelog(format: 'slack', title: 'Android Alpha')
```

### `analyze_commits`

- analyzes your git history
- finds last tag on current branch (for example ios/beta/1.3.2)
- parses the last version from tag (1.3.2)
- gets all commits since this tag
- analyzes subject of every single commit and increases version number if there is a need (check conventional commit rules)
- if next version number is higher then last version number it will recommend you to release this version

Options:

- `ignore_scopes: ['android','windows']`: allows you to ignore any commits which include a given scope, like this one: `feat(android): add functionality not relevant to the release we are producing`

Example usage:

```ruby
isReleasable = analyze_commits(match: 'ios/beta*')
```

It provides these variables in `lane_context`.

```ruby
['RELEASE_ANALYZED', 'True if commits were analyzed.'],
['RELEASE_IS_NEXT_VERSION_HIGHER', 'True if next version is higher then last version'],
['RELEASE_LAST_TAG_HASH', 'Hash of commit that is tagged as a last version'],
['RELEASE_LAST_VERSION', 'Last version number - parsed from last tag.'],
['RELEASE_NEXT_MAJOR_VERSION', 'Major number of the next version'],
['RELEASE_NEXT_MINOR_VERSION', 'Minor number of the next version'],
['RELEASE_NEXT_PATCH_VERSION', 'Patch number of the next version'],
['RELEASE_NEXT_VERSION', 'Next version string in format (major.minor.patch)'],
```

And you can access these like this:

```ruby
next_version = lane_context[SharedValues::RELEASE_NEXT_VERSION]
```

## Tests

To run the test suite (contained in `./spec`), call `bundle exec rake`
