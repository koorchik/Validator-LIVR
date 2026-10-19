# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Validator::LIVR is the Perl implementation of LIVR (Language Independent Validation Rules, https://livr-spec.org), published on CPAN.

## Commands

```sh
cpanm --installdeps .            # test dependencies: Test::More 0.96, Test::Exception, JSON
perl Makefile.PL && make test    # build and run all tests
prove -l t/                      # run all tests without building
prove -lv t/07-wrong_rules.t     # run one test file
make disttest                    # what CI runs: tests the distribution built from MANIFEST
make dist                        # the release tarball
```

`t/01-livr_test_suite.t` runs all cases of the specification test suite and cannot run one case. It stops at the first failing negative case (`exit`), so later cases do not run.

## How validation works

- `lib/Validator/LIVR.pm` has `%DEFAULT_RULES`, which maps rule names to rule builders in `lib/Validator/LIVR/Rules/*.pm`. `new()` copies the table into the validator. `register_rules()` and `register_aliased_rule()` change only that copy, and `register_default_rules()` changes the table for validators created later.
- `prepare()`, which the first `validate()` calls, builds a closure for every rule. A rule is a name, a hash with exactly one key (`{ name => $args }`), or a list of those. A builder gets the arguments (a non-array argument is wrapped in an array) and then a hashref of all rule builders, and returns `sub { my ($value, $all_values, $output_ref) = @_; ... }`.
- `validate()` applies the closures of a field in order, passing each the output of the previous one, and stops the field at its first error. Errors of all fields are collected, and the output has only the fields that have rules.
- A closure returns nothing when the value is valid, or an error code. Metarules return a hash or a list of nested errors instead. Modifiers assign to `$$output_ref`.
- Metarules (`Rules/Meta.pm`) and aliases (`_build_aliased_rule`) create nested `Validator::LIVR` objects and call `register_rules(%$rule_builders)` on them. That is how custom rules work inside `nested_object`, `list_of`, `or` and aliases. `list_of`, `or` and aliases validate the value wrapped as `{ field => $value }` or `{ value => $value }`, so `$all_values` has no other fields there.
- Rules return early on empty values (`undef` or `''`), so that `required` is a separate rule. `required`, `not_empty`, `not_empty_list` and `default` check empty values, and `or` passes them to its rule sets.

## Compatibility

- `t/test_suite/` is the shared test suite from https://github.com/koorchik/LIVR. Update it by copying from there; the behavior must match it.
- `email` and `url` (`Rules/Special.pm`) use their own regular expressions. `url` checks hosts, IPv4 addresses and ports as Validator::LIVR 2.0 did (`http://intranet/` is valid), not as the JavaScript implementation does. `email` follows the JavaScript structure with the RFC length limits. `t/08-email_and_url.t` pins the edge cases.
- Inputs have no length limit, so regular expressions must stay linear: no nested quantifiers such as `(?:[a-z]-*)*[a-z]+`. Regexp::Common, used in 2.0, took more than 20 seconds for a wrong 100 KB URL. Use `\z`, not `$`, which also matches before a trailing newline.

## Constraints

- No runtime dependencies outside the Perl core, and the minimum Perl is 5.10: no syntax from later versions, such as `s///r` or the `/u` flag. CI tests Perl 5.10 to the newest one.
- List every new file in `MANIFEST`. `make disttest` builds the distribution from it, so a missing file fails CI.
- `README.pod` is a copy of the POD of `lib/Validator/LIVR.pm`. Regenerate it after changing the POD: `sed -n '/^=for HTML/,$p' lib/Validator/LIVR.pm > README.pod`. `MY::libscan` in `Makefile.PL` keeps old MakeMaker versions from installing it.
- All seven modules have `our $VERSION`. Change them together, with an entry in `Changes`.
