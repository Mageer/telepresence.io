define nl


endef

subtree-preflight:
	@if ! grep -q -e 'has_been_added' $$(PATH=$$(git --exec-path):$$PATH which git-subtree 2>/dev/null) /dev/null; then \
	    printf '$(RED)Please upgrade your git-subtree:$(END)\n'; \
	    printf '$(BLD)  sudo curl -fL https://raw.githubusercontent.com/LukeShu/git/lukeshu/next/2021-05-15/contrib/subtree/git-subtree.sh -o $$(git --exec-path)/git-subtree && sudo chmod 755 $$(git --exec-path)/git-subtree$(END)\n'; \
	    false; \
	else \
	    printf '$(GRN)git-subtree OK$(END)\n'; \
	fi
	git gc
.PHONY: subtree-preflight

PULL_PREFIX ?=
PUSH_PREFIX ?= $(USER)/from-telepresence.io-$(shell date +%Y-%m-%d)/

dir2branch = $(patsubst docs/%,release/%,$(subst pre-release,v2,$1))

# Used when syncing from telepresenceio since that repo doesn't
# have docs for v1.
EXCLUDE_DIR ?= ""
pull-docs: ## Update ./docs from https://github.com/telepresenceio/docs
pull-docs: subtree-preflight
	$(foreach subdir,$(shell find docs -mindepth 1 -maxdepth 1 -type d -not -name $(EXCLUDE_DIR)|sort -V),\
          git subtree pull --squash --prefix=$(subdir) https://github.com/telepresenceio/docs $(PULL_PREFIX)$(call dir2branch,$(subdir))$(nl))
.PHONY: pull-docs

PUSH_BRANCH ?= $(USER)/from-telepresence.io-$(shell date +%Y-%m-%d)
push-docs: ## Publish ./ambassador to https://github.com/telepresenceio/docs
push-docs: subtree-preflight
	@PS4=; set -x; { \
	  git remote add --no-tags remote-docs https://github.com/telepresenceio/docs && \
	  git remote set-url --push remote-docs https://github.com/telepresenceio/docs && \
	:; } || true
	git fetch --prune remote-docs
	$(foreach subdir,$(shell find docs -mindepth 1 -maxdepth 1 -type d|sort -V),\
          git subtree push --rejoin --squash --prefix=$(subdir) remote-docs $(PUSH_PREFIX)$(call dir2branch,$(subdir))$(nl))
.PHONY: push-docs
