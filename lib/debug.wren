// Debug begin.
class LDebug {
	construct new() {
	}

	lastLine { _lastLine }
	lastColumn { _lastColumn }
	setLastLocation(ln, col) {
		_lastLine = ln
		_lastColumn = col
	}
}
var ldebug = LDebug.new()
// Debug end.
