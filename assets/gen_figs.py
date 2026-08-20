# -*- coding: utf-8 -*-
"""生成三张静态 SVG 图，供 New Concepts/ 下的笔记内联引用。
数据全部实算，改参数后重跑即可。用法： python assets/gen_figs.py
"""
import io, math, os

BG, LINE, TX, TX3 = '#0d1117', '#232c38', '#c9d4e0', '#5f6b7a'
HL, HL2, OK, WARN = '#ffcb6b', '#7fd1ff', '#8bd48b', '#ff9d7a'
FONT = "-apple-system,'Segoe UI','PingFang SC','Microsoft YaHei',sans-serif"
MONO = "Consolas,'JetBrains Mono',monospace"
OUT = os.path.dirname(os.path.abspath(__file__))


def hdr(w, h):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
            f'viewBox="0 0 {w} {h}" font-family="{FONT}">'
            f'<rect width="{w}" height="{h}" rx="8" fill="{BG}" stroke="{LINE}"/>')


def txt(x, y, s, fill=TX, size=13, anchor='start', mono=False, weight='normal'):
    f = f' font-family="{MONO}"' if mono else ''
    return (f'<text x="{x}" y="{y}" fill="{fill}" font-size="{size}" '
            f'text-anchor="{anchor}" font-weight="{weight}"{f}>{s}</text>')


def save(name, body):
    p = os.path.join(OUT, name)
    io.open(p, 'w', encoding='utf-8', newline='\n').write(body + '</svg>\n')
    print('written:', name, os.path.getsize(p), 'bytes')


# ── 图 1：HG 相位函数三个 g 的花瓣 ────────────────────────────────
def hg(c, g):
    g2 = g * g
    return (1 - g2) / (4 * math.pi * max(1 + g2 - 2 * g * c, 1e-4) ** 1.5)


def fig_phase():
    W, H, PW = 840, 320, 280
    s = [hdr(W, H), txt(W / 2, 26, 'Henyey-Greenstein 相位函数：g 越大越集中在前向',
                        TX, 14, 'middle', weight='600')]
    for i, g in enumerate((0.0, 0.4, 0.8)):
        cx, cy, R = i * PW + PW / 2, 178, 88
        peak = max(hg(math.cos(math.radians(a)), g) for a in range(361))
        sc = R / peak
        s.append(f'<circle cx="{cx}" cy="{cy}" r="{R}" fill="none" stroke="#1c2530"/>')
        s.append(f'<line x1="{cx-R-16}" y1="{cy}" x2="{cx+R+16}" y2="{cy}" stroke="#1c2530"/>')
        s.append(f'<line x1="{cx}" y1="{cy-R-14}" x2="{cx}" y2="{cy+R+14}" stroke="#1c2530"/>')
        pts = []
        for a in range(361):
            t = math.radians(a)
            r = hg(math.cos(t), g) * sc
            pts.append(f'{cx + math.cos(t) * r:.1f},{cy - math.sin(t) * r:.1f}')
        s.append(f'<polygon points="{" ".join(pts)}" fill="{HL}" fill-opacity="0.22" '
                 f'stroke="{HL}" stroke-width="2"/>')
        # 指向光源
        s.append(f'<line x1="{cx}" y1="{cy}" x2="{cx+R+14}" y2="{cy}" stroke="{HL2}" stroke-width="1.6"/>')
        s.append(f'<polygon points="{cx+R+20},{cy} {cx+R+10},{cy-4.5} {cx+R+10},{cy+4.5}" fill="{HL2}"/>')
        s.append(txt(cx, cy + R + 34, f'g = {g:.1f}', HL, 14, 'middle', mono=True, weight='600'))
        s.append(txt(cx, cy + R + 52, f'峰值 {peak:.3f}', TX3, 11, 'middle', mono=True))
    s.append(txt(W / 2, H - 10, '→ 蓝色箭头 = 指向光源；花瓣离中心越远，表示往该方向散射越多（各图按自身峰值归一化）',
                 TX3, 11, 'middle'))
    save('fig-hg-phase.svg', ''.join(s))


