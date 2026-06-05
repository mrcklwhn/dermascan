import 'package:dermascan/core/models/classification_model.dart';

const String anonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFrdmx4aWRvb21maXVoZWx3bmptIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM4ODcxMDIsImV4cCI6MjA3OTQ2MzEwMn0.3cI3vFPeuTNboc_fy3w5qlE8udh9VNyQrAEjGRi5RcM';
const String edgeFunctionsURL =
    'https://qkvlxidoomfiuhelwnjm.supabase.co/functions/v1';
const String supabaseURL = 'https://qkvlxidoomfiuhelwnjm.supabase.co';

final ClassificationModel rgbModel = ClassificationModel(
  0.5,
  'assets/models/rgb_efficientnet_v2_s_a_1node.onnx',
);
