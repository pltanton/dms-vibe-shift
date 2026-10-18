.pragma library

const FOREVER = -1;

function clockTarget(s, nowMs) {
    const m = /^(\d{1,2}):(\d{2})$/.exec(s);
    if (!m)
        return 0;
    const h = parseInt(m[1], 10), min = parseInt(m[2], 10);
    if (h > 23 || min > 59)
        return 0;
    const now = new Date(nowMs);
    const t = new Date(now.getFullYear(), now.getMonth(), now.getDate(), h, min, 0, 0);
    if (t.getTime() <= nowMs)
        t.setDate(t.getDate() + 1);
    return t.getTime();
}

// Returns the absolute end time in ms, FOREVER, or 0 for unparseable input.
function resolve(text, nowMs) {
    const s = String(text ?? "").trim().toLowerCase();
    if (s === "∞" || s === "inf" || s === "infinity" || s === "forever")
        return FOREVER;
    const clock = clockTarget(s, nowMs);
    if (clock)
        return clock;
    if (/^\d+$/.test(s))
        return parseInt(s, 10) > 0 ? nowMs + parseInt(s, 10) * 60000 : 0;
    const re = /(\d+)\s*([hms])/g;
    let total = 0, consumed = "", m;
    while ((m = re.exec(s)) !== null) {
        total += parseInt(m[1], 10) * ({ h: 3600, m: 60, s: 1 })[m[2]];
        consumed += m[0];
    }
    if (total <= 0 || consumed.replace(/\s/g, "") !== s.replace(/\s/g, ""))
        return 0;
    return nowMs + total * 1000;
}

function parseList(text) {
    return String(text ?? "").split(",").map(p => p.trim()).filter(p => resolve(p, Date.now()) !== 0);
}

function isClock(text) {
    return /^\d{1,2}:\d{2}$/.test(String(text).trim());
}

function presetLabel(text) {
    const s = String(text).trim();
    if (resolve(s, Date.now()) === FOREVER)
        return "∞";
    if (isClock(s))
        return s.padStart(5, "0");
    if (/^\d+$/.test(s))
        return s + "m";
    return s.replace(/\s+/g, " ");
}

function remaining(until, nowMs) {
    if (until === FOREVER)
        return FOREVER;
    return Math.max(0, Math.ceil((until - nowMs) / 1000));
}

function label(seconds) {
    if (seconds === FOREVER)
        return "∞";
    const h = Math.floor(seconds / 3600);
    const m = Math.ceil((seconds % 3600) / 60);
    if (m === 60)
        return `${h + 1} h`;
    if (h > 0)
        return m > 0 ? `${h} h ${m} min` : `${h} h`;
    return `${Math.max(m, 1)} min`;
}

function short(until, nowMs) {
    const r = remaining(until, nowMs);
    if (r === FOREVER)
        return "∞";
    const totalMin = Math.ceil(r / 60);
    const h = Math.floor(totalMin / 60);
    const m = totalMin % 60;
    return h === 0 ? `${m}m` : `${h}:${String(m).padStart(2, "0")}`;
}

function clock(ms, use24h) {
    const d = new Date(ms);
    if (use24h)
        return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
    const h = d.getHours() % 12 || 12;
    return `${h}:${String(d.getMinutes()).padStart(2, "0")} ${d.getHours() < 12 ? "AM" : "PM"}`;
}