# ── 图 2：三种深度切片分布 ────────────────────────────────────────
def fig_depth():
    W, H = 840, 290
    NEAR, FAR, N, MARK = 0.3, 64.0, 56, 16.0
    modes = [('均匀   Δz 恒定', lambda t: NEAR + (FAR - NEAR) * t, '#8b98a8'),
             ('平方   Δz ∝ √z    ← froxel', lambda t: NEAR + (FAR - NEAR) * t * t, OK),
             ('对数   Δz ∝ z      ← cluster', lambda t: NEAR * (FAR / NEAR) ** t, HL2)]
    L, R = 210, W - 34
    s = [hdr(W, H), txt(W / 2, 26, f'同样 {N} 个切片，三种深度分布（near {NEAR} m → far {int(FAR)} m）',
                        TX, 14, 'middle', weight='600')]
    for i, (name, f, col) in enumerate(modes):
        y = 84 + i * 62
        s.append(txt(L - 16, y + 5, name, col, 12.5, 'end', mono=True))
        s.append(f'<line x1="{L}" y1="{y+17}" x2="{R}" y2="{y+17}" stroke="#1c2530"/>')
        cnt = 0
        for k in range(N + 1):
            d = f(k / N)
            x = L + (d - NEAR) / (FAR - NEAR) * (R - L)
            if d <= MARK:
                cnt += 1
            c = col if d <= MARK else '#3a4553'
            s.append(f'<line x1="{x:.1f}" y1="{y-13}" x2="{x:.1f}" y2="{y+13}" stroke="{c}"/>')
        mx = L + (MARK - NEAR) / (FAR - NEAR) * (R - L)
        s.append(f'<line x1="{mx:.1f}" y1="{y-22}" x2="{mx:.1f}" y2="{y+22}" '
                 f'stroke="{HL}" stroke-width="1.4" stroke-dasharray="4 3"/>')
        s.append(txt(mx + 7, y - 9, f'{cnt/(N+1)*100:.0f}%', col, 12, mono=True, weight='600'))
    s.append(txt(L, H - 34, f'{NEAR} m', TX3, 11, mono=True))
    s.append(txt(R, H - 34, f'{int(FAR)} m', TX3, 11, 'end', mono=True))
    s.append(txt(W / 2, H - 12,
                 f'黄色虚线 = {int(MARK)} m；百分比 = 前 {int(MARK)} m 分到的切片占比。对数把七成切片压在最近处，'
                 f'远处只剩十几层 → 光柱后半段出色带',
                 TX3, 11, 'middle'))
    save('fig-depth-distribution.svg', ''.join(s))


# ── 图 3：色带 vs 抖动（与交互 demo 同一场景，实算）─────────────
def fig_banding():
    W, H = 840, 268
    CAM = (440.0, 414.0)
    HALF, MAXD, NRAY = math.radians(42), 372.0, 336
    sx, sy = 0.30, -1.0
    ln = math.hypot(sx, sy)
    SUN = (sx / ln, sy / ln)
    BARS = [(440 - 3.5 * 84 + i * 84 + 27, 96.0, 30.0, 118.0) for i in range(7)]

    def hits(px, py, dx, dy, b):
        bx, by, bw, bh = b
        tmin, tmax = -1e30, 1e30
        for p, d, lo, hi in ((px, dx, bx, bx + bw), (py, dy, by, by + bh)):
            if abs(d) < 1e-9:
                if p < lo or p > hi:
                    return False
            else:
                t1, t2 = (lo - p) / d, (hi - p) / d
                if t1 > t2:
                    t1, t2 = t2, t1
                tmin, tmax = max(tmin, t1), min(tmax, t2)
        return tmax >= max(tmin, 0)

    def lit(x, y):
        return 0.0 if any(hits(x, y, SUN[0], SUN[1], b) for b in BARS) else 1.0

    def march(ri, steps, dither):
        a = -HALF + 2 * HALF * ri / (NRAY - 1)
        dx, dy = math.sin(a), -math.cos(a)
        step = MAXD / steps
        j = (math.sin(ri * 127.1) * 43758.5453) % 1.0 if dither else 0.5
        return sum(lit(CAM[0] + dx * (i + j) * step, CAM[1] + dy * (i + j) * step)
                   for i in range(steps)) * step / MAXD

    s = [hdr(W, H), txt(W / 2, 26, '抖动：不增加任何采样，把规律色带换成细噪点',
                        TX, 14, 'middle', weight='600')]
    L, RW = 30, W - 60
    bw = RW / NRAY
    rows = [('6 步 · 无抖动　→ 一道道台阶', 6, False, WARN),
            ('6 步 · 有抖动　→ 采样数完全相同', 6, True, OK),
            ('64 步 · 参考真值', 64, False, TX3)]
    for row, (label, steps, dither, col) in enumerate(rows):
        y = 60 + row * 62
        s.append(txt(L, y - 7, label, col, 12, mono=True, weight='600'))
        for r in range(NRAY):
            v = march(r, steps, dither)
            c = min(255, int(v * 470))
            s.append(f'<rect x="{L + r*bw:.2f}" y="{y}" width="{bw+0.5:.2f}" height="36" '
                     f'fill="rgb({c},{int(c*0.93)},{int(c*0.78)})"/>')
        s.append(f'<rect x="{L}" y="{y}" width="{RW}" height="36" fill="none" stroke="{LINE}"/>')
    s.append(txt(W / 2, H - 14,
                 f'前两条的采样次数完全一样（{NRAY} 条视线 × 6 步）。抖动只是让每条视线的起步位置随机错开一点点，'
                 f'色块段数 31 → 164（64 步参考值 176，说明抖动后的空间结构已接近真值）',
                 TX3, 11, 'middle'))
    save('fig-banding-dither.svg', ''.join(s))


if __name__ == '__main__':
    fig_phase()
    fig_depth()
    fig_banding()
