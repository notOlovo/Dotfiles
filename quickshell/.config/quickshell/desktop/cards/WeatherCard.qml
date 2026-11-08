import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

Card {
    id: card
    title: Weather.city
    iconCode: 0xF034E   // map-marker

    readonly property var cur: Weather.current
    readonly property var loc: I18n.locale       // dates in the interface language

    Txt {
        visible: !Weather.ready
        text: Weather.failed ? I18n.t("no connection to the weather station…", "нет связи с метеостанцией…") : I18n.t("fetching the forecast…", "запрашиваю прогноз…")
        color: Theme.muted
    }

    // ---- Now ----
    RowLayout {
        visible: Weather.ready
        spacing: 16
        Txt {
            text: Weather.icon(card.cur.weather_code, card.cur.is_day)
            color: Theme.cyan
            font.pixelSize: 54
        }
        ColumnLayout {
            spacing: 0
            Txt {
                text: Math.round(card.cur.temperature_2m) + "°"
                color: Theme.bright
                font.pixelSize: 42
                font.weight: Font.Light
            }
            Txt {
                text: Weather.describe(card.cur.weather_code)
                      + I18n.t("  ·  feels like ", "  ·  ощущается ") + Math.round(card.cur.apparent_temperature) + "°"
                color: Theme.subtle
                font.pixelSize: 12
            }
        }
    }

    // ---- Details ----
    GridLayout {
        visible: Weather.ready
        columns: 2
        columnSpacing: 20
        rowSpacing: 6
        Layout.fillWidth: true

        Stat { iconCode: 0xF059D; label: I18n.t("wind", "ветер")
               value: Math.round(card.cur.wind_speed_10m) + I18n.t(" m/s ", " м/с ") + Weather.windDir(card.cur.wind_direction_10m)
                      + " (" + Math.round(card.cur.wind_gusts_10m) + ")" }
        Stat { iconCode: 0xF058E; label: I18n.t("humidity", "влажность"); value: card.cur.relative_humidity_2m + "%" }
        Stat { iconCode: 0xF029A; label: I18n.t("pressure", "давление")
               value: I18n.ru ? Math.round(card.cur.surface_pressure * 0.750062) + " мм" : Math.round(card.cur.surface_pressure) + " hPa" }
        Stat { iconCode: 0xF0599; label: "UV"; value: Weather.uv.toFixed(1)
               valueColor: Weather.uv >= 6 ? Theme.rose : Weather.uv >= 3 ? Theme.violet : Theme.text }
        Stat { iconCode: 0xF054A; label: I18n.t("precip.", "осадки")
               value: (Weather.daily[0]?.pop ?? 0) + "%" }
        Stat { iconCode: 0xF059C; label: I18n.t("sun", "солнце"); value: Weather.sunrise + "–" + Weather.sunset }
    }

    // ---- Hourly chart ----
    Canvas {
        id: chart
        visible: Weather.ready
        Layout.fillWidth: true
        Layout.preferredHeight: 74

        property var hours: Weather.hourly
        onHoursChanged: requestPaint()
        onWidthChanged: requestPaint()

        // Repaint when the palette or the language changes
        Connections {
            target: Theme
            function onCChanged() { chart.requestPaint(); }
        }
        Connections {
            target: I18n
            function onLangChanged() { chart.requestPaint(); }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const h = hours;
            if (!h || h.length < 2) return;

            const temps = h.map(p => p.temp);
            const lo = Math.min(...temps), hi = Math.max(...temps);
            const span = Math.max(1, hi - lo);
            const top = 16, bottom = height - 18;
            const pad = 20;   // room for labels at the edges
            const step = (width - pad * 2) / (h.length - 1);
            const x = i => pad + i * step;
            const y = t => bottom - (t - lo) / span * (bottom - top);

            // Precipitation probability — bars at the bottom
            for (let i = 0; i < h.length; i++) {
                if (!h[i].pop) continue;
                const ph = h[i].pop / 100 * 18;
                ctx.fillStyle = Qt.rgba(Theme.cyan.r, Theme.cyan.g, Theme.cyan.b, 0.18);
                ctx.fillRect(x(i) - 3, bottom - ph, 6, ph);
            }

            ctx.beginPath();
            ctx.moveTo(x(0), y(temps[0]));
            for (let i = 1; i < h.length; i++) ctx.lineTo(x(i), y(temps[i]));
            ctx.lineWidth = 1.5;
            ctx.strokeStyle = Theme.blue;
            ctx.stroke();

            ctx.font = "10px '" + Theme.font + "'";
            ctx.textAlign = "center";
            for (let i = 0; i < h.length; i += 3) {
                ctx.fillStyle = Theme.blue;
                ctx.beginPath();
                ctx.arc(x(i), y(temps[i]), 2.5, 0, Math.PI * 2);
                ctx.fill();
                const tx = x(i);
                ctx.fillStyle = Theme.text;
                ctx.fillText(Math.round(temps[i]) + "°", tx, y(temps[i]) - 6);
                ctx.fillStyle = Theme.muted;
                ctx.fillText(i === 0 ? I18n.t("now", "сейчас") : h[i].hour + ":00", tx, height - 2);
            }
        }
    }

    // ---- 5 days ----
    Row {
        id: days
        visible: Weather.ready
        Layout.fillWidth: true

        Repeater {
            model: Weather.daily.slice(1, 6)
            Column {
                required property var modelData
                width: days.width / 5
                spacing: 2
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: card.loc.dayName(new Date(parent.modelData.date + "T12:00").getDay(), Locale.ShortFormat)
                    color: Theme.subtle
                    font.pixelSize: 11
                }
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Weather.icon(parent.modelData.code, true)
                    color: Theme.text
                    font.pixelSize: 20
                }
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Math.round(parent.modelData.max) + "°"
                    color: Theme.bright
                    font.pixelSize: 12
                }
                Txt {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Math.round(parent.modelData.min) + "°"
                    color: Theme.muted
                    font.pixelSize: 11
                }
            }
        }
    }
}
