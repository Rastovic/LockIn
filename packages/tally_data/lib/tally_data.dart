/// Tally's persistence layer.
///
/// The schema obeys `00-foundation/DATA-PORTABILITY.md` by construction: every
/// travelling table mixes in `PortableTable`, so there is no way to add a table
/// that cannot be backed up, merged or eventually synced.
library;

export 'src/backup.dart';
export 'src/database.dart';
export 'src/tables.dart';
