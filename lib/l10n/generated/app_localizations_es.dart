// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Sushi Tracker';

  @override
  String get settingsTooltip => 'Ajustes';

  @override
  String get navCounter => 'Contador';

  @override
  String get navHistory => 'Historial';

  @override
  String get navStats => 'Estadísticas';

  @override
  String get cancel => 'Cancelar';

  @override
  String get close => 'Cerrar';

  @override
  String get delete => 'Eliminar';

  @override
  String get reset => 'Reiniciar';

  @override
  String get undo => 'Deshacer';

  @override
  String get storageError => 'No se pudieron abrir tus datos guardados.';

  @override
  String get tryAgain => 'Reintentar';

  @override
  String currentSessionSemantics(int count) {
    return 'Sesión actual: $count sushi';
  }

  @override
  String get tapToStart => 'Toca el sushi para empezar';

  @override
  String get tapHint =>
      'Toca para sumar · Mantén pulsado o Deshacer para restar';

  @override
  String get sushiButtonLabel => 'Sumar un sushi';

  @override
  String get sushiButtonHint =>
      'Toca dos veces para sumar uno. Mantén pulsado para restar uno.';

  @override
  String get endSession => 'Terminar sesión';

  @override
  String get thisSession => 'Esta sesión';

  @override
  String get lifetimeTotal => 'Total histórico';

  @override
  String get elapsed => 'Tiempo';

  @override
  String get errorSaveOngoing => 'No se pudo guardar la sesión actual.';

  @override
  String get errorResetCurrent => 'No se pudo reiniciar la sesión actual.';

  @override
  String get errorCompleteSession =>
      'No se pudo guardar esta sesión. Inténtalo de nuevo.';

  @override
  String get discardSession => 'Descartar sesión';

  @override
  String get discardSessionTitle => '¿Descartar esta sesión?';

  @override
  String get discardSessionBody =>
      'Sus toques no se guardarán en el historial.';

  @override
  String get discard => 'Descartar';

  @override
  String get sessionDiscarded => 'Sesión descartada.';

  @override
  String get historyTitle => 'HISTORIAL DE SESIONES';

  @override
  String get noSessions => 'Todavía no hay sesiones.';

  @override
  String durationLabel(String duration) {
    return 'Duración: $duration';
  }

  @override
  String get beforeReset => 'Antes del reinicio';

  @override
  String get deleteSessionTooltip => 'Eliminar sesión';

  @override
  String get deleteSessionTitle => '¿Eliminar sesión?';

  @override
  String get deleteSessionBody =>
      'Se quitará del historial. El total histórico se actualiza si pertenece al periodo actual.';

  @override
  String sessionsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sesiones eliminadas',
      one: 'Sesión eliminada',
    );
    return '$_temp0';
  }

  @override
  String get couldNotDelete =>
      'No se pudo eliminar esta sesión. Inténtalo de nuevo.';

  @override
  String get couldNotRestore => 'No se pudo restaurar esta sesión.';

  @override
  String get sessionDetails => 'Detalles de la sesión';

  @override
  String get beforeResetDetail =>
      'Se registró antes del último reinicio, así que no cuenta en los totales históricos actuales.';

  @override
  String get statsTitle => 'ESTADÍSTICAS';

  @override
  String get lifetimeTaps => 'Toques históricos';

  @override
  String get lifetimeSessions => 'Sesiones históricas';

  @override
  String averageKpi(String range) {
    return 'Media ($range)';
  }

  @override
  String bestKpi(String range) {
    return 'Mejor ($range)';
  }

  @override
  String get filterLast7 => '7 sesiones';

  @override
  String get filterLast30 => '30 sesiones';

  @override
  String get filterAll => 'Todas';

  @override
  String get rangeSemantics => 'Rango en número de sesiones';

  @override
  String get sessionTrend => 'Evolución';

  @override
  String get noTrend => 'Termina una sesión para ver tu evolución.';

  @override
  String chartSemantics(int count) {
    return 'Gráfico de evolución de $count sesiones. Toca un punto para ver su fecha y sus toques.';
  }

  @override
  String tapsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count toques',
      one: '1 toque',
    );
    return '$_temp0';
  }

  @override
  String sinceReset(String date) {
    return 'Desde el reinicio del $date';
  }

  @override
  String get settingsTitle => 'AJUSTES';

  @override
  String get resetCurrentTitle => 'Reiniciar sesión actual';

  @override
  String get resetCurrentSubtitle => 'Borra los toques activos sin guardarlos';

  @override
  String get resetCurrentDialogTitle => '¿Reiniciar la sesión actual?';

  @override
  String get resetCurrentDialogBody =>
      'Se borrarán los toques en curso sin guardarlos.';

  @override
  String get currentSessionReset => 'Sesión actual reiniciada.';

  @override
  String get resetLifetimeTitle => 'Reiniciar totales históricos';

  @override
  String get resetLifetimeSubtitle =>
      'Pone a 0 de forma permanente los toques y sesiones totales';

  @override
  String get finishSessionFirst =>
      'Primero termina o reinicia la sesión actual.';

  @override
  String get permanentReset => 'REINICIO PERMANENTE';

  @override
  String permanentResetBody(String keyword) {
    return 'Esta acción borra de forma permanente tus totales históricos. El historial de sesiones se conserva, pero los totales vuelven a 0.\n\nEscribe \"$keyword\" para confirmar.';
  }

  @override
  String get resetKeyword => 'BORRAR';

  @override
  String get confirmReset => 'CONFIRMAR REINICIO';

  @override
  String get lifetimeResetDone => 'Totales históricos reiniciados.';

  @override
  String get couldNotResetLifetime =>
      'No se pudieron reiniciar los totales. Inténtalo de nuevo.';

  @override
  String get keepScreenOnTitle =>
      'Mantener la pantalla encendida en una sesión';

  @override
  String get keepScreenOnSubtitle =>
      'Gasta algo más de batería mientras cuentas';

  @override
  String get couldNotSaveSetting => 'No se pudo guardar este ajuste.';

  @override
  String get exportTitle => 'Exportar datos';

  @override
  String get exportSubtitle => 'Guarda una copia de tu historial y totales';

  @override
  String exportDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copia de $count sesiones copiada al portapapeles.',
      one: 'Copia de 1 sesión copiada al portapapeles.',
    );
    return '$_temp0';
  }

  @override
  String get importTitle => 'Importar datos';

  @override
  String get importSubtitle => 'Sustituye todos los datos por una copia';

  @override
  String get importDialogTitle => 'Importar copia';

  @override
  String get importDialogBody => 'Pega una copia de Sushi Tracker.';

  @override
  String get importPaste => 'Pegar';

  @override
  String get importConfirm => 'Sustituir datos';

  @override
  String get importInvalid => 'No es una copia válida de Sushi Tracker.';

  @override
  String importDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Se importaron $count sesiones.',
      one: 'Se importó 1 sesión.',
    );
    return '$_temp0';
  }

  @override
  String get importFailed => 'No se pudo importar la copia.';

  @override
  String get privacyTitle => 'Política de privacidad';

  @override
  String get privacyBody =>
      'Sushi Tracker no recopila, transmite ni comparte datos personales. No tiene cuentas, analíticas, anuncios ni servicios de red.\n\nTus recuentos, historial y totales se guardan en este dispositivo. Si la copia de seguridad de Android está activada en tu cuenta de Google, Android puede incluir estos datos en esa copia y restaurarlos al reinstalar la app o configurar un dispositivo nuevo. Esa copia la gestiona Google en tu cuenta; el desarrollador nunca la recibe.\n\nBorrar los datos de la app los elimina de este dispositivo. Puedes exportar tu propia copia desde Ajustes.\n\nLa app no pide permisos especiales del dispositivo.\n\nPara cualquier duda, escribe a labradorsantoseduardo@gmail.com.';

  @override
  String get sessionAlreadySaved =>
      'Esta sesión ya se había guardado en el historial.';

  @override
  String exportSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copia de $count sesiones guardada.',
      one: 'Copia de 1 sesión guardada.',
    );
    return '$_temp0';
  }

  @override
  String get couldNotSaveFile => 'No se pudo guardar el archivo.';

  @override
  String get couldNotReadFile => 'No se pudo leer el archivo.';

  @override
  String get importNext => 'Continuar';

  @override
  String get importConfirmTitle => '¿Sustituir todos los datos?';

  @override
  String importConfirmBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Tu historial y totales actuales se sustituirán por la copia, que tiene $count sesiones.',
      one:
          'Tu historial y totales actuales se sustituirán por la copia, que tiene 1 sesión.',
    );
    return '$_temp0';
  }

  @override
  String get setPrice => 'Añadir precio';

  @override
  String get editPrice => 'Editar precio';

  @override
  String get priceDialogTitle => '¿Cuánto costó esta comida?';

  @override
  String get priceHint => 'p. ej. 24,90';

  @override
  String get priceInvalid => 'Introduce un importe entre 0 y 100.000.';

  @override
  String get save => 'Guardar';

  @override
  String get removePrice => 'Quitar precio';

  @override
  String get couldNotSavePrice => 'No se pudo guardar el precio.';

  @override
  String costPerPiece(String range) {
    return 'Coste por pieza ($range)';
  }

  @override
  String get recordsTitle => 'Récords';

  @override
  String get bestEver => 'Mejor sesión';

  @override
  String get weeklyStreak => 'Racha semanal';

  @override
  String weeksCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count semanas',
      one: '1 semana',
      zero: 'Sin racha',
    );
    return '$_temp0';
  }

  @override
  String get sessionsThisMonth => 'Sesiones este mes';

  @override
  String get piecesThisMonth => 'Piezas este mes';

  @override
  String recordToBeat(int best, int remaining) {
    return 'Récord $best · te faltan $remaining';
  }

  @override
  String recordTied(int best) {
    return '¡Has igualado tu récord de $best!';
  }

  @override
  String newRecord(int best) {
    return '¡Nuevo récord! El anterior era $best';
  }

  @override
  String get emptyHistoryHint => 'Termina una sesión y aparecerá aquí.';

  @override
  String monthSummary(int sessions, int pieces) {
    String _temp0 = intl.Intl.pluralLogic(
      sessions,
      locale: localeName,
      other: '$sessions sesiones',
      one: '1 sesión',
    );
    String _temp1 = intl.Intl.pluralLogic(
      pieces,
      locale: localeName,
      other: '$pieces piezas',
      one: '1 pieza',
    );
    return '$_temp0 · $_temp1';
  }

  @override
  String get recordBadge => 'Récord';

  @override
  String get summaryTitle => 'Resumen';

  @override
  String averageLine(String value) {
    return 'Media $value';
  }

  @override
  String get weeklyTitle => 'Piezas por semana';

  @override
  String weeklySemantics(int weeks) {
    return 'Gráfico de barras con las piezas de cada una de las últimas $weeks semanas.';
  }

  @override
  String piecesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count piezas',
      one: '1 pieza',
    );
    return '$_temp0';
  }

  @override
  String piecesUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'piezas',
      one: 'pieza',
    );
    return '$_temp0';
  }

  @override
  String get settingsSectionSession => 'Sesión';

  @override
  String get settingsSectionPreferences => 'Preferencias';

  @override
  String get settingsSectionData => 'Tus datos';

  @override
  String get settingsSectionAbout => 'Información';

  @override
  String get settingsTagline => 'Tu sushi, contado en este dispositivo.';

  @override
  String get loadingData => 'Preparando tu sushi…';

  @override
  String timeRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get detailPieces => 'Piezas';

  @override
  String get detailDuration => 'Duración';

  @override
  String get detailPace => 'Ritmo';

  @override
  String get detailPrice => 'Precio';

  @override
  String paceValue(String pace) {
    return '$pace/min';
  }

  @override
  String get noValue => '—';

  @override
  String get addRestaurant => 'Añadir restaurante';

  @override
  String get editRestaurant => 'Cambiar restaurante';

  @override
  String get restaurantDialogTitle => '¿Dónde comiste?';

  @override
  String get restaurantHint => 'p. ej. Sushi Zen';

  @override
  String get removeRestaurant => 'Quitar';

  @override
  String get couldNotSaveRestaurant => 'No se pudo guardar el restaurante.';

  @override
  String get byRestaurantTitle => 'Por restaurante';

  @override
  String restaurantSummary(int sessions, String average) {
    String _temp0 = intl.Intl.pluralLogic(
      sessions,
      locale: localeName,
      other: '$sessions sesiones',
      one: '1 sesión',
    );
    return '$_temp0 · media $average';
  }

  @override
  String perPiece(String value) {
    return '$value/pieza';
  }
}
