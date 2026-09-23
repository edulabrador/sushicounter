String formatSessionDuration(Duration duration) {
  final safeDuration = duration.isNegative ? Duration.zero : duration;
  final hours = safeDuration.inHours;
  final minutes = hours > 0
      ? safeDuration.inMinutes.remainder(60)
      : safeDuration.inMinutes;
  final seconds = safeDuration.inSeconds.remainder(60);
  final formattedMinutes = minutes.toString().padLeft(2, '0');
  final formattedSeconds = seconds.toString().padLeft(2, '0');

  return hours > 0
      ? '$hours:$formattedMinutes:$formattedSeconds'
      : '$formattedMinutes:$formattedSeconds';
}

Duration elapsedSince(DateTime startedAt, {DateTime? now}) {
  final elapsed = (now ?? DateTime.now()).difference(startedAt);
  return elapsed.isNegative ? Duration.zero : elapsed;
}
