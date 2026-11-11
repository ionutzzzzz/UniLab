import 'sim_definition.dart';

/// Ring buffer preserving historical simulation states for real-time bidirectional time-travel scrubbing.
class SimulationStateBuffer {
  final int maxCapacity;
  final List<SimSnapshot> _snapshots = [];
  int _scrubIndex = -1;
  bool _isScrubbing = false;
  double _speedMultiplier = 1.0;

  SimulationStateBuffer({this.maxCapacity = 7200});

  List<SimSnapshot> get snapshots => List.unmodifiable(_snapshots);
  int get count => _snapshots.length;
  bool get isEmpty => _snapshots.isEmpty;
  bool get isScrubbing => _isScrubbing;
  double get speedMultiplier => _speedMultiplier;

  set speedMultiplier(double val) {
    if (val > 0) {
      _speedMultiplier = val;
    }
  }

  double get minTime => _snapshots.isNotEmpty ? _snapshots.first.time : 0.0;
  double get maxTime => _snapshots.isNotEmpty ? _snapshots.last.time : 0.0;
  double get currentTime {
    if (_snapshots.isEmpty) return 0.0;
    if (_isScrubbing && _scrubIndex >= 0 && _scrubIndex < _snapshots.length) {
      return _snapshots[_scrubIndex].time;
    }
    return _snapshots.last.time;
  }

  /// Appends a new frame snapshot. If over capacity, drops oldest frame.
  void addSnapshot(SimSnapshot snapshot) {
    if (_isScrubbing) {
      // If we resumed running while scrubbed back in time, branch off from current scrub point
      if (_scrubIndex >= 0 && _scrubIndex < _snapshots.length - 1) {
        _snapshots.removeRange(_scrubIndex + 1, _snapshots.length);
      }
      _isScrubbing = false;
    }

    _snapshots.add(snapshot);
    if (_snapshots.length > maxCapacity) {
      _snapshots.removeAt(0);
    }
    _scrubIndex = _snapshots.length - 1;
  }

  /// Restores state at a specific past timestamp [targetTime].
  SimSnapshot? seekToTime(double targetTime) {
    if (_snapshots.isEmpty) return null;
    _isScrubbing = true;

    // Binary search for closest snapshot to targetTime
    int low = 0;
    int high = _snapshots.length - 1;
    int bestIndex = high;
    double bestDiff = double.infinity;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final diff = (_snapshots[mid].time - targetTime).abs();

      if (diff < bestDiff) {
        bestDiff = diff;
        bestIndex = mid;
      }

      if (_snapshots[mid].time < targetTime) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    _scrubIndex = bestIndex;
    return _snapshots[_scrubIndex];
  }

  /// Step one frame backward in time.
  SimSnapshot? stepBackward() {
    if (_snapshots.isEmpty) return null;
    _isScrubbing = true;
    if (_scrubIndex > 0) {
      _scrubIndex--;
    }
    return _snapshots[_scrubIndex];
  }

  /// Step one frame forward in time.
  SimSnapshot? stepForward() {
    if (_snapshots.isEmpty) return null;
    if (_scrubIndex < _snapshots.length - 1) {
      _scrubIndex++;
      return _snapshots[_scrubIndex];
    } else {
      _isScrubbing = false;
      return _snapshots.last;
    }
  }

  /// Resume playback from the currently scrubbed frame.
  void resumeFromScrub() {
    _isScrubbing = false;
  }

  /// Clear buffer on model reset.
  void clear() {
    _snapshots.clear();
    _scrubIndex = -1;
    _isScrubbing = false;
  }
}
