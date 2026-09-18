.pragma library

const CONSTS = {
    pi: Math.PI, tau: 2 * Math.PI, e: Math.E, phi: (1 + Math.sqrt(5)) / 2
};
const CONST_GLYPH = { pi: "π", tau: "τ", e: "e", phi: "φ" };
const CONST_TEX = { pi: "\\pi", tau: "\\tau", e: "e", phi: "\\varphi" };

const FNS = {
    sqrt: 1, cbrt: 1, root: 2, abs: 1, floor: 1, ceil: 1, round: 1,
    sin: 1, cos: 1, tan: 1, asin: 1, acos: 1, atan: 1,
    sinh: 1, cosh: 1, tanh: 1,
    ln: 1, log: 1, lg: 1, log2: 1, exp: 1, min: -1, max: -1
};
const ALIASES = {
    arcsin: "asin", arccos: "acos", arctan: "atan", log10: "log", sqr: "sqrt"
};

const FN_GLYPH = { asin: "arcsin", acos: "arccos", atan: "arctan" };
const FN_TEX = {
    sin: "\\sin", cos: "\\cos", tan: "\\tan", asin: "\\arcsin", acos: "\\arccos",
    atan: "\\arctan", sinh: "\\sinh", cosh: "\\cosh", tanh: "\\tanh", ln: "\\ln",
    exp: "\\exp", min: "\\min", max: "\\max", lg: "\\lg"
};

const COMMANDS = {
    cdot: ["op", "*"], times: ["op", "x"], div: ["op", "div"], bmod: ["op", "mod"],
    mod: ["op", "mod"], frac: ["frac"], dfrac: ["frac"], tfrac: ["frac"],
    sqrt: ["name", "sqrt"], pi: ["name", "pi"], tau: ["name", "tau"],
    phi: ["name", "phi"], varphi: ["name", "phi"], vert: ["bar"], lvert: ["bar"],
    rvert: ["bar"], left: ["skip"], right: ["skip"], quad: ["skip"], qquad: ["skip"],
    lfloor: ["name", "floor"], lceil: ["name", "ceil"], rfloor: ["skip"], rceil: ["skip"],
    circ: ["deg"]
};
for (const f of Object.keys(FNS))
    COMMANDS[f] = COMMANDS[f] || ["name", f];
for (const a of Object.keys(ALIASES))
    COMMANDS[a] = ["name", ALIASES[a]];

const KNOWN_WORDS = Object.keys(CONSTS).concat(Object.keys(FNS), Object.keys(ALIASES), ["mod"]);

