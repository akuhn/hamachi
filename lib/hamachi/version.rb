# frozen_string_literal: true

module Hamachi
  VERSION = "0.3.2-beta"
end

__END__

# Major version bump when breaking changes or new features
# Minor version bump when backward-compatible changes or enhancements
# Patch version bump when backward-compatible bug fixes, security updates etc


0.3.2

- New function Model#error_messages
- Reorganize tests and write more tests
- ...

0.3.1

- Rename check_types to valid? and validate_fields!
- Reorganize tests and write more tests

0.3.0

- Rename Matcher class to Field class
- Rename Model.register_matcher to Model.register_type

0.2.0

- Require 'hamachi/model' to import model as top-level constant
- Require 'hamachi/ext' to extend arrays and other enumerables
- New function Model.register_matcher

0.1.0

- Initial import from internal project.
