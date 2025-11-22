# frozen_string_literal: true
# see https://github.com/kbrock/bundler-inject/tree/gem_path

# specify one or more ruby files in this directory to be injected into bundler
# you can use `gem` to add new gems, `override_gem` to change an existing gem
# or `ensure_gem` to make sure a gem is there w/o worrying about if it is an
# override or not

# NOTE: these injected gems are very sticky... it appears that you must rebuild
# your docker container and rebundle to get rid of an injected gem.
