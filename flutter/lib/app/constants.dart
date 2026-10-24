import 'package:dermascan/core/models/classification_model.dart';

const String anonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFzb2pmcHptbG96c25ldGN3ZWprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAzNDUyMjUsImV4cCI6MjEwNTkyMTIyNX0.p4SZqX5w85c3TcoZGcU9NSZWpCQ4Wu9epZIJVwamtX4';
const String supabaseURL = 'https://qsojfpzmlozsnetcwejk.supabase.co';

final ClassificationModel rgbModel = ClassificationModel(
  0.1,
  'assets/models/eff_bce_strong_reg.onnx',
);
