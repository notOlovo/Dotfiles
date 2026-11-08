import QtQuick
import qs.services

// A line with a gradient fill: load history etc.
Canvas {
    id: spark

    property var values: []
    property real maxValue: 1
    property int capacity: 40
    property color color: Theme.blue

    implicitHeight: 42
    onValuesChanged: requestPaint()
    onColorChanged: requestPaint()
    Connections { target: Theme; function onCChanged() { spark.requestPaint(); } }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        if (values.length < 2) return;

        const step = width / (capacity - 1);
        const x0 = width - (values.length - 1) * step;
        const y = v => height - 2 - Math.min(1, v / maxValue) * (height - 4);

        ctx.beginPath();
        ctx.moveTo(x0, y(values[0]));
        for (let i = 1; i < values.length; i++)
            ctx.lineTo(x0 + i * step, y(values[i]));

        ctx.lineWidth = 1.5;
        ctx.strokeStyle = color;
        ctx.stroke();

        ctx.lineTo(width, height);
        ctx.lineTo(x0, height);
        ctx.closePath();
        const g = ctx.createLinearGradient(0, 0, 0, height);
        g.addColorStop(0, Qt.rgba(color.r, color.g, color.b, 0.35));
        g.addColorStop(1, Qt.rgba(color.r, color.g, color.b, 0));
        ctx.fillStyle = g;
        ctx.fill();
    }
}
