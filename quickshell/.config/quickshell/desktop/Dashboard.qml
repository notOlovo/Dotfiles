import QtQuick
import qs.cards

// Widget layout. Used both on the wallpaper and in the overlay (Win+D).
// Drawn in "design" coordinates and scaled down as a whole on small screens
// (e.g. the 1133×744 iPad virtual monitor), so cards don't overlap.
Item {
    id: root

    readonly property int marginTop: 64      // below Waybar
    readonly property int marginSide: 48
    readonly property int marginBottom: 40
    readonly property int cardWidth: 380     // all cards share one width
    readonly property int gap: 18

    // The bottom row (calendar, player) fits between the columns: 3 cards + 2 gaps + margins
    readonly property int minWidth: cardWidth * 3 + gap * 2 + marginSide * 2

    // Shared bottom line: the bottom of the right column, but the calendar never climbs onto the clock
    // (weather without a connection is shorter — it used to pull the whole bottom row up)
    readonly property real bottomLine: Math.max(rightColumn.y + rightColumn.height,
                                                clock.y + clock.height + gap + calendar.height)

    readonly property real fit: Math.min(1, width / minWidth, height / (bottomLine + marginBottom))

    Item {
        id: canvas
        width: root.width / root.fit
        height: root.height / root.fit
        scale: root.fit
        transformOrigin: Item.TopLeft

        // ---- Top left: clock and ArchWiki ----
        ClockCard {
            id: clock
            revealDelay: 0
            x: root.marginSide
            y: root.marginTop
        }

        // ---- Bottom left: calendar ----
        CalendarCard {
            id: calendar
            revealDelay: 140
            width: root.cardWidth
            x: root.marginSide
            y: root.bottomLine - height
        }

        // ---- Bottom center: player ----
        PlayerCard {
            revealDelay: 220
            width: root.cardWidth
            x: (canvas.width - width) / 2
            y: root.bottomLine - height
        }

        // ---- Right: weather and system ----
        Column {
            id: rightColumn
            x: canvas.width - width - root.marginSide
            y: root.marginTop
            spacing: root.gap

            WeatherCard   { width: root.cardWidth; revealDelay: 70 }
            ResourcesCard { width: root.cardWidth; revealDelay: 170 }
        }
    }
}
