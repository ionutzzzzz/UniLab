#!/usr/bin/env python3
"""
UniLab Video Exporter
Compiles frame images into an optimized MP4 video file using OpenCV.
"""
import sys
import os
import argparse
import glob
import time

try:
    import cv2
    import numpy as np
    HAS_CV2 = True
except ImportError:
    HAS_CV2 = False


def compile_frames_to_mp4(input_dir, output_path, fps=30):
    if not HAS_CV2:
        print("ERROR: opencv-python (cv2) is not installed in the python environment.", file=sys.stderr)
        return False

    if not os.path.isdir(input_dir):
        print(f"ERROR: Input directory does not exist: {input_dir}", file=sys.stderr)
        return False

    # Find all frame images sorted numerically/alphabetically
    extensions = ('*.png', '*.jpg', '*.jpeg')
    frame_files = []
    for ext in extensions:
        frame_files.extend(glob.glob(os.path.join(input_dir, ext)))

    frame_files.sort()

    if not frame_files:
        print(f"ERROR: No image frames found in {input_dir}", file=sys.stderr)
        return False

    # Read first frame to get dimensions
    first_frame = cv2.imread(frame_files[0])
    if first_frame is None:
        print(f"ERROR: Could not read first frame: {frame_files[0]}", file=sys.stderr)
        return False

    height, width, _ = first_frame.shape

    # Ensure output directory exists
    out_dir = os.path.dirname(os.path.abspath(output_path))
    if out_dir and not os.path.exists(out_dir):
        os.makedirs(out_dir, exist_ok=True)

    # Use mp4v codec for universal MP4 compatibility
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    writer = cv2.VideoWriter(output_path, fourcc, float(fps), (width, height))

    if not writer.isOpened():
        # Fallback to avc1 or MJPG if mp4v fails
        for fallback_fourcc in ('avc1', 'XVID', 'MJPG'):
            try:
                fourcc = cv2.VideoWriter_fourcc(*fallback_fourcc)
                writer = cv2.VideoWriter(output_path, fourcc, float(fps), (width, height))
                if writer.isOpened():
                    break
            except Exception:
                continue

    if not writer.isOpened():
        print(f"ERROR: Failed to initialize VideoWriter for {output_path}", file=sys.stderr)
        return False

    total_frames = len(frame_files)
    t0 = time.time()

    for idx, frame_path in enumerate(frame_files):
        img = cv2.imread(frame_path)
        if img is not None:
            if img.shape[0] != height or img.shape[1] != width:
                img = cv2.resize(img, (width, height), interpolation=cv2.INTER_LINEAR)
            writer.write(img)

    writer.release()
    elapsed = time.time() - t0
    file_size_kb = os.path.getsize(output_path) / 1024.0

    print(f"SUCCESS: Exported {total_frames} frames to {output_path} ({file_size_kb:.1f} KB in {elapsed:.2f}s)")
    return True


def run_self_test():
    if not HAS_CV2:
        print("FAIL: cv2 not installed")
        return 1

    temp_dir = "/tmp/unilab_test_frames"
    temp_mp4 = "/tmp/unilab_test_output.mp4"
    os.makedirs(temp_dir, exist_ok=True)

    try:
        # Create 30 synthetic frames
        w, h = 640, 480
        for i in range(30):
            canvas = np.zeros((h, w, 3), dtype=np.uint8)
            # Draw gradient background
            canvas[:, :, 0] = int(20 + i * 2)
            canvas[:, :, 1] = int(30 + i)
            canvas[:, :, 2] = 50
            # Draw moving circle
            cv2.circle(canvas, (80 + i * 15, 240), 30, (0, 230, 180), -1)
            cv2.putText(canvas, f"UniLab Frame {i:03d}", (40, 60), cv2.FONT_HERSHEY_SIMPLEX, 1.0, (255, 255, 255), 2)
            cv2.imwrite(os.path.join(temp_dir, f"frame_{i:04d}.png"), canvas)

        ok = compile_frames_to_mp4(temp_dir, temp_mp4, fps=30)
        if ok and os.path.exists(temp_mp4) and os.path.getsize(temp_mp4) > 100:
            print("Self-test PASSED!")
            return 0
        else:
            print("Self-test FAILED!")
            return 1
    finally:
        for f in glob.glob(os.path.join(temp_dir, "*")):
            try: os.remove(f)
            except: pass
        try: os.rmdir(temp_dir)
        except: pass
        if os.path.exists(temp_mp4):
            try: os.remove(temp_mp4)
            except: pass


def main():
    parser = argparse.ArgumentParser(description="UniLab MP4 Video Exporter")
    parser.add_argument("--input-dir", help="Directory containing frame images (*.png, *.jpg)")
    parser.add_argument("--output", help="Output .mp4 file destination")
    parser.add_argument("--fps", type=float, default=30.0, help="Frames per second (default: 30)")
    parser.add_argument("--test", action="store_true", help="Run self-test verification")

    args = parser.parse_args()

    if args.test:
        sys.exit(run_self_test())

    if not args.input_dir or not args.output:
        parser.print_help()
        sys.exit(1)

    success = compile_frames_to_mp4(args.input_dir, args.output, fps=args.fps)
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
