import os
import sys
import subprocess
import math

pcb = sys.argv[1]
outdir = sys.argv[2]

frames_dir = os.path.join(outdir, "frames")
os.makedirs(frames_dir, exist_ok=True)

angles = range(0, 360, 5)

for angle in angles:

    outfile = os.path.join(
        frames_dir,
        f"frame_{angle:03d}.png"
    )

    tilt = 130 * math.sin(math.radians(angle*2))

    rotation = f"--rotate='{tilt:.1f},0,{angle}'"

    #rotation = f"--rotate='-30,0,{angle}'"

    cmd = [
        "kicad-cli",
        "pcb",
        "render",
        "--background",
        "opaque",
        rotation,
        "--zoom",
        "0.9",
        "--perspective",
 #       "--floor",
        "--width",
        "640",
        "--height",
        "640",
        "--light-top", "0.9",
        "--light-side", "0.2",
        "--light-camera", "0.0",
        "--light-bottom", "0.0",
        "--output",
        outfile,
        pcb
    ]

    print("Rendering:", rotation)

    subprocess.run(cmd, check=True)

gif_out = os.path.join(outdir, "board_spin.gif")

subprocess.run([
    "magick",
    os.path.join(frames_dir, "frame_*.png"),
    "-dispose", "2",
    "-delay", "8",
    "-loop", "0",
    gif_out
], check=True)

print("GIF created:", gif_out)

subprocess.run([
    "ffmpeg",
    "-y",

    "-framerate", "12",

    "-i", os.path.join(frames_dir, "frame_%03d.png"),

    "-vf", "format=yuv420p",

    "-c:v", "libx264",

    "-pix_fmt", "yuv420p",

    "-movflags", "+faststart",

    os.path.join(outdir, "board_spin.mp4")
], check=True)
print("MP4 created:", os.path.join(outdir, "board_spin.mp4"))