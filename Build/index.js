// ── Volume ────────────────────────────────────────────────────────
const frame   = document.getElementById('game-frame');
const slider  = document.getElementById('vol-slider');
const iconOn  = document.getElementById('icon-vol-on');
const iconOff = document.getElementById('icon-vol-off');
const volIcon = document.getElementById('vol-icon');

let lastVol = 1;

function setFrameVolume(v)
{
    try
    {
        const vids = frame.contentDocument?.querySelectorAll('audio, video') ?? [];
        vids.forEach(el => el.volume = v);
    } catch (_) {}
}

slider.addEventListener('input', () =>
{
    const v = parseFloat(slider.value);
    lastVol = v > 0 ? v : lastVol;
    iconOn.style.display  = v > 0 ? '' : 'none';
    iconOff.style.display = v > 0 ? 'none' : '';
    setFrameVolume(v);
});

volIcon.addEventListener('click', () =>
{
    if (parseFloat(slider.value) > 0) slider.value = 0;
    else slider.value = lastVol;
    slider.dispatchEvent(new Event('input'));
});

const volSlider = document.getElementById("vol-slider");
const volPercent = document.getElementById("vol-percent");

function updateVolumeUI()
{
    volPercent.textContent =
        `${Math.round(volSlider.value * 100)}%`;
}

volSlider.addEventListener("input", updateVolumeUI);

updateVolumeUI();

// ── Fullscreen ────────────────────────────────────────────────────
const fsBtn     = document.getElementById('fs-btn');
const iconEnter = document.getElementById('icon-fs-enter');
const iconExit  = document.getElementById('icon-fs-exit');
const gameWrap  = document.getElementById('game-wrap');

fsBtn.addEventListener('click', () => {
    if (!document.fullscreenElement) gameWrap.requestFullscreen();
    else document.exitFullscreen();
});

document.addEventListener('fullscreenchange', () =>
{
    const inFS = !!document.fullscreenElement;
    iconEnter.style.display = inFS ? 'none' : '';
    iconExit.style.display  = inFS ? '' : 'none';
    window.dispatchEvent(new Event("resize"));

    const frame = document.getElementById("game-frame");
    try
    {
        frame.contentWindow.dispatchEvent(new Event("resize"));
    } catch {}
});

// Dot grid BG
const canvas = document.createElement('canvas');
canvas.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;z-index:0;pointer-events:none';
document.body.prepend(canvas);
const ctx = canvas.getContext('2d');

const SPACING       = 36;
const DOT_R         = 2;
const FISH_R        = 220;
const FISH_R2       = FISH_R * FISH_R;
const FISH_STRENGTH = 0.2;
const FISH_FADE = 0.12;

let fish_r2 = 0;
let mx = -9999, my = -9999;
let iframeFocused = false;

window.addEventListener('mousemove', e =>
{
    mx = e.clientX;
    my = e.clientY;
});

gameWrap.addEventListener('mouseenter', () => { iframeFocused = true; });
gameWrap.addEventListener('mouseleave', () => { iframeFocused = false; });

let gridPts = [];

function buildGrid(w, h)
{
    gridPts = [];
    const cols = Math.ceil(w / SPACING) + 2;
    const rows = Math.ceil(h / SPACING) + 2;
    for (let r = 0; r < rows; r++)
        for (let c = 0; c < cols; c++)
            gridPts.push(c * SPACING, r * SPACING);
}

function resizeCanvas()
{
    canvas.width  = window.innerWidth;
    canvas.height = window.innerHeight;
    buildGrid(canvas.width, canvas.height);
}
resizeCanvas();
window.addEventListener('resize', resizeCanvas);

let lastFrame = 0;
const FRAME_MS = 1000 / 30;

function drawDots(ts)
{
    requestAnimationFrame(drawDots);
    if (ts - lastFrame < FRAME_MS) return;
    lastFrame = ts;

    const targetR2 = iframeFocused ? 0 : FISH_R2;
    fish_r2 += (targetR2 - fish_r2) * FISH_FADE;

    const fish_r = Math.sqrt(fish_r2);
    mx = mx;
    my = my;

    ctx.clearRect(0, 0, canvas.width, canvas.height);

    for (let i = 0; i < gridPts.length; i += 2)
    {
        const gx = gridPts[i];
        const gy = gridPts[i + 1];

        const dx   = gx - mx;
        const dy   = gy - my;
        const dist2 = dx * dx + dy * dy;

        let px = gx, py = gy, scale = 1;

        if (dist2 < fish_r2 && dist2 > 0)
        {
            const dist    = Math.sqrt(dist2);
            const norm    = dist / fish_r;
            const falloff = (1 - norm) * (1 - norm);
            const push    = falloff * FISH_STRENGTH;
            px    = gx + dx * push;
            py    = gy + dy * push;
            scale = 1 + falloff * 1.2;
        }

        const alpha = 0.18 + (scale - 1) * 0.28;
        ctx.beginPath();
        ctx.arc(px, py, DOT_R * Math.min(scale, 1.5), 0, Math.PI * 2);
        ctx.fillStyle = `rgba(255,255,255,${Math.min(alpha, 0.5)})`;
        ctx.fill();
    }
}
requestAnimationFrame(drawDots);