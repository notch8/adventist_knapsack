# frozen_string_literal: true
# see https://github.com/kbrock/bundler-inject/tree/gem_path

# specify one or more ruby files in this directory to be injected into bundler
# you can use `gem` to add new gems, `override_gem` to change an existing gem
# or `ensure_gem` to make sure a gem is there w/o worrying about if it is an
# override or not

# Note: these injected gems are very sticky... it appears that you must rebuild
# your docker container and rebundle to get rid of an injected gem. 

ensure_gem 'derivative-rodeo', '~> 0.5', '>= 0.5.3'
ensure_gem 'json-canonicalization', '~> 0.3.3'
# Refer to this rails version to resolve compatibility issues with good_job
# branch: '6-1-stable'
ensure_gem 'rails', '~> 6.0', github: 'rails/rails', ref: 'd16199e507086e3d54d94253b7e1d87ead394d9f'