function tokenize(src) {
    const out = [];
    let i = 0;
    while (i < src.length) {
        const c = src[i];
        const rest = src.slice(i);
        let m;
        if (/\s/.test(c)) {
            i++;
        } else if ((m = /^(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?/.exec(rest))) {
            out.push({ k: "num", s: m[0] });
            i += m[0].length;
        } else if ((m = /^\\([A-Za-z]+|[,;:! ])/.exec(rest))) {
            i += m[0].length;
            const cmd = COMMANDS[m[1]];
            if (m[1].length === 1 || (cmd && cmd[0] === "skip"))
                continue;
            if (!cmd)
                throw { msg: "unknown command \\" + m[1] };
            out.push(cmd[0] === "op" ? { k: "op", v: cmd[1] }
                   : cmd[0] === "name" ? { k: "name", v: cmd[1], tex: true }
                   : { k: cmd[0] });
        } else if ((m = /^(?:log2|log10|[A-Za-z]+)/.exec(rest))) {
            const w = m[0].toLowerCase();
            i += m[0].length;
            if (w === "mod")
                out.push({ k: "op", v: "mod" });
            else if (CONSTS[w] !== undefined || FNS[w] !== undefined)
                out.push({ k: "name", v: w });
            else if (ALIASES[w])
                out.push({ k: "name", v: ALIASES[w] });
            else
                out.push({ k: "name", v: w, unknown: true, last: i >= src.length });
        } else if (rest.startsWith("**")) {
            out.push({ k: "op", v: "^" });
            i += 2;
        } else {
            i++;
            switch (c) {
            case "+": out.push({ k: "op", v: "+" }); break;
            case "-": case "−": out.push({ k: "op", v: "-" }); break;
            case "*": case "·": case "⋅": out.push({ k: "op", v: "*" }); break;
            case "×": out.push({ k: "op", v: "x" }); break;
            case "/": out.push({ k: "op", v: "/" }); break;
            case "÷": out.push({ k: "op", v: "div" }); break;
            case "%": out.push({ k: "op", v: "mod" }); break;
            case "^": out.push({ k: "op", v: "^" }); break;
            case "²": out.push({ k: "sq", v: "2" }); break;
            case "³": out.push({ k: "sq", v: "3" }); break;
            case "!": out.push({ k: "bang" }); break;
            case "°": out.push({ k: "deg" }); break;
            case "_": out.push({ k: "under" }); break;
            case ",": out.push({ k: "comma" }); break;
            case "|": out.push({ k: "bar" }); break;
            case "(": case "[": case "{": out.push({ k: "open", v: c }); break;
            case ")": case "]": case "}": out.push({ k: "close", v: c }); break;
            case "π": out.push({ k: "name", v: "pi" }); break;
            case "τ": out.push({ k: "name", v: "tau" }); break;
            case "φ": out.push({ k: "name", v: "phi" }); break;
            case "√": out.push({ k: "name", v: "sqrt" }); break;
            case "∛": out.push({ k: "name", v: "cbrt" }); break;
            default: throw { msg: "unexpected " + c };
            }
        }
    }
    return out;
}

const CLOSER = { "(": ")", "[": "]", "{": "}" };

function parse(tokens) {
    let pos = 0;
    let absDepth = 0;
    const st = { incomplete: false, hadDiv: false };

    const peek = () => tokens[pos];
    const isOp = (v) => { const t = tokens[pos]; return t && t.k === "op" && t.v === v; };
    function hole() { st.incomplete = true; return { k: "hole" }; }

    function expr() {
        let a = term();
        while (isOp("+") || isOp("-")) {
            const op = tokens[pos++].v;
            a = { k: "bin", op: op, a: a, b: term() };
        }
        return a;
    }

    function term() {
        if (isOp("-")) {
            pos++;
            return { k: "neg", a: term() };
        }
        if (isOp("+")) {
            pos++;
            return term();
        }
        return mul();
    }
    function startsImplicit(t) {
        if (!t)
            return false;
        return t.k === "name" || t.k === "frac" || (t.k === "open" && t.v !== "{")
            || (t.k === "bar" && absDepth === 0);
    }
    function mul() {
        let a = unary();
        for (;;) {
            const t = peek();
            if (t && t.k === "op" && (t.v === "*" || t.v === "x" || t.v === "/" || t.v === "div" || t.v === "mod")) {
                pos++;
                if (t.v === "/" || t.v === "div")
                    st.hadDiv = true;
                a = { k: "bin", op: t.v, a: a, b: unary() };
            } else if (startsImplicit(t)) {
                a = { k: "bin", op: "imp", a: a, b: unary() };
            } else {
                return a;
            }
        }
    }
    function unary() {
        if (isOp("-")) {
            pos++;
            return { k: "neg", a: unary() };
        }
        if (isOp("+")) {
            pos++;
            return unary();
        }
        return power();
    }
    function power() {
        const base = postfix();
        if (isOp("^")) {
            pos++;
            return { k: "pow", a: base, b: unary() };
        }
        const t = peek();
        if (t && t.k === "sq") {
            pos++;
            return { k: "pow", a: base, b: { k: "num", s: t.v } };
        }
        return base;
    }
    function postfix() {
        let a = atom();
        for (;;) {
            const t = peek();
            if (t && t.k === "bang") {
                pos++;
                a = { k: "fact", a: a };
            } else if (t && t.k === "deg") {
                pos++;
                a = { k: "deg", a: a };
            } else if (isOp("^") && peek2IsDeg()) {
                pos += 2;
                a = { k: "deg", a: a };
            } else {
                return a;
            }
        }
    }
    function peek2IsDeg() {
        const t = tokens[pos + 1];
        return !!t && t.k === "deg";
    }
    function close(opener) {
        const t = peek();
        if (!t) {
            st.incomplete = true;
            return;
        }
        if (t.k !== "close" || t.v !== CLOSER[opener])
            throw { msg: "expected " + CLOSER[opener] };
        pos++;
    }

    function texArg() {
        const t = peek();
        if (t && t.k === "open" && t.v === "{") {
            pos++;
            const e = expr();
            close("{");
            return e;
        }
        if (t && t.k === "num" && t.s.length > 1 && /^\d+$/.test(t.s)) {
            const first = t.s[0];
            t.s = t.s.slice(1);
            return { k: "num", s: first };
        }
        return atom();
    }
    function atom() {
        const t = peek();
        if (!t)
            return hole();
        switch (t.k) {
        case "num":
            pos++;
            return { k: "num", s: t.s };
        case "frac": {
            pos++;
            st.hadDiv = true;
            const a = texArg();
            return { k: "bin", op: "/", a: a, b: texArg() };
        }
        case "open": {
            pos++;
            const e = expr();
            close(t.v);
            return { k: "group", fence: t.v, a: e };
        }
        case "bar": {
            pos++;
            absDepth++;
            const e = expr();
            absDepth--;
            if (!peek())
                st.incomplete = true;
            else if (peek().k === "bar")
                pos++;
            else
                throw { msg: "expected |" };
            return { k: "abs", a: e };
        }
        case "name":
            pos++;
            if (t.unknown) {
                if (t.last && KNOWN_WORDS.some(w => w.startsWith(t.v)))
                    return hole();
                throw { msg: "unknown name " + t.v };
            }
            if (CONSTS[t.v] !== undefined)
                return { k: "const", name: t.v };
            return fn(t);
        }
        throw { msg: "unexpected token" };
    }
    function fn(t) {
        const name = t.v;
        let sub = null;
        if (name === "sqrt" && t.tex) {
            let index = null;
            const o = peek();
            if (o && o.k === "open" && o.v === "[") {
                pos++;
                index = expr();
                close("[");
            }
            return { k: "fn", name: index ? "root" : "sqrt", args: index ? [texArg(), index] : [texArg()], paren: false };
        }
        if (name === "log" && peek() && peek().k === "under") {
            pos++;
            sub = texArg();
        }
        const o = peek();
        if (o && o.k === "open" && o.v === "(") {
            pos++;
            const args = [expr()];
            while (peek() && peek().k === "comma") {
                pos++;
                args.push(expr());
            }
            close("(");
            return checkArity({ k: "fn", name: name, args: args, paren: true, base: sub });
        }
        if (o && o.k === "open" && o.v === "{" && t.tex) {
            return checkArity({ k: "fn", name: name, args: [texArg()], paren: false, base: sub });
        }
        return checkArity({ k: "fn", name: name, args: [power()], paren: false, base: sub });
    }
    function checkArity(node) {
        const want = FNS[node.name];
        if (want > 0 && node.args.length !== want && !(node.name === "root" && node.args.length === 2))
            throw { msg: node.name + " takes " + want + " argument(s)" };
        return node;
    }

    const tree = expr();
    if (pos < tokens.length)
        throw { msg: "unexpected token" };
    return { tree: tree, incomplete: st.incomplete, hadDiv: st.hadDiv };
}

function gcd(a, b) {
    a = Math.abs(a);
    b = Math.abs(b);
    while (b) {
        const t = a % b;
        a = b;
        b = t;
    }
    return a;
}
function Q(n, d) {
    if (d === undefined)
        d = 1;
    if (d === 0 || !Number.isSafeInteger(n) || !Number.isSafeInteger(d))
        return null;
    if (d < 0) {
        n = -n;
        d = -d;
    }
    const g = gcd(n, d) || 1;
    return { n: n / g, d: d / g };
}
function qadd(x, y) {
    if (!x || !y)
        return null;
    const g = gcd(x.d, y.d);
    return Q(x.n * (y.d / g) + y.n * (x.d / g), x.d * (y.d / g));
}
function qneg(x) { return x ? Q(-x.n, x.d) : null; }
function qmul(x, y) {
    if (!x || !y)
        return null;
    const g1 = gcd(x.n, y.d) || 1, g2 = gcd(y.n, x.d) || 1;
    return Q((x.n / g1) * (y.n / g2), (x.d / g2) * (y.d / g1));
}
function qinv(x) { return x && x.n !== 0 ? Q(x.d, x.n) : null; }
function qint(x) { return !!x && x.d === 1; }
function qpowInt(x, e) {
    if (!x || Math.abs(e) > 4096)
        return null;
    let r = Q(1), b = e < 0 ? qinv(x) : x;
    for (let k = Math.abs(e); k > 0 && r; k--)
        r = qmul(r, b);
    return r;
}

function iroot(n, k) {
    if (n < 0 && k % 2 === 0)
        return null;
    const r = Math.round(Math.sign(n) * Math.pow(Math.abs(n), 1 / k));
    return Math.pow(r, k) === n ? r : null;
}
function qroot(x, k) {
    if (!x)
        return null;
    const n = iroot(x.n, k), d = iroot(x.d, k);
    return n !== null && d !== null ? Q(n, d) : null;
}
function qfloor(x) { return x ? Q(Math.floor(x.n / x.d)) : null; }
function qFromDecimal(s) {
    const m = /^(\d*)\.?(\d*)(?:[eE]([+-]?\d+))?$/.exec(s);
    if (!m)
        return null;
    let n = Number((m[1] || "0") + m[2]);
    let exp = (m[3] ? parseInt(m[3], 10) : 0) - m[2].length;
    if (Math.abs(exp) > 22)
        return null;
    return exp >= 0 ? Q(n * Math.pow(10, exp)) : Q(n, Math.pow(10, -exp));
}

function evaluate(node) {
    const V = (v, q) => ({ v: q ? q.n / q.d : v, q: q || null });
    switch (node.k) {
    case "hole":
        throw { incomplete: true };
    case "num":
        return V(parseFloat(node.s), qFromDecimal(node.s));
    case "const":
        return V(CONSTS[node.name], null);
    case "group":
        return evaluate(node.a);
    case "neg": {
        const a = evaluate(node.a);
        return V(-a.v, qneg(a.q));
    }
    case "abs": {
        const a = evaluate(node.a);
        return V(Math.abs(a.v), a.q ? Q(Math.abs(a.q.n), a.q.d) : null);
    }
    case "deg": {
        const a = evaluate(node.a);
        return V(a.v * Math.PI / 180, null);
    }
    case "fact": {
        const a = evaluate(node.a);
        if (!qint(a.q) || a.q.n < 0)
            return V(NaN, null);
        let v = 1, q = Q(1);
        for (let k = 2; k <= a.q.n && v < Infinity; k++) {
            v *= k;
            q = qmul(q, Q(k));
        }
        return V(v, q);
    }
    case "pow": {
        const a = evaluate(node.a), b = evaluate(node.b);
        let q = null;
        if (a.q && b.q) {
            if (b.q.d === 1)
                q = a.q.n === 0 && b.q.n < 0 ? null : qpowInt(a.q, b.q.n);
            else if (b.q.d <= 16)
                q = qpowInt(qroot(a.q, b.q.d), b.q.n);
        }
        let v = Math.pow(a.v, b.v);

        if (isNaN(v) && a.v < 0 && b.q && b.q.d % 2 === 1)
            v = (b.q.n % 2 === 0 ? 1 : -1) * Math.pow(-a.v, b.v);
        return V(v, q);
    }
    case "bin": {
        const a = evaluate(node.a), b = evaluate(node.b);
        switch (node.op) {
        case "+": return V(a.v + b.v, qadd(a.q, b.q));
        case "-": return V(a.v - b.v, qadd(a.q, qneg(b.q)));
        case "*": case "x": case "imp": return V(a.v * b.v, qmul(a.q, b.q));
        case "/": case "div": return V(a.v / b.v, qmul(a.q, qinv(b.q)));
        case "mod": {
            const q = a.q && b.q && b.q.n !== 0
                ? qadd(a.q, qneg(qmul(b.q, qfloor(qmul(a.q, qinv(b.q)))))) : null;
            return V(a.v - b.v * Math.floor(a.v / b.v), q);
        }
        }
        break;
    }
    case "fn": {
        const args = node.args.map(evaluate);
        const a = args[0];
        switch (node.name) {
        case "sqrt": return V(Math.sqrt(a.v), a.v >= 0 ? qroot(a.q, 2) : null);
        case "cbrt": return V(Math.cbrt(a.v), qroot(a.q, 3));
        case "root": {
            const k = args[1];
            if (qint(k.q) && k.q.n > 0)
                return V(k.q.n % 2 && a.v < 0 ? -Math.pow(-a.v, 1 / k.v) : Math.pow(a.v, 1 / k.v), qroot(a.q, k.q.n));
            return V(Math.pow(a.v, 1 / k.v), null);
        }
        case "abs": return V(Math.abs(a.v), a.q ? Q(Math.abs(a.q.n), a.q.d) : null);
        case "floor": return V(Math.floor(a.v), qfloor(a.q));
        case "ceil": return V(Math.ceil(a.v), a.q ? qneg(qfloor(qneg(a.q))) : null);
        case "round": return V(Math.round(a.v), a.q ? qfloor(qadd(a.q, Q(1, 2))) : null);
        case "min":
        case "max": {
            const pick = args.reduce((m, x) => (node.name === "min" ? x.v < m.v : x.v > m.v) ? x : m);
            return V(pick.v, args.every(x => x.q) ? pick.q : null);
        }
        case "ln": return V(Math.log(a.v), qint(a.q) && a.q.n === 1 ? Q(0) : null);
        case "log":
            if (node.base) {
                const base = evaluate(node.base);
                return V(Math.log(a.v) / Math.log(base.v),
                         qint(base.q) && base.q.n > 1 ? exactLog(a.q, base.q.n) : null);
            }
            return V(Math.log10(a.v), exactLog(a.q, 10));
        case "lg": return V(Math.log10(a.v), exactLog(a.q, 10));
        case "log2": return V(Math.log2(a.v), exactLog(a.q, 2));
        case "exp": return V(Math.exp(a.v), qint(a.q) && a.q.n === 0 ? Q(1) : null);
        case "sin": return V(Math.sin(a.v), zeroAtZero(a));
        case "cos": return V(Math.cos(a.v), a.q && a.q.n === 0 ? Q(1) : null);
        case "tan": return V(Math.tan(a.v), zeroAtZero(a));
        case "asin": return V(Math.asin(a.v), zeroAtZero(a));
        case "acos": return V(Math.acos(a.v), null);
        case "atan": return V(Math.atan(a.v), zeroAtZero(a));
        case "sinh": return V(Math.sinh(a.v), zeroAtZero(a));
        case "cosh": return V(Math.cosh(a.v), a.q && a.q.n === 0 ? Q(1) : null);
        case "tanh": return V(Math.tanh(a.v), zeroAtZero(a));
        }
    }
    }
    throw { msg: "cannot evaluate " + node.k };
}
function zeroAtZero(a) { return a.q && a.q.n === 0 ? Q(0) : null; }

function exactLog(q, b) {
    if (!q || q.n <= 0)
        return null;
    const num = q.d === 1 ? q.n : q.n === 1 ? q.d : 0;
    const sign = q.d === 1 ? 1 : -1;
    for (let k = 0, p = 1; p <= num; k++, p *= b)
        if (p === num)
            return Q(sign * k);
    return null;
}

const SIG = 12;

function expand(q) {
    const neg = q.n < 0;
    const n = Math.abs(q.n), d = q.d;
    const intPart = Math.floor(n / d);
    let r = n % d;
    const seen = {};
    let digits = "";
    while (r !== 0 && seen[r] === undefined) {
        if (digits.length >= 16)
            return null;
        seen[r] = digits.length;
        r *= 10;
        digits += Math.floor(r / d);
        r %= d;
    }
    if (r === 0)
        return { neg: neg, int: String(intPart), pre: digits, rep: "" };
    return { neg: neg, int: String(intPart), pre: digits.slice(0, seen[r]), rep: digits.slice(seen[r]) };
}

function floatParts(v) {
    if (Math.abs(v) < 1e-13)
        v = 0;
    if (v !== 0 && (Math.abs(v) >= 1e15 || Math.abs(v) < 1e-5)) {
        const s = v.toExponential(SIG - 1);
        const m = /^(-?[\d.]+)e([+-]\d+)$/.exec(s);
        return { mant: trimZeros(m[1]), exp: parseInt(m[2], 10) };
    }
    return { mant: trimZeros(String(Number(v.toPrecision(SIG)))), exp: 0 };
}
function trimZeros(s) {
    return s.indexOf(".") >= 0 && s.indexOf("e") < 0 ? s.replace(/\.?0+$/, "") : s;
}

const sym = (s, cls, it) => ({ t: "sym", s: s, cls: cls || "ord", it: !!it });
const row = (c) => ({ t: "row", c: c });

function bare(node) {
    return node.k === "group" && (node.fence === "(" || node.fence === "{") ? node.a : node;
}
function needsParens(node) {
    return node.k === "neg" || node.k === "bin" || (node.k === "fn" && !node.paren);
}

const OP_GLYPH = { "+": "+", "-": "−", "*": "·", x: "×", div: "÷" };
const OP_TEX = { "+": "+", "-": "-", "*": "\\cdot", x: "\\times", div: "\\div", mod: "\\bmod" };

function display(node) {
    switch (node.k) {
    case "hole": return { t: "hole" };
    case "num": return sym(node.s);
    case "const": return sym(CONST_GLYPH[node.name], "ord", true);
    case "group":
        return node.fence === "{" ? display(node.a) : fence(node.fence, CLOSER[node.fence], display(node.a));
    case "abs": return fence("|", "|", display(node.a));
    case "neg": {
        const a = wrapIf(node.a, node.a.k === "neg" || (node.a.k === "bin" && (node.a.op === "+" || node.a.op === "-")));
        return row([sym("−", "open"), a]);
    }
    case "fact": return row([wrapIf(node.a, needsParens(node.a) || node.a.k === "pow"), sym("!", "close")]);
    case "deg": return row([wrapIf(node.a, needsParens(node.a)), sym("°", "close")]);
    case "pow":
        return { t: "script", base: wrapIf(node.a, needsParens(node.a) || node.a.k === "pow"), sup: display(bare(node.b)) };
    case "bin": {
        if (node.op === "/")
            return { t: "frac", num: display(bare(node.a)), den: display(bare(node.b)) };
        const b = wrapIf(node.b, node.b.k === "neg" || (node.op === "-" && node.b.k === "bin" && (node.b.op === "+" || node.b.op === "-")));
        if (node.op === "imp")
            return row([display(node.a), b]);
        if (node.op === "mod")
            return row([display(node.a), sym("mod", "bin"), b]);
        return row([display(node.a), sym(OP_GLYPH[node.op], "bin"), b]);
    }
    case "fn": return displayFn(node);
    }
    return sym("?");
}
function wrapIf(node, cond) {
    return cond ? fence("(", ")", display(node)) : display(node);
}
function fence(l, r, body) { return { t: "fence", l: l, r: r, body: body }; }
function displayFn(node) {
    const args = node.args;
    switch (node.name) {
    case "sqrt": return { t: "radical", body: display(bare(args[0])) };
    case "cbrt": return { t: "radical", body: display(bare(args[0])), index: sym("3") };
    case "root": return { t: "radical", body: display(bare(args[0])), index: display(bare(args[1])) };
    case "abs": return fence("|", "|", display(bare(args[0])));
    case "floor": return fence("⌊", "⌋", display(bare(args[0])));
    case "ceil": return fence("⌈", "⌉", display(bare(args[0])));
    }
    let head;
    if (node.name === "log")
        head = { t: "script", base: sym("log", "op"), sub: node.base ? display(bare(node.base)) : sym("10") };
    else if (node.name === "log2")
        head = { t: "script", base: sym("log", "op"), sub: sym("2") };
    else
        head = sym(FN_GLYPH[node.name] || node.name, "op");
    if (!node.paren && !needsParens(args[0]))
        return row([head, display(args[0])]);
    const inner = [];
    args.forEach((a, i) => {
        if (i > 0)
            inner.push(sym(",", "punct"));
        inner.push(display(a));
    });
    return row([head, fence("(", ")", row(inner))]);
}

function tex(node) {
    switch (node.k) {
    case "hole": return "\\square";
    case "num": return node.s;
    case "const": return CONST_TEX[node.name];
    case "group":
        return node.fence === "{" ? "{" + tex(node.a) + "}" : delim(node.fence, CLOSER[node.fence], node.a);
    case "abs": return delim("|", "|", node.a);
    case "neg": return "-" + texWrap(node.a, node.a.k === "neg" || (node.a.k === "bin" && (node.a.op === "+" || node.a.op === "-")));
    case "fact": return texWrap(node.a, needsParens(node.a) || node.a.k === "pow") + "!";
    case "deg": return texWrap(node.a, needsParens(node.a)) + "^\\circ";
    case "pow":
        return texWrap(node.a, needsParens(node.a) || node.a.k === "pow") + "^{" + tex(bare(node.b)) + "}";
    case "bin": {
        if (node.op === "/")
            return "\\frac{" + tex(bare(node.a)) + "}{" + tex(bare(node.b)) + "}";
        const b = texWrap(node.b, node.b.k === "neg" || (node.op === "-" && node.b.k === "bin" && (node.b.op === "+" || node.b.op === "-")));
        if (node.op === "imp")
            return join(tex(node.a), b);
        return tex(node.a) + " " + OP_TEX[node.op] + " " + b;
    }
    case "fn": {
        const a = node.args;
        switch (node.name) {
        case "sqrt": return "\\sqrt{" + tex(bare(a[0])) + "}";
        case "cbrt": return "\\sqrt[3]{" + tex(bare(a[0])) + "}";
        case "root": return "\\sqrt[" + tex(bare(a[1])) + "]{" + tex(bare(a[0])) + "}";
        case "abs": return delim("|", "|", bare(a[0]));
        case "floor": return delim("\\lfloor", "\\rfloor", bare(a[0]));
        case "ceil": return delim("\\lceil", "\\rceil", bare(a[0]));
        }
        const head = node.name === "log" ? "\\log_{" + (node.base ? tex(bare(node.base)) : "10") + "}"
                   : node.name === "log2" ? "\\log_{2}"
                   : FN_TEX[node.name] || "\\operatorname{" + node.name + "}";
        if (!node.paren && !needsParens(a[0]))
            return join(head, tex(a[0]));
        return head + delimRaw("(", ")", a.map(tex).join(", "), a.some(isTall));
    }
    }
    return "";
}
function texWrap(node, cond) { return cond ? delim("(", ")", node) : tex(node); }
function isTall(node) {
    if (!node || typeof node !== "object")
        return false;
    if ((node.k === "bin" && node.op === "/") || (node.k === "fn" && /sqrt|cbrt|root/.test(node.name)))
        return true;
    return ["a", "b", "base"].some(key => isTall(node[key])) || (node.args || []).some(isTall);
}
function delim(l, r, inner) { return delimRaw(l, r, tex(inner), isTall(inner)); }
function delimRaw(l, r, s, tall) {
    return tall ? "\\left" + l + " " + s + " \\right" + r : l + s + r;
}

function join(a, b) {
    return /\\[A-Za-z]+$/.test(a) && /^[A-Za-z0-9]/.test(b) ? a + " " + b : a + b;
}

function groupDigits(s) {
    return s.length < 5 ? s : s.replace(/\B(?=(\d{3})+$)/g, " ");
}

function formatValue(val, hadDiv, tree) {
    const parts = [];
    let copy;
    const v = val.v;
    if (isNaN(v))
        return { parts: [{ rel: "=", disp: sym("undefined", "ord"), tex: "\\text{undefined}" }], copy: "NaN" };
    if (!isFinite(v)) {
        const s = v < 0 ? "−∞" : "∞";
        return { parts: [{ rel: "=", disp: sym(s), tex: (v < 0 ? "-" : "") + "\\infty" }], copy: v < 0 ? "-Infinity" : "Infinity" };
    }
    const q = val.q;
    if (q && q.d !== 1 && hadDiv && q.d <= 1e6 && !isPlainFraction(tree, q)) {
        const n = Math.abs(q.n);
        const f = { t: "frac", num: sym(String(n)), den: sym(String(q.d)) };
        parts.push({ rel: "=", disp: q.n < 0 ? row([sym("−", "open"), f]) : f, tex: (q.n < 0 ? "-" : "") + "\\frac{" + n + "}{" + q.d + "}" });
    }
    const ex = q && Math.abs(q.n / q.d) < 1e15 ? expand(q) : null;
    if (ex) {
        const sign = ex.neg && (ex.int !== "0" || ex.pre || ex.rep) ? "−" : "";
        let head = sign + groupDigits(ex.int) + (ex.pre || ex.rep ? "." + ex.pre : "");
        let texS = (sign ? "-" : "") + ex.int.replace(/\B(?=(\d{3})+$)/g, ex.int.length >= 5 ? "\\," : "") + (ex.pre || ex.rep ? "." + ex.pre : "");
        let disp = sym(head);
        if (ex.rep) {
            disp = row([sym(head), { t: "over", body: sym(ex.rep) }]);
            texS += "\\overline{" + ex.rep + "}";
        }
        parts.push({ rel: "=", disp: disp, tex: texS });
        copy = ex.rep ? trimZeros(String(Number((q.n / q.d).toPrecision(15)))) : (sign ? "-" : "") + ex.int + (ex.pre ? "." + ex.pre : "");
    } else {
        const fp = floatParts(v);

        const exact = qint(q) && fp.exp === 0;
        const neg = fp.mant[0] === "-";
        const mant = neg ? fp.mant.slice(1) : fp.mant;
        const mantDisp = (neg ? "−" : "") + (fp.exp === 0 && mant.indexOf(".") < 0 ? groupDigits(mant) : mant);
        let disp, texS;
        if (fp.exp !== 0) {
            disp = row([sym(mantDisp), sym("×", "bin"), { t: "script", base: sym("10"), sup: sym(fp.exp < 0 ? "−" + -fp.exp : String(fp.exp)) }]);
            texS = (neg ? "-" : "") + mant + " \\times 10^{" + fp.exp + "}";
            copy = fp.mant + "e" + fp.exp;
        } else {
            disp = sym(mantDisp);
            texS = (neg ? "-" : "") + mant;
            copy = fp.mant;
        }
        parts.push({ rel: exact ? "=" : "≈", disp: disp, tex: texS });
    }
    return { parts: parts, copy: copy };
}
function isPlainFraction(tree, q) {
    const t = tree.k === "neg" ? tree.a : tree;
    if (t.k !== "bin" || t.op !== "/" || bare(t.a).k !== "num" || bare(t.b).k !== "num")
        return false;
    return Math.abs(Number(bare(t.a).s)) === Math.abs(q.n) && Number(bare(t.b).s) === q.d;
}

function analyse(query) {
    let src = query.trim();
    const forced = src.startsWith("=");
    src = src.replace(/^=+/, "").replace(/=+\s*$/, "").trim();
    if (!src)
        return null;

    const numeric = forced || /[\d\\√∛π²³]/.test(src);
    if (!numeric && !/[-+*/^()|!×÷·]/.test(src))
        return null;

    let parsed;
    try {
        parsed = parse(tokenize(src));
    } catch (e) {
        return null;
    }
    const tree = parsed.tree;

    if (!forced && (tree.k === "num" || tree.k === "const" || tree.k === "hole"))
        return null;
    if (!numeric && parsed.incomplete)
        return null;

    const exprDisp = display(tree);
    let exprTex = tex(tree);
    if (parsed.incomplete) {
        return { tree: { t: "color", role: "dim", body: exprDisp }, tex: exprTex, copy: "", hasValue: false };
    }

    let val;
    try {
        val = evaluate(tree);
    } catch (e) {
        return null;
    }
    const res = formatValue(val, parsed.hadDiv, tree);
    const items = [exprDisp];
    let texS = exprTex;
    for (const p of res.parts) {
        items.push({ t: "color", role: "rel", body: sym(p.rel, "rel") });
        items.push({ t: "color", role: "result", body: p.disp });
        texS += " " + (p.rel === "≈" ? "\\approx" : "=") + " " + p.tex;
    }
    return { tree: row(items), tex: texS, copy: res.copy, hasValue: true };
}

const MU = 1 / 18;

const SPACE = {
    ord: { op: 3, bin: 4, rel: 5, inner: 3 },
    op: { ord: 3, op: 3, rel: 5, inner: 3 },
    bin: { ord: 4, op: 4, open: 4, inner: 4 },
    rel: { ord: 5, op: 5, open: 5, inner: 5 },
    close: { op: 3, bin: 4, rel: 5, inner: 3 },
    punct: { ord: 3, op: 3, rel: 3, open: 3, close: 3, punct: 3, inner: 3 },
    inner: { ord: 3, op: 3, bin: 4, rel: 5, open: 3, punct: 3, inner: 3 }
};
const SCRIPT_ONLY_SPACE = { bin: true, rel: true };

function shift(ops, dx, dy) {
    return ops.map(o => {
        const c = Object.assign({}, o);
        c.x += dx;
        c.y += dy;
        if (c.pts)
            c.pts = c.pts.map(p => [p[0] + dx, p[1] + dy]);
        return c;
    });
}

function layout(node, measure, size, family) {
    return lay(node, { measure: measure, family: family, role: "expr", tight: false }, size, 0);
}

function lay(node, env, s, depth) {
    const axis = 0.29 * s;
    const rule = Math.max(1, 0.05 * s);
    switch (node.t) {
    case "color":
        return lay(node.body, Object.assign({}, env, { role: node.role }), s, depth);
    case "sym": {
        const font = (node.it ? "italic " : "") + s.toFixed(2) + "px \"" + env.family + "\"";
        const w = env.measure(font, node.s) + (node.it ? 0.04 * s : 0);
        const low = /[gjpqyφ,()|⌊⌋⌈⌉]/.test(node.s);
        return {
            w: w, a: 0.74 * s, d: low ? 0.22 * s : 0.02 * s, cls: node.cls,
            ops: [{ op: "text", x: 0, y: 0, s: node.s, font: font, role: env.role }]
        };
    }
    case "hole":
        return {
            w: 0.6 * s, a: 0.68 * s, d: 0.02 * s, cls: "ord",
            ops: [{ op: "rect", x: 0.08 * s, y: -0.64 * s, w: 0.44 * s, h: 0.64 * s, lw: Math.max(1, 0.04 * s), role: "dim" }]
        };
    case "row": {
        let x = 0, a = 0, d = 0, ops = [], prev = null, first = null;
        for (const child of node.c) {
            const b = lay(child, env, s, depth);
            const left = b.clsL || b.cls;
            if (prev) {
                const mu = (SPACE[prev] || {})[left] || 0;
                const dropped = env.tight && (SCRIPT_ONLY_SPACE[prev] || SCRIPT_ONLY_SPACE[left]);
                if (!dropped)
                    x += mu * MU * s;
            }
            ops = ops.concat(shift(b.ops, x, 0));
            x += b.w;
            a = Math.max(a, b.a);
            d = Math.max(d, b.d);
            if (first === null)
                first = left;
            prev = b.clsR || b.cls;
        }
        return { w: x, a: a, d: d, cls: "ord", clsL: first || "ord", clsR: prev || "ord", ops: ops };
    }
    case "frac": {
        const cs = depth === 0 ? s * 0.92 : Math.max(9, s * 0.78);
        const num = lay(node.num, env, cs, depth + 1);
        const den = lay(node.den, env, cs, depth + 1);
        const pad = 0.12 * s, gap = 0.14 * s;
        const w = Math.max(num.w, den.w) + 2 * pad;
        const barY = -axis;
        const numBase = barY - rule / 2 - gap - num.d;
        const denBase = barY + rule / 2 + gap + den.a;
        const ops = shift(num.ops, (w - num.w) / 2, numBase)
            .concat(shift(den.ops, (w - den.w) / 2, denBase))
            .concat([{ op: "fill", x: 0.04 * s, y: barY - rule / 2, w: w - 0.08 * s, h: rule, role: env.role }]);
        return { w: w, a: -numBase + num.a, d: denBase + den.d, cls: "inner", ops: ops };
    }
    case "script": {
        const base = lay(node.base, env, s, depth);
        const ss = Math.max(8, s * 0.7);
        const senv = Object.assign({}, env, { tight: true });
        let w = base.w, a = base.a, d = base.d, ops = base.ops.slice();
        let extra = 0;
        if (node.sup) {
            const sup = lay(node.sup, senv, ss, depth + 1);
            const up = Math.max(0.42 * s, base.a - 0.3 * ss);
            ops = ops.concat(shift(sup.ops, base.w + 0.03 * s, -up));
            extra = Math.max(extra, sup.w + 0.03 * s);
            a = Math.max(a, up + sup.a);
        }
        if (node.sub) {
            const sub = lay(node.sub, senv, ss, depth + 1);
            const down = Math.max(0.2 * s, base.d + 0.1 * s);
            ops = ops.concat(shift(sub.ops, base.w, down));
            extra = Math.max(extra, sub.w);
            d = Math.max(d, down + sub.d);
        }
        return { w: w + extra, a: a, d: d, cls: base.cls, clsL: base.clsL, clsR: base.clsR, ops: ops };
    }
    case "radical": {
        const body = lay(node.body, env, s, depth);
        const gap = 0.14 * s;
        const top = -(Math.max(body.a, 0.7 * s) + gap);
        const bottom = Math.max(body.d, 0.12 * s) + 0.04 * s;
        const h = bottom - top;
        let x0 = 0, ops = [], a = -top + rule;
        if (node.index) {
            const idx = lay(node.index, Object.assign({}, env, { tight: true }), Math.max(8, s * 0.55), depth + 2);
            const idxBase = top + h * 0.42;
            x0 = Math.max(0, idx.w - 0.22 * s);
            ops = ops.concat(shift(idx.ops, 0, idxBase - 0.06 * s));
            a = Math.max(a, -(idxBase - 0.06 * s) + idx.a);
        }
        const tickY = top + h * 0.6;
        const p = [
            [x0 + 0.02 * s, tickY + 0.06 * s],
            [x0 + 0.16 * s, tickY - 0.02 * s],
            [x0 + 0.34 * s, bottom],
            [x0 + 0.34 * s + h * 0.2, top]
        ];
        const bodyX = p[3][0] + 0.06 * s;
        const w = bodyX + body.w + 0.08 * s;
        ops.push({ op: "line", x: 0, y: 0, pts: [p[0], p[1], p[2], p[3], [w, top]], lw: rule, role: env.role });
        ops.push({ op: "line", x: 0, y: 0, pts: [p[1], p[2]], lw: rule * 2.4, role: env.role });
        ops = ops.concat(shift(body.ops, bodyX, 0));
        return { w: w, a: a, d: bottom, cls: "ord", ops: ops };
    }
    case "over": {
        const body = lay(node.body, env, s, depth);
        const y = -(body.a + 0.02 * s);
        const ops = body.ops.concat([{ op: "fill", x: 0.02 * s, y: y - rule / 2, w: body.w - 0.02 * s, h: rule, role: env.role }]);
        return { w: body.w, a: -y + rule, d: body.d, cls: "ord", ops: ops };
    }
    case "fence": {
        const body = lay(node.body, env, s, depth);
        const half = Math.max(body.a - axis, body.d + axis) + 0.06 * s;
        const tall = half * 2 > 1.12 * s;
        const H = Math.max(half * 2, 1.0 * s);
        const yTop = -axis - H / 2, yBot = -axis + H / 2;
        const L = delimiter(node.l, true, tall, yTop, yBot, s, env, rule);
        const R = delimiter(node.r, false, tall, yTop, yBot, s, env, rule);

        const padIn = tall ? 0.04 * s : 0;
        let ops = L.ops.slice();
        ops = ops.concat(shift(body.ops, L.w + padIn, 0));
        ops = ops.concat(shift(R.ops, L.w + padIn + body.w + padIn, 0));
        return {
            w: L.w + body.w + 2 * padIn + R.w,
            a: Math.max(body.a, -yTop, L.a), d: Math.max(body.d, yBot, L.d),
            cls: "inner", clsL: "open", clsR: "close", ops: ops
        };
    }
    }
    return { w: 0, a: 0, d: 0, cls: "ord", ops: [] };
}

function delimiter(ch, left, tall, yTop, yBot, s, env, rule) {
    if (!tall) {
        const b = lay(sym(ch, left ? "open" : "close"), env, s, 0);
        return { w: b.w, a: b.a, d: b.d, ops: b.ops };
    }
    const H = yBot - yTop;
    const role = env.role;
    if (ch === "(" || ch === ")") {
        const w = 0.34 * s + H * 0.05;
        const inner = left ? w * 0.82 : w * 0.18;
        const bulge = left ? w * 0.14 : w * 0.86;
        const thick = (left ? 1 : -1) * Math.max(rule * 3.5, 0.2 * s);

        const cx = 2 * bulge - inner;
        return {
            w: w, a: -yTop, d: yBot, ops: [{
                op: "paren", x: 0, y: 0, role: role,
                pts: [[inner, yTop], [cx, (yTop + yBot) / 2], [inner, yBot], [cx + thick, (yTop + yBot) / 2]]
            }]
        };
    }
    const w = 0.3 * s;
    const lw = Math.max(1, rule * 1.1);
    const xs = left ? 0.12 * s : w - 0.12 * s;
    const xe = left ? w - 0.02 * s : 0.02 * s;
    let pts;
    if (ch === "|")
        pts = [[w / 2, yTop], [w / 2, yBot]];
    else if (ch === "[" || ch === "]")
        pts = [[xe, yTop], [xs, yTop], [xs, yBot], [xe, yBot]];
    else if (ch === "⌊" || ch === "⌋")
        pts = [[xs, yTop], [xs, yBot], [xe, yBot]];
    else
        pts = [[xe, yTop], [xs, yTop], [xs, yBot]];
    return { w: w, a: -yTop, d: yBot, ops: [{ op: "line", x: 0, y: 0, pts: pts, lw: lw, role: role, square: true }] };
}
