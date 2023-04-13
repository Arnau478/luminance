Xephyr :1 & # Open xephyr in parallel
while [ ! -f /tmp/.X1-lock ]; do :; done # Wait for the X lock
env DISPLAY=:1 zig-out/bin/luminance & # Start luminance
wait # Wait for parallel processes to finish
