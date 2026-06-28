# dashboardscreen.dart — manual patch (line ~461)

## The error
```
'${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}'
```
`latitude` and `longitude` are `double?` (nullable), so `.toStringAsFixed()` can't
be called directly.

## Fix — replace that line with:
```dart
report.locationString,
```

`locationString` is a getter on `ReportModel` (already included in the new
`report_model.dart`) that safely handles nulls:
```dart
String get locationString {
  if (latitude != null && longitude != null) {
    return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
  }
  return address ?? 'Location not set';
}
```

## Alternative inline fix (if you prefer not to use the getter):
```dart
'${report.latitude?.toStringAsFixed(4) ?? 'N/A'}, ${report.longitude?.toStringAsFixed(4) ?? 'N/A'}',
```
