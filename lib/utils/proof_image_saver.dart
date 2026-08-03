export 'proof_image_saver_stub.dart'
    if (dart.library.html) 'proof_image_saver_web.dart'
    if (dart.library.io) 'proof_image_saver_io.dart';