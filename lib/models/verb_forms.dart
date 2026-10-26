/// Verb conjugation entry, combining the row-aligned English and German
/// `tenses_*.csv` files into a single record.
///
/// English columns: `level,infinitive_en,past_simple,past_participle,
/// russian_inf,ru_present_ya,ru_past_on,ru_future_ya`
///
/// German columns: `level,infinitiv_de,praesens_er_sie_es,praeteritum,
/// partizip_ii,hilfsverb,russian_inf,ru_present_ya,ru_past_on,ru_future_ya`
///
/// The shared Russian fields (`russian_inf,ru_present_ya,ru_past_on,
/// ru_future_ya`) are identical in both files; the English-side values are
/// kept as the source of truth. No values are transformed.
class VerbForms {
  const VerbForms({
    required this.level,
    required this.infinitiveEn,
    required this.pastSimple,
    required this.pastParticiple,
    required this.infinitivDe,
    required this.praesensErSieEs,
    required this.praeteritum,
    required this.partizipII,
    required this.hilfsverb,
    required this.russianInf,
    required this.ruPresentYa,
    required this.ruPastOn,
    required this.ruFutureYa,
  });

  final String level;

  final String infinitiveEn;
  final String pastSimple;
  final String pastParticiple;

  final String infinitivDe;
  final String praesensErSieEs;
  final String praeteritum;
  final String partizipII;
  final String hilfsverb;

  final String russianInf;
  final String ruPresentYa;
  final String ruPastOn;
  final String ruFutureYa;

  String get id => '$level|$infinitiveEn';

  @override
  String toString() => 'VerbForms($level, $infinitiveEn, $infinitivDe)';
}
