/// The version of the F5J calculation logic, stamped on every stored result.
///
/// Bump it by hand whenever a change alters any F5J score, ranking or total
/// for the same inputs. Every result stamped with an older value is then
/// stale and is recomputed before it is shown as official.
const String f5jCalculationVersion = 'f5j-1';
