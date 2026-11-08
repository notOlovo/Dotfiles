import QtQuick
import QtQuick.Shapes
import QtQuick.Effects
import qs.services

// A neon progress ring
Item {
    id: ring

    property real value: 0            // 0..1
    property string label: ""
    property string valueText: Math.round(value * 100) + "%"
    property color color: value > 0.9 ? Theme.rose : value > 0.7 ? Theme.violet : Theme.blue
    property real thickness: 5

    property real shown: value
    Behavior on shown { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

    implicitWidth: 84
    implicitHeight: 84

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: Theme.overlay
            strokeWidth: ring.thickness
            fillColor: "transparent"
            PathAngleArc {
                centerX: ring.width / 2; centerY: ring.height / 2
                radiusX: ring.width / 2 - ring.thickness; radiusY: ring.height / 2 - ring.thickness
                startAngle: 0; sweepAngle: 360
            }
        }
    }

    Shape {
        id: arc
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: ring.color
            shadowBlur: 0.6
            shadowOpacity: 0.7
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 0
        }
        ShapePath {
            strokeColor: ring.color
            strokeWidth: ring.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: ring.width / 2; centerY: ring.height / 2
                radiusX: ring.width / 2 - ring.thickness; radiusY: ring.height / 2 - ring.thickness
                startAngle: -90; sweepAngle: 360 * Math.max(0.001, ring.shown)
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 0
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ring.valueText
            color: Theme.bright
            font.pixelSize: 16
            font.weight: Font.DemiBold
        }
        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ring.label
            color: Theme.subtle
            font.pixelSize: 10
            font.letterSpacing: 1
        }
    }
}
