# Bashly Fixture Matrix

| Fixture | Status | Diagnostics | Failures | Gate |
| --- | --- | --- | --- | --- |
| bashly-basic | ok | - | - | green |
| missing-source | ok | BASHLY_SOURCE_FILE_MISSING, BASHLY_HANDLER_MISSING | - | blocking |
| unknown-args-ref | ok | BASHLY_ARGS_REF_UNKNOWN | - | blocking |
| unused-arg | ok | BASHLY_ARG_DECLARED_UNUSED | - | green |
| unused-flag | ok | BASHLY_FLAG_DECLARED_UNUSED | - | green |
| argc-inner | ok | SOURCE_HANDLER_ORPHANED | - | green |
| argc-unknown-ref | ok | SOURCE_HANDLER_ORPHANED, ARGC_VAR_REF_UNKNOWN | - | blocking |
| apply-guard-stale | ok | - | stale_file_hash, stale_node_hash, stale_changedtick | green |
| bash-ast-parse-error | skipped | - | - | green |
