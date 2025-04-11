import 'dart:async';

extension DebounceStreamExtension<T> on Stream<T> {
  Stream<T> debounceTime(Duration duration) {
    Timer? timer;
    return transform(StreamTransformer<T, T>.fromHandlers(
      handleData: (T data, EventSink<T> sink) {
        timer?.cancel();
        timer = Timer(duration, () => sink.add(data));
      },
    ));
  }
} 