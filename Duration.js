.pragma library

const FOREVER = -1;

function parse(text) {
    const s = String(text ?? "").trim().toLowerCase();
    if (s === "∞" || s === "inf" || s === "infinity" || s === "forever")
        return FOREVER;
    if (/^\d+$/.test(s))
        return parseInt(s, 10) * 60;
    const re = /(\d+)\s*([hms])/g;
    let total = 0, consumed = "", m;
    while ((m = re.exec(s)) !== null) {
        total += parseInt(m[1], 10) * ({ h: 3600, m: 60, s: 1 })[m[2]];
        consumed += m[0];
    }
    if (total <= 0 || consumed.replace(/\s/g, "") !== s.replace(/\s/g, ""))
        return 0;
    return total;
}

function parseList(text) {
    return String(text ?? "").split(",").map(p => p.trim()).filter(p => parse(p) !== 0);
}

function label(seconds) {
    if (seconds === FOREVER)
        return "∞";
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    if (h > 0)
        return m > 0 ? `${h}h ${m}m` : `${h}h`;
    return m > 0 ? `${m}m` : `${seconds}s`;
}

function remaining(until, now) {
    if (until === FOREVER)
        return FOREVER;
    return Math.max(0, Math.ceil((until - now) / 1000));
}

function short(until, now) {
    const r = remaining(until, now);
    if (r === FOREVER)
        return "∞";
    const h = Math.floor(r / 3600);
    const m = Math.ceil((r % 3600) / 60);
    if (h === 0)
        return `${Math.max(m, 1)}m`;
    return `${h}:${String(Math.min(m, 59)).padStart(2, "0")}`;
}
