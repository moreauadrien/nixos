pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string time: {
        clock.date.toLocaleString(Language.locale, "dddd HH:mm");
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
}
