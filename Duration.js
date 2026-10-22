.pragma library

const FOREVER = -1;

const CLOCK = /^([01]?\d|2[0-3]):([0-5]\d)$/;
const SPAN = /^(?:(\d+)\s*h)?\s*(?:(\d+)\s*(?:m|$))?\s*(?:(\d+)\s*s)?$/;

function resolve(text, nowMs) {
    const s = String(text ?? "").trim().toLowerCase();
    if (["∞", "inf", "infinity", "forever"].includes(s))
        return FOREVER;
    const c = CLOCK.exec(s);
    if (c) {
        const t = new Date(nowMs);
        t.setHours(Number(c[1]), Number(c[2]), 0, 0);
        if (t.getTime() <= nowMs)
            t.setDate(t.getDate() + 1);
        return t.getTime();
    }
    const d = SPAN.exec(s);
    const seconds = d ? Number(d[1] ?? 0) * 3600 + Number(d[2] ?? 0) * 60 + Number(d[3] ?? 0) : 0;
    return seconds > 0 ? nowMs + seconds * 1000 : 0;
}

function parseList(text) {
    return String(text ?? "").split(",").map(p => p.trim()).filter(p => resolve(p, Date.now()) !== 0);
}

function isClock(text) {
    return CLOCK.test(String(text).trim());
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
