import QtQuick

// Cascading reveal of list rows: ListView { populate: PopulateFx {} }
Transition {
    id: fx

    SequentialAnimation {
        PropertyAction { property: "opacity"; value: 0 }
        PauseAnimation { duration: Math.min(fx.ViewTransition.index, 10) * 16 }
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
            NumberAnimation { property: "x"; from: 10; duration: 320; easing.type: Easing.OutQuint }
        }
    }
}
