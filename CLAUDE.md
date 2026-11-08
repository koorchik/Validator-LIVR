# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Validator::LIVR is the Perl implementation of LIVR (Language Independent Validation Rules, https://livr-spec.org), published on CPAN.

## Commands

```sh
cpanm --installdeps .            # test dependencies: Test::More 0.96, Test::Exception, Test::MockTime, JSON
perl Makefile.PL && make test    # build and run all tests
prove -l t/                      # run all tests without building
prove -lv t/07-wrong_rules.t     # run one test file
make disttest                    # what CI runs: tests the distribution built from MANIFEST
make dist                        # the release tarball
```

`t/01-livr_test_suite.t` runs all cases of the specification test suite and cannot run one case. It stops at the first failing negative case (`exit`), so later cases do not run.

## How validation works

- `lib/Validator/LIVR.pm` has `$DEFAULT_RULES`, which maps rule names to rule builders in `lib/Validator/LIVR/Rules/*.pm`. The LIVR 2.5 rules (`Types`, `DateTime`, `Conditional`, `Collection`, `Format`) are loaded on first use through `_lazy_rule()`. The table is never changed in place: `new()` shares it, `register_rules()` and `register_aliased_rule()` copy it first (`_own_builders()`), and `register_default_rules()` makes a new table for validators created later.
- `prepare()`, which the first `validate()` calls, builds a closure for every rule. A rule is a name, a hash with exactly one key (`{ name => $args }`), or a list of those. A builder gets the arguments (a non-array argument is wrapped in an array, `{ name => undef }` gives `undef`, a wrong argument for every LIVR 2.5 rule; `iso_date` takes it as no arguments, as 2.0 ignored its arguments) and then a hashref of all rule builders (shared, never changed), and returns `sub { my ($value, $all_values, $output_ref) = @_; ... }`. LIVR 2.5 builders die on wrong arguments and ignore the arguments after the ones they take; LIVR 2.0 builders ignore extra arguments too. The rule builders are always the last argument, so take them as `$_[-1]`, not by position.
- `validate()` applies the closures of a field in order, passing each the output of the previous one, and stops the field at its first error. Errors of all fields are collected, and the output has only the fields that have rules.
- A closure returns nothing when the value is valid, or an error code. Metarules return a hash or a list of nested errors instead. Modifiers assign to `$$output_ref`.
- Metarules and aliases (`_build_aliased_rule`) create nested validators with `_new_with_rules($livr, $rule_builders)`, which shares the rules of the parent. That is how custom rules work inside `nested_object`, `list_of`, `or` and aliases. `list_of`, `or`, `when`, `values`, `keys` and aliases call the rules of a field directly with `_field_rule()`: `or`, `when` and aliases pass the `$all_values` of their caller (LIVR 2.5: they are transparent), `list_of`, `values` and `keys` an empty hash.
- `today`, `yesterday` and `tomorrow` read `time` (`Rules/DateTime.pm`). There is no clock option: tests fix the time with Test::MockTime, loaded before Validator::LIVR, because it replaces `CORE::GLOBAL::time` only for code compiled after it.
- Rules return early on empty values (`undef` or `''`), so that `required` is a separate rule. `required`, `not_empty`, `not_empty_list` and `default` check empty values, and `or` passes them to its rule sets.

## Compatibility

- `t/test_suite/` and `t/test_suite_2.5/` are the shared test suites from https://github.com/koorchik/LIVR. Update them by copying from there; the behavior must match them. `options.json` of a case gives the time that `t/01-livr_test_suite.t` fixes with Test::MockTime, `schema_errors/` cases pass when `prepare()` dies.
- `email` and `url` (`Rules/Special.pm`) use their own regular expressions. `url` checks hosts and IPv4 addresses as Validator::LIVR 2.0 did (`http://intranet/` is valid), not as the JavaScript implementation does, plus the three points of LIVR 2.5: no dot after the host, labels of up to 63 characters, ports of 1-5 digits from 0 to 65535. `email` follows the JavaScript structure with the RFC length limits. `t/08-email_and_url.t` pins the edge cases.
- Inputs have no length limit, so regular expressions must stay linear: no nested quantifiers such as `(?:[a-z]-*)*[a-z]+`. Regexp::Common, used in 2.0, took more than 20 seconds for a wrong 100 KB URL. Use `\z`, not `$`, which also matches before a trailing newline.

## Constraints

- No runtime dependencies outside the Perl core, and the minimum Perl is 5.10: no syntax from later versions, such as `s///r` or the `/u` flag. CI tests Perl 5.10 to the newest one.
- List every new file in `MANIFEST`. `make disttest` builds the distribution from it, so a missing file fails CI.
- `README.pod` is a copy of the POD of `lib/Validator/LIVR.pm`. Regenerate it after changing the POD: `sed -n '/^=for HTML/,$p' lib/Validator/LIVR.pm > README.pod`. `MY::libscan` in `Makefile.PL` keeps old MakeMaker versions from installing it.
- All twelve modules have `our $VERSION`. Change them together, with an entry in `Changes`.
