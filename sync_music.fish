function sync_music
    # --- Configuration ---
    # Set the source directory for your music.
    # The trailing slash is important! It tells rsync to copy the *contents*
    # of the directory, not the directory itself.
    set source_dir "/Users/shaped/Library/CloudStorage/ProtonDrive-write@cesarbrun.xyz-folder/HibyR1-exports/"

    # Set the destination directory on your SD card.
    set dest_dir /Volumes/64failing/Music/

    # --- Logic ---
    echo "🎵 Starting music sync..."
    echo "     From: $source_dir"
    echo "       To: $dest_dir"
    echo ""

    # Check if the destination directory exists.
    if not test -d "$dest_dir"
        echo "❌ Error: Destination directory not found at $dest_dir"
        echo "   Please make sure your SD card is mounted correctly."
        return 1 # Exit the function with an error code
    end

    # Run the rsync command with options:
    # -a: Archive mode (preserves permissions, timestamps, etc.)
    # -v: Verbose (lists the files being transferred)
    # -h: Human-readable format for file sizes
    # --progress: Shows a progress bar for each file
    # --append-verify: Resumes transfers of partial files and verifies checksums after.
    #                  This is generally safer than just --append.
    # --delete: Deletes files from the destination if they no longer exist in the source.
    #           (Optional: remove this if you don't want this behavior)
    rsync -avh --progress --append-verify --delete "$source_dir" "$dest_dir"

    echo ""
    echo "✅ Music sync complete."
end
