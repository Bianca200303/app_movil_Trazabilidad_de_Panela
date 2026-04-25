class ProductionDateGroup {
  final DateTime date;
  final int batchCount;
  final double totalPanelaKg;
  final bool alreadyRecorded;

  const ProductionDateGroup({
    required this.date,
    required this.batchCount,
    required this.totalPanelaKg,
    required this.alreadyRecorded,
  });
}
