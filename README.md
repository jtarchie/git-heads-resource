# `git` head resource

This resource will detect new commits that are done across branches, tags, and
(if using Github) pull requests. It returns them in order of most recent, so
concourse can effectively iterate with them `version: every`.

## Using in a pipeline

Define a custom resource type in your pipeline YAML. You'll have to this in
each pipeline.

```
resource_types:
- name: git-head
  type: docker-image
  source:
    repository: jtarchie/git-head-resource
    branches:
      only: /master/

resources:
- name: github-pullrequest-resource
  type: git-head
  source:
    uri: https://github.com/jtarchie/github-pullrequest-resource

jobs:
- name: example
  plan:
  - get: github-pullrequest-resource
    trigger: true
    version: every
```

## Source configuration

* `uri`: *Required*. The uri to the git repo.
* `branches.only`: *Optional*. A regex to match the branch names to include.
  Default is `.*`, which means all branches.
* `branches.ignore`: *Optional*. A regex to match the branch names to exclude.
* `tags.only`: *Optional*. A regex to match the tags names to include. Default
  is `.*`, which means all tags.
* `tags.ignore`: *Optional*. A regex to match the tags names to exclude.
* `git.fetch`: *Optional*. The command that fetches the branch/tag reference.
  The default is `git fetch --unshallow --force --recurse-submodules=yes
  --jobs=4 origin $REF`.

## Behaviour

### `check`: Get new commits against configured
### `in`: Checkout git repo to SHA
### `out`: noop
