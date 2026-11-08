pragma Singleton
import QtQuick
import Quickshell

// Weather from Open-Meteo: free, no API key. Refreshed every 30 minutes.
Singleton {
    id: root

    readonly property string city: I18n.t("Prague", "Прага")
    readonly property real lat: 50.0755
    readonly property real lon: 14.4378
    readonly property string tz: "Europe/Prague"

    property bool ready: false
    property bool failed: false
    property var current: ({})
    property var hourly: []          // [{ hour, temp, pop, code }] for the next 12 hours
    property var daily: []           // [{ date, code, max, min, pop }]
    property string sunrise: ""
    property string sunset: ""
    property real uv: 0
    property date updated

    readonly property string url: "https://api.open-meteo.com/v1/forecast"
        + "?latitude=" + lat + "&longitude=" + lon + "&timezone=" + tz
        + "&wind_speed_unit=ms&forecast_days=6"
        + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,"
        + "wind_speed_10m,wind_direction_10m,wind_gusts_10m,surface_pressure,is_day,precipitation"
        + "&hourly=temperature_2m,precipitation_probability,weather_code,is_day"
        + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,"
        + "uv_index_max,precipitation_probability_max"

    function fetch() {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status === 200) {
                try { parse(JSON.parse(xhr.responseText)); root.failed = false; }
                catch (e) { root.failed = true; retry.restart(); }
            } else {
                root.failed = true;
                retry.restart();
            }
        };
        xhr.send();
    }

    function parse(j) {
        root.current = j.current;
        const h = j.hourly;
        const start = Math.max(0, h.time.findIndex(t => t.slice(0, 13) === j.current.time.slice(0, 13)));
        const hours = [];
        for (let i = start; i < Math.min(start + 13, h.time.length); i++)
            hours.push({ hour: h.time[i].slice(11, 13), temp: h.temperature_2m[i],
                         pop: h.precipitation_probability[i], code: h.weather_code[i], day: h.is_day[i] });
        root.hourly = hours;

        const d = j.daily;
        root.daily = d.time.map((t, i) => ({ date: t, code: d.weather_code[i], max: d.temperature_2m_max[i],
                                             min: d.temperature_2m_min[i], pop: d.precipitation_probability_max[i] }));
        root.sunrise = d.sunrise[0].slice(11, 16);
        root.sunset = d.sunset[0].slice(11, 16);
        root.uv = d.uv_index_max[0];
        root.updated = new Date();
        root.ready = true;
    }

    // WMO codes → description
    function describe(code) {
        if (code === 0) return I18n.t("clear", "ясно");
        if (code === 1) return I18n.t("mostly clear", "почти ясно");
        if (code === 2) return I18n.t("partly cloudy", "переменная облачность");
        if (code === 3) return I18n.t("overcast", "пасмурно");
        if (code === 45 || code === 48) return I18n.t("fog", "туман");
        if (code >= 51 && code <= 55) return I18n.t("drizzle", "морось");
        if (code === 56 || code === 57) return I18n.t("freezing drizzle", "ледяная морось");
        if (code === 61) return I18n.t("light rain", "небольшой дождь");
        if (code === 63) return I18n.t("rain", "дождь");
        if (code === 65) return I18n.t("heavy rain", "сильный дождь");
        if (code === 66 || code === 67) return I18n.t("freezing rain", "ледяной дождь");
        if (code === 71) return I18n.t("light snow", "небольшой снег");
        if (code === 73) return I18n.t("snow", "снег");
        if (code === 75) return I18n.t("heavy snow", "сильный снег");
        if (code === 77) return I18n.t("snow grains", "снежная крупа");
        if (code >= 80 && code <= 82) return I18n.t("showers", "ливень");
        if (code === 85 || code === 86) return I18n.t("snow showers", "снегопад");
        if (code === 95) return I18n.t("thunderstorm", "гроза");
        if (code === 96 || code === 99) return I18n.t("thunderstorm with hail", "гроза с градом");
        return "—";
    }

    // WMO codes → Nerd Font icon (md-weather-*)
    function icon(code, isDay) {
        let cp;
        if (code === 0 || code === 1)      cp = isDay ? 0xF0599 : 0xF0594;
        else if (code === 2)               cp = isDay ? 0xF0595 : 0xF0F31;
        else if (code === 3)               cp = 0xF0590;
        else if (code === 45 || code === 48) cp = 0xF0591;
        else if (code >= 51 && code <= 63) cp = 0xF0597;
        else if (code === 65 || (code >= 80 && code <= 82)) cp = 0xF0596;
        else if (code === 66 || code === 67 || code === 56 || code === 57) cp = 0xF067F;
        else if (code >= 71 && code <= 86) cp = 0xF0598;
        else if (code === 95)              cp = 0xF0593;
        else if (code >= 96)               cp = 0xF067E;
        else                               cp = 0xF0590;
        return String.fromCodePoint(cp);
    }

    function windDir(deg) {
        return (I18n.ru ? ["С", "СВ", "В", "ЮВ", "Ю", "ЮЗ", "З", "СЗ"] : ["N", "NE", "E", "SE", "S", "SW", "W", "NW"])[Math.round(deg / 45) % 8];
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetch()
    }

    Timer { id: retry; interval: 30 * 1000;   onTriggered: root.fetch() }
}
